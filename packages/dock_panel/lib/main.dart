/// dock_panel demo / playground.
///
/// This file is NOT part of the dock_panel library API.
/// It exists for local testing only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: _DockDemoApp()));
}

class _DockDemoApp extends StatelessWidget {
  const _DockDemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dock Panel Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Dock Panel')),
        body: const Center(child: Text('dock_panel playground')),
      ),
    );
  }
}
