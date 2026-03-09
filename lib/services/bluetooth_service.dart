import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../core/constants.dart';
import '../core/language_manager.dart';
import '../core/gesture_manager.dart';
import '../utils/logger.dart';

class BluetoothService with ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final List<String> _messageQueue = [];
  final LanguageManager _languageManager = LanguageManager();

  // Stream subscriptions
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Bluetooth state
  BluetoothDevice? _connectedDevice;
  HandGesture? _currentGesture;

  // Stream controllers
  final BehaviorSubject<bool> _isScanningController = BehaviorSubject.seeded(false);
  final BehaviorSubject<TtsState> _ttsStateController = BehaviorSubject.seeded(TtsState.stopped);
  final BehaviorSubject<String?> _currentSpokenTextController = BehaviorSubject.seeded(null);
  final BehaviorSubject<BluetoothConnectionStatus> _connectionStatusController =
      BehaviorSubject.seeded(BluetoothConnectionStatus.disconnected);
  final BehaviorSubject<List<ScanResult>> _scanResultsController = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _isAdvertisingController = BehaviorSubject.seeded(false);

  final StreamController<String> _messageController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  final StreamController<HandGesture?> _gestureController = StreamController.broadcast();

  // TTS properties
  String _ttsLanguage = '';
  List<String> _availableTtsLanguages = [];
  String _translationLanguage = ''; // Desired translation language

  // Public getters
  Stream<bool> get isScanning => _isScanningController.stream;
  Stream<bool> get isAdvertising => _isAdvertisingController.stream;
  Stream<TtsState> get ttsState => _ttsStateController.stream;
  Stream<String?> get currentSpokenText => _currentSpokenTextController.stream;
  Stream<BluetoothConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  Stream<String> get onMessageReceived => _messageController.stream;
  Stream<String> get errors => _errorController.stream;
  Stream<HandGesture?> get onGestureDetected => _gestureController.stream;

  bool get isScanningCurrent => _isScanningController.value;
  TtsState get currentTtsState => _ttsStateController.value;
  BluetoothConnectionStatus get currentConnectionStatus => _connectionStatusController.value;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  HandGesture? get currentGesture => _currentGesture;

  String getTtsLanguage() => _ttsLanguage;
  List<String> getAvailableTtsLanguages() => _availableTtsLanguages;
  String getTranslationLanguage() => _translationLanguage;

  BluetoothService() {
    AppLogger.info('BluetoothService initialized');
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _initTts();
      _initBluetooth();
      AppLogger.info('Services initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize services', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('tts_init_failed') + e.toString());
    }
  }

  Future<void> _initTts() async {
    try {
      AppLogger.tts('Initializing TTS');
      _ttsLanguage = _languageManager.getDeviceLanguage();
      await _flutterTts.setLanguage(_ttsLanguage);

      // Configure TTS settings for better sound
      await _flutterTts.setSpeechRate(0.5); // Slower speech for clarity
      await _flutterTts.setVolume(1.0); // Maximum volume
      await _flutterTts.setPitch(1.0); // Normal pitch

      final languages = await _flutterTts.getLanguages;
      if (languages is List<dynamic>) {
        _availableTtsLanguages = languages.map((lang) => lang.toString()).toList();
        AppLogger.tts('Available TTS languages: $_availableTtsLanguages');
      }

      _flutterTts.setCompletionHandler(() {
        AppLogger.tts('TTS completed');
        _ttsStateController.add(TtsState.stopped);
        _currentSpokenTextController.add(null);
        _speakNextMessage();
      });

      AppLogger.tts('TTS initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize TTS', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> setTtsLanguage(String language) async {
    try {
      AppLogger.tts('Setting TTS language to: $language');
      _ttsLanguage = language;
      await _flutterTts.setLanguage(_ttsLanguage);
      notifyListeners();
      AppLogger.tts('TTS language set successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set TTS language', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('tts_language_failed') + e.toString());
    }
  }

  Future<void> setTtsVolume(double volume) async {
    try {
      AppLogger.tts('Setting TTS volume to: $volume');
      await _flutterTts.setVolume(volume);
      notifyListeners();
      AppLogger.tts('TTS volume set successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set TTS volume', error: e, stackTrace: stackTrace);
      _errorController.add('Failed to set TTS volume: $e');
    }
  }

  Future<void> setTtsSpeechRate(double rate) async {
    try {
      AppLogger.tts('Setting TTS speech rate to: $rate');
      await _flutterTts.setSpeechRate(rate);
      notifyListeners();
      AppLogger.tts('TTS speech rate set successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set TTS speech rate', error: e, stackTrace: stackTrace);
      _errorController.add('Failed to set TTS speech rate: $e');
    }
  }

  Future<void> setTtsPitch(double pitch) async {
    try {
      AppLogger.tts('Setting TTS pitch to: $pitch');
      await _flutterTts.setPitch(pitch);
      notifyListeners();
      AppLogger.tts('TTS pitch set successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set TTS pitch', error: e, stackTrace: stackTrace);
      _errorController.add('Failed to set TTS pitch: $e');
    }
  }

  Future<void> testTts() async {
    try {
      AppLogger.tts('Testing TTS');
      _messageQueue.add('TTS test - Smart Glove is working properly');
      if (_ttsStateController.value == TtsState.stopped) {
        _speakNextMessage();
      }
    } catch (e, stackTrace) {
      AppLogger.error('TTS test failed', error: e, stackTrace: stackTrace);
      _errorController.add('TTS test failed: $e');
    }
  }

  Future<void> setTranslationLanguage(String language) async {
    try {
      AppLogger.info('Setting translation language to: $language');
      _translationLanguage = language;
      notifyListeners();
      AppLogger.info('Translation language set successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set translation language', error: e, stackTrace: stackTrace);
      _errorController.add('Failed to set translation language: $e');
    }
  }

  void _initBluetooth() {
    try {
      AppLogger.bluetooth('Initializing Bluetooth');
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        AppLogger.bluetooth('Bluetooth adapter state changed: $state');
        _handleBluetoothStateChange(state);
      });
      AppLogger.bluetooth('Bluetooth initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Bluetooth', error: e, stackTrace: stackTrace);
      _errorController.add('Bluetooth initialization failed: $e');
    }
  }

  void _handleBluetoothStateChange(BluetoothAdapterState state) {
    if (state != BluetoothAdapterState.on) {
      String message;
      switch (state) {
        case BluetoothAdapterState.off:
          message = _languageManager.getLocalizedText('bluetooth_off');
          break;
        case BluetoothAdapterState.turningOff:
          message = _languageManager.getLocalizedText('bluetooth_turning_off');
          break;
        case BluetoothAdapterState.unauthorized:
          message = _languageManager.getLocalizedText('bluetooth_unauthorized');
          break;
        case BluetoothAdapterState.unavailable:
          message = _languageManager.getLocalizedText('bluetooth_unavailable');
          break;
        default:
          message = _languageManager.getLocalizedText('bluetooth_not_ready');
      }
      AppLogger.warning(message);
      _errorController.add(message);
      _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
    }
  }

  Future<void> startScan() async {
    if (_isScanningController.value) {
      AppLogger.bluetooth('Scan already in progress');
      return;
    }

    try {
      AppLogger.bluetooth('Checking Bluetooth permissions and state');

      // Request permissions if not granted
      final scanPermission = await Permission.bluetoothScan.request();
      final connectPermission = await Permission.bluetoothConnect.request();
      final locationPermission = await Permission.location.request();

      if (!scanPermission.isGranted || !connectPermission.isGranted || !locationPermission.isGranted) {
        AppLogger.warning('Bluetooth or location permissions not granted');
        _errorController.add(_languageManager.getLocalizedText('permissions_not_granted'));
        return;
      }

      // Turn on Bluetooth if it's off
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        AppLogger.bluetooth('Bluetooth is off, turning it on');
        await FlutterBluePlus.turnOn();
        // Wait a moment for Bluetooth to turn on
        await Future.delayed(const Duration(seconds: 1));
      }

      AppLogger.bluetooth('Starting Bluetooth scan for ALL devices');
      _isScanningController.add(true);
      _scanResultsController.add([]);

      // Cancel existing scan subscription
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      // Scan without service filter - show ALL Bluetooth devices
      await FlutterBluePlus.startScan(
        timeout: AppConstants.bluetoothScanTimeout,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        // Create a map to deduplicate by device ID (keep latest scan result)
        final deviceMap = <String, ScanResult>{};
        for (final result in results) {
          final deviceId = result.device.remoteId.toString();
          // Keep the result with the best name (prefer name from advertisement)
          final existing = deviceMap[deviceId];
          if (existing == null) {
            deviceMap[deviceId] = result;
          } else {
            // Prefer result with better name info
            final existingHasName = existing.device.platformName.isNotEmpty ||
                                   existing.advertisementData.advName.isNotEmpty;
            final newHasName = result.device.platformName.isNotEmpty ||
                              result.advertisementData.advName.isNotEmpty;
            if (!existingHasName && newHasName) {
              deviceMap[deviceId] = result;
            }
          }
        }

        // Convert to list and sort: named devices first
        final allDevices = deviceMap.values.toList();
        allDevices.sort((a, b) {
          // Helper to check if device has any name
          bool hasName(ScanResult r) =>
            r.device.platformName.isNotEmpty ||
            r.advertisementData.advName.isNotEmpty;

          if (hasName(a) && !hasName(b)) return -1;
          if (!hasName(a) && hasName(b)) return 1;
          return 0;
        });

        _scanResultsController.add(allDevices);
        AppLogger.bluetooth('Found ${allDevices.length} unique Bluetooth devices');
      });

      AppLogger.bluetooth('Scan started successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Scan failed', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('scan_failed') + e.toString());
    } finally {
      await Future.delayed(AppConstants.bluetoothScanTimeout);
      _isScanningController.add(false);
      await FlutterBluePlus.stopScan();
      AppLogger.bluetooth('Scan completed');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice?.remoteId == device.remoteId) {
      AppLogger.bluetooth('Already connected to device: ${device.remoteId}');
      return;
    }

    try {
      AppLogger.bluetooth('Connecting to device: ${device.remoteId}');
      _connectionStatusController.add(BluetoothConnectionStatus.connecting);

      await device.connect(autoConnect: false).timeout(
        AppConstants.bluetoothConnectionTimeout,
        onTimeout: () {
          AppLogger.warning('Connection timeout for device: ${device.remoteId}');
          throw TimeoutException('Connection timeout', AppConstants.bluetoothConnectionTimeout);
        },
      );

      _connectionStateSubscription = device.connectionState.listen((state) async {
        AppLogger.bluetooth('Connection state changed: $state for device: ${device.remoteId}');
        await _handleConnectionStateChange(state, device);
      });

      AppLogger.bluetooth('Connection initiated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to connect to device', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('connection_failed') + e.toString());
      _connectionStatusController.add(BluetoothConnectionStatus.error);
    }
  }

  Future<void> _handleConnectionStateChange(BluetoothConnectionState state, BluetoothDevice device) async {
    switch (state) {
      case BluetoothConnectionState.connected:
        _connectedDevice = device;
        _connectionStatusController.add(BluetoothConnectionStatus.connected);
        AppLogger.bluetooth('Connected to device: ${device.remoteId}');
        await _discoverServicesAndListen(device);
        break;
      case BluetoothConnectionState.disconnected:
        _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
        _connectedDevice = null;
        AppLogger.bluetooth('Disconnected from device: ${device.remoteId}');
        break;
      default:
        break;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        AppLogger.bluetooth('Disconnecting from device: ${_connectedDevice!.remoteId}');
        await _connectedDevice!.disconnect();
        _connectionStatusController.add(BluetoothConnectionStatus.disconnected);
        _connectedDevice = null;
        AppLogger.bluetooth('Disconnected successfully');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to disconnect', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('disconnect_failed') + e.toString());
    }
  }

  Future<void> _discoverServicesAndListen(BluetoothDevice device) async {
    try {
      AppLogger.bluetooth('Discovering services for device: ${device.remoteId}');
      await device.requestMtu(AppConstants.bluetoothMtuSize);

      final services = await device.discoverServices();
      AppLogger.bluetooth('Found ${services.length} services');

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            AppLogger.bluetooth('Found notify characteristic: ${characteristic.uuid}');
            await characteristic.setNotifyValue(true);

            // Cancel existing value subscription
            await _valueSubscription?.cancel();
            _valueSubscription = null;

            _valueSubscription = characteristic.onValueReceived.listen(
              (value) => _processReceivedData(value),
              onError: (error) {
                AppLogger.error('Error receiving data', error: error);
                _errorController.add("Error receiving data: $error");
              },
            );
          }
        }
      }

      AppLogger.bluetooth('Service discovery completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to discover services', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('services_discovery_failed') + e.toString());
    }
  }

  void _processReceivedData(List<int> value) {
    if (value.isEmpty) return;

    try {
      final message = utf8.decode(value);
      AppLogger.bluetooth('Received data: $message');

      // Translate message to system language if needed
      final translatedMessage = _translateMessage(message);

      _messageController.add(translatedMessage);

      // Detect gesture from original message (not translated)
      _detectGesture(message);

      _messageQueue.add(translatedMessage);

      if (_ttsStateController.value == TtsState.stopped) {
        _speakNextMessage();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to process received data', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('data_processing_failed') + e.toString());
    }
  }

  String _translateMessage(String message) {
    try {
      // Use translation language if set, otherwise use system language
      final targetLanguage = _translationLanguage.isNotEmpty
          ? _translationLanguage
          : _languageManager.getDeviceLanguage();

      AppLogger.info('Translating message: "$message" to language: $targetLanguage');

      // Define translations for common Arduino messages
      final Map<String, Map<String, String>> translations = {
        // English -> Arabic -> French
        'Stable - No Pain': {
          'en': 'Stable - No Pain',
          'ar': 'مستقر - لا يوجد ألم',
          'fr': 'Stable - Pas de douleur',
        },
        'Severe Pain': {
          'en': 'Severe Pain',
          'ar': 'ألم شديد',
          'fr': 'Douleur sévère',
        },
        'OK': {
          'en': 'OK',
          'ar': 'حسنا',
          'fr': 'OK',
        },
        'Need Help': {
          'en': 'Need Help',
          'ar': 'يحتاج مساعدة',
          'fr': 'Besoin d\'aide',
        },
        'Moderate Pain': {
          'en': 'Moderate Pain',
          'ar': 'ألم متوسط',
          'fr': 'Douleur modérée',
        },
        'High Pain': {
          'en': 'High Pain',
          'ar': 'ألم عالي',
          'fr': 'Douleur élevée',
        },
        'EMERGENCY': {
          'en': 'EMERGENCY',
          'ar': 'طوارئ',
          'fr': 'URGENCE',
        },
        'Minor Pain': {
          'en': 'Minor Pain',
          'ar': 'ألم خفيف',
          'fr': 'Douleur mineure',
        },
        'Discomfort': {
          'en': 'Discomfort',
          'ar': 'عدم الراحة',
          'fr': 'Inconfort',
        },
        'Confirm': {
          'en': 'Confirm',
          'ar': 'تأكيد',
          'fr': 'Confirmer',
        },
        'FIST_DETECTED': {
          'en': 'Fist Detected',
          'ar': 'تم اكتشاف قبضة اليد',
          'fr': 'Poing détecté',
        },
        'OPEN_PALM_DETECTED': {
          'en': 'Open Palm Detected',
          'ar': 'تم اكتشاف راحة اليد',
          'fr': 'Paume ouverte détectée',
        },
        'POINT_DETECTED': {
          'en': 'Point Detected',
          'ar': 'تم اكتشاف الإشارة',
          'fr': 'Pointage détecté',
        },
        'PEACE_DETECTED': {
          'en': 'Peace Sign Detected',
          'ar': 'تم اكتشاف علامة السلام',
          'fr': 'Signe de paix détecté',
        },
        'THUMBS_UP_DETECTED': {
          'en': 'Thumbs Up Detected',
          'ar': 'تم اكتشاف إبهام لأعلى',
          'fr': 'Pouces levés détectés',
        },
      };

      // Check if message exists in translations
      for (final originalMessage in translations.keys) {
        if (message.toUpperCase().contains(originalMessage.toUpperCase())) {
          final translationMap = translations[originalMessage]!;
          final translatedText = translationMap[targetLanguage] ?? translationMap['en']!;
          AppLogger.info('Translation found: "$originalMessage" -> "$translatedText"');
          return translatedText;
        }
      }

      // If no translation found, return original message
      AppLogger.info('No translation found for: "$message", returning original');
      return message;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to translate message', error: e, stackTrace: stackTrace);
      return message; // Return original message if translation fails
    }
  }

  void _detectGesture(String message) {
    try {
      // Check if message contains any gesture keywords
      final allGestures = GestureManager.getDefaultGestures();

      for (final gesture in allGestures) {
        // Check if message contains gesture detection keywords
        if (message.toUpperCase().contains(gesture.id.toUpperCase()) ||
            message.toUpperCase().contains('${gesture.name.toUpperCase()}_DETECTED') ||
            message.toUpperCase().contains(gesture.name.toUpperCase())) {

          AppLogger.bluetooth('Gesture detected: ${gesture.name}');
          _currentGesture = gesture;
          _gestureController.add(gesture);

          // Speak TTS message if available
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }

          return;
        }
      }

      // Check for medical pain assessment patterns
      if (message.toUpperCase().contains('STABLE - NO PAIN')) {
        final gesture = GestureManager.getGestureById('stable_no_pain');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('SEVERE PAIN')) {
        final gesture = GestureManager.getGestureById('severe_pain');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('OK')) {
        final gesture = GestureManager.getGestureById('ok');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('NEED HELP')) {
        final gesture = GestureManager.getGestureById('need_help');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('MODERATE PAIN')) {
        final gesture = GestureManager.getGestureById('moderate_pain');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('HIGH PAIN')) {
        final gesture = GestureManager.getGestureById('high_pain');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('EMERGENCY')) {
        final gesture = GestureManager.getGestureById('emergency');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('MINOR PAIN')) {
        final gesture = GestureManager.getGestureById('minor_pain');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('DISCOMFORT')) {
        final gesture = GestureManager.getGestureById('discomfort');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('CONFIRM')) {
        final gesture = GestureManager.getGestureById('confirm');
        if (gesture != null) {
          _currentGesture = gesture;
          _gestureController.add(gesture);
          if (gesture.ttsMessage != null) {
            _messageQueue.add(gesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      }

      // Check for common Arduino gesture patterns (fallback)
      if (message.toUpperCase().contains('FIST')) {
        final fistGesture = GestureManager.getGestureById('fist');
        if (fistGesture != null) {
          _currentGesture = fistGesture;
          _gestureController.add(fistGesture);
          if (fistGesture.ttsMessage != null) {
            _messageQueue.add(fistGesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('OPEN_PALM')) {
        final palmGesture = GestureManager.getGestureById('open_palm');
        if (palmGesture != null) {
          _currentGesture = palmGesture;
          _gestureController.add(palmGesture);
          if (palmGesture.ttsMessage != null) {
            _messageQueue.add(palmGesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('POINT')) {
        final pointGesture = GestureManager.getGestureById('point');
        if (pointGesture != null) {
          _currentGesture = pointGesture;
          _gestureController.add(pointGesture);
          if (pointGesture.ttsMessage != null) {
            _messageQueue.add(pointGesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('PEACE')) {
        final peaceGesture = GestureManager.getGestureById('peace');
        if (peaceGesture != null) {
          _currentGesture = peaceGesture;
          _gestureController.add(peaceGesture);
          if (peaceGesture.ttsMessage != null) {
            _messageQueue.add(peaceGesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      } else if (message.toUpperCase().contains('THUMBS_UP')) {
        final thumbsGesture = GestureManager.getGestureById('thumbs_up');
        if (thumbsGesture != null) {
          _currentGesture = thumbsGesture;
          _gestureController.add(thumbsGesture);
          if (thumbsGesture.ttsMessage != null) {
            _messageQueue.add(thumbsGesture.ttsMessage!);
            if (_ttsStateController.value == TtsState.stopped) {
              _speakNextMessage();
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to detect gesture', error: e, stackTrace: stackTrace);
    }
  }

  void _speakNextMessage() {
    if (_messageQueue.isEmpty || _ttsStateController.value != TtsState.stopped) {
      return;
    }

    final message = _messageQueue.removeAt(0);
    AppLogger.tts('Speaking message: $message');

    _ttsStateController.add(TtsState.playing);
    _currentSpokenTextController.add(message);

    _flutterTts.speak(message).catchError((error) {
      AppLogger.error('Failed to speak', error: error);
      _errorController.add(_languageManager.getLocalizedText('tts_speak_failed') + error.toString());
      _ttsStateController.add(TtsState.stopped);
      _currentSpokenTextController.add(null);
    });
  }

  Future<void> stopSpeaking() async {
    try {
      AppLogger.tts('Stopping speech');
      await _flutterTts.stop();
      _messageQueue.clear();
      _ttsStateController.add(TtsState.stopped);
      _currentSpokenTextController.add(null);
      AppLogger.tts('Speech stopped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop speaking', error: e, stackTrace: stackTrace);
      _errorController.add(_languageManager.getLocalizedText('tts_stop_failed') + e.toString());
    }
  }

  Future<void> startAdvertising() async {
    try {
      // Request advertise permission
      final advertiseStatus = await Permission.bluetoothAdvertise.request();
      if (!advertiseStatus.isGranted) {
        AppLogger.warning('Bluetooth advertise permission not granted');
        _errorController.add('Bluetooth advertise permission required');
        return;
      }

      AppLogger.bluetooth('Starting Bluetooth advertising');

      // flutter_blue_plus doesn't support advertising directly
      // This is a limitation of the current package
      _isAdvertisingController.add(true);
      AppLogger.bluetooth('Advertising mode enabled (limited by package)');
      _messageController.add('Advertising enabled - device may be discoverable');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start advertising', error: e, stackTrace: stackTrace);
      _errorController.add('Failed to start advertising: $e');
    }
  }

  Future<void> stopAdvertising() async {
    try {
      AppLogger.bluetooth('Stopping Bluetooth advertising');
      _isAdvertisingController.add(false);
      AppLogger.bluetooth('Bluetooth advertising stopped');
      _messageController.add('Advertising disabled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop advertising', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    AppLogger.info('Disposing BluetoothService');

    _adapterStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _valueSubscription?.cancel();
    _scanSubscription?.cancel();

    _isScanningController.close();
    _messageController.close();
    _connectionStatusController.close();
    _errorController.close();
    _scanResultsController.close();
    _ttsStateController.close();
    _currentSpokenTextController.close();
    _isAdvertisingController.close();
    _gestureController.close();

    _flutterTts.stop().catchError((e) => AppLogger.error('Error stopping TTS on dispose', error: e));

    super.dispose();
    AppLogger.info('BluetoothService disposed');
  }
}
