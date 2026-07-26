import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart' show rootBundle;

/// Creates and tracks routes using geocoded addresses and a transportation
/// network packaged in a local [MobileMapPackage].
class OfflineAddressRouteService {
  static const _offlineRoutingMmpkAssetPath =
      'assets/offline/RoadNetworkaAndAddressGeocode.mmpk';

  OfflineAddressRouteService.fromMobileMapPackage(
    MobileMapPackage mobileMapPackage,
  ) : _mobileMapPackage = mobileMapPackage;

  final MobileMapPackage _mobileMapPackage;

  /// Loads the MMPK containing the Vernon address locator and road network.
  ///
  /// [mmpkUri] must identify an app-readable local copy of the package. When
  /// omitted, this method copies the bundled offline routing package to a
  /// local temporary file before loading it.
  static Future<OfflineAddressRouteService> loadFromMmpk({Uri? mmpkUri}) async {
    final localMmpkUri = mmpkUri ?? await _materializeOfflineRoutingMmpk();
    final package = MobileMapPackage.withFileUri(localMmpkUri);
    await package.load();

    if (package.maps.isEmpty) {
      throw StateError('The mobile map package does not contain a map.');
    }
    if (package.locatorTask == null) {
      throw StateError(
        'The mobile map package does not contain an address locator.',
      );
    }
    if (package.maps.first.transportationNetworks.isEmpty) {
      throw StateError(
        'The mobile map package does not contain a transportation network.',
      );
    }

    return OfflineAddressRouteService.fromMobileMapPackage(package);
  }

  static Future<Uri> _materializeOfflineRoutingMmpk() async {
    final assetData = await rootBundle.load(_offlineRoutingMmpkAssetPath);
    final directory = await Directory.systemTemp.createTemp('rugged_mmpk_');
    final outputFile = File(
      '${directory.path}/RoadNetworkaAndAddressGeocode.mmpk',
    );
    await outputFile.writeAsBytes(
      assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      ),
      flush: true,
    );
    return outputFile.uri;
  }

  /// The most recently solved route polyline. It is retained in memory so a
  /// caller can display it in a [GraphicsOverlay] or persist it as needed.
  Polyline? savedPolyline;

  /// The tracker associated with [savedPolyline]'s route result.
  RouteTracker? routeTracker;

  /// Geocodes [startAddress] and [destinationAddress] with the MMPK locator,
  /// solves on the MMPK road network, saves its [Polyline], and creates a
  /// [RouteTracker].
  Future<OnRoadRoute> generateRoute({
    required String startAddress,
    required String destinationAddress,
  }) async {
    final start = startAddress.trim();
    final destination = destinationAddress.trim();
    if (start.isEmpty || destination.isEmpty) {
      throw const FormatException(
        'A start address and a destination address are required.',
      );
    }
    if (_mobileMapPackage.maps.isEmpty) {
      throw StateError('The mobile map package does not contain a map.');
    }

    final locatorTask = _mobileMapPackage.locatorTask;
    if (locatorTask == null) {
      throw StateError(
        'The mobile map package does not contain an offline address locator.',
      );
    }
    final transportationNetworks =
        _mobileMapPackage.maps.first.transportationNetworks;
    if (transportationNetworks.isEmpty) {
      throw StateError(
        'The mobile map package does not contain a transportation network.',
      );
    }

    await locatorTask.load();
    final addresses = await Future.wait([
      _routePointForAddress(locatorTask, start, 'Start'),
      _routePointForAddress(locatorTask, destination, 'Destination'),
    ]);

    final routeTask = RouteTask.withDataset(transportationNetworks.first);
    await routeTask.load();
    final parameters = await routeTask.createDefaultParameters();
    parameters
      ..returnDirections = true
      ..returnStops = true
      ..setStops([Stop(addresses[0]), Stop(addresses[1])]);

    final routeResult = await routeTask.solveRoute(parameters);
    if (routeResult.routes.isEmpty) {
      throw StateError('No route was found between the supplied addresses.');
    }

    final route = routeResult.routes.first;
    final polyline = route.routeGeometry;
    if (polyline == null) {
      throw StateError('The solved route did not contain a polyline.');
    }
    final destinationGeometry = route.stops.isEmpty
        ? null
        : route.stops.last.geometry;
    if (destinationGeometry is! ArcGISPoint) {
      throw StateError(
        'The solved route did not return a destination stop point.',
      );
    }
    final destinationPoint = destinationGeometry;

    final tracker = RouteTracker.create(
      routeResult: routeResult,
      routeIndex: 0,
      skipCoincidentStops: true,
    );
    if (tracker == null) {
      throw StateError('Could not create a RouteTracker for the solved route.');
    }

    savedPolyline = polyline;
    routeTracker = tracker;
    debugPrint(
      'Route generated successfully: ${route.totalLength.toStringAsFixed(0)} m, '
      '${route.totalTime.toStringAsFixed(1)} min.',
    );
    return OnRoadRoute(
      polyline: polyline,
      destination: destinationPoint,
      routeResult: routeResult,
      routeTracker: tracker,
      totalLengthMeters: route.totalLength,
      totalTimeMinutes: route.totalTime,
    );
  }

  /// Forwards a GPS or simulated location to the active [RouteTracker].
  Future<void> trackLocation(ArcGISLocation location) {
    final tracker = routeTracker;
    if (tracker == null) {
      throw StateError('Generate a route before tracking locations.');
    }
    return tracker.trackLocation(location);
  }

  /// Creates a graphic for [savedPolyline] that callers can add to a map view.
  Graphic? createSavedRouteGraphic() {
    final polyline = savedPolyline;
    if (polyline == null) return null;
    return Graphic(
      geometry: polyline,
      symbol: SimpleLineSymbol(color: Colors.blue, width: 5),
    );
  }

  Future<ArcGISPoint> _routePointForAddress(
    LocatorTask locatorTask,
    String address,
    String label,
  ) async {
    final results = await locatorTask.geocode(searchText: address);
    if (results.isEmpty) {
      throw StateError('$label address was not found: $address');
    }

    final routePoint =
        results.first.routeLocation ?? results.first.displayLocation;
    if (routePoint == null) {
      throw StateError('$label address did not provide a routeable location.');
    }
    return routePoint;
  }
}

/// The saved route output and its navigation tracker.
class OnRoadRoute {
  const OnRoadRoute({
    required this.polyline,
    required this.destination,
    required this.routeResult,
    required this.routeTracker,
    required this.totalLengthMeters,
    required this.totalTimeMinutes,
  });

  final Polyline polyline;
  final ArcGISPoint destination;
  final RouteResult routeResult;
  final RouteTracker routeTracker;
  final double totalLengthMeters;
  final double totalTimeMinutes;
}
