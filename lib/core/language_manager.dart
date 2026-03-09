import 'dart:ui' as ui;

class LanguageManager {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'connecting': 'Connecting...',
      'error': 'Error',
      'settings': 'Settings',
      'disconnect': 'Disconnect',
      'scan': 'Scan',
      'scanning': 'Scanning...',
      'unknown': 'Unknown Device',
      'connect': 'Connect',
      'speaking': 'Speaking...',
      'waiting': 'Waiting for messages...',
      'stopSpeaking': 'Stop Speaking',
      'bluetooth_off': 'Bluetooth is off. Please turn it on.',
      'bluetooth_turning_off': 'Bluetooth is turning off...',
      'bluetooth_unauthorized': 'Bluetooth permission denied.',
      'bluetooth_unavailable': 'Bluetooth is not available on this device.',
      'bluetooth_not_ready': 'Bluetooth is not ready.',
      'scan_failed': 'Scan failed: ',
      'connection_failed': 'Failed to connect: ',
      'disconnect_failed': 'Failed to disconnect: ',
      'services_discovery_failed': 'Failed to discover services: ',
      'tts_init_failed': 'Failed to initialize TTS: ',
      'tts_language_failed': 'Failed to set TTS language: ',
      'tts_speak_failed': 'Failed to speak: ',
      'tts_stop_failed': 'Failed to stop speaking: ',
      'data_processing_failed': 'Failed to process received data: ',
      'permissions_not_granted': 'Bluetooth permissions not granted',
    },
    'ar': {
      'connected': 'متصل',
      'disconnected': 'غير متصل',
      'connecting': 'جاري الاتصال...',
      'error': 'خطأ',
      'settings': 'الإعدادات',
      'disconnect': 'قطع الاتصال',
      'scan': 'بحث',
      'scanning': 'جاري البحث...',
      'unknown': 'جهاز غير معروف',
      'connect': 'اتصال',
      'speaking': 'جاري التحدث...',
      'waiting': 'في انتظار الرسائل...',
      'stopSpeaking': 'إيقاف التحدث',
      'bluetooth_off': 'البلوتوث مغلق. يرجى تشغيله.',
      'bluetooth_turning_off': 'جاري إيقاف البلوتوث...',
      'bluetooth_unauthorized': 'تم رفض إذن البلوتوث.',
      'bluetooth_unavailable': 'البلوتوث غير متاح على هذا الجهاز.',
      'bluetooth_not_ready': 'البلوتوث غير جاهز.',
      'scan_failed': 'فشل البحث: ',
      'connection_failed': 'فشل الاتصال: ',
      'disconnect_failed': 'فشل قطع الاتصال: ',
      'services_discovery_failed': 'فشل اكتشاف الخدمات: ',
      'tts_init_failed': 'فشل تهيئة تحويل النص إلى كلام: ',
      'tts_language_failed': 'فشل تعيين لغة تحويل النص إلى كلام: ',
      'tts_speak_failed': 'فشل التحدث: ',
      'tts_stop_failed': 'فشل إيقاف التحدث: ',
      'data_processing_failed': 'فشل معالجة البيانات المستلمة: ',
      'permissions_not_granted': 'لم يتم منح أذونات البلوتوث',
    },
    'fr': {
      'connected': 'Connecté',
      'disconnected': 'Déconnecté',
      'connecting': 'Connexion...',
      'error': 'Erreur',
      'settings': 'Paramètres',
      'disconnect': 'Déconnecter',
      'scan': 'Rechercher',
      'scanning': 'Recherche...',
      'unknown': 'Appareil inconnu',
      'connect': 'Connecter',
      'speaking': 'Parole...',
      'waiting': 'En attente de messages...',
      'stopSpeaking': 'Arrêter de parler',
      'bluetooth_off': 'Le Bluetooth est éteint. Veuillez l\'activer.',
      'bluetooth_turning_off': 'Le Bluetooth s\'éteint...',
      'bluetooth_unauthorized': 'Autorisation Bluetooth refusée.',
      'bluetooth_unavailable': 'Le Bluetooth n\'est pas disponible sur cet appareil.',
      'bluetooth_not_ready': 'Le Bluetooth n\'est pas prêt.',
      'scan_failed': 'Échec de la recherche: ',
      'connection_failed': 'Échec de la connexion: ',
      'disconnect_failed': 'Échec de la déconnexion: ',
      'services_discovery_failed': 'Échec de la découverte des services: ',
      'tts_init_failed': 'Échec de l\'initialisation TTS: ',
      'tts_language_failed': 'Échec de la définition de la langue TTS: ',
      'tts_speak_failed': 'Échec de la parole: ',
      'tts_stop_failed': 'Échec de l\'arrêt de la parole: ',
      'data_processing_failed': 'Échec du traitement des données reçues: ',
      'permissions_not_granted': 'Autorisations Bluetooth non accordées',
    },
  };

  String getDeviceLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    return locale.languageCode;
  }

  String getLocalizedText(String key) {
    final deviceLanguage = getDeviceLanguage();
    final languageMap = _localizedStrings[deviceLanguage] ?? _localizedStrings['en']!;
    return languageMap[key] ?? key;
  }
}
