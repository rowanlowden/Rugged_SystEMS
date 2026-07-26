import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/foundation.dart' show FlutterError, debugPrint;
import 'package:flutter/services.dart';

const offroadGridWkid = 3071;
const offroadWalkingWeightThreshold = 3.0;

/// Solves the build-time configured least-cost path from one local Esri ASCII
/// cost grid. No display raster, map view, network service, or user input is
/// used.
///
/// The bundled default is `assets/offline/costsurface.asc`, interpreted as
/// WKID 3071. Configure an existing local grid-file path with `--dart-define`.
/// Start and destination coordinates are selected randomly from connected,
/// traversable cells in the grid.
///
/// ```text
/// OFFLINE_COST_GRID_PATH=/app/data/cost.asc
/// ```
Future<LeastCostPathResult> solvePresetLeastCostPath() async {
  const gridPath = String.fromEnvironment(
    'OFFLINE_COST_GRID_PATH',
    defaultValue: 'assets/offline/costsurface.asc',
  );
  const wkid = offroadGridWkid;

  if (gridPath.trim().isEmpty) {
    throw const FormatException(
      'OFFLINE_COST_GRID_PATH must identify an app-readable Esri ASCII grid.',
    );
  }

  final localGridPath = await _resolveCostGridPath(gridPath);

  final result = await OfflineLeastCostPathSolver(
    costGridPath: localGridPath,
    spatialReferenceWkid: wkid,
  ).solveRandomCoordinates();
  debugPrint(
    'Least-cost path solved successfully: ${result.cells.length} cells, '
    'accumulated cost ${result.accumulatedCost}.',
  );
  return result;
}

/// Solves from an on-road destination to a fixed off-road destination.
Future<LeastCostPathResult> solveLeastCostPathToFixedDestination({
  required ArcGISPoint start,
  required ArcGISPoint destination,
}) async {
  const gridPath = String.fromEnvironment(
    'OFFLINE_COST_GRID_PATH',
    defaultValue: 'assets/offline/costsurface.asc',
  );
  final localGridPath = await _resolveCostGridPath(gridPath);
  return OfflineLeastCostPathSolver(
    costGridPath: localGridPath,
    spatialReferenceWkid: offroadGridWkid,
  ).solve(
    start: start,
    destination: destination,
  );
}

Future<String> _resolveCostGridPath(String configuredPath) async {
  final path = configuredPath.trim();
  if (path.isEmpty) {
    throw const FormatException(
      'OFFLINE_COST_GRID_PATH must identify an app-readable Esri ASCII grid.',
    );
  }

  final localFile = File(path);
  if (await localFile.exists()) {
    return localFile.absolute.path;
  }

  try {
    final assetData = await rootBundle.load(path);
    final tempDirectory = await Directory.systemTemp.createTemp('rugged_grid_');
    final outputFile = File('${tempDirectory.path}/cost.asc');
    await outputFile.writeAsBytes(
      assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      ),
      flush: true,
    );
    return outputFile.path;
  } on FlutterError catch (_) {
    throw FileSystemException(
      'ASCII cost grid was not found as a local file or bundled asset',
      path,
    );
  }
}

/// Performs headless least-cost-path analysis using only an Esri ASCII grid.
///
/// File parsing and A* run in a worker isolate. ArcGIS geometry is created on
/// the calling isolate and returned to whichever file is responsible for
/// display or persistence.
class OfflineLeastCostPathSolver {
  const OfflineLeastCostPathSolver({
    required this.costGridPath,
    required this.spatialReferenceWkid,
  });

  /// Path to an Esri ASCII cost grid in app-accessible local storage.
  final String costGridPath;

  /// Coordinate-system WKID for both the grid and input/output geometry.
  final int spatialReferenceWkid;

  /// Solves between two preset ArcGIS points.
  Future<LeastCostPathResult> solve({
    required ArcGISPoint start,
    required ArcGISPoint destination,
  }) {
    _validatePointSpatialReference(start, 'start');
    _validatePointSpatialReference(destination, 'destination');
    return solveCoordinates(
      startX: start.x,
      startY: start.y,
      destinationX: destination.x,
      destinationY: destination.y,
    );
  }

