import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart' show Colors;

import 'onroad_route.dart';

/// Loads, solves, and displays MMPK-backed address-to-address road routes.
class OnRoadRoutePlotter {
  OnRoadRoutePlotter(this._mapViewController);

  final ArcGISMapViewController _mapViewController;
  final GraphicsOverlay _routeOverlay = GraphicsOverlay();

  OfflineAddressRouteService? _service;
  bool _isAttached = false;

  /// The loaded routing service, including its saved polyline and tracker.
  OfflineAddressRouteService? get service => _service;

  /// The active tracker for the most recently generated route.
  RouteTracker? get routeTracker => _service?.routeTracker;

  /// Loads the MMPK-backed service used for address geocoding and road routes.
  Future<OfflineAddressRouteService> loadService({Uri? mmpkUri}) async {
    final service = await OfflineAddressRouteService.loadFromMmpk(
      mmpkUri: mmpkUri,
    );
    _service = service;
    return service;
  }

  /// Adds this plotter's route overlay to the map view once.
  void attach() {
    if (_isAttached) return;
    _mapViewController.graphicsOverlays.add(_routeOverlay);
    _isAttached = true;
  }

  /// Generates, displays, and zooms to a route between two address strings.
  Future<OnRoadRoute> generateAndDisplayRoute({
    required String startAddress,
    required String destinationAddress,
  }) async {
    final route = await generateRoute(
      startAddress: startAddress,
      destinationAddress: destinationAddress,
    );
    await displayRoute(route);
    return route;
  }

  /// Generates a route between two address strings without changing the map.
  Future<OnRoadRoute> generateRoute({
    required String startAddress,
    required String destinationAddress,
  }) async {
    final service = _service;
    if (service == null) {
      throw StateError(
        'Load the on-road routing service before generating a route.',
      );
    }

    final route = await service.generateRoute(
      startAddress: startAddress,
      destinationAddress: destinationAddress,
    );
    return route;
  }

  /// Replaces the route graphic and zooms the map view to [route].
  Future<void> displayRoute(OnRoadRoute route, {bool zoom = true}) async {
    attach();
    _routeOverlay.graphics
      ..clear()
      ..add(
        Graphic(
          geometry: route.polyline,
          symbol: SimpleLineSymbol(color: Colors.blue, width: 5),
        ),
      );
    if (zoom) {
      await _fitRoute(route.polyline);
    }
  }

  Future<void> _fitRoute(Polyline polyline) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final completed = await _mapViewController.setViewpointGeometry(
        polyline,
        paddingInDiPs: 32,
      );
      if (completed) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Could not complete the on-road route zoom.');
  }

  /// Clears the displayed graphic but retains the service and route tracker.
  void clear() {
    _routeOverlay.graphics.clear();
  }

  /// Clears and removes this plotter's overlay from the map view.
  void detach() {
    if (!_isAttached) return;
    clear();
    _mapViewController.graphicsOverlays.remove(_routeOverlay);
    _isAttached = false;
  }
}
