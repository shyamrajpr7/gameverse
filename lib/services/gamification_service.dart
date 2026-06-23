import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  bool isUnlocked(List<String> unlockedIds) => unlockedIds.contains(id);
}

const List<AchievementBadge> allBadges = [
  AchievementBadge(id: 'first_task', title: 'First Steps', description: 'Complete your first task', icon: Icons.eco),
  AchievementBadge(id: 'ten_tasks', title: 'Task Machine', description: 'Complete 10 tasks', icon: Icons.workspace_premium),
  AchievementBadge(id: 'fifty_tasks', title: 'Task Legend', description: 'Complete 50 tasks', icon: Icons.emoji_events),
  AchievementBadge(id: 'first_focus', title: 'Focus Starter', description: 'Complete your first focus session', icon: Icons.timer),
  AchievementBadge(id: 'five_focus', title: 'Focus Master', description: 'Complete 5 focus sessions', icon: Icons.auto_awesome),
  AchievementBadge(id: 'twenty_five_focus', title: 'Focus Legend', description: 'Complete 25 focus sessions', icon: Icons.military_tech),
  AchievementBadge(id: 'early_bird', title: 'Early Bird', description: 'Complete a task before 8 AM', icon: Icons.wb_sunny),
  AchievementBadge(id: 'night_owl', title: 'Night Owl', description: 'Complete a task after 10 PM', icon: Icons.nightlight_round),
  AchievementBadge(id: 'level_5', title: 'Rising Star', description: 'Reach level 5', icon: Icons.trending_up),
  AchievementBadge(id: 'level_10', title: 'Superstar', description: 'Reach level 10', icon: Icons.military_tech),
];

class GamificationService {
  static final GamificationService _instance = GamificationService._();
  factory GamificationService() => _instance;
  GamificationService._();

  static const String _xpKey = 'current_xp';
  static const String _badgesKey = 'unlocked_badges';
  static const String _tasksDoneKey = 'tasks_completed_count';
  static const String _focusSessionsKey = 'focus_sessions_count';

  int currentXP = 0;
  List<String> unlockedBadges = [];
  int tasksCompleted = 0;
  int focusSessionsCompleted = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currentXP = prefs.getInt(_xpKey) ?? 0;
    tasksCompleted = prefs.getInt(_tasksDoneKey) ?? 0;
    focusSessionsCompleted = prefs.getInt(_focusSessionsKey) ?? 0;
    final String? badgesData = prefs.getString(_badgesKey);
    if (badgesData != null) {
      unlockedBadges = List<String>.from(jsonDecode(badgesData) as List);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, currentXP);
    await prefs.setInt(_tasksDoneKey, tasksCompleted);
    await prefs.setInt(_focusSessionsKey, focusSessionsCompleted);
    await prefs.setString(_badgesKey, jsonEncode(unlockedBadges));
  }

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return 50 * level * (level - 1);
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

  String? _checkTaskBadges() {
    if (!unlockedBadges.contains('first_task') && tasksCompleted >= 1) {
      return 'first_task';
    }
    if (!unlockedBadges.contains('ten_tasks') && tasksCompleted >= 10) {
      return 'ten_tasks';
    }
    if (!unlockedBadges.contains('fifty_tasks') && tasksCompleted >= 50) {
      return 'fifty_tasks';
    }
    return null;
  }

  String? _checkFocusBadges() {
    if (!unlockedBadges.contains('first_focus') && focusSessionsCompleted >= 1) {
      return 'first_focus';
    }
    if (!unlockedBadges.contains('five_focus') && focusSessionsCompleted >= 5) {
      return 'five_focus';
    }
    if (!unlockedBadges.contains('twenty_five_focus') && focusSessionsCompleted >= 25) {
      return 'twenty_five_focus';
    }
    return null;
  }

  String? _checkTimeBadge() {
    if (unlockedBadges.contains('early_bird') && unlockedBadges.contains('night_owl')) {
      return null;
    }
    final hour = DateTime.now().hour;
    if (!unlockedBadges.contains('early_bird') && hour < 8) {
      return 'early_bird';
    }
    if (!unlockedBadges.contains('night_owl') && hour >= 22) {
      return 'night_owl';
    }
    return null;
  }

  String? _checkLevelBadges() {
    final level = getLevel(currentXP);
    if (!unlockedBadges.contains('level_5') && level >= 5) {
      return 'level_5';
    }
    if (!unlockedBadges.contains('level_10') && level >= 10) {
      return 'level_10';
    }
    return null;
  }

  Future<UnlockResult> checkAndUnlockBadges() async {
    final newBadgeId = _checkTaskBadges() ??
        _checkFocusBadges() ??
        _checkTimeBadge() ??
        _checkLevelBadges();

    if (newBadgeId != null) {
      unlockedBadges.add(newBadgeId);
      await _save();
      final badge = allBadges.firstWhere((b) => b.id == newBadgeId);
      return UnlockResult(badge: badge, isNew: true);
    }
    return UnlockResult(badge: null, isNew: false);
  }

  bool _wasLevelUp = false;

  Future<UnlockResult> addXP(int amount) async {
    final oldLevel = getLevel(currentXP);
    currentXP += amount;
    final newLevel = getLevel(currentXP);
    _wasLevelUp = newLevel > oldLevel;
    await _save();
    final badgeResult = await checkAndUnlockBadges();
    if (_wasLevelUp && badgeResult.badge == null) {
      return UnlockResult(badge: null, isNew: false, leveledUp: true, newLevel: newLevel);
    }
    return badgeResult;
  }

  bool get justLeveledUp => _wasLevelUp;

  Future<void> incrementTasksCompleted() async {
    tasksCompleted++;
    await _save();
  }

  Future<void> decrementTasksCompleted() async {
    if (tasksCompleted > 0) tasksCompleted--;
    await _save();
  }

  Future<void> incrementFocusSessions() async {
    focusSessionsCompleted++;
    await _save();
  }

  AchievementBadge? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

class UnlockResult {
  final AchievementBadge? badge;
  final bool isNew;
  final bool leveledUp;
  final int? newLevel;

  const UnlockResult({
    this.badge,
    this.isNew = false,
    this.leveledUp = false,
    this.newLevel,
  });
}
