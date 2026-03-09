import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class GlovePermissionManager {
  static Future<bool> requestGlovePermissions() async {
    AppLogger.info('Requesting all Smart Glove permissions');

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    // Log each permission status
    statuses.forEach((permission, status) {
      AppLogger.info('Permission $permission: $status');
    });

    // Check if any permission is permanently denied
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      AppLogger.warning('Some permissions permanently denied, opening app settings');
      await openAppSettings();
      return false;
    }

    final allGranted = statuses.values.every((status) => status.isGranted);
    AppLogger.info('All permissions granted: $allGranted');
    return allGranted;
  }

  static Future<bool> checkPermissionsStatus() async {
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    final advertiseStatus = await Permission.bluetoothAdvertise.status;
    final locationStatus = await Permission.location.status;

    return scanStatus.isGranted && connectStatus.isGranted &&
           advertiseStatus.isGranted && locationStatus.isGranted;
  }
}
