import 'package:flutter/material.dart';

enum BluetoothConnectionStatus {
  connected,
  disconnected,
  connecting,
  error;
}

extension BluetoothConnectionStatusExtension on BluetoothConnectionStatus {
  String get key {
    switch (this) {
      case BluetoothConnectionStatus.connected:
        return 'connected';
      case BluetoothConnectionStatus.disconnected:
        return 'disconnected';
      case BluetoothConnectionStatus.connecting:
        return 'connecting';
      case BluetoothConnectionStatus.error:
        return 'error';
    }
  }
}

enum TtsState {
  playing,
  stopped;
}

class AppConstants {
  static const String appName = 'Smart Glove';
  static const Duration bluetoothScanTimeout = Duration(seconds: 5);
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 10);
  static const int bluetoothMtuSize = 512;
  static const String bluetoothServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  
  // RSSI signal strength thresholds
  static const int rssiStrong = -70;
  static const int rssiMedium = -90;
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // Arabic
    Locale('fr', ''), // French
  ];
}
