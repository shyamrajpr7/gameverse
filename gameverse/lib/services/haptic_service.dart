import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticService {
  static final HapticService _instance = HapticService._();
  factory HapticService() => _instance;
  HapticService._();

  bool _enabled = true;

  bool get isHapticsEnabled => _enabled;

  void setHapticsEnabled(bool v) => _enabled = v;

  void toggleHaptics() => _enabled = !_enabled;

  static bool get _supported =>
      !kIsWeb && (_isAndroid || _isIOS || _isMacOS);

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  static void light() {
    if (!_supported || !_instance._enabled) return;
    HapticFeedback.lightImpact();
  }

  static void medium() {
    if (!_supported || !_instance._enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!_supported || !_instance._enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (!_supported || !_instance._enabled) return;
    HapticFeedback.selectionClick();
  }
}
