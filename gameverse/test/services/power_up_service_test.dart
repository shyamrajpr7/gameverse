import 'package:flutter_test/flutter_test.dart';
import 'package:gameverse/models/power_up.dart';
import 'package:gameverse/services/power_up_service.dart';

void main() {
  group('PowerUpService', () {
    late PowerUpService service;

    setUp(() {
      service = PowerUpService();
    });

    test('starts with no active power-ups', () {
      expect(service.activeTypes, isEmpty);
      for (final type in PowerUpType.values) {
        expect(service.isActive(type), isFalse);
        expect(service.remainingTime(type), equals(0.0));
        expect(service.progress(type), equals(0.0));
      }
    });

    test('activate makes power-up active', () {
      service.activate(PowerUpType.shield, 10);
      expect(service.isActive(PowerUpType.shield), isTrue);
      expect(service.activeTypes, contains(PowerUpType.shield));
    });

    test('activate stores correct duration', () {
      service.activate(PowerUpType.doublePoints, 8);
      expect(service.totalDuration(PowerUpType.doublePoints), closeTo(8, 0.001));
      expect(service.remainingTime(PowerUpType.doublePoints), closeTo(8, 0.001));
    });

    test('deactivate removes power-up', () {
      service.activate(PowerUpType.shield, 10);
      expect(service.isActive(PowerUpType.shield), isTrue);
      service.deactivate(PowerUpType.shield);
      expect(service.isActive(PowerUpType.shield), isFalse);
      expect(service.activeTypes, isEmpty);
    });

    test('update reduces remaining time', () {
      service.activate(PowerUpType.shield, 10);
      service.update(3);
      expect(service.remainingTime(PowerUpType.shield), closeTo(7, 0.001));
    });

    test('update expires power-up when time runs out', () {
      service.activate(PowerUpType.shield, 2);
      service.update(2.1);
      expect(service.isActive(PowerUpType.shield), isFalse);
      expect(service.activeTypes, isEmpty);
    });

    test('update handles multiple active power-ups', () {
      service.activate(PowerUpType.shield, 10);
      service.activate(PowerUpType.speedBoost, 5);

      service.update(3);

      expect(service.isActive(PowerUpType.shield), isTrue);
      expect(service.remainingTime(PowerUpType.shield), closeTo(7, 0.001));

      service.update(3);

      expect(service.isActive(PowerUpType.speedBoost), isFalse);
      expect(service.isActive(PowerUpType.shield), isTrue);
      expect(service.activeTypes, hasLength(1));
    });

    test('onPowerUpActivated callback fires', () {
      PowerUpType? activatedType;
      service.onPowerUpActivated = (type) => activatedType = type;

      service.activate(PowerUpType.extraLife, 0);
      expect(activatedType, equals(PowerUpType.extraLife));
    });

    test('onPowerUpExpired callback fires', () {
      PowerUpType? expiredType;
      service.onPowerUpExpired = (type) => expiredType = type;

      service.activate(PowerUpType.freeze, 1);
      service.update(1.1);
      expect(expiredType, equals(PowerUpType.freeze));
    });

    test('progress goes from 0 to partial, resets to 0 after expiry', () {
      service.activate(PowerUpType.magnet, 10);
      expect(service.progress(PowerUpType.magnet), closeTo(0, 0.001));

      service.update(5);
      expect(service.progress(PowerUpType.magnet), closeTo(0.5, 0.01));

      service.update(5); // expires
      expect(service.isActive(PowerUpType.magnet), isFalse);
      // After expiry, both maps are cleared so progress returns 0
      expect(service.progress(PowerUpType.magnet), closeTo(0.0, 0.001));
    });

    test('reset clears all power-ups', () {
      service.activate(PowerUpType.shield, 10);
      service.activate(PowerUpType.speedBoost, 5);
      expect(service.activeTypes, hasLength(2));

      service.reset();
      expect(service.activeTypes, isEmpty);
      for (final type in PowerUpType.values) {
        expect(service.isActive(type), isFalse);
      }
    });

    test('deactivate on inactive power-up does nothing', () {
      service.deactivate(PowerUpType.shield);
      expect(service.activeTypes, isEmpty);
    });

    test('update with zero dt does not change state', () {
      service.activate(PowerUpType.shield, 10);
      final before = service.remainingTime(PowerUpType.shield);
      service.update(0);
      expect(service.remainingTime(PowerUpType.shield), equals(before));
    });
  });
}
