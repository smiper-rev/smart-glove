class HandGesture {
  final String id;
  final String name;
  final String description;
  final String arduinoCode;
  final String? ttsMessage;
  final String? iconPath;

  HandGesture({
    required this.id,
    required this.name,
    required this.description,
    required this.arduinoCode,
    this.ttsMessage,
    this.iconPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'arduinoCode': arduinoCode,
      'ttsMessage': ttsMessage,
      'iconPath': iconPath,
    };
  }

  factory HandGesture.fromJson(Map<String, dynamic> json) {
    return HandGesture(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      arduinoCode: json['arduinoCode'],
      ttsMessage: json['ttsMessage'],
      iconPath: json['iconPath'],
    );
  }
}

class GestureManager {
  static final List<HandGesture> _defaultGestures = [
    // Basic Gestures
    HandGesture(
      id: 'fist',
      name: 'Fist',
      description: 'Closed hand gesture',
      arduinoCode: '''
// Arduino code for Fist gesture
int flexSensor1 = analogRead(A0);
int flexSensor2 = analogRead(A1);
int flexSensor3 = analogRead(A2);

if (flexSensor1 > 800 && flexSensor2 > 800 && flexSensor3 > 800) {
  Serial.println("FIST_DETECTED");
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Fist gesture detected',
      iconPath: 'assets/icons/fist.png',
    ),
    HandGesture(
      id: 'open_palm',
      name: 'Open Palm',
      description: 'Open hand gesture',
      arduinoCode: '''
// Arduino code for Open Palm gesture
int flexSensor1 = analogRead(A0);
int flexSensor2 = analogRead(A1);
int flexSensor3 = analogRead(A2);

if (flexSensor1 < 300 && flexSensor2 < 300 && flexSensor3 < 300) {
  Serial.println("OPEN_PALM_DETECTED");
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Open palm gesture detected',
      iconPath: 'assets/icons/open_palm.png',
    ),

    // Medical Pain Assessment Gestures
    HandGesture(
      id: 'stable_no_pain',
      name: 'Stable - No Pain',
      description: 'All fingers extended - no pain detected',
      arduinoCode: '''
// ===== منطق الإيماءات الطبية =====
// t = thumb, i = index, m = middle, r = ring, p = pinky
// true = bent, false = extended

bool t = false; // thumb extended
bool i = false; // index extended
bool m = false; // middle extended
bool r = false; // ring extended
bool p = false; // pinky extended

if (!t && !i && !m && !r && !p) {
  Serial.println("Stable - No Pain");          // 1
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Stable - No pain detected',
      iconPath: 'assets/icons/stable.png',
    ),
    HandGesture(
      id: 'severe_pain',
      name: 'Severe Pain',
      description: 'All fingers bent - severe pain',
      arduinoCode: '''
// Severe Pain - all fingers bent
bool t = true;  // thumb bent
bool i = true;  // index bent
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (t && i && m && r && p) {
  Serial.println("Severe Pain");               // 2
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Severe pain detected - immediate attention needed',
      iconPath: 'assets/icons/severe_pain.png',
    ),
    HandGesture(
      id: 'ok',
      name: 'OK',
      description: 'Thumb extended, others bent',
      arduinoCode: '''
// OK gesture
bool t = false; // thumb extended
bool i = true;  // index bent
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (!t && i && m && r && p) {
  Serial.println("OK");                        // 3
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'OK - patient is stable',
      iconPath: 'assets/icons/ok.png',
    ),
    HandGesture(
      id: 'need_help',
      name: 'Need Help',
      description: 'Thumb bent, index extended, others bent',
      arduinoCode: '''
// Need Help gesture
bool t = true;  // thumb bent
bool i = false; // index extended
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (t && !i && m && r && p) {
  Serial.println("Need Help");                 // 4
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Need help - assistance required',
      iconPath: 'assets/icons/need_help.png',
    ),
    HandGesture(
      id: 'moderate_pain',
      name: 'Moderate Pain',
      description: 'Thumb bent, index extended, middle extended, others bent',
      arduinoCode: '''
// Moderate Pain gesture
bool t = true;  // thumb bent
bool i = false; // index extended
bool m = false; // middle extended
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (t && !i && !m && r && p) {
  Serial.println("Moderate Pain");             // 5
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Moderate pain detected',
      iconPath: 'assets/icons/moderate_pain.png',
    ),
    HandGesture(
      id: 'high_pain',
      name: 'High Pain',
      description: 'Thumb, index, middle extended, ring, pinky bent',
      arduinoCode: '''
// High Pain gesture
bool t = false; // thumb extended
bool i = false; // index extended
bool m = false; // middle extended
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (!t && !i && !m && r && p) {
  Serial.println("High Pain");                 // 6
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'High pain detected - medical attention needed',
      iconPath: 'assets/icons/high_pain.png',
    ),
    HandGesture(
      id: 'emergency',
      name: 'EMERGENCY',
      description: 'Thumb, middle, ring, pinky bent, index extended',
      arduinoCode: '''
// EMERGENCY gesture
bool t = false; // thumb extended
bool i = false; // index extended
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = true;  // pinky bent

if (!t && i && m && r && !p) {
  Serial.println("EMERGENCY");                 // 7
  digitalWrite(LED_PIN, HIGH);
  // Activate emergency buzzer
  digitalWrite(BUZZER_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);
}
''',
      ttsMessage: 'EMERGENCY - immediate medical attention required',
      iconPath: 'assets/icons/emergency.png',
    ),
    HandGesture(
      id: 'minor_pain',
      name: 'Minor Pain',
      description: 'All fingers extended except pinky',
      arduinoCode: '''
// Minor Pain gesture
bool t = false; // thumb extended
bool i = false; // index extended
bool m = false; // middle extended
bool r = false; // ring extended
bool p = true;  // pinky bent

if (t && i && m && r && !p) {
  Serial.println("Minor Pain");                // 8
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Minor pain detected',
      iconPath: 'assets/icons/minor_pain.png',
    ),
    HandGesture(
      id: 'discomfort',
      name: 'Discomfort',
      description: 'Thumb bent, index extended, middle, ring bent, pinky extended',
      arduinoCode: '''
// Discomfort gesture
bool t = true;  // thumb bent
bool i = false; // index extended
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = false; // pinky extended

if (t && !i && m && r && !p) {
  Serial.println("Discomfort");                // 9
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Discomfort detected',
      iconPath: 'assets/icons/discomfort.png',
    ),
    HandGesture(
      id: 'confirm',
      name: 'Confirm',
      description: 'Thumb, index, middle bent, ring, pinky extended',
      arduinoCode: '''
// Confirm gesture
bool t = true;  // thumb bent
bool i = true;  // index bent
bool m = true;  // middle bent
bool r = true;  // ring bent
bool p = false; // pinky extended

if (!t && !i && m && r && p) {
  Serial.println("Confirm");                  // 10
  digitalWrite(LED_PIN, HIGH);
} else {
  digitalWrite(LED_PIN, LOW);
}
''',
      ttsMessage: 'Confirmed',
      iconPath: 'assets/icons/confirm.png',
    ),
  ];

  static List<HandGesture> getDefaultGestures() {
    return List.from(_defaultGestures);
  }

  static HandGesture? getGestureById(String id) {
    try {
      return _defaultGestures.firstWhere((gesture) => gesture.id == id);
    } catch (e) {
      return null;
    }
  }

  static HandGesture? getGestureByArduinoCode(String code) {
    try {
      return _defaultGestures.firstWhere((gesture) =>
        gesture.arduinoCode.contains(code.split('\n')[0].trim()));
    } catch (e) {
      return null;
    }
  }

  static void addCustomGesture(HandGesture gesture) {
    _defaultGestures.add(gesture);
  }

  static void removeGesture(String id) {
    _defaultGestures.removeWhere((gesture) => gesture.id == id);
  }
}
