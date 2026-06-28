import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game.dart';
import '../models/quest.dart';

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
  static const String _coinsKey = 'gameverse_coins';
  static const String _unlockedCosmeticsKey = 'gameverse_unlocked_cosmetics';
  static const String _equippedThemeKey = 'gameverse_equipped_theme';
  static const String _equippedSnakeSkinKey = 'gameverse_equipped_snake_skin';
  static const String _questsKey = 'gameverse_active_quests';
  static const String _lastQuestRefreshKey = 'gameverse_last_quest_refresh';

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

  // ── Coins & Cosmetics ──
  int coins = 0;
  List<String> unlockedCosmetics = ['theme_default'];
  String equippedTheme = 'default';
  String equippedSnakeSkin = 'default';

  List<Quest> activeQuests = [];
  String? _lastQuestRefreshDate;

  VoidCallback? onDataChanged;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currentXP = prefs.getInt(_xpKey) ?? 0;
    final badgesData = prefs.getString(_badgesKey);
    unlockedBadges = badgesData != null
        ? List<String>.from(jsonDecode(badgesData) as List)
        : [];
    final scoresData = prefs.getString(_highScoresKey);
    highScores = scoresData != null
        ? (jsonDecode(scoresData) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt()))
        : {};
    final playedData = prefs.getString(_playedGamesKey);
    playedGames = playedData != null
        ? List<String>.from(jsonDecode(playedData) as List)
        : [];
    hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _lastDailyDate = prefs.getString(_dailyDateKey);
    username = prefs.getString(_usernameKey) ?? 'Player';
    avatarIndex = prefs.getInt(_avatarIndexKey) ?? 0;
    totalGamesPlayed = prefs.getInt(_totalPlaysKey) ?? 0;
    currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    _lastPlayedDate = prefs.getString(_lastPlayedDateKey);

    coins = prefs.getInt(_coinsKey) ?? 0;
    final cosmeticsData = prefs.getString(_unlockedCosmeticsKey);
    unlockedCosmetics = cosmeticsData != null
        ? List<String>.from(jsonDecode(cosmeticsData) as List)
        : [];
    if (!unlockedCosmetics.contains('theme_default')) {
      unlockedCosmetics.add('theme_default');
    }
    equippedTheme = prefs.getString(_equippedThemeKey) ?? 'default';
    equippedSnakeSkin = prefs.getString(_equippedSnakeSkinKey) ?? 'default';

    _lastQuestRefreshDate = prefs.getString(_lastQuestRefreshKey);
    final questsData = prefs.getString(_questsKey);
    if (questsData != null) {
      final list = jsonDecode(questsData) as List;
      activeQuests = list.map((e) => Quest.fromJson(e as Map<String, dynamic>)).toList();
    }
    await checkAndRefreshQuests();
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

    await prefs.setInt(_coinsKey, coins);
    await prefs.setString(_unlockedCosmeticsKey, jsonEncode(unlockedCosmetics));
    await prefs.setString(_equippedThemeKey, equippedTheme);
    await prefs.setString(_equippedSnakeSkinKey, equippedSnakeSkin);
    await prefs.setString(_lastQuestRefreshKey, _lastQuestRefreshDate ?? '');
    await prefs.setString(_questsKey, jsonEncode(activeQuests.map((q) => q.toJson()).toList()));
    onDataChanged?.call();
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

  Future<void> checkAndRefreshQuests() async {
    if (activeQuests.isEmpty || _lastQuestRefreshDate != _todayString()) {
      _generateQuests();
      await _save();
    }
  }

  void _generateQuests() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    const dailyPool = [
      (
        title: 'First Win',
        description: 'Play 1 game of any type',
        targetType: QuestTargetType.playGames,
        targetValue: 1,
        coinReward: 20,
        xpReward: 50,
        gameId: null,
      ),
      (
        title: 'Snake Master',
        description: 'Score 50+ in Classic Snake',
        targetType: QuestTargetType.reachScore,
        targetValue: 50,
        coinReward: 30,
        xpReward: 60,
        gameId: 'classic_snake',
      ),
      (
        title: 'Brick Breaker',
        description: 'Score 100+ in Brick Breaker',
        targetType: QuestTargetType.reachScore,
        targetValue: 100,
        coinReward: 30,
        xpReward: 60,
        gameId: 'brick_breaker',
      ),
      (
        title: 'Gold Digger',
        description: 'Earn 30 coins in games',
        targetType: QuestTargetType.earnCoins,
        targetValue: 30,
        coinReward: 15,
        xpReward: 40,
        gameId: null,
      ),
      (
        title: 'Big Spender',
        description: 'Spend 100 coins in the Shop',
        targetType: QuestTargetType.spendCoins,
        targetValue: 100,
        coinReward: 25,
        xpReward: 50,
        gameId: null,
      ),
    ];

    const weeklyPool = [
      (
        title: 'Hardcore Gamer',
        description: 'Play 10 games',
        targetType: QuestTargetType.playGames,
        targetValue: 10,
        coinReward: 100,
        xpReward: 250,
        gameId: null,
      ),
      (
        title: 'High Roller',
        description: 'Earn 200 coins',
        targetType: QuestTargetType.earnCoins,
        targetValue: 200,
        coinReward: 80,
        xpReward: 200,
        gameId: null,
      ),
      (
        title: 'Champion',
        description: 'Reach score 200 in any game',
        targetType: QuestTargetType.reachScore,
        targetValue: 200,
        coinReward: 100,
        xpReward: 250,
        gameId: null,
      ),
    ];

    final dailies = List.of(dailyPool)..shuffle();
    final selectedDailies = dailies.take(3).toList();

    final weeklies = List.of(weeklyPool)..shuffle();
    final selectedWeeklies = weeklies.take(2).toList();

    activeQuests = [
      ...selectedDailies.asMap().entries.map((e) => Quest(
            id: 'daily_${timestamp}_${e.key}',
            title: e.value.title,
            description: e.value.description,
            type: QuestType.daily,
            targetType: e.value.targetType,
            targetValue: e.value.targetValue,
            coinReward: e.value.coinReward,
            xpReward: e.value.xpReward,
            gameId: e.value.gameId,
          )),
      ...selectedWeeklies.asMap().entries.map((e) => Quest(
            id: 'weekly_${timestamp}_${e.key}',
            title: e.value.title,
            description: e.value.description,
            type: QuestType.weekly,
            targetType: e.value.targetType,
            targetValue: e.value.targetValue,
            coinReward: e.value.coinReward,
            xpReward: e.value.xpReward,
            gameId: e.value.gameId,
          )),
    ];
    _lastQuestRefreshDate = _todayString();
  }

  Future<void> updateQuestProgress(QuestTargetType targetType, int increment, {String? gameId}) async {
    bool changed = false;
    for (int i = 0; i < activeQuests.length; i++) {
      final quest = activeQuests[i];
      if (quest.isCompleted) continue;
      if (quest.targetType != targetType) continue;
      if (quest.gameId != null && quest.gameId != gameId) continue;

      final newValue = (quest.currentValue + increment).clamp(0, quest.targetValue);
      activeQuests[i] = quest.copyWith(currentValue: newValue);
      changed = true;
    }
    if (changed) {
      await _save();
    }
  }

  Future<Quest?> claimQuestReward(String questId) async {
    final index = activeQuests.indexWhere((q) => q.id == questId);
    if (index == -1) return null;

    final quest = activeQuests[index];
    if (!quest.isCompleted || quest.isClaimed) return null;

    final claimed = quest.copyWith(isClaimed: true);
    activeQuests[index] = claimed;

    await addCoins(quest.coinReward);
    await addXP(quest.xpReward);
    await _save();

    return claimed;
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
    final oldLevel = getLevel(currentXP);
    currentXP += amount;
    await _save();

    final newLevel = getLevel(currentXP);
    if (newLevel > oldLevel) {
      await updateQuestProgress(QuestTargetType.levelUp, newLevel - oldLevel);
    }

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

  // ── Coins & Cosmetics ──

  Future<void> addCoins(int amount) async {
    coins += amount;
    await _save();
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _save();
    return true;
  }

  bool isCosmeticUnlocked(String id) => unlockedCosmetics.contains(id);

  Future<void> unlockCosmetic(String id) async {
    if (!unlockedCosmetics.contains(id)) {
      unlockedCosmetics.add(id);
      await _save();
    }
  }

  Future<void> equipCosmetic(String id) async {
    if (id.startsWith('snake_')) {
      equippedSnakeSkin = id;
    } else if (id.startsWith('theme_')) {
      equippedTheme = id;
    }
    await _save();
  }
}