  /// Solves between two preset coordinates in [spatialReferenceWkid].
  Future<LeastCostPathResult> solveCoordinates({
    required double startX,
    required double startY,
    required double destinationX,
    required double destinationY,
  }) async {
    final path = costGridPath.trim();
    if (path.isEmpty) {
      throw const FormatException('The ASCII cost-grid path cannot be empty.');
    }
    if (spatialReferenceWkid <= 0) {
      throw const FormatException(
        'The ASCII grid spatial-reference WKID must be positive.',
      );
    }
    if (![
      startX,
      startY,
      destinationX,
      destinationY,
    ].every((v) => v.isFinite)) {
      throw const FormatException('Route coordinates must be finite numbers.');
    }

    final solved = await Isolate.run(
      () => _loadAsciiGridAndSolve(
        path: path,
        startX: startX,
        startY: startY,
        destinationX: destinationX,
        destinationY: destinationY,
      ),
    );

    if (solved.cells.isEmpty) {
      throw const PathNotFoundException(
        'No traversable path connects the preset points.',
      );
    }

    final spatialReference = SpatialReference(wkid: spatialReferenceWkid);
    final cells = List<LeastCostPathCell>.unmodifiable(
      solved.cells.map((cell) => LeastCostPathCell(cell.row, cell.column)),
    );
    final steps = List<LeastCostPathStep>.unmodifiable(
      List.generate(solved.cells.length, (index) {
        final cell = solved.cells[index];
        return LeastCostPathStep(
          cell: cells[index],
          center: _cellCenter(
            cell: cell,
            rows: solved.rows,
            xMin: solved.xMin,
            yMin: solved.yMin,
            cellSize: solved.cellSize,
            spatialReference: spatialReference,
          ),
          weight: solved.weights[index],
        );
      }),
    );
    final gridVertices = _removeCollinearCells(solved.cells).map(
      (cell) => _cellCenter(
        cell: cell,
        rows: solved.rows,
        xMin: solved.xMin,
        yMin: solved.yMin,
        cellSize: solved.cellSize,
        spatialReference: spatialReference,
      ),
    );
    final vertices = List<ArcGISPoint>.unmodifiable([
      ArcGISPoint(x: startX, y: startY, spatialReference: spatialReference),
      ...gridVertices,
      ArcGISPoint(
        x: destinationX,
        y: destinationY,
        spatialReference: spatialReference,
      ),
    ]);

    final builder = PolylineBuilder(spatialReference: spatialReference);
    for (final vertex in vertices) {
      builder.addPoint(vertex);
    }

    return LeastCostPathResult(
      polyline: builder.toGeometry() as Polyline,
      vertices: vertices,
      cells: cells,
      steps: steps,
      accumulatedCost: solved.cost,
    );
  }

  /// Selects random connected traversable cells and solves between their
  /// centers in [spatialReferenceWkid].
  Future<LeastCostPathResult> solveRandomCoordinates() async {
    final path = costGridPath.trim();
    if (path.isEmpty) {
      throw const FormatException('The ASCII cost-grid path cannot be empty.');
    }
    if (spatialReferenceWkid <= 0) {
      throw const FormatException(
        'The ASCII grid spatial-reference WKID must be positive.',
      );
    }

    final coordinates = await Isolate.run(
      () => _loadAsciiGridAndSelectRandomCoordinates(path),
    );

    return solveCoordinates(
      startX: coordinates.startX,
      startY: coordinates.startY,
      destinationX: coordinates.destinationX,
      destinationY: coordinates.destinationY,
    );
  }

