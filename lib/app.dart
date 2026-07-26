import 'dart:async' show Timer, unawaited;
import 'dart:io';
import 'dart:math' as math;

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'offroad_route.dart';
import 'locationspoof.dart';
import 'onroad_route.dart';
import 'plot_offroad_route.dart';
import 'plot_onroad_route.dart';
import 'utils/consts.dart';
import 'widgets/current_dispatch_overlay.dart';
import 'widgets/dispatch_call_panel.dart';
import 'widgets/hospital_navigation_hud.dart';
import 'widgets/hospital_route_panel.dart';
import 'widgets/map_header_bar.dart';
import 'widgets/navigation_phase.dart';
import 'widgets/navigation_phase_hud.dart';
import 'widgets/navigation_status_panel.dart';

const offlineMapAssetDirectory = 'assets/offline/';
const offlineMapAssetName = 'thisshouldwork.mmpk';
const _onRoadStartAddress = '1501 WATER AVE, HILLSBORO, WI 54634';
const _onRoadDestinationAddress = '3610 STATE HIGHWAY 80, HILLSBORO, WI 54634';
const _fixedCoordinatesLabel = '43.599812 N, -90.350285 W';

class OfflineNavigationApp extends StatelessWidget {
  const OfflineNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const OfflineNavigationPage(username: 'Operator');
  }
}

class OfflineNavigationPage extends StatefulWidget {
  const OfflineNavigationPage({super.key, required this.username});

  final String username;

  @override
  State<OfflineNavigationPage> createState() => _OfflineNavigationPageState();
}

class _OfflineNavigationPageState extends State<OfflineNavigationPage> {
  final ArcGISMapViewController _mapViewController =
      ArcGISMapView.createController();
  late final OffroadRoutePlotter _offroadRoutePlotter;
  late final OnRoadRoutePlotter _onRoadRoutePlotter;
  late final PathLocationSpoofer _locationSpoofer;
  late final DemoIncidentProfile _profile;

  bool _mapViewReady = false;
  bool _offlineMapLoadStarted = false;
  bool _mapLoaded = false;
  bool _locationEnabled = false;
  bool _busy = true;
  bool _isGeneratingRoute = false;
  bool _serviceFault = false;
  bool _dispatchCallShown = false;
  bool _dispatchCallAccepted = false;
  bool _currentDispatchOpen = false;
  bool _hospitalNavigationMode = false;
  NavigationPhase? _activePhase;
  OnRoadRoute? _onRoadRoute;
  LeastCostPathResult? _offroadRoute;
  Polyline? _offroadDrivePolyline;
  Polyline? _walkingPolyline;
  Future<void>? _offroadSolveFuture;
  Object? _offroadSolveError;
  bool _offroadTransitionRequested = false;
  final math.Random _random = math.Random();
  Timer? _speedSimulationTimer;
  String? _pavedSpeedOverride;
  String? _offroadSpeedOverride;
  double _pavedDistanceMiles = 0;
  double _offroadDistanceMiles = 0;
  double _walkingDistanceMiles = 0;
  double _pavedProgress = 0;
  double _offroadProgress = 0;
  double _walkingProgress = 0;

  String _status = 'Loading offline map…';
  String _coordinatesLabel = '';

  bool get _systemOn => _mapLoaded && !_serviceFault;
  bool get _navigationStarted => _activePhase != null;

