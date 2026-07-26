import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'offroad_route.dart';
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
import 'widgets/patient_route_sheet.dart';
import 'widgets/route_summary_bar.dart';

const offlineMapAssetDirectory = 'assets/offline/';
const offlineMapAssetName = 'map_package.mmpk';
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
  late final DemoIncidentProfile _profile;

  bool _mapViewReady = false;
  bool _mapLoaded = false;
  bool _locationEnabled = false;
  bool _busy = true;
  bool _serviceFault = false;
  bool _dispatchCallShown = false;
  bool _dispatchCallAccepted = false;
  bool _currentDispatchOpen = false;
  bool _hospitalNavigationMode = false;
  NavigationPhase? _activePhase;
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
    _loadOfflineMap();
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
    final expectedAssetPath =
        '$offlineMapAssetDirectory$offlineMapAssetName'.toLowerCase();
    final matchingMapAssets =
        manifest
            .listAssets()
            .where(
              (assetPath) =>
                  assetPath.toLowerCase() == expectedAssetPath,
            )
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

  void _toggleLocation() {
    if (!_mapViewReady || !_mapLoaded) return;

    final locationDisplay = _mapViewController.locationDisplay;

    try {
      if (_locationEnabled) {
        locationDisplay.stop();

        if (!mounted) return;
        setState(() {
          _locationEnabled = false;
          _status = 'Location stopped';
        });
        return;
      }

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

  void _recenter() {
    if (!_locationEnabled) {
      _showMessage('Enable location before recentering.');
      return;
    }

    _mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.recenter;

    setState(() {
      _status = 'Following current location';
    });
  }

  Future<bool> _createRoute() async {
    if (!_mapLoaded || !_mapViewReady) {
      _showMessage('Wait for the offline map to finish loading.');
      return false;
    }

    _setStatus('Generating on-road and off-road routes…', busy: true);
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
      if (!mounted) return false;

      await _offroadRoutePlotter.displayRoute(offroadRoute, zoom: false);
      await _onRoadRoutePlotter.displayRoute(onRoadRoute);
      if (!mounted) return false;

      setState(() {
        _offroadRoute = offroadRoute;
        _busy = false;
        _serviceFault = false;
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
    return false;
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

  void _goToNextPhase() {
    final currentPhase = _activePhase;
    if (currentPhase == null) {
      return;
    }

    switch (currentPhase) {
      case NavigationPhase.paved:
        _setNavigationPhase(NavigationPhase.offroad);
        break;
      case NavigationPhase.offroad:
        _setNavigationPhase(NavigationPhase.walking);
        break;
      case NavigationPhase.walking:
        _setNavigationPhase(NavigationPhase.walking);
        break;
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
    _offroadRoutePlotter.detach();
    _onRoadRoutePlotter.detach();
    _mapViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              setState(() => _mapViewReady = true);
            },
          ),
          if (!_navigationStarted && !_hospitalNavigationMode)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: RouteSummaryBar(
                  totalResponseTime: _profile.totalResponseTime,
                  totalDistance: _profile.totalDistance,
                ),
              ),
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
                  onPhaseSelected: _setNavigationPhase,
                  onNextPhase: _goToNextPhase,
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
          if (_busy || _serviceFault)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 74),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _StatusCard(message: _status, showProgress: _busy),
                ),
              ),
            ),
          if (!_navigationStarted && !_hospitalNavigationMode)
            DraggableScrollableSheet(
              initialChildSize: 0.22,
              minChildSize: 0.12,
              maxChildSize: 0.52,
              snap: true,
              snapSizes: const [0.22, 0.52],
              builder: (context, scrollController) {
                return PatientRouteSheet(
                  scrollController: scrollController,
                  onStartNavigation: _startRoadNavigation,
                  routeSegments: _profile.routeSegments,
                );
              },
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
          if (_dispatchCallShown && !_dispatchCallAccepted)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: DispatchCallPanel(
                  profile: _profile,
                  onAcceptNavigate: _acceptDispatchCall,
                ),
              ),
            ),
          if (_currentDispatchOpen)
            Positioned.fill(
              child: CurrentDispatchOverlay(
                profile: _profile,
                onClose: _closeCurrentDispatch,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'recenter',
            tooltip: 'Recenter',
            onPressed: _mapLoaded ? _recenter : null,
            child: const Icon(Icons.gps_fixed),
          ),
        ],
      ),
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