  /// Uses [start] as the grid handoff point and selects a distinct reachable
  /// destination whose geodesic distance is within [maxDistanceMeters].
  Future<LeastCostPathResult> solveFromStartWithRandomDestination({
    required ArcGISPoint start,
    double maxDistanceMeters = 250,
  }) async {
    _validatePointSpatialReference(start, 'start');
    if (!maxDistanceMeters.isFinite || maxDistanceMeters <= 0) {
      throw ArgumentError.value(
        maxDistanceMeters,
        'maxDistanceMeters',
        'Must be a positive finite distance.',
      );
    }
    if (spatialReferenceWkid != offroadGridWkid) {
      throw UnsupportedError(
        'Random destinations constrained in meters require WKID '
        '$offroadGridWkid.',
      );
    }

    final path = costGridPath.trim();
    if (path.isEmpty) {
      throw const FormatException('The ASCII cost-grid path cannot be empty.');
    }
    final startX = start.x;
    final startY = start.y;
    final coordinates = await Isolate.run(
      () => _loadAsciiGridAndSelectNearbyRandomCoordinates(
        path: path,
        startX: startX,
        startY: startY,
        maxDistanceMeters: maxDistanceMeters,
      ),
    );
    return solveCoordinates(
      startX: coordinates.startX,
      startY: coordinates.startY,
      destinationX: coordinates.destinationX,
      destinationY: coordinates.destinationY,
    );
  }

  void _validatePointSpatialReference(ArcGISPoint point, String name) {
    final pointSpatialReference = point.spatialReference;
    if (pointSpatialReference == null) {
      throw FormatException('The $name point must have a spatial reference.');
    }
    if (pointSpatialReference.wkid != spatialReferenceWkid) {
      throw FormatException(
        'The $name point uses WKID ${pointSpatialReference.wkid}; '
        'expected $spatialReferenceWkid.',
      );
    }
  }
}

/// Output that another file can display, save, or further process.
class LeastCostPathResult {
  const LeastCostPathResult({
    required this.polyline,
    required this.vertices,
    required this.cells,
    required this.steps,
    required this.accumulatedCost,
  });

  /// ArcGIS geometry ready to assign to a [Graphic] or feature.
  final Polyline polyline;

  /// Exact solver endpoints plus simplified intermediate cell-center points
  /// used to build [polyline].
  final List<ArcGISPoint> vertices;

  /// Every ASCII-grid cell traversed from start to destination.
  final List<LeastCostPathCell> cells;

  /// Every raw route cell with its center point and ASCII-grid weight.
  ///
  /// Unlike [vertices], these values are not simplified, so each item maps to
  /// exactly one traversed raster cell in travel order.
  final List<LeastCostPathStep> steps;

  /// Builds an alternate polyline from the first route cell whose raster
  /// weight is strictly greater than [threshold] through the destination.
  Polyline? polylineFromFirstWeightAbove(double threshold) {
    return splitAtFirstWeightAbove(threshold)?.alternate;
  }

  /// Splits the raw route at its first cell whose raster weight is strictly
  /// greater than [threshold].
  ///
  /// The alternate segment begins at that qualifying cell and continues to the
  /// destination. It is `null` when no route cell exceeds [threshold].
  LeastCostPathThresholdSplit? splitAtFirstWeightAbove(double threshold) {
    if (!threshold.isFinite) {
      throw ArgumentError.value(threshold, 'threshold', 'Must be finite.');
    }
    final firstHighWeightIndex = steps.indexWhere(
      (step) => step.weight > threshold,
    );
    if (firstHighWeightIndex == -1) return null;

    return LeastCostPathThresholdSplit(
      beforeAlternate: firstHighWeightIndex == 0
          ? null
          : _polylineForSteps(steps.sublist(0, firstHighWeightIndex)),
      alternate: _polylineForSteps(steps.sublist(firstHighWeightIndex)),
    );
  }

  static Polyline _polylineForSteps(List<LeastCostPathStep> routeSteps) {
    final builder = PolylineBuilder(
      spatialReference: routeSteps.first.center.spatialReference!,
    );
    for (final step in routeSteps) {
      builder.addPoint(step.center);
    }
    if (routeSteps.length == 1) {
      builder.addPoint(routeSteps.single.center);
    }
    return builder.toGeometry() as Polyline;
  }

  /// Sum of cost-weighted movement distance along the path.
  final double accumulatedCost;
}

/// The off-road route portions before and from the first high-weight cell.
class LeastCostPathThresholdSplit {
  const LeastCostPathThresholdSplit({
    required this.beforeAlternate,
    required this.alternate,
  });

  /// The route before [alternate], or `null` when the route starts there.
  final Polyline? beforeAlternate;

  /// The route from its first cell above the selected weight through the end.
  final Polyline alternate;
}

