import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const GameBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  bool isUnlocked(List<String> unlockedIds) => unlockedIds.contains(id);
}

const List<GameBadge> allBadges = [
  GameBadge(id: 'first_game', title: 'First Play', description: 'Play your first game', icon: Icons.play_circle),
  GameBadge(id: 'five_games', title: 'Gamer', description: 'Play 5 different games', icon: Icons.games),
  GameBadge(id: 'all_games', title: 'Game Master', description: 'Play every game', icon: Icons.workspace_premium),
  GameBadge(id: 'high_score', title: 'High Scorer', description: 'Score 1000+ in any game', icon: Icons.emoji_events),
  GameBadge(id: 'level_5', title: 'Rising Star', description: 'Reach level 5', icon: Icons.trending_up),
  GameBadge(id: 'level_10', title: 'Game Legend', description: 'Reach level 10', icon: Icons.military_tech),
];

class GameService {
  static final GameService _instance = GameService._();
  factory GameService() => _instance;
  GameService._();

  static const String _xpKey = 'gameverse_xp';
  static const String _badgesKey = 'gameverse_badges';
  static const String _highScoresKey = 'gameverse_highscores';
  static const String _playedGamesKey = 'gameverse_played';
  static const String _onboardingKey = 'gameverse_onboarding_seen';

  int currentXP = 0;
  List<String> unlockedBadges = [];
  Map<String, int> highScores = {};
  List<String> playedGames = [];
  bool hasSeenOnboarding = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currentXP = prefs.getInt(_xpKey) ?? 0;
    final badgesData = prefs.getString(_badgesKey);
    if (badgesData != null) {
      unlockedBadges = List<String>.from(jsonDecode(badgesData) as List);
    }
    final scoresData = prefs.getString(_highScoresKey);
    if (scoresData != null) {
      final decoded = jsonDecode(scoresData) as Map<String, dynamic>;
      highScores = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    final playedData = prefs.getString(_playedGamesKey);
    if (playedData != null) {
      playedGames = List<String>.from(jsonDecode(playedData) as List);
    }
    hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, currentXP);
    await prefs.setString(_badgesKey, jsonEncode(unlockedBadges));
    await prefs.setString(_highScoresKey, jsonEncode(highScores));
    await prefs.setString(_playedGamesKey, jsonEncode(playedGames));
    await prefs.setBool(_onboardingKey, hasSeenOnboarding);
  }

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return 100 * level * (level - 1);
  }

  static int getLevel(int xp) {
    int level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  static double getProgress(int xp) {
    final level = getLevel(xp);
    final current = xpForLevel(level);
    final next = xpForLevel(level + 1);
    if (next <= current) return 1.0;
    return (xp - current) / (next - current);
  }

  String? _checkBadges() {
    if (!unlockedBadges.contains('first_game') && playedGames.isNotEmpty) return 'first_game';
    if (!unlockedBadges.contains('five_games') && playedGames.length >= 5) return 'five_games';
    if (!unlockedBadges.contains('all_games') && playedGames.length >= 10) return 'all_games';
    final level = getLevel(currentXP);
    if (!unlockedBadges.contains('level_5') && level >= 5) return 'level_5';
    if (!unlockedBadges.contains('level_10') && level >= 10) return 'level_10';
    return null;
  }

  Future<String?> addXP(int amount) async {
    currentXP += amount;
    await _save();
    final badge = _checkBadges();
    if (badge != null && !unlockedBadges.contains(badge)) {
      unlockedBadges.add(badge);
      await _save();
      return badge;
    }
    return null;
  }

  Future<void> recordGamePlayed(String gameId) async {
    if (!playedGames.contains(gameId)) {
      playedGames.add(gameId);
      await _save();
    }
  }

  Future<void> updateHighScore(String gameId, int score) async {
    if (!highScores.containsKey(gameId) || score > highScores[gameId]!) {
      highScores[gameId] = score;
      await _save();
      if (score >= 1000 && !unlockedBadges.contains('high_score')) {
        unlockedBadges.add('high_score');
        await _save();
      }
    }
  }

  int getHighScore(String gameId) => highScores[gameId] ?? 0;
  bool hasPlayed(String gameId) => playedGames.contains(gameId);

  Future<void> markOnboardingSeen() async {
    hasSeenOnboarding = true;
    await _save();
  }
}
