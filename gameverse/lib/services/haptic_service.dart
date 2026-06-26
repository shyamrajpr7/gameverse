import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticService {
  static bool get _supported =>
      !kIsWeb && (_isAndroid || _isIOS || _isMacOS);

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  static void light() {
    if (!_supported) return;
    HapticFeedback.lightImpact();
  }

  static void medium() {
    if (!_supported) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!_supported) return;
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (!_supported) return;
    HapticFeedback.selectionClick();
  }
}