/// A raw route cell with the cost-surface weight used by the solver.
class LeastCostPathStep {
  const LeastCostPathStep({
    required this.cell,
    required this.center,
    required this.weight,
  });

  final LeastCostPathCell cell;
  final ArcGISPoint center;
  final double weight;
}

/// Public row/column index of a traversed ASCII-grid cell.
class LeastCostPathCell {
  const LeastCostPathCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is LeastCostPathCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'LeastCostPathCell(row: $row, column: $column)';
}

/// Thrown when valid preset points are separated by impassable cells.
class PathNotFoundException implements Exception {
  const PathNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'PathNotFoundException: $message';
}

_RandomRouteCoordinates _loadAsciiGridAndSelectRandomCoordinates(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('ASCII cost grid not found', path);
  }

  final grid = _AsciiCostGrid.parse(file.readAsStringSync());
  final traversableCells = <_GridCell>[
    for (var index = 0; index < grid.costs.length; index++)
      if (grid.costs[index].isFinite) grid.cellForIndex(index),
  ];
  final random = math.Random();
  final start = traversableCells[random.nextInt(traversableCells.length)];
  final reachableCells = _reachableCells(grid, start);
  final destination = reachableCells[random.nextInt(reachableCells.length)];

  return _RandomRouteCoordinates(
    startX: _cellCenterX(grid, start),
    startY: _cellCenterY(grid, start),
    destinationX: _cellCenterX(grid, destination),
    destinationY: _cellCenterY(grid, destination),
  );
}

_RandomRouteCoordinates _loadAsciiGridAndSelectNearbyRandomCoordinates({
  required String path,
  required double startX,
  required double startY,
  required double maxDistanceMeters,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('ASCII cost grid not found', path);
  }

  final grid = _AsciiCostGrid.parse(file.readAsStringSync());
  final start = grid.cellAt(startX, startY);
  if (start == null) {
    throw const FormatException(
      'The on-road destination is outside the off-road cost grid.',
    );
  }
  if (!grid.isTraversable(start)) {
    throw const FormatException(
      'The on-road destination falls on a NoData or negative-cost grid cell.',
    );
  }

  final startCenterX = _cellCenterX(grid, start);
  final startCenterY = _cellCenterY(grid, start);
  final candidates = _reachableCells(
        grid,
        start,
        includeCell: (cell) =>
            _planarDistanceMeters(
              startX,
              startY,
              _cellCenterX(grid, cell),
              _cellCenterY(grid, cell),
            ) <=
            maxDistanceMeters,
      )
      .where((cell) => cell != start)
      .toList();
  if (candidates.isEmpty) {
    throw PathNotFoundException(
      'No distinct reachable off-road cell exists within '
      '${maxDistanceMeters.toStringAsFixed(0)} meters of the on-road destination.',
    );
  }

  final destination = candidates[math.Random().nextInt(candidates.length)];
  return _RandomRouteCoordinates(
    startX: startCenterX,
    startY: startCenterY,
    destinationX: _cellCenterX(grid, destination),
    destinationY: _cellCenterY(grid, destination),
  );
}

double _planarDistanceMeters(
  double xA,
  double yA,
  double xB,
  double yB,
) {
  final dx = xB - xA;
  final dy = yB - yA;
  return math.sqrt(dx * dx + dy * dy);
}

List<_GridCell> _reachableCells(
  _AsciiCostGrid grid,
  _GridCell start, {
  bool Function(_GridCell cell)? includeCell,
}) {
  const directions = <(int, int)>[
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
    (-1, -1),
    (-1, 1),
    (1, -1),
    (1, 1),
  ];
  final cells = <_GridCell>[start];
  final visited = <int>{grid.indexOf(start)};

  for (var index = 0; index < cells.length; index++) {
    final current = cells[index];
    for (final (rowDelta, columnDelta) in directions) {
      final row = current.row + rowDelta;
      final column = current.column + columnDelta;
      if (row < 0 || row >= grid.rows || column < 0 || column >= grid.columns) {
        continue;
      }

      final next = _GridCell(row, column);
      final nextIndex = grid.indexOf(next);
      if (visited.contains(nextIndex) ||
          !grid.isTraversable(next) ||
          (includeCell != null && !includeCell(next))) {
        continue;
      }
      if (rowDelta != 0 &&
          columnDelta != 0 &&
          (!grid.isTraversable(_GridCell(current.row, column)) ||
              !grid.isTraversable(_GridCell(row, current.column)))) {
        continue;
      }

      visited.add(nextIndex);
      cells.add(next);
    }
  }

  return cells;
}

