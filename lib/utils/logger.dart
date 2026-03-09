import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'SmartGlove';
  
  static void debug(String message, {String? tag}) {
    developer.log('🔍 $message', name: tag ?? _tag, level: 500);
  }
  
  static void info(String message, {String? tag}) {
    developer.log('ℹ️ $message', name: tag ?? _tag, level: 800);
  }
  
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log('⚠️ $message', 
      name: tag ?? _tag, 
      level: 900, 
      error: error, 
      stackTrace: stackTrace
    );
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log('❌ $message', 
      name: tag ?? _tag, 
      level: 1000, 
      error: error, 
      stackTrace: stackTrace
    );
  }
  
  static void bluetooth(String message) {
    debug('🔵 $message', tag: 'Bluetooth');
  }
  
  static void tts(String message) {
    debug('🔊 $message', tag: 'TTS');
  }
  
  static void ui(String message) {
    debug('🖼️ $message', tag: 'UI');
  }
}
