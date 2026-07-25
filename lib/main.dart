import 'package:flutter/material.dart';
import 'package:rugged_systems/offroad_route.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  solvePresetLeastCostPath();
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

