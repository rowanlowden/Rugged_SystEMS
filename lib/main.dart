import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'map.dart';

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

