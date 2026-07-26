import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart' show Colors;

import 'offroad_route.dart';

/// Displays [LeastCostPathResult.polyline] values on an [ArcGISMapView].
///
/// Create this after the map view controller is available, call [attach] after
/// the map view is ready, then call [displayRoute] or [solveAndDisplayPreset].
class OffroadRoutePlotter {
  OffroadRoutePlotter(this._mapViewController);

  final ArcGISMapViewController _mapViewController;
  final GraphicsOverlay _routeOverlay = GraphicsOverlay();
  bool _isAttached = false;

  /// Adds the route overlay to the map view once.
  void attach() {
    if (_isAttached) return;
    _mapViewController.graphicsOverlays.add(_routeOverlay);
    _isAttached = true;
  }

  /// Solves the configured off-road route and draws the resulting polyline.
  Future<LeastCostPathResult> solveAndDisplayPreset() async {
    final route = await solvePreset();
    await displayRoute(route);
    return route;
  }

  /// Solves the configured off-road route without changing the map display.
  Future<LeastCostPathResult> solvePreset() => solvePresetLeastCostPath();

  /// Starts at [onRoadDestination] and selects a random connected off-road
  /// destination no more than [maxDistanceMeters] away.
  Future<LeastCostPathResult> solveFromOnRoadDestination({
    required ArcGISPoint onRoadDestination,
    double maxDistanceMeters = 250,
  }) {
    final start = _projectToOffroadGrid(onRoadDestination);
    return solveLeastCostPathFromOnRoadDestination(
      start: start,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  ArcGISPoint _projectToOffroadGrid(ArcGISPoint point) {
    if (point.spatialReference?.wkid == offroadGridWkid) {
      return point;
    }
    final projected = GeometryEngine.project(
      point,
      outputSpatialReference: SpatialReference(wkid: offroadGridWkid),
    );
    if (projected is! ArcGISPoint) {
      throw StateError(
        'Could not project the on-road destination to the grid.',
      );
    }
    return projected;
  }

  /// Replaces the displayed route with [route]'s generated polyline and zooms
  /// the map view to fit it with visual padding.
  Future<void> displayRoute(
    LeastCostPathResult route, {
    bool zoom = true,
  }) async {
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
      final completed = await _mapViewController.setViewpointGeometry(
        route.polyline,
        paddingInDiPs: 32,
      );
      if (!completed) {
        throw StateError('Could not complete the off-road route zoom.');
      }
    }
  }

  /// Removes the currently displayed off-road route but retains the overlay.
  void clear() {
    _routeOverlay.graphics.clear();
  }

  /// Removes the route overlay from the map view.
  void detach() {
    if (!_isAttached) return;
    _mapViewController.graphicsOverlays.remove(_routeOverlay);
    _isAttached = false;
  }
}
