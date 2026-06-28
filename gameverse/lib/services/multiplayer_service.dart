import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/multiplayer.dart';

class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._();
  factory MultiplayerService() => _instance;
  MultiplayerService._();

  static const String _historyKey = 'mp_history';

  List<MultiplayerSession> history = [];

  VoidCallback? onDataChanged;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      history = list
          .map((e) => MultiplayerSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((s) => s.toJson()).toList()),
    );
    onDataChanged?.call();
  }

  Future<void> saveSession(MultiplayerSession session) async {
    history.insert(0, session);
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }
    await _save();
  }

  Map<String, int> get playerWins {
    final wins = <String, int>{};
    for (final session in history) {
      final ranked = session.rankedPlayers;
      if (ranked.isNotEmpty) {
        final winner = ranked.first;
        final key = '${session.gameId}:${winner.name}';
        wins[key] = (wins[key] ?? 0) + 1;
      }
    }
    return wins;
  }
}
