import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/bluetooth_service.dart' as local;
import '../core/permission_manager.dart';
import '../core/language_manager.dart';
import '../core/constants.dart';
import '../core/gesture_manager.dart';
import '../widgets/device_list.dart';
import '../widgets/tts_player.dart';
import '../widgets/intro_screen.dart';
import '../screens/gesture_list_screen.dart';
import '../utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LanguageManager _languageManager = LanguageManager();

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HomeScreen initialized');
    _requestPermissionsOnStartup();
  }

  Future<void> _requestPermissionsOnStartup() async {
    AppLogger.info('Requesting permissions on app startup');

    final allGranted = await GlovePermissionManager.requestGlovePermissions();

    if (allGranted) {
      AppLogger.info('All permissions granted - enabling Bluetooth and Location');
      await _enableBluetoothAndLocation();
    } else {
      AppLogger.warning('Some permissions were denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_languageManager.getLocalizedText('permissions_not_granted')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _enableBluetoothAndLocation() async {
    try {
      // Check and enable Bluetooth
      final bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        AppLogger.info('Bluetooth is off, requesting to turn on');
        await FlutterBluePlus.turnOn();
        AppLogger.info('Bluetooth turned on');
      }

      // Check and request Location Service
      final locationServiceStatus = await Permission.location.serviceStatus;
      if (!locationServiceStatus.isEnabled) {
        AppLogger.info('Location service is off, requesting to turn on');
        // This will prompt user to enable location
        await Permission.locationWhenInUse.request();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enable Bluetooth/Location', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = Provider.of<local.BluetoothService>(context);

    AppLogger.ui('Building HomeScreen');

    return Scaffold(
      appBar: _buildAppBar(context, bluetoothService),
      body: _buildBody(context, bluetoothService),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, local.BluetoothService bluetoothService) {
    return AppBar(
      title: StreamBuilder<BluetoothConnectionStatus>(
        stream: bluetoothService.connectionStatus,
        initialData: BluetoothConnectionStatus.disconnected,
        builder: (context, snapshot) {
          final status = snapshot.data ?? BluetoothConnectionStatus.disconnected;
          return Text(_languageManager.getLocalizedText(status.key));
        },
      ),
      actions: [
        _buildSettingsButton(context),
        _buildGestureButton(context),
        _buildDisconnectButton(bluetoothService),
        _buildScanButton(bluetoothService),
        _buildAdvertiseButton(bluetoothService),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: _languageManager.getLocalizedText('settings'),
      onPressed: () => _navigateToSettings(context),
    );
  }

  Widget _buildGestureButton(BuildContext context) {
    return StreamBuilder<HandGesture?>(
      stream: Provider.of<local.BluetoothService>(context).onGestureDetected,
      initialData: null,
      builder: (context, snapshot) {
        final currentGesture = snapshot.data;
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.gesture),
              if (currentGesture != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Hand Gestures',
          onPressed: () => _navigateToGestures(context),
        );
      },
    );
  }

  Widget _buildDisconnectButton(local.BluetoothService bluetoothService) {
    return StreamBuilder<BluetoothConnectionStatus>(
      stream: bluetoothService.connectionStatus,
      initialData: BluetoothConnectionStatus.disconnected,
      builder: (context, snapshot) {
        if (snapshot.data == BluetoothConnectionStatus.connected) {
          return IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: _languageManager.getLocalizedText('disconnect'),
            onPressed: () => bluetoothService.disconnect(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScanButton(local.BluetoothService bluetoothService) {
    return StreamBuilder<bool>(
      stream: bluetoothService.isScanning,
      initialData: false,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;

        if (isScanning) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.search),
            tooltip: _languageManager.getLocalizedText('scan'),
            onPressed: () => bluetoothService.startScan(),
          );
        }
      },
    );
  }

  Widget _buildAdvertiseButton(local.BluetoothService bluetoothService) {
    return StreamBuilder<bool>(
      stream: bluetoothService.isAdvertising,
      initialData: false,
      builder: (context, snapshot) {
        final isAdvertising = snapshot.data ?? false;

        return IconButton(
          icon: Icon(isAdvertising ? Icons.campaign : Icons.campaign_outlined),
          tooltip: isAdvertising ? 'Stop Advertising' : 'Advertise Device',
          color: isAdvertising ? Colors.green : null,
          onPressed: () {
            if (isAdvertising) {
              bluetoothService.stopAdvertising();
            } else {
              bluetoothService.startAdvertising();
            }
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, local.BluetoothService bluetoothService) {
    return StreamBuilder<BluetoothConnectionStatus>(
      stream: bluetoothService.connectionStatus,
      initialData: BluetoothConnectionStatus.disconnected,
      builder: (context, connectionSnapshot) {
        final isConnected = connectionSnapshot.data == BluetoothConnectionStatus.connected;

        if (isConnected) {
          return _buildConnectedView(context, bluetoothService);
        } else {
          return _buildDisconnectedView(context, bluetoothService);
        }
      },
    );
  }

  Widget _buildConnectedView(BuildContext context, local.BluetoothService bluetoothService) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: StreamBuilder<String?>(
              stream: bluetoothService.currentSpokenText,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    snapshot.data ?? _languageManager.getLocalizedText('waiting'),
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        TtsPlayer(
          bluetoothService: bluetoothService,
          languageManager: _languageManager,
        ),
      ],
    );
  }

  Widget _buildDisconnectedView(BuildContext context, local.BluetoothService bluetoothService) {
    return StreamBuilder<bool>(
      stream: bluetoothService.isScanning,
      initialData: false,
      builder: (context, scanningSnapshot) {
        final isScanning = scanningSnapshot.data ?? false;

        if (isScanning) {
          return _buildScanningView(context);
        } else {
          return _buildDeviceListView(context, bluetoothService);
        }
      },
    );
  }

  Widget _buildScanningView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _languageManager.getLocalizedText('scanning'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListView(BuildContext context, local.BluetoothService bluetoothService) {
    return StreamBuilder<List<ScanResult>>(
      stream: bluetoothService.scanResults,
      initialData: const [],
      builder: (context, scanSnapshot) {
        final hasResults = (scanSnapshot.data?.isNotEmpty ?? false);

        if (!hasResults) {
          return const IntroScreen();
        }

        return DeviceList(
          bluetoothService: bluetoothService,
          languageManager: _languageManager,
        );
      },
    );
  }

  void _navigateToSettings(BuildContext context) {
    AppLogger.ui('Navigating to settings screen');
    Navigator.of(context).pushNamed('/settings');
  }

  void _navigateToGestures(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GestureListScreen(
          languageManager: _languageManager,
          onGestureSelected: (gesture) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: ${gesture.name}')),
            );
          },
        ),
      ),
    );
  }
}