class _RandomRouteCoordinates {
  const _RandomRouteCoordinates({
    required this.startX,
    required this.startY,
    required this.destinationX,
    required this.destinationY,
  });

  final double startX;
  final double startY;
  final double destinationX;
  final double destinationY;
}

double _cellCenterX(_AsciiCostGrid grid, _GridCell cell) =>
    grid.xMin + (cell.column + 0.5) * grid.cellSize;

double _cellCenterY(_AsciiCostGrid grid, _GridCell cell) =>
    grid.yMin + (grid.rows - cell.row - 0.5) * grid.cellSize;

_SolvedGridPath _loadAsciiGridAndSolve({
  required String path,
  required double startX,
  required double startY,
  required double destinationX,
  required double destinationY,
}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('ASCII cost grid not found', path);
  }

  final grid = _AsciiCostGrid.parse(file.readAsStringSync());
  final start = grid.cellAt(startX, startY);
  if (start == null) {
    throw const FormatException(
      'The preset start point is outside the ASCII grid.',
    );
  }
  final destination = grid.cellAt(destinationX, destinationY);
  if (destination == null) {
    throw const FormatException(
      'The preset destination point is outside the ASCII grid.',
    );
  }
  if (!grid.isTraversable(start)) {
    throw const FormatException(
      'The preset start point falls on a NoData or negative-cost cell.',
    );
  }
  if (!grid.isTraversable(destination)) {
    throw const FormatException(
      'The preset destination point falls on a NoData or negative-cost cell.',
    );
  }

  final result = _findLeastCostPath(grid, start, destination);
  return _SolvedGridPath(
    cells: result.cells,
    weights: List<double>.unmodifiable(
      result.cells.map((cell) => grid.costs[grid.indexOf(cell)]),
    ),
    cost: result.cost,
    rows: grid.rows,
    xMin: grid.xMin,
    yMin: grid.yMin,
    cellSize: grid.cellSize,
  );
}

class _SolvedGridPath {
  const _SolvedGridPath({
    required this.cells,
    required this.weights,
    required this.cost,
    required this.rows,
    required this.xMin,
    required this.yMin,
    required this.cellSize,
  });

  final List<_GridCell> cells;
  final List<double> weights;
  final double cost;
  final int rows;
  final double xMin;
  final double yMin;
  final double cellSize;
}

class _AsciiCostGrid {
  const _AsciiCostGrid({
    required this.columns,
    required this.rows,
    required this.xMin,
    required this.yMin,
    required this.cellSize,
    required this.costs,
    required this.minimumCost,
  });

  final int columns;
  final int rows;
  final double xMin;
  final double yMin;
  final double cellSize;
  final List<double> costs;
  final double minimumCost;

  double get xMax => xMin + columns * cellSize;
  double get yMax => yMin + rows * cellSize;

  factory _AsciiCostGrid.parse(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final header = <String, double>{};
    final valueTokens = <String>[];
    var readingValues = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      final key = parts.first.toLowerCase();
      const headerKeys = {
        'ncols',
        'nrows',
        'xllcorner',
        'xllcenter',
        'yllcorner',
        'yllcenter',
        'cellsize',
        'nodata_value',
      };
      if (!readingValues && headerKeys.contains(key)) {
        if (parts.length != 2 || double.tryParse(parts[1]) == null) {
          throw FormatException('Malformed ASCII header line: $line');
        }
        header[key] = double.parse(parts[1]);
      } else {
        readingValues = true;
        valueTokens.addAll(parts);
      }
    }

