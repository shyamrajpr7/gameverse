import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class ZombieSurvivalGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const ZombieSurvivalGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<ZombieSurvivalGame> createState() => _ZombieSurvivalGameState();
}

class _ZombieSurvivalGameState extends State<ZombieSurvivalGame> {
  final List<_Zombie> _zombies = [];
  final Random _rng = Random();
  int _score = 0;
  int _health = 100;
  bool _gameOver = false;
  double _playerX = 0.5;
  double _playerY = 0.85;
  late Timer _gameTimer;
  int _spawnCounter = 0;
  int _wave = 1;

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

    setState(() {
      _spawnCounter++;
      if (_spawnCounter % (60 - _wave * 3).clamp(20, 60) == 0) {
        _zombies.add(_Zombie(
          x: _rng.nextDouble() * 0.9 + 0.05,
          y: -0.05,
          speed: 0.003 + _rng.nextDouble() * 0.004 + _wave * 0.0005,
          health: 1 + _wave ~/ 3,
          size: 0.04 + _rng.nextDouble() * 0.02,
        ));
      }

      if (_score > 0 && _score % 20 == 0) _wave++;

      for (final z in _zombies) {
        z.y += z.speed;
        z.x += sin(_score * 0.1 + _zombies.indexOf(z)) * 0.001;

        final dx = (_playerX - z.x).abs();
        final dy = (_playerY - z.y).abs();
        if (dx < 0.04 && dy < 0.04) {
          _health -= 10;
          z.health = 0;
          HapticService.heavy();
          if (_health <= 0) {
            _gameOver = true;
            widget.onGameOver(_score);
            return;
          }
        }
      }

      _zombies.removeWhere((z) => z.y > 1.1 || z.health <= 0);
    });
  }

  void _onTap(TapDownDetails details, Size size) {
    if (_gameOver) return;
    final tx = details.localPosition.dx / size.width;
    final ty = details.localPosition.dy / size.height;

    for (int i = _zombies.length - 1; i >= 0; i--) {
      final z = _zombies[i];
      if ((tx - z.x).abs() < z.size * 2 && (ty - z.y).abs() < z.size * 2) {
        z.health--;
        if (z.health <= 0) {
          _zombies.removeAt(i);
          _score++;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.shoot);
          HapticService.light();
        }
        return;
      }
    }

    final dx = (tx - _playerX) * 3;
    final dy = (ty - _playerY) * 3;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 0) {
      _playerX += dx / dist * 0.02;
      _playerY += dy / dist * 0.02;
      _playerX = _playerX.clamp(0.05, 0.95);
      _playerY = _playerY.clamp(0.4, 0.95);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {

            return GestureDetector(
              onTapDown: (d) => _onTap(d, Size(constraints.maxWidth, constraints.maxHeight)),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ZombiePainter(
                      zombies: _zombies,
                      playerX: _playerX,
                      playerY: _playerY,
                      health: _health,
                      gameColor: widget.gameColor,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                          onPressed: () => widget.onGameOver(_score),
                        ),
                        const Spacer(),
                        _buildStat(Icons.favorite, '$_health', Colors.red),
                        const SizedBox(width: 8),
                        _buildStat(Icons.emoji_events, '$_score', widget.gameColor),
                        const SizedBox(width: 8),
                        _buildStat(Icons.waves, 'Wave $_wave', Colors.blueAccent),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Tap on zombies to shoot! Tap ground to move.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Zombie {
  double x;
  double y;
  double speed;
  int health;
  double size;
  _Zombie({required this.x, required this.y, required this.speed, required this.health, required this.size});
}

class _ZombiePainter extends CustomPainter {
  final List<_Zombie> zombies;
  final double playerX;
  final double playerY;
  final int health;
  final Color gameColor;

  _ZombiePainter({
    required this.zombies,
    required this.playerX,
    required this.playerY,
    required this.health,
    required this.gameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = LinearGradient(
      colors: [const Color(0xFF0A0A1A), const Color(0xFF1A0A0A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final groundPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF1A1A0A), const Color(0xFF0A1A0A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15), groundPaint);

    for (int i = 0; i < 30; i++) {
      final sx = (i * 47.3 + 20) % size.width;
      final sy = (i * 31.7 + 10) % size.height;
      canvas.drawCircle(Offset(sx, sy), 1, Paint()..color = Colors.white.withValues(alpha: 0.15));
    }

    for (final z in zombies) {
      final zx = z.x * size.width;
      final zy = z.y * size.height;
      final zsize = z.size * size.width;

      canvas.drawCircle(
        Offset(zx, zy),
        zsize,
        Paint()..color = const Color(0xFF2ECC71).withValues(alpha: z.health > 1 ? 0.7 : 0.9),
      );
      canvas.drawCircle(
        Offset(zx - zsize * 0.4, zy - zsize * 0.3),
        zsize * 0.3,
        Paint()..color = Colors.red,
      );
      canvas.drawCircle(
        Offset(zx + zsize * 0.4, zy - zsize * 0.3),
        zsize * 0.3,
        Paint()..color = Colors.red,
      );

      if (z.health > 1) {
        canvas.drawCircle(Offset(zx, zy), zsize + 3, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.orange.withValues(alpha: 0.5));
      }
    }

    final px = playerX * size.width;
    final py = playerY * size.height;
    canvas.drawCircle(
      Offset(px, py),
      16,
      Paint()..color = gameColor,
    );
    canvas.drawCircle(
      Offset(px, py),
      16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    canvas.drawRect(
      Rect.fromLTWH(px - 15, py - 35, 30, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    canvas.drawRect(
      Rect.fromLTWH(px - 15, py - 35, 30 * (health / 100), 4),
      Paint()..color = health > 50 ? Colors.green : health > 25 ? Colors.orange : Colors.red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
