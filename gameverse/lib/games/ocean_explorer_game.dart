import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class OceanExplorerGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const OceanExplorerGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<OceanExplorerGame> createState() => _OceanExplorerGameState();
}

class _OceanExplorerGameState extends State<OceanExplorerGame> {
  double _diverX = 0.5;
  double _diverY = 0.3;
  final List<_Bubble> _bubbles = [];
  final List<_Fish> _fish = [];
  final Random _rng = Random();
  int _score = 0;
  int _oxygen = 100;
  bool _gameOver = false;
  double _targetX = 0.5;
  double _targetY = 0.3;
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

    _diverX += (_targetX - _diverX) * 0.05;
    _diverY += (_targetY - _diverY) * 0.05;

    if (_frame % 30 == 0) {
      _bubbles.add(_Bubble(x: _diverX + (_rng.nextDouble() - 0.5) * 0.1, y: _diverY));
    }

    if (_frame % 60 == 0) {
      _fish.add(_Fish(
        x: _rng.nextDouble() > 0.5 ? 1.1 : -0.1,
        y: 0.1 + _rng.nextDouble() * 0.7,
        speed: 0.005 + _rng.nextDouble() * 0.005,
        dir: _rng.nextDouble() > 0.5 ? 1 : -1,
      ));
    }

    for (final b in _bubbles) { b.y -= 0.008; }
    for (final f in _fish) { f.x += f.speed * f.dir; }

    for (int i = _fish.length - 1; i >= 0; i--) {
      if ((_fish[i].x - _diverX).abs() < 0.05 && (_fish[i].y - _diverY).abs() < 0.05) {
        _score += 5;
        _oxygen = (_oxygen + 10).clamp(0, 100);
        widget.onScoreChanged(_score);
        AudioService().play(SoundType.collect);
        HapticService.light();
        _fish.removeAt(i);
      }
    }

    _oxygen--;
    if (_oxygen <= 0) { _gameOver = true; widget.onGameOver(_score); return; }

    _bubbles.removeWhere((b) => b.y < -0.05);
    _fish.removeWhere((f) => f.x < -0.2 || f.x > 1.2);

    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    _targetX = (_targetX + details.delta.dx / size.width).clamp(0.05, 0.95);
    _targetY = (_targetY + details.delta.dy / size.height).clamp(0.05, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (d) => _onPanUpdate(d, Size(constraints.maxWidth, constraints.maxHeight)),
            child: Stack(children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _OceanPainter(diverX: _diverX, diverY: _diverY, bubbles: _bubbles, fish: _fish, oxygen: _oxygen, gameColor: widget.gameColor, score: _score),
              ),
              Positioned(top: 8, left: 8, right: 8,
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
                  const Spacer(),
                  _badge(Icons.air, '$_oxygen%', _oxygen > 50 ? Colors.cyan : Colors.red),
                  const SizedBox(width: 6),
                  _badge(Icons.emoji_events, '$_score', widget.gameColor),
                ]),
              ),
              Positioned(bottom: 20, left: 0, right: 0,
                child: Text('Drag to swim! Collect fish for oxygen!', textAlign: TextAlign.center,
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

class _Bubble { double x, y; _Bubble({required this.x, required this.y}); }
class _Fish { double x, y, speed; int dir; _Fish({required this.x, required this.y, required this.speed, required this.dir}); }

class _OceanPainter extends CustomPainter {
  final double diverX, diverY; final List<_Bubble> bubbles; final List<_Fish> fish; final int oxygen; final Color gameColor; final int score;
  _OceanPainter({required this.diverX, required this.diverY, required this.bubbles, required this.fish, required this.oxygen, required this.gameColor, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = LinearGradient(
      colors: [const Color(0xFF001133), const Color(0xFF002266), const Color(0xFF003399)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    for (final b in bubbles) {
      canvas.drawCircle(Offset(b.x * size.width, b.y * size.height), 4, Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    for (final f in fish) {
      canvas.drawCircle(Offset(f.x * size.width, f.y * size.height), 8, Paint()..color = const Color(0xFFFFD700));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(f.x * size.width + (f.dir > 0 ? 5 : -5), f.y * size.height), width: 16, height: 6), const Radius.circular(3)), Paint()..color = const Color(0xFFFFD700));
    }

    canvas.drawCircle(Offset(diverX * size.width, diverY * size.height), 12, Paint()..color = gameColor);
    canvas.drawRect(Rect.fromLTWH(diverX * size.width - 10, diverY * size.height - 22, 20, 4), Paint()..color = Colors.white.withValues(alpha: 0.2));
    canvas.drawRect(Rect.fromLTWH(diverX * size.width - 10, diverY * size.height - 22, 20 * (oxygen / 100), 4), Paint()..color = oxygen > 50 ? Colors.cyan : Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
