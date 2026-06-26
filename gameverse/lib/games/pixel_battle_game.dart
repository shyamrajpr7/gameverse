import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class PixelBattleGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const PixelBattleGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<PixelBattleGame> createState() => _PixelBattleGameState();
}

class _PixelBattleGameState extends State<PixelBattleGame> {
  double _playerX = 0.5;
  double _playerY = 0.8;
  final List<_Enemy2> _enemies = [];
  int _score = 0;
  int _health = 5;
  bool _gameOver = false;
  int _frame = 0;
  late Timer _gameTimer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _update(Timer timer) {
    if (_gameOver) return;
    _frame++;

    if (_frame % 40 == 0) {
      _enemies.add(_Enemy2(
        x: _rng.nextDouble() * 0.8 + 0.1,
        y: -0.05,
        speed: 0.004 + _score * 0.0001,
      ));
    }

    for (final e in _enemies) {
      e.y += e.speed;
      e.x += sin(_frame * 0.03) * 0.002;
    }

    for (int i = _enemies.length - 1; i >= 0; i--) {
      if ((_enemies[i].x - _playerX).abs() < 0.05 &&
          (_enemies[i].y - _playerY).abs() < 0.05) {
        _health--;
        _enemies.removeAt(i);
        if (_health <= 0) { _gameOver = true; widget.onGameOver(_score); return; }
      }
    }

    _enemies.removeWhere((e) => e.y > 1.1);
    setState(() {});
  }

  void _onTap(TapDownDetails details, Size size) {
    if (_gameOver) return;
    final tx = details.localPosition.dx / size.width;
    final ty = details.localPosition.dy / size.height;

    bool hit = false;
    for (int i = _enemies.length - 1; i >= 0; i--) {
      if ((tx - _enemies[i].x).abs() < 0.05 && (ty - _enemies[i].y).abs() < 0.05) {
        _enemies.removeAt(i);
        _score++;
        widget.onScoreChanged(_score);
        AudioService().play(SoundType.shoot);
        HapticService.light();
        hit = true;
        break;
      }
    }

    if (!hit) {
      AudioService().play(SoundType.click);
      _playerX = (_playerX + (tx - _playerX) * 0.3).clamp(0.05, 0.95);
      _playerY = (_playerY + (ty - _playerY) * 0.3).clamp(0.05, 0.95);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (d) => _onTap(d, Size(constraints.maxWidth, constraints.maxHeight)),
            child: Stack(children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _PixelPainter(
                  playerX: _playerX, playerY: _playerY,
                  enemies: _enemies, health: _health,
                  gameColor: widget.gameColor,
                ),
              ),
              Positioned(top: 8, left: 8, right: 8,
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
                  const Spacer(),
                  _badge(Icons.favorite, '$_health', Colors.red),
                  const SizedBox(width: 6),
                  _badge(Icons.emoji_events, '$_score', widget.gameColor),
                ]),
              ),
              Positioned(bottom: 20, left: 0, right: 0,
                child: Text('Tap enemies to attack! Tap ground to move!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}

class _Enemy2 { double x, y, speed; _Enemy2({required this.x, required this.y, required this.speed}); }

class _PixelPainter extends CustomPainter {
  final double playerX, playerY;
  final List<_Enemy2> enemies;
  final int health;
  final Color gameColor;
  _PixelPainter({required this.playerX, required this.playerY, required this.enemies, required this.health, required this.gameColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0F0F23));

    for (int x = 0; x < 20; x++) {
      for (int y = 0; y < 30; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x * size.width / 20, y * size.height / 30, size.width / 20, size.height / 30),
          Paint()..color = ((x + y) % 2 == 0
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.transparent),
        );
      }
    }

    for (final e in enemies) {
      final px = e.x * size.width;
      final py = e.y * size.height;
      final pw = size.width / 20;
      final ph = size.height / 30;
      canvas.drawRect(Rect.fromLTWH(px - pw / 2, py - ph / 2, pw, ph), Paint()..color = const Color(0xFFE74C3C));
      canvas.drawRect(Rect.fromLTWH(px - pw / 2, py - ph / 2 - ph, pw, ph / 2), Paint()..color = const Color(0xFFC0392B));
    }

    final pw = size.width / 20;
    final ph = size.height / 30;
    canvas.drawRect(
      Rect.fromLTWH(playerX * size.width - pw / 2, playerY * size.height - ph / 2, pw, ph),
      Paint()..color = gameColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(playerX * size.width - pw / 2, playerY * size.height - ph / 2 - ph, pw, ph / 2),
      Paint()..color = gameColor.withValues(alpha: 0.5),
    );

    final barW = 40.0;
    canvas.drawRect(
      Rect.fromLTWH(playerX * size.width - barW / 2, playerY * size.height - ph / 2 - ph - 6, barW, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawRect(
      Rect.fromLTWH(playerX * size.width - barW / 2, playerY * size.height - ph / 2 - ph - 6, barW * (health / 5), 4),
      Paint()..color = health > 3 ? Colors.green : health > 1 ? Colors.orange : Colors.red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