    final columnsValue = header['ncols'];
    final rowsValue = header['nrows'];
    final cellSize = header['cellsize'];
    final hasXCorner = header.containsKey('xllcorner');
    final hasXCenter = header.containsKey('xllcenter');
    final hasYCorner = header.containsKey('yllcorner');
    final hasYCenter = header.containsKey('yllcenter');
    if (columnsValue == null ||
        rowsValue == null ||
        cellSize == null ||
        hasXCorner == hasXCenter ||
        hasYCorner == hasYCenter) {
      throw const FormatException(
        'ASCII header requires ncols, nrows, cellsize, and exactly one '
        'x/y lower-left origin.',
      );
    }

    final columns = columnsValue.toInt();
    final rows = rowsValue.toInt();
    if (columnsValue != columns ||
        rowsValue != rows ||
        columns <= 0 ||
        rows <= 0 ||
        !cellSize.isFinite ||
        cellSize <= 0) {
      throw const FormatException(
        'ASCII grid dimensions and cellsize must be positive.',
      );
    }

    final cellCount = columns * rows;
    if (valueTokens.length != cellCount) {
      throw FormatException(
        'Expected $cellCount ASCII cell values but found '
        '${valueTokens.length}.',
      );
    }

    final noData = header['nodata_value'];
    final costs = List<double>.filled(cellCount, double.nan);
    var minimumCost = double.infinity;
    for (var index = 0; index < cellCount; index++) {
      final value = double.tryParse(valueTokens[index]);
      if (value == null) {
        throw FormatException('ASCII cell ${index + 1} is not numeric.');
      }
      final isNoData = noData != null && value == noData;
      if (!isNoData && value.isFinite && value >= 0) {
        costs[index] = value;
        minimumCost = math.min(minimumCost, value);
      }
    }
    if (!minimumCost.isFinite) {
      throw const FormatException(
        'The ASCII grid contains no traversable cells.',
      );
    }

    final rawX = header[hasXCorner ? 'xllcorner' : 'xllcenter']!;
    final rawY = header[hasYCorner ? 'yllcorner' : 'yllcenter']!;
    return _AsciiCostGrid(
      columns: columns,
      rows: rows,
      xMin: rawX - (hasXCenter ? cellSize / 2 : 0),
      yMin: rawY - (hasYCenter ? cellSize / 2 : 0),
      cellSize: cellSize,
      costs: costs,
      minimumCost: minimumCost,
    );
  }

  _GridCell? cellAt(double x, double y) {
    if (x < xMin || x >= xMax || y < yMin || y >= yMax) return null;
    final column = ((x - xMin) / cellSize).floor();
    final rowFromBottom = ((y - yMin) / cellSize).floor();
    return _GridCell(rows - rowFromBottom - 1, column);
  }

  bool isTraversable(_GridCell cell) => costs[indexOf(cell)].isFinite;

  int indexOf(_GridCell cell) => cell.row * columns + cell.column;

  _GridCell cellForIndex(int index) =>
      _GridCell(index ~/ columns, index % columns);
}

class _GridCell {
  const _GridCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is _GridCell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

class _PathResult {
  const _PathResult(this.cells, this.cost);