  @override
  void initState() {
    super.initState();
    _profile = demoProfileForUsername(widget.username);
    _coordinatesLabel = _fixedCoordinatesLabel;
    _offroadRoutePlotter = OffroadRoutePlotter(_mapViewController);
    _onRoadRoutePlotter = OnRoadRoutePlotter(_mapViewController);
    _locationSpoofer = PathLocationSpoofer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDispatchCallNotification();
    });
  }

  Future<void> _loadOfflineMap() async {
    final mmpkAssetPath = await _findOfflineMmpkAssetPath();

    if (mmpkAssetPath == null) {
      _setStatus(
        'No offline map package was found in assets/offline.\n\n'
        'Add a .mmpk file to assets/offline and list it in pubspec.yaml.',
        busy: false,
      );
      return;
    }

    try {
      final localMmpkPath = await _materializeAssetToLocalFile(mmpkAssetPath);

      final package = MobileMapPackage.withFileUri(Uri.file(localMmpkPath));

      await package.load();

      if (package.maps.isEmpty) {
        throw StateError('The mobile map package does not contain any maps.');
      }

      final map = package.maps.first;
      await map.load();
      _mapViewController.arcGISMap = map;

      if (!mounted) return;

      setState(() {
        _mapLoaded = true;
        _busy = false;
        _serviceFault = false;
        _status = 'Offline map loaded: ${_fileNameFromPath(mmpkAssetPath)}';
      });
    } on ArcGISException catch (error) {
      _serviceFault = true;
      _setStatus(
        'Could not load the offline map:\n${error.message}',
        busy: false,
      );
    } catch (error) {
      _serviceFault = true;
      _setStatus('Could not load the offline map:\n$error', busy: false);
    }
  }

  Future<String?> _findOfflineMmpkAssetPath() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final expectedAssetPath = '$offlineMapAssetDirectory$offlineMapAssetName'
        .toLowerCase();
    final matchingMapAssets = manifest
        .listAssets()
        .where((assetPath) => assetPath.toLowerCase() == expectedAssetPath)
        .toList();

    if (matchingMapAssets.isEmpty) {
      return null;
    }

    return matchingMapAssets.first;
  }

  Future<String> _materializeAssetToLocalFile(String assetPath) async {
    final assetData = await rootBundle.load(assetPath);
    final tempDir = await Directory.systemTemp.createTemp('rugged_mmpk_');
    final outputPath = '${tempDir.path}/${_fileNameFromPath(assetPath)}';
    final outputFile = File(outputPath);

    await outputFile.writeAsBytes(assetData.buffer.asUint8List(), flush: true);

    return outputFile.path;
  }

  String _fileNameFromPath(String path) {
    final normalizedPath = path.replaceAll('\\\\', '/');
    final lastSlashIndex = normalizedPath.lastIndexOf('/');

    if (lastSlashIndex == -1 || lastSlashIndex == normalizedPath.length - 1) {
      return normalizedPath;
    }

    return normalizedPath.substring(lastSlashIndex + 1);
  }

  Future<void> _toggleLocation() async {
    if (!_mapViewReady || !_mapLoaded) return;

    final locationDisplay = _mapViewController.locationDisplay;

    try {
      if (_locationEnabled) {
        locationDisplay.stop();
        await _locationSpoofer.stop();

        if (!mounted) return;
        setState(() {
          _locationEnabled = false;
          _status = 'Location stopped';
        });
        return;
      }

      await _locationSpoofer.stop();
      locationDisplay.dataSource = SystemLocationDataSource();
      locationDisplay.autoPanMode = LocationDisplayAutoPanMode.recenter;

      locationDisplay.start();

      if (!mounted) return;
      setState(() {
        _locationEnabled = true;
        _status = 'Following current location';
      });
    } on ArcGISException catch (error) {
      _serviceFault = true;
      _setStatus('Location unavailable: ${error.message}', busy: false);
    } catch (error) {
      _serviceFault = true;
      _setStatus('Location unavailable: $error', busy: false);
    }
  }

  Future<bool> _createRoute() async {
    if (!_mapLoaded || !_mapViewReady) {
      _showMessage('Wait for the offline map to finish loading.');
      return false;
    }

    setState(() {
      _isGeneratingRoute = true;
      _status = 'Generating on-road route…';
      _busy = true;
    });
    try {
      if (_onRoadRoutePlotter.service == null) {
        await _onRoadRoutePlotter.loadService();
      }
      final onRoadRoute = await _onRoadRoutePlotter.generateRoute(
        startAddress: _onRoadStartAddress,
        destinationAddress: _onRoadDestinationAddress,
      );
      if (!mounted) return false;

      await _onRoadRoutePlotter.displayRoute(onRoadRoute);
      if (!mounted) return false;

      setState(() {
        _onRoadRoute = onRoadRoute;
        _offroadRoute = null;
        _offroadDrivePolyline = null;
        _walkingPolyline = null;
        _offroadSolveError = null;
        _offroadTransitionRequested = false;
        _pavedDistanceMiles = _polylineMiles(onRoadRoute.polyline);
        _offroadDistanceMiles = 0;
        _walkingDistanceMiles = 0;
        _pavedProgress = 0;
        _offroadProgress = 0;
        _walkingProgress = 0;
        _busy = false;
        _serviceFault = false;
        _coordinatesLabel = _fixedCoordinatesLabel;
        _status = 'On-road route ready. Preparing off-road route…';
      });
      _offroadSolveFuture = _solveOffroadInBackground(
        onRoadDestination: onRoadRoute.destination,
      );
      unawaited(_offroadSolveFuture!);
      _showMessage('On-road route ready. Preparing off-road route.');
      return true;
    } on ArcGISException catch (error) {
      final message = 'Could not generate routes: ${error.message}';
      debugPrint(message);
      _setStatus(message, busy: false);
      _showMessage(message);
    } catch (error, stackTrace) {
      final message = 'Could not generate routes: $error';
      debugPrint('$message\n$stackTrace');
      _setStatus(message, busy: false);
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingRoute = false);
      }
    }
    return false;
  }

  Future<void> _solveOffroadInBackground({
    required ArcGISPoint onRoadDestination,
  }) async {
    try {
      final route = await _offroadRoutePlotter.solveFromOnRoadDestination(
        onRoadDestination: onRoadDestination,
      );
      if (!mounted) return;

      setState(() {
        _offroadRoute = route;
        final split = route.splitAtFirstWeightAbove(
          offroadWalkingWeightThreshold,
        );
        _offroadDrivePolyline = split?.beforeAlternate ?? route.polyline;
        _walkingPolyline = split?.alternate;
        _offroadDistanceMiles = _polylineMiles(_offroadDrivePolyline!);
        _walkingDistanceMiles = _walkingPolyline == null
            ? 0
            : _polylineMiles(_walkingPolyline!);
        _offroadSolveError = null;
        if (_activePhase == NavigationPhase.paved) {
          _status = 'Road navigation active. Off-road route ready.';
        }
      });
    } on ArcGISException catch (error) {
      debugPrint('Could not prepare off-road route: ${error.message}');
      if (!mounted) return;
      setState(() => _offroadSolveError = error);
    } catch (error, stackTrace) {
      debugPrint('Could not prepare off-road route: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _offroadSolveError = error);
    }
  }

  void _setStatus(String status, {required bool busy}) {
    if (!mounted) return;

    setState(() {
      _status = status;
      _busy = busy;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDispatchCallNotification() async {
    if (!mounted || _dispatchCallShown) {
      return;
    }

    _dispatchCallShown = true;

    setState(() {
      _dispatchCallAccepted = false;
      _status = 'Incoming dispatch call';
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    setState(() {
      _coordinatesLabel = _fixedCoordinatesLabel;
      _status = 'Dispatch updated coordinates';
    });
  }

  void _acceptDispatchCall() {
    setState(() {
      _dispatchCallAccepted = true;
      _status = 'Dispatch accepted. Navigate to patient.';
    });

    _startRoadNavigation();
  }

  void _openCurrentDispatch() {
    setState(() {
      _currentDispatchOpen = true;
    });
  }

  void _closeCurrentDispatch() {
    setState(() {
      _currentDispatchOpen = false;
    });
  }

  Future<void> _startRoadNavigation() async {
    if (_activePhase != null || _busy) {
      return;
    }

    final routesCreated = await _createRoute();
    if (!routesCreated || !mounted) {
      return;
    }

    await _setNavigationPhase(NavigationPhase.paved);
    await _startPavedSimulation();
  }

  Future<void> _startPavedSimulation() async {
    final route = _onRoadRoute;
    if (!mounted || _activePhase != NavigationPhase.paved || route == null) {
      return;
    }

    try {
      await _locationSpoofer.start(
        paths: [route.polyline],
        metersPerSecond: 200,
        locationDisplay: _mapViewController.locationDisplay,
        onFinished: () => unawaited(_startOffroadSimulation()),
        onProgress: (progress) {
          if (!mounted || _activePhase != NavigationPhase.paved) return;
          setState(() => _pavedProgress = progress);
        },
      );
      _mapViewController.locationDisplay.start();
      if (!mounted) return;
      setState(() => _locationEnabled = true);
    } on ArcGISException catch (error) {
      _setStatus(
        'Could not start paved simulation: ${error.message}',
        busy: false,
      );
    } catch (error) {
      _setStatus('Could not start paved simulation: $error', busy: false);
    }
  }

  Future<void> _startOffroadSimulation() async {
    if (!mounted ||
        _activePhase != NavigationPhase.paved ||
        _offroadTransitionRequested) {
      return;
    }
    _offroadTransitionRequested = true;

    if (_offroadRoute == null) {
      final solveFuture = _offroadSolveFuture;
      if (solveFuture != null) {
        setState(
          () => _status = 'Arrived at road handoff; preparing off-road route…',
        );
        await solveFuture;
      }
    }

    if (!mounted || _activePhase != NavigationPhase.paved) {
      _offroadTransitionRequested = false;
      return;
    }
    final route = _offroadRoute;
    if (route == null) {
      _offroadTransitionRequested = false;
      final error = _offroadSolveError;
      final message = error == null
          ? 'Off-road route is unavailable; simulated navigation stopped at '
                'the road handoff.'
          : 'Off-road route could not be prepared; simulated navigation '
                'stopped at the road handoff.\n$error';
      _setStatus(message, busy: false);
      _showMessage('Off-road route unavailable at the road handoff.');
      return;
    }

    final split = route.splitAtFirstWeightAbove(offroadWalkingWeightThreshold);
    final offroadPolyline = split?.beforeAlternate ?? route.polyline;
    setState(() {
      _pavedProgress = 1;
      _offroadProgress = 0;
    });
    await _setNavigationPhase(NavigationPhase.offroad);
    if (!mounted || _activePhase != NavigationPhase.offroad) return;

    if (split?.beforeAlternate == null && split != null) {
      await _startWalkingSimulation(split.alternate);
      return;
    }

    try {
      await _locationSpoofer.start(
        paths: [offroadPolyline],
        metersPerSecond: 12,
        locationDisplay: _mapViewController.locationDisplay,
        onFinished: split == null
            ? _markSimulatedNavigationComplete
            : () => unawaited(_startWalkingSimulation(split.alternate)),
        onProgress: (progress) {
          if (!mounted || _activePhase != NavigationPhase.offroad) return;
          setState(() => _offroadProgress = progress);
        },
      );
      _mapViewController.locationDisplay.start();
    } on ArcGISException catch (error) {
      _setStatus(
        'Could not start off-road simulation: ${error.message}',
        busy: false,
      );
    } catch (error) {
      _setStatus('Could not start off-road simulation: $error', busy: false);
    }
  }

  Future<void> _startWalkingSimulation(Polyline alternateRoute) async {
    if (!mounted || _activePhase != NavigationPhase.offroad) return;

    setState(() {
      _offroadProgress = 1;
      _walkingProgress = 0;
    });
    await _setNavigationPhase(NavigationPhase.walking);
    if (!mounted || _activePhase != NavigationPhase.walking) return;

    try {
      await _locationSpoofer.start(
        paths: [alternateRoute],
        metersPerSecond: 12,
        locationDisplay: _mapViewController.locationDisplay,
        onFinished: _markSimulatedNavigationComplete,
        onProgress: (progress) {
          if (!mounted || _activePhase != NavigationPhase.walking) return;
          setState(() => _walkingProgress = progress);
        },
      );
      _mapViewController.locationDisplay.start();
    } on ArcGISException catch (error) {
      _setStatus(
        'Could not start walking simulation: ${error.message}',
        busy: false,
      );
    } catch (error) {
      _setStatus('Could not start walking simulation: $error', busy: false);
    }
  }

  void _markSimulatedNavigationComplete() {
    if (!mounted) return;
    setState(() {
      _walkingProgress = 1;
      _status = 'Simulated navigation reached the destination.';
    });
  }

  Future<void> _setNavigationPhase(NavigationPhase phase) async {
    setState(() {
      _activePhase = phase;
      _status = _statusForPhase(phase);
    });
    _syncSpeedSimulation();

    if (phase == NavigationPhase.offroad) {
      final route = _offroadRoute;
      if (route != null) {
        try {
          await _offroadRoutePlotter.displayRoute(route);
        } on ArcGISException catch (error) {
          _setStatus(
            'Could not zoom to off-road route: ${error.message}',
            busy: false,
          );
        } catch (error) {
          _setStatus('Could not zoom to off-road route: $error', busy: false);
        }
      }
    }
  }

  String _statusForPhase(NavigationPhase phase) {
    switch (phase) {
      case NavigationPhase.paved:
        return 'Road navigation active';
      case NavigationPhase.offroad:
        return 'Transitioning to offroad segment';
      case NavigationPhase.walking:
        return 'Walking segment active';
    }
  }

  void _markPatientReached() {
    setState(() {
      _hospitalNavigationMode = true;
      _activePhase = null;
      _pavedProgress = 1;
      _offroadProgress = 1;
      _walkingProgress = 1;
      _status = 'Patient secured. Hospital navigation available.';
    });
    _syncSpeedSimulation();

    _showMessage('Patient secured. Ready to route to hospital.');
  }

  void _syncSpeedSimulation() {
    final phase = _activePhase;
    final shouldSimulate =
        !_hospitalNavigationMode &&
        (phase == NavigationPhase.paved || phase == NavigationPhase.offroad);

    if (!shouldSimulate) {
      _speedSimulationTimer?.cancel();
      _speedSimulationTimer = null;
      if (_pavedSpeedOverride != null || _offroadSpeedOverride != null) {
        setState(() {
          _pavedSpeedOverride = null;
          _offroadSpeedOverride = null;
        });
      }
      return;
    }

    _updateSpeedForActivePhase();
    _speedSimulationTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateSpeedForActivePhase(),
    );
  }

  void _updateSpeedForActivePhase() {
    if (!mounted) {
      return;
    }

    final phase = _activePhase;
    if (phase == NavigationPhase.paved) {
      final nextSpeed = (52 + _random.nextInt(9)).toString();
      setState(() {
        _pavedSpeedOverride = nextSpeed;
        _offroadSpeedOverride = null;
      });
      return;
    }

    if (phase == NavigationPhase.offroad) {
      final nextSpeed = '${10 + _random.nextInt(6)} MPH';
      setState(() {
        _offroadSpeedOverride = nextSpeed;
        _pavedSpeedOverride = null;
      });
      return;
    }

    _syncSpeedSimulation();
  }

  void _startHospitalRoute() {
    _showMessage('Starting hospital route...');
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  double _polylineMiles(Polyline polyline) {
    final projected = _projectPolylineToWgs84(polyline);
    var meters = 0.0;
    for (final part in projected.parts) {
      final points = part.getPoints();
      ArcGISPoint? previous;
      for (final point in points) {
        if (previous != null) {
          meters += _haversineMeters(previous, point);
        }
        previous = point;
      }
    }
    return meters / 1609.344;
  }

  Polyline _projectPolylineToWgs84(Polyline polyline) {
    if (polyline.spatialReference?.wkid == 4326) {
      return polyline;
    }
    final projected = GeometryEngine.project(
      polyline,
      outputSpatialReference: SpatialReference(wkid: 4326),
    );
    if (projected is! Polyline) {
      throw StateError('Could not project route polyline to WKID 4326.');
    }
    return projected;
  }

  double _haversineMeters(ArcGISPoint a, ArcGISPoint b) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _degreesToRadians(a.y);
    final lat2 = _degreesToRadians(b.y);
    final dLat = _degreesToRadians(b.y - a.y);
    final dLon = _degreesToRadians(b.x - a.x);
    final sinLat = math.sin(dLat / 2);
    final sinLon = math.sin(dLon / 2);
    final h =
        sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

  String get _livePavedRoadEtaLabel {
    if (_pavedDistanceMiles <= 0) {
      return _profile.pavedRoadEta;
    }
    final remainingMinutes = (_remainingPavedMiles / 56) * 60;
    return '${remainingMinutes.toStringAsFixed(1)} MIN';
  }

  String get _livePavedRouteProgressLabel {
    if (_pavedDistanceMiles <= 0) {
      return _profile.pavedRouteProgress;
    }
    final traveled = (_pavedDistanceMiles - _remainingPavedMiles).clamp(
      0,
      _pavedDistanceMiles,
    );
    return '${traveled.toStringAsFixed(1)} / ${_pavedDistanceMiles.toStringAsFixed(1)} Miles';
  }

  String get _liveOffroadRoadEtaLabel {
    if (_offroadDistanceMiles <= 0) {
      return _offroadRoute == null
          ? '--'
          : _profile.routeSegments[1].eta.toUpperCase();
    }
    final remainingMinutes = (_remainingOffroadMiles / 12) * 60;
    return '${remainingMinutes.toStringAsFixed(1)} MIN';
  }

  String get _liveOffroadRouteProgressLabel {
    if (_offroadDistanceMiles <= 0) {
      return _profile.offroadDistToExit.replaceFirst(
        'DIST TO OFFROAD EXIT ',
        '',
      );
    }
    final traveled = (_offroadDistanceMiles - _remainingOffroadMiles).clamp(
      0,
      _offroadDistanceMiles,
    );
    return '${traveled.toStringAsFixed(1)} / ${_offroadDistanceMiles.toStringAsFixed(1)} Miles';
  }

  String get _liveWalkingDistanceLabel {
    final remainingMeters = _remainingWalkingMiles * 1609.344;
    if (remainingMeters < 100) {
      return '${remainingMeters.toStringAsFixed(1)} M';
    }
    return '${remainingMeters.round()} M';
  }

  String get _routeTotalDistanceLabel {
    if (!_hasComputedRouteTotals) {
      return _profile.totalDistance;
    }

    final totalMiles =
        _pavedDistanceMiles + _offroadDistanceMiles + _walkingDistanceBaseMiles;
    return '${totalMiles.toStringAsFixed(2)} MI';
  }

  String get _routeTotalEtaLabel {
    if (!_hasComputedRouteTotals) {
      return _profile.totalResponseTime;
    }

    final totalMinutes =
        (_pavedDistanceMiles / 56) * 60 +
        (_offroadDistanceMiles / 12) * 60 +
        (_walkingDistanceBaseMiles / 3) * 60;
    return '${totalMinutes.toStringAsFixed(1)} MINS';
  }

  bool get _hasComputedRouteTotals =>
      _pavedDistanceMiles > 0 && _offroadDistanceMiles > 0;

  double get _remainingPavedMiles =>
      (_pavedDistanceMiles * (1 - _pavedProgress)).clamp(
        0,
        _pavedDistanceMiles,
      );

  double get _remainingOffroadMiles =>
      (_offroadDistanceMiles * (1 - _offroadProgress)).clamp(
        0,
        _offroadDistanceMiles,
      );

  double get _remainingWalkingMiles =>
      (_walkingDistanceBaseMiles * (1 - _walkingProgress)).clamp(
        0,
        _walkingDistanceBaseMiles,
      );

  bool get _canMarkPatientReached => (_remainingWalkingMiles * 1609.344) <= 0.5;

  double get _walkingDistanceBaseMiles {
    if (_walkingDistanceMiles > 0) {
      return _walkingDistanceMiles;
    }

    if (_profile.routeSegments.length >= 3) {
      final walkingText = _profile.routeSegments[2].distance;
      final parsedMeters = _parseDistanceMeters(walkingText);
      if (parsedMeters > 0) {
        return parsedMeters / 1609.344;
      }
    }

    return 340 / 1609.344;
  }

  double _parseDistanceMeters(String input) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(input);
    if (match == null) {
      return 0;
    }

    final value = double.tryParse(match.group(1)!);
    if (value == null || value <= 0) {
      return 0;
    }

    final lower = input.toLowerCase();
    if (lower.contains('km')) {
      return value * 1000;
    }
    if (lower.contains('mi') || lower.contains('mile')) {
      return value * 1609.344;
    }
    if (lower.contains('m')) {
      return value;
    }
    return 0;
  }

  @override
  void dispose() {
    _speedSimulationTimer?.cancel();
    _mapViewController.locationDisplay.stop();
    unawaited(_locationSpoofer.dispose());
    _offroadRoutePlotter.detach();
    _onRoadRoutePlotter.detach();
    _mapViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Rugged SystEMS'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(148),
              child: MapHeaderBar(
                coordinatesLabel: _coordinatesLabel,
                username: widget.username,
                showCurrentDispatch: _dispatchCallAccepted,
                onOpenCurrentDispatch: _openCurrentDispatch,
                onLogout: _logout,
                systemOn: _systemOn,
              ),
            ),
            actions: [
              IconButton(
                tooltip: _locationEnabled ? 'Stop location' : 'Start location',
                onPressed: _mapLoaded ? _toggleLocation : null,
                icon: Icon(
                  _locationEnabled
                      ? Icons.location_disabled
                      : Icons.my_location,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: () {
                  if (!mounted) return;
                  _offroadRoutePlotter.attach();
                  _onRoadRoutePlotter.attach();
                  _locationSpoofer.attach(_mapViewController);
                  setState(() => _mapViewReady = true);
                  if (!_offlineMapLoadStarted) {
                    _offlineMapLoadStarted = true;
                    unawaited(_loadOfflineMap());
                  }
                },
              ),
              if (_navigationStarted && !_hospitalNavigationMode)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: NavigationPhaseHud(
                      phase: _activePhase!,
                      routeSegments: _profile.routeSegments,
                      pavedInstructionDistance:
                          _profile.pavedInstructionDistance,
                      pavedInstructionText: _profile.pavedInstructionText,
                      offroadAdvisoryTitle: _profile.offroadAdvisoryTitle,
                      offroadAdvisoryDetails: _profile.offroadAdvisoryDetails,
                      walkingAdvisoryTitle: _profile.walkingAdvisoryTitle,
                      walkingAdvisoryDetails: _profile.walkingAdvisoryDetails,
                    ),
                  ),
                ),
              if (_hospitalNavigationMode)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: HospitalNavigationHud(profile: _profile),
                  ),
                ),
              if (_serviceFault || (_busy && !_isGeneratingRoute))
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 74),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _StatusCard(message: _status, showProgress: _busy),
                    ),
                  ),
                ),
              if (_navigationStarted && !_hospitalNavigationMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: NavigationStatusPanel(
                      phase: _activePhase!,
                      profile: _profile,
                      onPatientReached: _markPatientReached,
                      pavedSpeedOverride: _pavedSpeedOverride,
                      offroadSpeedOverride: _offroadSpeedOverride,
                      pavedRoadEta: _livePavedRoadEtaLabel,
                      pavedRouteProgress: _livePavedRouteProgressLabel,
                      offroadRoadEta: _liveOffroadRoadEtaLabel,
                      offroadRouteProgress: _liveOffroadRouteProgressLabel,
                      walkingDistanceToPatient: _liveWalkingDistanceLabel,
                      walkingCanMarkReached: _canMarkPatientReached,
                    ),
                  ),
                ),
              if (_hospitalNavigationMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: HospitalRoutePanel(
                      profile: _profile,
                      onStartHospitalRoute: _startHospitalRoute,
                    ),
                  ),
                ),
              if (_currentDispatchOpen)
                Positioned.fill(
                  child: CurrentDispatchOverlay(
                    profile: _profile,
                    coordinatesLabel: _coordinatesLabel,
                    totalResponseTime: _routeTotalEtaLabel,
                    totalDistance: _routeTotalDistanceLabel,
                    onClose: _closeCurrentDispatch,
                  ),
                ),
            ],
          ),
          floatingActionButton: null,
        ),
        if (_dispatchCallShown && !_dispatchCallAccepted)
          Positioned.fill(
            child: DispatchCallPanel(
              profile: _profile,
              coordinatesLabel: _coordinatesLabel,
              onAcceptNavigate: _acceptDispatchCall,
            ),
          ),
        if (_isGeneratingRoute)
          Positioned.fill(child: _RouteLoadingScreen(message: _status)),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, required this.showProgress});

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 48,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Generating route',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
