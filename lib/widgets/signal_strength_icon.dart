import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';

class SignalStrengthIcon extends StatelessWidget {
  final int rssi;

  const SignalStrengthIcon({super.key, required this.rssi});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    
    if (rssi > AppConstants.rssiStrong) {
      icon = Icons.signal_cellular_alt;
      color = AppTheme.successColor;
    } else if (rssi > AppConstants.rssiMedium) {
      icon = Icons.signal_cellular_alt_2_bar;
      color = AppTheme.warningColor;
    } else {
      icon = Icons.signal_cellular_alt_1_bar;
      color = AppTheme.errorColor;
    }
    
    return Icon(icon, color: color);
  }
}
