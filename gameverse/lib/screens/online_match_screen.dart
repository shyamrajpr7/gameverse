import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/online_multiplayer_service.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../games/racing_rivals_game.dart';
import '../games/classic_snake_game.dart';
import '../games/brick_breaker_game.dart';
import '../games/pixel_battle_game.dart';

class OnlineMatchScreen extends StatefulWidget {
  final Game game;
  final String matchId;

  const OnlineMatchScreen({
    super.key,
    required this.game,
    required this.matchId,
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  final OnlineMultiplayerService _onlineService = OnlineMultiplayerService();
  final GameService _gameService = GameService();
  late Stream<OnlineMatch> _matchStream;

  bool _playing = false;
  bool _submitted = false;
  int _lastScore = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _matchStream = _onlineService.watchMatch(widget.matchId);
  }

  void _startPlaying() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    setState(() {
      _playing = true;
      _saved = false;
    });
  }

  void _onScoreChanged(int score) {
    if (!_saved) {
      AudioService().play(SoundType.score);
      HapticService.light();
    }
  }

  Future<void> _onGameOver(int finalScore) async {
    if (_saved) return;
    _saved = true;

    AudioService().play(SoundType.gameOver);
    HapticService.heavy();

    _lastScore = finalScore;
    setState(() => _playing = false);

    try {
      await _onlineService.submitScore(widget.matchId, finalScore);
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit score: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: StreamBuilder<OnlineMatch>(
        stream: _matchStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Connection error',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final match = snapshot.data!;

          if (match.isComplete) return _buildResults(match);
          if (_playing) return _buildGame();
          if (_submitted) return _buildWaitingForOpponent(match);
          if (match.isMyTurn) return _buildYourTurn(match);

          return _buildWaitingForOpponent(match);
        },
      ),
    );
  }

  Widget _buildYourTurn(OnlineMatch match) {
    final opponent = match.opponent(
      _onlineService.currentUser!.uid,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.game.color.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.play_arrow, size: 50, color: widget.game.color),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Turn!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (opponent != null) ...[
            const SizedBox(height: 8),
            Text(
              'Playing against ${opponent.name}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _startPlaying,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text(
                'Play!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.game.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: widget.game.color.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForOpponent(OnlineMatch match) {
    final opponent = match.opponent(
      _onlineService.currentUser!.uid,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Waiting for opponent...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (opponent != null && _submitted) ...[
            const SizedBox(height: 8),
            Text(
              '${opponent.name} is playing',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.game.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your score: $_lastScore',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.game.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(OnlineMatch match) {
    final userId = _onlineService.currentUser!.uid;
    final myScore = match.host.id == userId ? match.hostScore : match.guestScore;
    final opponent = match.opponent(userId);
    final opponentScore = match.host.id == userId ? match.guestScore : match.hostScore;

    final isWinner = myScore != null && opponentScore != null && myScore > opponentScore;
    final isTie = myScore != null && opponentScore != null && myScore == opponentScore;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTie ? Icons.emoji_events : (isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied),
            size: 72,
            color: isWinner || isTie ? const Color(0xFFFFD700) : Colors.white38,
          ),
          const SizedBox(height: 16),
          Text(
            isTie ? "It's a Tie!" : (isWinner ? 'You Win!' : 'You Lose'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isWinner || isTie ? const Color(0xFFFFD700) : Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerScoreCard(
                _gameService.username,
                myScore ?? 0,
                widget.game.color,
                true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              _buildPlayerScoreCard(
                opponent?.name ?? 'Opponent',
                opponentScore ?? 0,
                Colors.white38,
                false,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home, size: 20),
              label: const Text(
                'Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.game.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScoreCard(
    String name,
    int score,
    Color color,
    bool isMe,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isMe ? widget.game.color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    final gameId = widget.game.id;
    final color = widget.game.color;

    Widget gameWidget;
    switch (gameId) {
      case 'racing_rivals':
        gameWidget = RacingRivalsGame(
          gameColor: color,
          onScoreChanged: _onScoreChanged,
          onGameOver: (s) => _onGameOver(s),
        );
      case 'classic_snake':
        gameWidget = ClassicSnakeGame(
          gameColor: color,
          onScoreChanged: _onScoreChanged,
          onGameOver: (s) => _onGameOver(s),
        );
      case 'brick_breaker':
        gameWidget = BrickBreakerGame(
          gameColor: color,
          onScoreChanged: _onScoreChanged,
          onGameOver: (s) => _onGameOver(s),
        );
      case 'pixel_battle':
        gameWidget = PixelBattleGame(
          gameColor: color,
          onScoreChanged: _onScoreChanged,
          onGameOver: (s) => _onGameOver(s),
        );
      default:
        gameWidget = Center(
          child: Text(
            'Unsupported game',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        );
    }

    return Stack(
      children: [
        gameWidget,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, right: 12),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
