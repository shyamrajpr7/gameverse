import 'package:flutter/material.dart';

enum PowerUpType { shield, speedBoost, doublePoints, magnet, freeze, extraLife }

class PowerUp {
  final PowerUpType type;
  final int durationSeconds;
  final IconData icon;
  final Color color;
  final String name;
  final String description;

  const PowerUp({
    required this.type,
    required this.durationSeconds,
    required this.icon,
    required this.color,
    required this.name,
    required this.description,
  });
}

const List<PowerUp> allPowerUps = [
  PowerUp(
    type: PowerUpType.shield,
    durationSeconds: 10,
    icon: Icons.shield,
    color: Color(0xFF4FC3F7),
    name: 'Shield',
    description: 'Survive one collision',
  ),
  PowerUp(
    type: PowerUpType.speedBoost,
    durationSeconds: 5,
    icon: Icons.bolt,
    color: Color(0xFFFF9800),
    name: 'Speed Boost',
    description: 'Move 50% faster',
  ),
  PowerUp(
    type: PowerUpType.doublePoints,
    durationSeconds: 8,
    icon: Icons.stars,
    color: Color(0xFFFFD700),
    name: 'Double Points',
    description: 'Score x2 for everything',
  ),
  PowerUp(
    type: PowerUpType.magnet,
    durationSeconds: 6,
    icon: Icons.explore,
    color: Color(0xFF9C27B0),
    name: 'Magnet',
    description: 'Attract nearby items',
  ),
  PowerUp(
    type: PowerUpType.freeze,
    durationSeconds: 4,
    icon: Icons.ac_unit,
    color: Color(0xFF00BCD4),
    name: 'Freeze',
    description: 'Slow down enemies',
  ),
  PowerUp(
    type: PowerUpType.extraLife,
    durationSeconds: 0,
    icon: Icons.favorite,
    color: Color(0xFFE53935),
    name: 'Extra Life',
    description: 'Gain one extra life',
  ),
];

PowerUp powerUpForType(PowerUpType type) {
  return allPowerUps.firstWhere((p) => p.type == type);
}
