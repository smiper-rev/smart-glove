# Smart Glove Flutter App

A comprehensive Flutter application for connecting and interacting with Smart Glove devices via Bluetooth. The app features real-time data reception, text-to-speech functionality, and multi-language support.

## Features

- **Bluetooth Connectivity**: Scan, connect, and communicate with Smart Glove devices
- **Real-time Data**: Receive and process data from connected devices
- **Text-to-Speech**: Convert received messages to speech using Flutter TTS
- **Multi-language Support**: Support for English, Arabic, and French
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Robust Error Handling**: Comprehensive error handling and logging
- **Responsive UI**: Clean, modern interface with Material Design 3

## Project Structure

```
lib/
├── core/
│   ├── constants.dart          # App constants and enums
│   └── language_manager.dart   # Multi-language support
├── services/
│   └── bluetooth_service.dart   # Bluetooth and TTS service
├── screens/
│   ├── home_screen.dart        # Main application screen
│   └── settings_screen.dart    # Settings and preferences
├── widgets/
│   ├── device_list.dart        # Bluetooth device list widget
│   ├── intro_screen.dart       # Introduction/onboarding widget
│   ├── signal_strength_icon.dart # Signal strength indicator
│   └── tts_player.dart         # Text-to-speech player widget
├── theme/
│   └── app_theme.dart          # App theme configuration
├── utils/
│   └── logger.dart             # Logging utility
└── main.dart                   # App entry point
```

## Key Improvements

### 1. **Robust Error Handling**
- Comprehensive try-catch blocks around all async operations
- Detailed error logging with stack traces
- User-friendly error messages with localization

### 2. **Improved Architecture**
- Separation of concerns with dedicated service layer
- Modular UI components for better maintainability
- Provider pattern for state management

### 3. **Enhanced Logging**
- Structured logging with different levels (debug, info, warning, error)
- Category-specific logging (Bluetooth, TTS, UI)
- Detailed error reporting for debugging

### 4. **Memory Management**
- Proper stream subscription management
- Resource cleanup in dispose methods
- Prevention of memory leaks

### 5. **User Experience**
- Real-time connection status updates
- Visual feedback for all operations
- Intuitive navigation and settings

## Dependencies

- `flutter_blue_plus`: Bluetooth connectivity
- `flutter_tts`: Text-to-speech functionality
- `permission_handler`: Runtime permissions
- `provider`: State management
- `rxdart`: Reactive programming utilities

## Getting Started

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Platform-specific setup**:
   - **Android**: Add Bluetooth permissions to `android/app/src/main/AndroidManifest.xml`
   - **iOS**: Add Bluetooth usage descriptions to `ios/Runner/Info.plist`

## Permissions

### Android
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
```

### iOS
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to Smart Glove devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to Smart Glove devices</string>
```

## Usage

1. **Enable Bluetooth** on your device
2. **Grant permissions** when prompted
3. **Tap the scan button** to discover nearby Smart Glove devices
4. **Select a device** from the list to connect
5. **View real-time data** and listen to spoken messages
6. **Customize settings** like TTS language in the settings screen

## Logging

The app includes comprehensive logging that can be viewed in the debug console. Logs are categorized by:
- 🔍 Debug: General debugging information
- ℹ️ Info: General information
- ⚠️ Warning: Warning messages
- ❌ Error: Error messages with stack traces
- 🔵 Bluetooth: Bluetooth-specific logs
- 🔊 TTS: Text-to-speech logs
- 🖼️ UI: UI-related logs

## Contributing

When contributing to this project:
1. Follow the existing code structure and patterns
2. Add appropriate logging for new features
3. Include error handling for all async operations
4. Update documentation as needed
5. Test on both Android and iOS platforms

## License

This project is proprietary and confidential.
