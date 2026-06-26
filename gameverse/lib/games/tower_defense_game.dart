import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class TowerDefenseGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const TowerDefenseGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<TowerDefenseGame> createState() => _TowerDefenseGameState();
}

class _TowerDefenseGameState extends State<TowerDefenseGame> {
  final List<_Enemy> _enemies = [];
  final List<_Tower> _towers = [];
  final Random _rng = Random();
  int _score = 0;
  int _gold = 50;
  int _lives = 20;
  int _wave = 0;
  bool _gameOver = false;
  int _enemiesSpawned = 0;
  int _enemiesPerWave = 5;
  late Timer _gameTimer;
  int _frame = 0;

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

    if (_enemiesSpawned < _enemiesPerWave) {
      if (_frame % 40 == 0) {
        _enemies.add(_Enemy(
          x: 1.05,
          y: 0.15 + _rng.nextDouble() * 0.7,
          hp: (2 + _wave).toDouble(),
          speed: 0.004 + _wave * 0.0003,
        ));
        _enemiesSpawned++;
      }
    } else if (_enemies.isEmpty) {
      _wave++;
      _enemiesSpawned = 0;
      _enemiesPerWave = 5 + _wave * 2;
      _gold += 20;
    }

    for (final e in _enemies) {
      e.x -= e.speed;
    }

    for (final t in _towers) {
      if (_frame % 30 == 0) {
        for (final e in _enemies) {
          final dx = e.x - t.x;
          final dy = e.y - t.y;
          if (sqrt(dx * dx + dy * dy) < t.range) {
            e.hp--;
            if (e.hp <= 0) {
              _enemies.remove(e);
              _score++;
              _gold += 5;
              widget.onScoreChanged(_score);
              AudioService().play(SoundType.collect);
              HapticService.light();
            }
            break;
          }
        }
      }
    }

    _enemies.removeWhere((e) {
      if (e.x < -0.05) {
        _lives--;
        if (_lives <= 0) {
          _gameOver = true;
          widget.onGameOver(_score);
        }
        return true;
      }
      return false;
    });

    setState(() {});
  }

  void _placeTower(TapDownDetails details, Size size) {
    if (_gold < 20) return;
    AudioService().play(SoundType.click);
    HapticService.light();
    setState(() {
      _towers.add(_Tower(
        x: details.localPosition.dx / size.width,
        y: details.localPosition.dy / size.height,
        range: 0.12,
      ));
      _gold -= 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (d) => _placeTower(d, Size(constraints.maxWidth, constraints.maxHeight)),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _TDPainter(
                      enemies: _enemies,
                      towers: _towers,
                      gameColor: widget.gameColor,
                      wave: _wave,
                    ),
                  ),
                  Positioned(top: 8, left: 8, right: 8,
                    child: Row(children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
                      const Spacer(),
                      _badge(Icons.favorite, '$_lives', Colors.red),
                      const SizedBox(width: 6),
                      _badge(Icons.monetization_on, '$_gold', widget.gameColor),
                      const SizedBox(width: 6),
                      _badge(Icons.waves, 'Wave $_wave', Colors.blueAccent),
                      const SizedBox(width: 6),
                      _badge(Icons.emoji_events, '$_score', Colors.amberAccent),
                    ]),
                  ),
                  Positioned(bottom: 20, left: 0, right: 0,
                    child: Text('Tap to place towers (20 gold)', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14), const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class _Enemy { double x, y, hp, speed; _Enemy({required this.x, required this.y, required this.hp, required this.speed}); }
class _Tower { double x, y, range; _Tower({required this.x, required this.y, required this.range}); }

class _TDPainter extends CustomPainter {
  final List<_Enemy> enemies; final List<_Tower> towers; final Color gameColor; final int wave;
  _TDPainter({required this.enemies, required this.towers, required this.gameColor, required this.wave});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0F0F23));

    final pathPaint = Paint()..color = const Color(0xFF1A1A2E);
    final path = Path()..moveTo(size.width, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(0, size.height * 0.3);
    canvas.drawPath(path, pathPaint);

    for (final t in towers) {
      canvas.drawCircle(Offset(t.x * size.width, t.y * size.height), t.range * size.width, Paint()
        ..color = gameColor.withValues(alpha: 0.1));
      canvas.drawRect(Rect.fromCenter(center: Offset(t.x * size.width, t.y * size.height), width: 20, height: 20), Paint()..color = gameColor);
    }

    for (final e in enemies) {
      canvas.drawCircle(Offset(e.x * size.width, e.y * size.height), 8, Paint()..color = const Color(0xFFE74C3C));
      canvas.drawRect(Rect.fromLTWH(e.x * size.width - 6, e.y * size.height - 12, 12 * (e.hp / (2 + wave)), 3), Paint()..color = Colors.green);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
