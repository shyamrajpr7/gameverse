import '../models/power_up.dart';

class PowerUpService {
  final Map<PowerUpType, double> _remainingTime = {};
  final Map<PowerUpType, double> _totalDuration = {};

  void Function(PowerUpType)? onPowerUpExpired;
  void Function(PowerUpType)? onPowerUpActivated;

  void activate(PowerUpType type, double durationSeconds) {
    _remainingTime[type] = durationSeconds;
    _totalDuration[type] = durationSeconds;
    onPowerUpActivated?.call(type);
  }

  bool isActive(PowerUpType type) =>
      _remainingTime.containsKey(type) && _remainingTime[type]! > 0;

  double remainingTime(PowerUpType type) => _remainingTime[type] ?? 0;

  double totalDuration(PowerUpType type) => _totalDuration[type] ?? 1;

  double progress(PowerUpType type) {
    final total = _totalDuration[type];
    final remaining = _remainingTime[type];
    if (total == null || remaining == null || total <= 0) return 0;
    return (total - remaining) / total;
  }

  void update(double dt) {
    for (final type in _remainingTime.keys.toList()) {
      _remainingTime[type] = _remainingTime[type]! - dt;
      if (_remainingTime[type]! <= 0) {
        _remainingTime.remove(type);
        _totalDuration.remove(type);
        onPowerUpExpired?.call(type);
      }
    }
  }

  void deactivate(PowerUpType type) {
    _remainingTime.remove(type);
    _totalDuration.remove(type);
    onPowerUpExpired?.call(type);
  }

  void reset() {
    _remainingTime.clear();
    _totalDuration.clear();
  }

  List<PowerUpType> get activeTypes => _remainingTime.keys.toList();
}
