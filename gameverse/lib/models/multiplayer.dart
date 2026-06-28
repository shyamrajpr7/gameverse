import '../models/game.dart';

class MultiplayerPlayer {
  final String id;
  String name;
  int? score;

  MultiplayerPlayer({
    required this.id,
    required this.name,
    this.score,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'score': score,
  };

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) =>
      MultiplayerPlayer(
        id: json['id'] as String,
        name: json['name'] as String,
        score: json['score'] as int?,
      );
}

class MultiplayerSession {
  final String gameId;
  final List<MultiplayerPlayer> players;
  final DateTime createdAt;
  int currentPlayerIndex;

  MultiplayerSession({
    required this.gameId,
    required this.players,
    DateTime? createdAt,
    this.currentPlayerIndex = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isComplete => players.every((p) => p.score != null);
  bool get isLastPlayer => currentPlayerIndex >= players.length - 1;

  MultiplayerPlayer get currentPlayer => players[currentPlayerIndex];

  List<MultiplayerPlayer> get rankedPlayers {
    final sorted = List<MultiplayerPlayer>.from(players)
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    return sorted;
  }

  void recordScore(int score) {
    players[currentPlayerIndex].score = score;
  }

  void advanceTurn() {
    if (!isLastPlayer) {
      currentPlayerIndex++;
    }
  }

  Game? get game {
    final matches = allGames.where((g) => g.id == gameId).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'players': players.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'currentPlayerIndex': currentPlayerIndex,
  };

  factory MultiplayerSession.fromJson(Map<String, dynamic> json) =>
      MultiplayerSession(
        gameId: json['gameId'] as String,
        players: (json['players'] as List)
            .map((e) => MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
      );
}
