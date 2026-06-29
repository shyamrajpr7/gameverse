import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_service.dart';

enum OnlineMatchStatus { waiting, playing, completed }

class OnlinePlayer {
  final String id;
  final String name;

  const OnlinePlayer({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory OnlinePlayer.fromJson(Map<String, dynamic> json) => OnlinePlayer(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class OnlineMatch {
  final String id;
  final String gameId;
  final OnlineMatchStatus status;
  final OnlinePlayer host;
  final OnlinePlayer? guest;
  final int? hostScore;
  final int? guestScore;
  final String currentTurn;
  final DateTime createdAt;
  final String joinCode;

  OnlineMatch({
    required this.id,
    required this.gameId,
    required this.status,
    required this.host,
    this.guest,
    this.hostScore,
    this.guestScore,
    required this.currentTurn,
    required this.createdAt,
    required this.joinCode,
  });

  bool get isComplete => hostScore != null && guestScore != null;
  bool get isMyTurn => currentTurn == FirebaseAuth.instance.currentUser?.uid;

  bool isPlayer(String userId) =>
      host.id == userId || (guest?.id == userId);

  OnlinePlayer? opponent(String userId) =>
      host.id == userId ? guest : host;

  factory OnlineMatch.fromFirestore(
      String id, Map<String, dynamic> data) {
    return OnlineMatch(
      id: id,
      gameId: data['gameId'] as String,
      status: OnlineMatchStatus.values[data['status'] as int],
      host: OnlinePlayer.fromJson(data['host'] as Map<String, dynamic>),
      guest: data['guest'] != null
          ? OnlinePlayer.fromJson(data['guest'] as Map<String, dynamic>)
          : null,
      hostScore: data['hostScore'] as int?,
      guestScore: data['guestScore'] as int?,
      currentTurn: data['currentTurn'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      joinCode: data['joinCode'] as String,
    );
  }
}

class OnlineMultiplayerService {
  static final OnlineMultiplayerService _instance =
      OnlineMultiplayerService._();
  factory OnlineMultiplayerService() => _instance;
  OnlineMultiplayerService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  Future<User> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user!;
  }

  Future<String> createMatch(String gameId, String playerName) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final joinCode = _generateJoinCode();

    final docRef = await _firestore.collection('matches').add({
      'gameId': gameId,
      'status': OnlineMatchStatus.waiting.index,
      'host': {'id': user.uid, 'name': playerName},
      'guest': null,
      'hostScore': null,
      'guestScore': null,
      'currentTurn': user.uid,
      'joinCode': joinCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<OnlineMatch?> joinMatch(String joinCode) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final snapshot = await _firestore
        .collection('matches')
        .where('joinCode', isEqualTo: joinCode)
        .where('status', isEqualTo: OnlineMatchStatus.waiting.index)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();

    if (data['host']['id'] == user.uid) return null;

    final guestName = GameService().username;

    await doc.reference.update({
      'guest': {'id': user.uid, 'name': guestName},
      'status': OnlineMatchStatus.playing.index,
    });

    return OnlineMatch.fromFirestore(doc.id, {
      ...data,
      'guest': {'id': user.uid, 'name': guestName},
      'status': OnlineMatchStatus.playing.index,
    });
  }

  Stream<OnlineMatch> watchMatch(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) throw Exception('Match not found');
      return OnlineMatch.fromFirestore(snap.id, snap.data()!);
    });
  }

  Future<void> submitScore(String matchId, int score) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final docRef = _firestore.collection('matches').doc(matchId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Match not found');

    final data = doc.data()!;
    final isHost = data['host']['id'] == user.uid;
    final field = isHost ? 'hostScore' : 'guestScore';

    await docRef.update({
      field: score,
    });

    final updatedDoc = await docRef.get();
    final updatedData = updatedDoc.data()!;

    if (updatedData['hostScore'] != null &&
        updatedData['guestScore'] != null) {
      await docRef.update({
        'status': OnlineMatchStatus.completed.index,
      });
    }
  }

  Future<OnlineMatch> getMatch(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) throw Exception('Match not found');
    return OnlineMatch.fromFirestore(doc.id, doc.data()!);
  }

  String _generateJoinCode() {
    final rng = Random();
    return String.fromCharCodes(
      List.generate(4, (_) => '0123456789'.codeUnitAt(rng.nextInt(10))),
    );
  }
}
