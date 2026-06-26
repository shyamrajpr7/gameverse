import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class SpaceWarsGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const SpaceWarsGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<SpaceWarsGame> createState() => _SpaceWarsGameState();
}

class _SpaceWarsGameState extends State<SpaceWarsGame> {
  double _shipX = 0.5;
  final double _shipY = 0.85;
  final List<_Bullet> _bullets = [];
  final List<_Alien> _aliens = [];
  final Random _rng = Random();
  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  int _frame = 0;
  late Timer _gameTimer;

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

    if (_frame % 50 == 0) {
      _aliens.add(_Alien(
        x: _rng.nextDouble() * 0.9 + 0.05,
        y: -0.05,
        speed: 0.003 + _score * 0.00005,
      ));
    }

    for (final b in _bullets) { b.y -= 0.015; }
    for (final a in _aliens) { a.y += a.speed; a.x += sin(_frame * 0.02 + a.x) * 0.002; }

    for (int i = _bullets.length - 1; i >= 0; i--) {
      for (int j = _aliens.length - 1; j >= 0; j--) {
        if ((_bullets[i].x - _aliens[j].x).abs() < 0.04 &&
            (_bullets[i].y - _aliens[j].y).abs() < 0.04) {
          _aliens.removeAt(j);
          _bullets.removeAt(i);
          _score++;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.collect);
          HapticService.light();
          break;
        }
      }
    }

    for (final a in _aliens) {
      if ((a.x - _shipX).abs() < 0.04 && (a.y - _shipY).abs() < 0.05) {
        _lives--;
        a.y = 2;
        if (_lives <= 0) { _gameOver = true; widget.onGameOver(_score); return; }
      }
    }

    _bullets.removeWhere((b) => b.y < -0.05);
    _aliens.removeWhere((a) => a.y > 1.1);

    setState(() {});
  }

  void _onTap(TapDownDetails details, Size size) {
    if (_gameOver) return;
    final x = details.localPosition.dx / size.width;
    if (x < _shipX) {
      _shipX = (_shipX - 0.04).clamp(0.05, 0.95);
    } else {
      _shipX = (_shipX + 0.04).clamp(0.05, 0.95);
      _bullets.add(_Bullet(x: _shipX, y: _shipY - 0.04));
      AudioService().play(SoundType.shoot);
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
              child: Stack(children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _SpacePainter(shipX: _shipX, shipY: _shipY, bullets: _bullets, aliens: _aliens, gameColor: widget.gameColor),
                ),
                Positioned(top: 8, left: 8, right: 8,
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
                    const Spacer(),
                    _badge(Icons.favorite, '$_lives', Colors.red),
                    const SizedBox(width: 6),
                    _badge(Icons.emoji_events, '$_score', widget.gameColor),
                  ]),
                ),
                Positioned(bottom: 20, left: 0, right: 0,
                  child: Text('Tap left to move, tap right to shoot', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                ),
              ]),
            );
          },
        ),
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

class _Bullet { double x, y; _Bullet({required this.x, required this.y}); }
class _Alien { double x, y, speed; _Alien({required this.x, required this.y, required this.speed}); }

class _SpacePainter extends CustomPainter {
  final double shipX, shipY; final List<_Bullet> bullets; final List<_Alien> aliens; final Color gameColor;
  _SpacePainter({required this.shipX, required this.shipY, required this.bullets, required this.aliens, required this.gameColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF050510));
    for (int i = 0; i < 50; i++) {
      canvas.drawCircle(Offset((i * 73.7 + 50) % size.width, (i * 41.3 + 20) % size.height), 1, Paint()..color = Colors.white.withValues(alpha: 0.15 + (i % 5) * 0.05));
    }
    for (final b in bullets) { canvas.drawCircle(Offset(b.x * size.width, b.y * size.height), 3, Paint()..color = gameColor); }
    for (final a in aliens) {
      canvas.drawCircle(Offset(a.x * size.width, a.y * size.height), 10, Paint()..color = const Color(0xFF2ECC71));
      canvas.drawCircle(Offset(a.x * size.width - 3, a.y * size.height - 3), 2, Paint()..color = Colors.red);
      canvas.drawCircle(Offset(a.x * size.width + 3, a.y * size.height - 3), 2, Paint()..color = Colors.red);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(shipX * size.width, shipY * size.height), width: 24, height: 16), const Radius.circular(8)), Paint()..color = gameColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
