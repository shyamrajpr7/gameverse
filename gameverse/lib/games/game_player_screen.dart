import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import 'sky_jumper_game.dart';
import 'puzzle_quest_game.dart';
import 'racing_rivals_game.dart';
import 'zombie_survival_game.dart';
import 'tower_defense_game.dart';
import 'space_wars_game.dart';
import 'ocean_explorer_game.dart';
import 'farm_life_game.dart';
import 'build_world_game.dart';
import 'pixel_battle_game.dart';
import 'classic_snake_game.dart';
import '../widgets/achievement_overlay.dart';
import '../widgets/share_preview_dialog.dart';

class GamePlayerScreen extends StatefulWidget {
  final Game game;
  const GamePlayerScreen({super.key, required this.game});

  @override
  State<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends State<GamePlayerScreen> {
  final GameService _gameService = GameService();
  int _score = 0;
  bool _gameOver = false;
  bool _gameStarted = false;
  bool _saved = false;
  int _coinsEarned = 0;

  @override
  void initState() {
    super.initState();
    _gameService.load();
  }

  void _onScoreChanged(int score) {
    if (!_gameOver) {
      setState(() => _score = score);
      AudioService().play(SoundType.score);
      HapticService.light();
    }
  }

  Future<void> _onGameOver(int finalScore) async {
    if (_saved) return;
    _saved = true;
    setState(() {
      _score = finalScore;
      _gameOver = true;
    });
    AudioService().play(SoundType.gameOver);
    HapticService.heavy();
    await _gameService.recordGamePlayed(widget.game.id);
    await _gameService.updateHighScore(widget.game.id, finalScore);
    _coinsEarned = (finalScore ~/ 5) + 5;
    await _gameService.addCoins(_coinsEarned);
    final baseXp = widget.game.xpReward + (finalScore ~/ 10);
    final multiplier = _gameService.dailyMultiplier(widget.game.id);
    final badge = await _gameService.addXP(baseXp * multiplier);
    if (multiplier > 1) {
      await _gameService.markDailyCompleted();
    }
    if (badge != null && mounted) {
      final badgeData = allBadges.firstWhere((b) => b.id == badge);
      AudioService().play(SoundType.achievement);
      HapticService.medium();
      Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => AchievementOverlay(
          badge: badgeData,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ));
    }
  }

  void _startGame() {
    AudioService().play(SoundType.swipe);
    HapticService.light();
    setState(() => _gameStarted = true);
  }

  void _restartGame() {
    AudioService().play(SoundType.swipe);
    HapticService.light();
    setState(() {
      _score = 0;
      _gameOver = false;
      _gameStarted = true;
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      return _buildStartScreen();
    }
    if (_gameOver) {
      return _buildGameOverScreen();
    }
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
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
              child: Icon(widget.game.icon, size: 50, color: widget.game.color),
            ),
            const SizedBox(height: 20),
            Text(widget.game.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Earn XP & compete for high scores!', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: widget.game.color.withValues(alpha: 0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text('Play', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final highScore = _gameService.getHighScore(widget.game.id);
    final isNewHighScore = _score >= highScore && _score > 0;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Game Over', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [widget.game.color, widget.game.color.withValues(alpha: 0.5)],
                    ),
                  ),
                  child: Center(
                    child: Text('$_score', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                if (isNewHighScore) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18),
                        SizedBox(width: 6),
                        Text('New High Score!', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _CoinsEarnedBadge(coins: _coinsEarned),
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SharePreviewDialog(
                          game: widget.game,
                          score: _score,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _restartGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.game.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Play Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to Details', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
          _FloatingCoins(coins: _coinsEarned, gameColor: widget.game.color),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    switch (widget.game.id) {
      case 'sky_jumper':
        return SkyJumperGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'puzzle_quest':
        return PuzzleQuestGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'racing_rivals':
        return RacingRivalsGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'zombie_survival':
        return ZombieSurvivalGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'tower_defense':
        return TowerDefenseGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'space_wars':
        return SpaceWarsGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'ocean_explorer':
        return OceanExplorerGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'farm_life':
        return FarmLifeGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'build_world':
        return BuildWorldGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'classic_snake':
        return ClassicSnakeGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      case 'pixel_battle':
        return PixelBattleGame(
          gameColor: widget.game.color,
          onScoreChanged: _onScoreChanged,
          onGameOver: _onGameOver,
        );
      default:
        return Center(
          child: Text('Game coming soon!', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        );
    }
  }
}

class _CoinsEarnedBadge extends StatefulWidget {
  final int coins;
  const _CoinsEarnedBadge({required this.coins});

  @override
  State<_CoinsEarnedBadge> createState() => _CoinsEarnedBadgeState();
}

class _CoinsEarnedBadgeState extends State<_CoinsEarnedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              '+${widget.coins} Coins',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCoins extends StatefulWidget {
  final int coins;
  final Color gameColor;
  const _FloatingCoins({required this.coins, required this.gameColor});

  @override
  State<_FloatingCoins> createState() => _FloatingCoinsState();
}

class _FloatingCoinsState extends State<_FloatingCoins>
    with TickerProviderStateMixin {
  late final List<_CoinAnim> _coins;

  @override
  void initState() {
    super.initState();
    final count = (widget.coins / 3).ceil().clamp(1, 10);
    for (int i = 0; i < count; i++) {
      _coins.add(_CoinAnim(
        dx: (i - count / 2) * 30,
        delay: i * 0.1,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(_coins.length, (i) {
          return _SingleFloatingCoin(
            coin: _coins[i],
            index: i,
          );
        }),
      ),
    );
  }
}

class _CoinAnim {
  final double dx;
  final double delay;
  _CoinAnim({required this.dx, required this.delay});
}

class _SingleFloatingCoin extends StatefulWidget {
  final _CoinAnim coin;
  final int index;
  const _SingleFloatingCoin({required this.coin, required this.index});

  @override
  State<_SingleFloatingCoin> createState() => _SingleFloatingCoinState();
}

class _SingleFloatingCoinState extends State<_SingleFloatingCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(Duration(milliseconds: (widget.coin.delay * 1000).round()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final y = -200 * t;
        final opacity = (1 - t).clamp(0.0, 1.0);
        final scale = 0.5 + 0.5 * (1 - t);
        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + widget.coin.dx - 12,
          top: MediaQuery.of(context).size.height / 2 + y,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 24),
            ),
          ),
        );
      },
    );
  }
}
