import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/settings_provider.dart';
import 'widgets/home_screen.dart';

const _kMinWidth = 1200.0;
const _kMinHeight = 800.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    await windowManager.setMinimumSize(const Size(_kMinWidth, _kMinHeight));

    final screen = await windowManager.getBounds();
    final double initW = screen.width.clamp(_kMinWidth, 1920);
    final double initH = screen.height.clamp(_kMinHeight, 1200);
    await windowManager.setSize(Size(initW, initH));
    await windowManager.center();

    final iconPath =
        '${Directory.current.path}${Platform.pathSeparator}assets${Platform.pathSeparator}logo${Platform.pathSeparator}logo_alpha0.png';
    final iconFile = File(iconPath);
    if (await iconFile.exists()) {
      await windowManager.setIcon(iconPath);
    }

    await windowManager.show();
  }

  runApp(const ProviderScope(child: TrreeeApp()));
}

class TrreeeApp extends ConsumerWidget {
  const TrreeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007ACC),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007ACC),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF1E1E1E),
        surfaceContainerLow: const Color(0xFF252526),
        surfaceContainerHighest: const Color(0xFF2D2D30),
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    );

    return MaterialApp(
      title: 'Trreee',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.materialThemeMode,
      home: const HomeScreen(),
    );
  }
}
