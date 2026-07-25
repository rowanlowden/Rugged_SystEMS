import 'package:flutter/material.dart';

import 'login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RuggedSystemsApp());
}

class RuggedSystemsApp extends StatelessWidget {
  const RuggedSystemsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rugged Systems',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
