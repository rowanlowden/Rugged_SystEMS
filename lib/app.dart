import 'dart:async' show unawaited;
import 'dart:io';

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
const _onRoadStartAddress = '7774 COUNTY ROAD P, WESTBY, WI 54667';
const _onRoadDestinationAddress = '7880 COUNTY ROAD P, WESTBY, WI 54667';

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

  String _status = 'Loading offline map…';
  String _coordinatesLabel = '';

  bool get _systemOn => _mapLoaded && !_serviceFault;
  bool get _navigationStarted => _activePhase != null;

  @override
  void initState() {
    super.initState();
    _profile = demoProfileForUsername(widget.username);
    _coordinatesLabel = _profile.stagingCoordinates;
    _offroadRoutePlotter = OffroadRoutePlotter(_mapViewController);
    _onRoadRoutePlotter = OnRoadRoutePlotter(_mapViewController);
    _locationSpoofer = PathLocationSpoofer(
      onFinished: () {
        if (!mounted) return;
        if (_activePhase == NavigationPhase.paved) {
          unawaited(_startOffroadSimulation());
        } else if (_activePhase == NavigationPhase.offroad) {
          setState(
            () => _status = 'Simulated navigation reached the destination.',
          );
        }
      },
    );
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
      _status = 'Generating on-road and off-road routes…';
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
      final offroadRoute = await _offroadRoutePlotter
          .solveFromOnRoadDestination(
            onRoadDestination: onRoadRoute.destination,
            maxDistanceMeters: 250,
          );
      final routeTarget = offroadRoute.vertices.isNotEmpty
          ? offroadRoute.vertices.last
          : onRoadRoute.destination;
      final routeCoordinatesLabel = _formatCoordinates(routeTarget);
      if (!mounted) return false;

      await _offroadRoutePlotter.displayRoute(offroadRoute, zoom: false);
      await _onRoadRoutePlotter.displayRoute(onRoadRoute);
      if (!mounted) return false;

      setState(() {
        _onRoadRoute = onRoadRoute;
        _offroadRoute = offroadRoute;
        _busy = false;
        _serviceFault = false;
        _coordinatesLabel = routeCoordinatesLabel;
        _status =
            'On-road and off-road routes are ready. '
            'Showing the on-road route.';
      });
      _showMessage('Both routes are ready. Showing the on-road route.');
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
    }
    finally {
      if (mounted) {
        setState(() => _isGeneratingRoute = false);
      }
    }
    return false;
  }

  String _formatCoordinates(ArcGISPoint point) {
    final geographicPoint = _projectToWgs84(point);
    final latitude = geographicPoint.y;
    final longitude = geographicPoint.x;
    final latitudeHemisphere = latitude >= 0 ? 'N' : 'S';
    final longitudeHemisphere = longitude >= 0 ? 'E' : 'W';

    return '$latitudeHemisphere ${latitude.abs().toStringAsFixed(4)}, '
        '$longitudeHemisphere ${longitude.abs().toStringAsFixed(4)}';
  }

  ArcGISPoint _projectToWgs84(ArcGISPoint point) {
    if (point.spatialReference?.wkid == 4326) {
      return point;
    }

    final projected = GeometryEngine.project(
      point,
      outputSpatialReference: SpatialReference(wkid: 4326),
    );
    if (projected is! ArcGISPoint) {
      throw StateError('Could not project route coordinates to WKID 4326.');
    }
    return projected;
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
      _coordinatesLabel = _profile.incidentCoordinates;
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
        metersPerSecond: 12,
        locationDisplay: _mapViewController.locationDisplay,
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
    final route = _offroadRoute;
    if (!mounted || _activePhase != NavigationPhase.paved || route == null) {
      return;
    }

    await _setNavigationPhase(NavigationPhase.offroad);
    if (!mounted || _activePhase != NavigationPhase.offroad) return;

    try {
      await _locationSpoofer.start(
        paths: [route.polyline],
        metersPerSecond: 12,
        locationDisplay: _mapViewController.locationDisplay,
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

  Future<void> _setNavigationPhase(NavigationPhase phase) async {
    setState(() {
      _activePhase = phase;
      _status = _statusForPhase(phase);
    });

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
      _status = 'Patient secured. Hospital navigation available.';
    });

    _showMessage('Patient secured. Ready to route to hospital.');
  }

  void _startHospitalRoute() {
    _showMessage('Starting hospital route...');
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void dispose() {
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
              _locationEnabled ? Icons.location_disabled : Icons.my_location,
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
                  pavedInstructionDistance: _profile.pavedInstructionDistance,
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

