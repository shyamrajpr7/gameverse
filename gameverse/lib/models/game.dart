import 'package:flutter/material.dart';

class GameCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const GameCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Game {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final Color color;
  final IconData icon;
  final int playerCount;
  final int visits;
  final double rating;
  final int ratingCount;
  final List<String> screenshots;
  final int xpReward;

  const Game({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.color,
    required this.icon,
    this.playerCount = 0,
    this.visits = 0,
    this.rating = 4.0,
    this.ratingCount = 0,
    this.screenshots = const [],
    this.xpReward = 50,
  });
}

const List<GameCategory> categories = [
  GameCategory(id: 'action', name: 'Action', icon: Icons.flash_on, color: Color(0xFFFF6B6B)),
  GameCategory(id: 'adventure', name: 'Adventure', icon: Icons.explore, color: Color(0xFF4ECDC4)),
  GameCategory(id: 'racing', name: 'Racing', icon: Icons.speed, color: Color(0xFFFFD93D)),
  GameCategory(id: 'simulation', name: 'Simulation', icon: Icons.settings, color: Color(0xFF6C5CE7)),
  GameCategory(id: 'puzzle', name: 'Puzzle', icon: Icons.extension, color: Color(0xFFA8E6CF)),
  GameCategory(id: 'strategy', name: 'Strategy', icon: Icons.track_changes, color: Color(0xFFFF8A5C)),
];

const List<Game> allGames = [
  Game(
    id: 'tower_defense',
    title: 'Tower Defense',
    description: 'Build powerful towers and defend your base against waves of enemies. Strategically place your defenses and upgrade them to survive increasingly difficult challenges.',
    categoryId: 'strategy',
    color: Color(0xFF6C5CE7),
    icon: Icons.shield,
    playerCount: 2847,
    visits: 89234,
    rating: 4.7,
    ratingCount: 1234,
    xpReward: 75,
  ),
  Game(
    id: 'racing_rivals',
    title: 'Racing Rivals',
    description: 'Race against friends and rivals on thrilling tracks. Customize your vehicles, master drift mechanics, and become the champion of the racing world.',
    categoryId: 'racing',
    color: Color(0xFFFFD93D),
    icon: Icons.directions_car,
    playerCount: 4521,
    visits: 156732,
    rating: 4.5,
    ratingCount: 2341,
    xpReward: 60,
  ),
  Game(
    id: 'build_world',
    title: 'Build World',
    description: 'Unleash your creativity in an open sandbox world. Build anything you can imagine with unlimited blocks, tools, and sharing features.',
    categoryId: 'simulation',
    color: Color(0xFF4ECDC4),
    icon: Icons.construction,
    playerCount: 6789,
    visits: 245678,
    rating: 4.8,
    ratingCount: 3456,
    xpReward: 100,
  ),
  Game(
    id: 'zombie_survival',
    title: 'Zombie Survival',
    description: 'Fight for survival in a post-apocalyptic world infested with zombies. Collect weapons, build shelters, and survive the night.',
    categoryId: 'action',
    color: Color(0xFFFF6B6B),
    icon: Icons.dangerous,
    playerCount: 5623,
    visits: 198456,
    rating: 4.6,
    ratingCount: 2876,
    xpReward: 80,
  ),
  Game(
    id: 'pixel_battle',
    title: 'Pixel Battle',
    description: 'Epic pixel-art battle royale with unique characters and weapons. Jump in, loot up, and be the last one standing.',
    categoryId: 'action',
    color: Color(0xFFFF8A5C),
    icon: Icons.sports_kabaddi,
    playerCount: 8901,
    visits: 312567,
    rating: 4.4,
    ratingCount: 4567,
    xpReward: 70,
  ),
  Game(
    id: 'sky_jumper',
    title: 'Sky Jumper',
    description: 'Jump from cloud to cloud in this addictive platformer. Collect stars, avoid obstacles, and reach new heights.',
    categoryId: 'adventure',
    color: Color(0xFF45B7D1),
    icon: Icons.cloud,
    playerCount: 3456,
    visits: 123456,
    rating: 4.3,
    ratingCount: 1876,
    xpReward: 45,
  ),
  Game(
    id: 'ocean_explorer',
    title: 'Ocean Explorer',
    description: 'Dive deep into the ocean and discover hidden treasures, exotic marine life, and ancient ruins. The depths hold many secrets.',
    categoryId: 'adventure',
    color: Color(0xFF1A8FE3),
    icon: Icons.sailing,
    playerCount: 2345,
    visits: 98765,
    rating: 4.6,
    ratingCount: 1654,
    xpReward: 65,
  ),
  Game(
    id: 'space_wars',
    title: 'Space Wars',
    description: 'Command your starship in intense space battles. Build your fleet, conquer planets, and explore the galaxy.',
    categoryId: 'strategy',
    color: Color(0xFF2D3436),
    icon: Icons.rocket_launch,
    playerCount: 4321,
    visits: 145678,
    rating: 4.5,
    ratingCount: 2123,
    xpReward: 90,
  ),
  Game(
    id: 'farm_life',
    title: 'Farm Life',
    description: 'Experience peaceful farming life. Grow crops, raise animals, trade with neighbors, and build your dream farm.',
    categoryId: 'simulation',
    color: Color(0xFF27AE60),
    icon: Icons.agriculture,
    playerCount: 5678,
    visits: 189012,
    rating: 4.2,
    ratingCount: 3123,
    xpReward: 40,
  ),
  Game(
    id: 'puzzle_quest',
    title: 'Puzzle Quest',
    description: 'Challenge your mind with hundreds of puzzles. Match colors, solve riddles, and unlock new levels in this addictive brain teaser.',
    categoryId: 'puzzle',
    color: Color(0xFFE17055),
    icon: Icons.psychology,
    playerCount: 3890,
    visits: 134567,
    rating: 4.4,
    ratingCount: 2567,
    xpReward: 55,
  ),
  Game(
    id: 'classic_snake',
    title: 'Classic Snake',
    description: 'Guide the snake to eat food and grow longer without crashing into walls or yourself. How long can you survive?',
    categoryId: 'puzzle',
    color: Color(0xFF00B894),
    icon: Icons.catching_pokemon,
    playerCount: 6543,
    visits: 234567,
    rating: 4.6,
    ratingCount: 3123,
    xpReward: 60,
  ),
  Game(
    id: 'brick_breaker',
    title: 'Brick Breaker',
    description: 'Break through colorful bricks with a bouncing ball and paddle. How many rows can you clear before losing all your lives?',
    categoryId: 'action',
    color: Color(0xFFE53935),
    icon: Icons.grid_on,
    playerCount: 1245,
    visits: 45678,
    rating: 4.3,
    ratingCount: 567,
    xpReward: 50,
  ),
];
