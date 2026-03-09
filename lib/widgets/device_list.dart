import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart' as local;
import '../core/language_manager.dart';
import '../widgets/signal_strength_icon.dart';
import '../utils/logger.dart';

class DeviceList extends StatelessWidget {
  final local.BluetoothService bluetoothService;
  final LanguageManager languageManager;

  const DeviceList({
    super.key,
    required this.bluetoothService,
    required this.languageManager,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.ui('Building Device List widget');

    return StreamBuilder<List<ScanResult>>(
      stream: bluetoothService.scanResults,
      initialData: const [],
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final result = devices[index];
            return _buildDeviceTile(context, result);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            languageManager.getLocalizedText('scanning'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, ScanResult result) {
    // Try to get device name from multiple sources
    String deviceName = result.device.platformName;

    // If platformName is empty, try advertisement data
    if (deviceName.isEmpty && result.advertisementData.advName.isNotEmpty) {
      deviceName = result.advertisementData.advName;
    }

    // If still empty, show as Unknown
    if (deviceName.isEmpty) {
      deviceName = languageManager.getLocalizedText('unknown');
    }

    final macAddress = result.device.remoteId.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: SignalStrengthIcon(rssi: result.rssi),
        title: Text(
          '$deviceName\n$macAddress',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 14,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(result.device),
          child: Text(languageManager.getLocalizedText('connect')),
        ),
      ),
    );
  }

  void _connectToDevice(BluetoothDevice device) {
    AppLogger.ui('Connecting to device: ${device.remoteId}');
    bluetoothService.connectToDevice(device);
  }
}
