import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflineNavigationApp());
}

/// Supply the local mobile map package path when running:
///
/// flutter run --dart-define=OFFLINE_MMPK_PATH=/path/to/navigation.mmpk
///
/// The package should contain:
/// - An offline map
/// - A transportation network, if offline routing will be implemented
/// - Any required local locator or navigation data
const offlineMapPackagePath = String.fromEnvironment(
  'OFFLINE_MMPK_PATH',
  defaultValue: '',
);

class OfflineNavigationApp extends StatelessWidget {
  const OfflineNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const OfflineNavigationPage(),
    );
  }
}

class OfflineNavigationPage extends StatefulWidget {
  const OfflineNavigationPage({super.key});

  @override
  State<OfflineNavigationPage> createState() =>
      _OfflineNavigationPageState();
}

class _OfflineNavigationPageState extends State<OfflineNavigationPage> {
  final ArcGISMapViewController _mapViewController =
      ArcGISMapView.createController();

  MobileMapPackage? _mobileMapPackage;

  bool _mapViewReady = false;
  bool _mapLoaded = false;
  bool _locationEnabled = false;
  bool _busy = true;

  String _status = 'Loading offline map…';

  @override
  void initState() {
    super.initState();
    _loadOfflineMap();
  }

  Future<void> _loadOfflineMap() async {
    if (offlineMapPackagePath.trim().isEmpty) {
      _setStatus(
        'No offline map package was configured.\n\n'
        'Provide OFFLINE_MMPK_PATH with --dart-define.',
        busy: false,
      );
      return;
    }

    try {
      final package = MobileMapPackage.withFileUri(
        Uri.file(offlineMapPackagePath),
      );

      await package.load();

      if (package.maps.isEmpty) {
        throw StateError(
          'The mobile map package does not contain any maps.',
        );
      }

      _mobileMapPackage = package;
      _mapViewController.arcGISMap = package.maps.first;

      if (!mounted) return;

      setState(() {
        _mapLoaded = true;
        _busy = false;
        _status = 'Offline map loaded';
      });
    } on ArcGISException catch (error) {
      _setStatus(
        'Could not load the offline map:\n${error.message}',
        busy: false,
      );
    } catch (error) {
      _setStatus(
        'Could not load the offline map:\n$error',
        busy: false,
      );
    }
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
      _setStatus('Location unavailable: ${error.message}', busy: false);
    } catch (error) {
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

  void _createRoute() {
    // Boilerplate extension point:
    //
    // 1. Obtain the transportation network from the loaded MMPK.
    // 2. Create a RouteTask using that local network.
    // 3. Add the start and destination stops.
    // 4. Solve the route entirely offline.
    // 5. Display the route in a GraphicsOverlay.
    // 6. Create a RouteTracker for turn-by-turn navigation.
    _showMessage(
      'Route setup placeholder: connect this action to the '
      'transportation network stored in the offline map package.',
    );
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

  @override
  void dispose() {
    _mapViewController.locationDisplay.stop();
    _mapViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Navigation'),
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
              setState(() => _mapViewReady = true);
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _StatusCard(
                message: _status,
                showProgress: _busy,
              ),
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
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'route',
            onPressed: _mapLoaded ? _createRoute : null,
            icon: const Icon(Icons.route),
            label: const Text('Route'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.message,
    required this.showProgress,
  });

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
