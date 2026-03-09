import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'services/bluetooth_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';

void main() {
  AppLogger.info('Starting Smart Glove application');
  runApp(const SmartGloveApp());
}

class SmartGloveApp extends StatelessWidget {
  const SmartGloveApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.ui('Building SmartGloveApp');
    
    return ChangeNotifierProvider(
      create: (_) => BluetoothService(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppConstants.supportedLocales,
        locale: ui.PlatformDispatcher.instance.locale,
        routes: {
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
