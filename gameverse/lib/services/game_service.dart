import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game.dart';

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
  static const String _dailyDateKey = 'gameverse_daily_date';
  static const String _usernameKey = 'gameverse_username';
  static const String _avatarIndexKey = 'gameverse_avatar';
  static const String _totalPlaysKey = 'gameverse_total_plays';
  static const String _currentStreakKey = 'gameverse_streak';
  static const String _bestStreakKey = 'gameverse_best_streak';
  static const String _lastPlayedDateKey = 'gameverse_last_played';

  int currentXP = 0;
  List<String> unlockedBadges = [];
  Map<String, int> highScores = {};
  List<String> playedGames = [];
  bool hasSeenOnboarding = false;
  String? _lastDailyDate;

  String username = 'Player';
  int avatarIndex = 0;

  int totalGamesPlayed = 0;
  int currentStreak = 0;
  int bestStreak = 0;
  String? _lastPlayedDate;

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
    _lastDailyDate = prefs.getString(_dailyDateKey);
    username = prefs.getString(_usernameKey) ?? 'Player';
    avatarIndex = prefs.getInt(_avatarIndexKey) ?? 0;
    totalGamesPlayed = prefs.getInt(_totalPlaysKey) ?? 0;
    currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    _lastPlayedDate = prefs.getString(_lastPlayedDateKey);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, currentXP);
    await prefs.setString(_badgesKey, jsonEncode(unlockedBadges));
    await prefs.setString(_highScoresKey, jsonEncode(highScores));
    await prefs.setString(_playedGamesKey, jsonEncode(playedGames));
    await prefs.setBool(_onboardingKey, hasSeenOnboarding);
    await prefs.setString(_dailyDateKey, _lastDailyDate ?? '');
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_avatarIndexKey, avatarIndex);
    await prefs.setInt(_totalPlaysKey, totalGamesPlayed);
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setInt(_bestStreakKey, bestStreak);
    await prefs.setString(_lastPlayedDateKey, _lastPlayedDate ?? '');
  }

  Future<void> updateUsername(String name) async {
    username = name;
    await _save();
  }

  Future<void> updateAvatarIndex(int index) async {
    avatarIndex = index;
    await _save();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Game getDailyChallenge() {
    final hash = _todayString().hashCode;
    return allGames[hash.abs() % allGames.length];
  }

  bool get isDailyCompleted {
    return _lastDailyDate == _todayString();
  }

  int dailyMultiplier(String gameId) {
    if (isDailyCompleted) return 1;
    return gameId == getDailyChallenge().id ? 2 : 1;
  }

  Future<void> markDailyCompleted() async {
    _lastDailyDate = _todayString();
    await _save();
  }

  IconData get avatarIcon => avatarIcons[avatarIndex];

  static const List<IconData> avatarIcons = [
    Icons.face,
    Icons.pets,
    Icons.rocket_launch,
    Icons.sports_esports,
    Icons.auto_awesome,
    Icons.bolt,
    Icons.diamond,
    Icons.local_fire_department,
    Icons.psychology,
    Icons.stars,
    Icons.shield,
    Icons.emoji_nature,
  ];

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
    totalGamesPlayed++;
    if (!playedGames.contains(gameId)) {
      playedGames.add(gameId);
    }
    _updateStreak();
    await _save();
  }

  void _updateStreak() {
    final today = _todayString();
    if (_lastPlayedDate == null) {
      currentStreak = 1;
    } else if (_lastPlayedDate == today) {
      return;
    } else {
      final last = DateTime.parse(_lastPlayedDate!);
      final now = DateTime.now();
      final diff = now.difference(last).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
    }
    _lastPlayedDate = today;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
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

  Game? get favoriteGame {
    String? bestId;
    int bestScore = 0;
    for (final entry in highScores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestId = entry.key;
      }
    }
    if (bestId == null) return null;
    return allGames.firstWhere(
      (g) => g.id == bestId,
      orElse: () => allGames.first,
    );
  }

  Future<void> markOnboardingSeen() async {
    hasSeenOnboarding = true;
    await _save();
  }
}
