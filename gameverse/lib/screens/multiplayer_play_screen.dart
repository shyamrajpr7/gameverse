import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/multiplayer.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../utils/page_transitions.dart';
import '../games/racing_rivals_game.dart';
import '../games/classic_snake_game.dart';
import '../games/brick_breaker_game.dart';
import '../games/pixel_battle_game.dart';
import 'multiplayer_results_screen.dart';

class MultiplayerPlayScreen extends StatefulWidget {
  final Game game;
  final MultiplayerSession session;

  const MultiplayerPlayScreen({
    super.key,
    required this.game,
    required this.session,
  });

  @override
  State<MultiplayerPlayScreen> createState() => _MultiplayerPlayScreenState();
}

class _MultiplayerPlayScreenState extends State<MultiplayerPlayScreen> {
  late MultiplayerSession _session;
  bool _playing = false;
  bool _intermission = false;
  int _lastScore = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  void _startTurn() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    setState(() {
      _playing = true;
      _intermission = false;
      _saved = false;
    });
  }

  void _onScoreChanged(int score) {
    if (!_saved) {
      AudioService().play(SoundType.score);
      HapticService.light();
    }
  }

  void _onGameOver(int finalScore) {
    if (_saved) return;
    _saved = true;

    AudioService().play(SoundType.gameOver);
    HapticService.heavy();

    _session.recordScore(finalScore);
    _lastScore = finalScore;

    if (_session.isLastPlayer) {
      setState(() => _playing = false);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showResults();
      });
    } else {
      setState(() {
        _playing = false;
        _intermission = true;
      });
    }
  }

  void _nextTurn() {
    _session.advanceTurn();
    _startTurn();
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      PageTransition.slideUp(MultiplayerResultsScreen(
        game: widget.game,
        session: _session,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_intermission) {
      return _buildIntermission();
    }
    if (!_playing) {
      return _buildTurnStart();
    }
    return _buildGame();
  }

  Widget _buildTurnStart() {
    final player = _session.currentPlayer;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.game.color.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.person, size: 50, color: widget.game.color),
            ),
            const SizedBox(height: 20),
            Text(
              player.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn ${_session.currentPlayerIndex + 1} of ${_session.players.length}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200, height: 56,
              child: ElevatedButton.icon(
                onPressed: _startTurn,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Play!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: widget.game.color.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntermission() {
    final player = _session.currentPlayer;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.game.color.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.check_circle, size: 40, color: widget.game.color),
            ),
            const SizedBox(height: 16),
            Text(
              '${player.name} scored $_lastScore!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Pass the device to the next player',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220, height: 56,
              child: ElevatedButton.icon(
                onPressed: _nextTurn,
                icon: const Icon(Icons.arrow_forward, size: 24),
                label: Text(
                  "Pass to ${_session.players[_session.currentPlayerIndex + 1].name}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: widget.game.color.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
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
          child: Text('Unsupported game', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        );
    }

    return Stack(
      children: [
        gameWidget,
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.game.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _session.currentPlayer.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_session.currentPlayerIndex + 1}/${_session.players.length}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
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