  final List<_GridCell> cells;
  final double cost;
}

_PathResult _findLeastCostPath(
  _AsciiCostGrid grid,
  _GridCell start,
  _GridCell destination,
) {
  if (start == destination) return _PathResult([start], 0);

  final count = grid.rows * grid.columns;
  final startIndex = grid.indexOf(start);
  final destinationIndex = grid.indexOf(destination);
  final distance = List<double>.filled(count, double.infinity);
  final previous = List<int>.filled(count, -1);
  final closed = List<bool>.filled(count, false);
  final queue = _MinHeap();
  distance[startIndex] = 0;
  queue.add(_QueueEntry(startIndex, _heuristic(grid, start, destination)));

  const directions = <(int, int)>[
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
    (-1, -1),
    (-1, 1),
    (1, -1),
    (1, 1),
  ];

  while (queue.isNotEmpty) {
    final currentIndex = queue.removeFirst().index;
    if (closed[currentIndex]) continue;
    if (currentIndex == destinationIndex) break;
    closed[currentIndex] = true;
    final current = grid.cellForIndex(currentIndex);

    for (final (rowDelta, columnDelta) in directions) {
      final row = current.row + rowDelta;
      final column = current.column + columnDelta;
      if (row < 0 || row >= grid.rows || column < 0 || column >= grid.columns) {
        continue;
      }

      final next = _GridCell(row, column);
      final nextIndex = grid.indexOf(next);
      if (closed[nextIndex] || !grid.costs[nextIndex].isFinite) continue;

      final diagonal = rowDelta != 0 && columnDelta != 0;
      if (diagonal) {
        final horizontal = _GridCell(current.row, column);
        final vertical = _GridCell(row, current.column);
        if (!grid.isTraversable(horizontal) || !grid.isTraversable(vertical)) {
          continue;
        }
      }

      final stepLength = diagonal ? math.sqrt2 : 1.0;
      final transitionCost =
          (grid.costs[currentIndex] + grid.costs[nextIndex]) /
          2 *
          grid.cellSize *
          stepLength;
      final candidate = distance[currentIndex] + transitionCost;
      if (candidate >= distance[nextIndex]) continue;

      distance[nextIndex] = candidate;
      previous[nextIndex] = currentIndex;
      queue.add(
        _QueueEntry(nextIndex, candidate + _heuristic(grid, next, destination)),
      );
    }
  }

  if (!distance[destinationIndex].isFinite) {
    return const _PathResult([], double.infinity);
  }

  final reversed = <_GridCell>[];
  var index = destinationIndex;
  while (index != -1) {
    reversed.add(grid.cellForIndex(index));
    if (index == startIndex) break;
    index = previous[index];
  }
  return _PathResult(reversed.reversed.toList(), distance[destinationIndex]);
}

double _heuristic(_AsciiCostGrid grid, _GridCell from, _GridCell to) {
  final deltaRow = (from.row - to.row).abs();
  final deltaColumn = (from.column - to.column).abs();
  final diagonal = math.min(deltaRow, deltaColumn);
  final straight = math.max(deltaRow, deltaColumn) - diagonal;
  return (diagonal * math.sqrt2 + straight) * grid.cellSize * grid.minimumCost;
}

List<_GridCell> _removeCollinearCells(List<_GridCell> cells) {
  if (cells.length <= 2) return cells;
  final result = <_GridCell>[cells.first];
  var previousRowDirection = cells[1].row - cells[0].row;
  var previousColumnDirection = cells[1].column - cells[0].column;
  for (var index = 1; index < cells.length - 1; index++) {
    final rowDirection = cells[index + 1].row - cells[index].row;
    final columnDirection = cells[index + 1].column - cells[index].column;
    if (rowDirection != previousRowDirection ||
        columnDirection != previousColumnDirection) {
      result.add(cells[index]);
    }
    previousRowDirection = rowDirection;
    previousColumnDirection = columnDirection;
  }
  result.add(cells.last);
  return result;
}

ArcGISPoint _cellCenter({
  required _GridCell cell,
  required int rows,
  required double xMin,
  required double yMin,
  required double cellSize,
  required SpatialReference spatialReference,
}) {
  return ArcGISPoint(
    x: xMin + (cell.column + 0.5) * cellSize,
    y: yMin + (rows - cell.row - 0.5) * cellSize,
    spatialReference: spatialReference,
  );
}

class _QueueEntry {
  const _QueueEntry(this.index, this.priority);

  final int index;
  final double priority;
}

class _MinHeap {
  final List<_QueueEntry> _values = [];

  bool get isNotEmpty => _values.isNotEmpty;

  void add(_QueueEntry value) {
    _values.add(value);
    var child = _values.length - 1;
    while (child > 0) {
      final parent = (child - 1) ~/ 2;
      if (_values[parent].priority <= value.priority) break;
      _values[child] = _values[parent];
      child = parent;
    }
    _values[child] = value;
  }

  _QueueEntry removeFirst() {
    final first = _values.first;
    final last = _values.removeLast();
    if (_values.isEmpty) return first;

    var parent = 0;
    while (true) {
      final left = parent * 2 + 1;
      if (left >= _values.length) break;
      final right = left + 1;
      var child = left;
      if (right < _values.length &&
          _values[right].priority < _values[left].priority) {
        child = right;
      }
      if (_values[child].priority >= last.priority) break;
      _values[parent] = _values[child];
      parent = child;
    }
    _values[parent] = last;
    return first;
  }
}
