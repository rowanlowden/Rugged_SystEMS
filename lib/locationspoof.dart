import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart' show Colors;

/// Moves a point feature along ordered generated route polylines at a constant
/// speed using ArcGIS simulated locations.
///
/// Call [attach] after the map view is ready, then call [start] with the
/// generated on-road and off-road polylines in travel order. If [start] is
/// given a [LocationDisplay], its data source is replaced by the same simulated
/// source, making the app's current location follow the route as well.
class PathLocationSpoofer {
  PathLocationSpoofer({this.onFinished})
    : marker = Graphic(
        symbol: SimpleMarkerSymbol(color: Colors.deepOrange, size: 14),
      ) {
    overlay.graphics.add(marker);
  }

  /// Overlay containing the moving point feature.
  final GraphicsOverlay overlay = GraphicsOverlay();

  /// Point feature whose geometry follows simulated route locations.
  final Graphic marker;

  /// Invoked after the simulator emits its final route location.
  final void Function()? onFinished;

  SimulatedLocationDataSource? _dataSource;
  StreamSubscription<ArcGISLocation>? _locationSubscription;
  ArcGISMapViewController? _mapViewController;
  bool _attached = false;
  bool _finished = false;
  int _session = 0;

  /// The active source that supplies the spoofed locations, if started.
  SimulatedLocationDataSource? get dataSource => _dataSource;

  /// Adds the moving point overlay to [mapViewController] once.
  void attach(ArcGISMapViewController mapViewController) {
    if (_attached) return;
    _mapViewController = mapViewController;
    mapViewController.graphicsOverlays.add(overlay);
    _attached = true;
  }

  /// Starts constant-speed playback over [paths].
  ///
  /// [metersPerSecond] is a real ground speed in metres per second. The ArcGIS
  /// simulator creates route positions one second apart at that distance.
  Future<SimulatedLocationDataSource> start({
    required List<Polyline> paths,
    required double metersPerSecond,
    LocationDisplay? locationDisplay,
    LocationDisplayAutoPanMode autoPanMode =
        LocationDisplayAutoPanMode.recenter,
    void Function()? onFinished,
  }) async {
    if (paths.isEmpty) {
      throw ArgumentError.value(
        paths,
        'paths',
        'At least one path is required.',
      );
    }
    if (!metersPerSecond.isFinite || metersPerSecond <= 0) {
      throw ArgumentError.value(
        metersPerSecond,
        'metersPerSecond',
        'Must be a positive finite value.',
      );
    }

    await stop();
    final session = ++_session;

    final tripPath = _joinOrderedPaths(paths);
    final source =
        SimulatedLocationDataSource.withPolylineAndSimulationParameters(
          tripPath,
          parameters: SimulationParameters(
            startTime: DateTime.now().toUtc(),
            speed: metersPerSecond,
          ),
        );
    if (source.locations.isEmpty) {
      throw StateError(
        'The supplied path did not produce simulated locations.',
      );
    }

    _dataSource = source;
    _finished = false;
    marker.geometry = source.locations.first.position;
    final completionCallback = onFinished ?? this.onFinished;
    late final StreamSubscription<ArcGISLocation> subscription;
    subscription = source.onLocationChanged.listen((location) {
      if (session != _session) return;
      marker.geometry = location.position;
      if (!_finished &&
          source.currentLocationIndex >= source.locations.length - 1) {
        _finished = true;
        unawaited(
          _finishPlayback(
            source: source,
            subscription: subscription,
            session: session,
            onFinished: completionCallback,
          ),
        );
      }
    });
    _locationSubscription = subscription;

    if (locationDisplay != null) {
      locationDisplay
        ..dataSource = source
        ..autoPanMode = autoPanMode;
    }

    await source.start();
    return source;
  }

  Future<void> _finishPlayback({
    required SimulatedLocationDataSource source,
    required StreamSubscription<ArcGISLocation> subscription,
    required int session,
    required void Function()? onFinished,
  }) async {
    await subscription.cancel();
    if (session != _session) return;

    await source.stop();
    if (session != _session) return;

    if (identical(_locationSubscription, subscription)) {
      _locationSubscription = null;
    }
    if (identical(_dataSource, source)) {
      _dataSource = null;
    }
    onFinished?.call();
  }

  /// Stops playback and removes the simulated location listener.
  Future<void> stop() async {
    _session++;
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    final source = _dataSource;
    _dataSource = null;
    _finished = false;
    if (source != null) {
      await source.stop();
    }
  }

  /// Stops playback and removes the moving point feature from the map view.
  Future<void> dispose() async {
    if (_attached) {
      _mapViewController?.graphicsOverlays.remove(overlay);
      _attached = false;
      _mapViewController = null;
    }
    await stop();
  }

  static Polyline _joinOrderedPaths(List<Polyline> paths) {
    final spatialReference = paths.first.spatialReference;
    if (spatialReference == null) {
      throw StateError('The first route path must have a spatial reference.');
    }

    final builder = PolylineBuilder(spatialReference: spatialReference);
    var vertexCount = 0;
    for (final path in paths) {
      final normalizedPath = _projectPolyline(path, spatialReference);
      for (final part in normalizedPath.parts) {
        for (final point in part.getPoints()) {
          builder.addPoint(point);
          vertexCount++;
        }
      }
    }

    if (vertexCount < 2) {
      throw StateError(
        'The supplied paths must contain at least two vertices.',
      );
    }
    return builder.toGeometry() as Polyline;
  }

  static Polyline _projectPolyline(
    Polyline path,
    SpatialReference targetSpatialReference,
  ) {
    if (path.spatialReference?.wkid == targetSpatialReference.wkid) {
      return path;
    }
    final projected = GeometryEngine.project(
      path,
      outputSpatialReference: targetSpatialReference,
    );
    if (projected is! Polyline) {
      throw StateError('Could not project a route path for simulation.');
    }
    return projected;
  }
}
