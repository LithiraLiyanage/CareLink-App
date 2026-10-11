import 'package:flutter/foundation.dart';

@immutable
class AccessibilityPreferences {
  final bool largerText;
  final bool highContrast;
  final bool reduceMotion;

  const AccessibilityPreferences({
    this.largerText = false,
    this.highContrast = false,
    this.reduceMotion = false,
  });
}

class AccessibilityController extends ValueNotifier<AccessibilityPreferences> {
  AccessibilityController._() : super(const AccessibilityPreferences());

  static final AccessibilityController instance = AccessibilityController._();

  void apply({
    required bool largerText,
    required bool highContrast,
    required bool reduceMotion,
  }) {
    value = AccessibilityPreferences(
      largerText: largerText,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
    );
  }

  void applyFromMap(Map<String, dynamic>? settings) {
    apply(
      largerText: settings?['largerText'] == true,
      highContrast: settings?['highContrast'] == true,
      reduceMotion: settings?['reduceMotion'] == true,
    );
  }

  void reset() {
    value = const AccessibilityPreferences();
  }
}
