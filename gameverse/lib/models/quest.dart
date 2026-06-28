enum QuestType { daily, weekly }

enum QuestTargetType { playGames, reachScore, earnCoins, spendCoins, levelUp }

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestTargetType targetType;
  final int targetValue;
  final int currentValue;
  final int xpReward;
  final int coinReward;
  final bool isClaimed;
  final String? gameId;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetType,
    required this.targetValue,
    this.currentValue = 0,
    required this.xpReward,
    required this.coinReward,
    this.isClaimed = false,
    this.gameId,
  });

  bool get isCompleted => currentValue >= targetValue;

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    QuestTargetType? targetType,
    int? targetValue,
    int? currentValue,
    int? xpReward,
    int? coinReward,
    bool? isClaimed,
    String? gameId,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      isClaimed: isClaimed ?? this.isClaimed,
      gameId: gameId ?? this.gameId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetType': targetType.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'isClaimed': isClaimed,
      'gameId': gameId,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: QuestType.values.firstWhere((e) => e.name == json['type']),
      targetType:
          QuestTargetType.values.firstWhere((e) => e.name == json['targetType']),
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int,
      xpReward: json['xpReward'] as int,
      coinReward: json['coinReward'] as int,
      isClaimed: json['isClaimed'] as bool,
      gameId: json['gameId'] as String?,
    );
  }
}
