import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class BuildWorldGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const BuildWorldGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<BuildWorldGame> createState() => _BuildWorldGameState();
}

class _BuildWorldGameState extends State<BuildWorldGame> {
  final List<_Block> _blocks = [];
  int _score = 0;
  int _timeLeft = 120;
  bool _gameOver = false;
  late Timer _timer;
  Color _selectedColor = Colors.red;

  final List<Color> _palette = [
    Colors.red, Colors.orange, Colors.yellow, Colors.green,
    Colors.blue, Colors.purple, Colors.white, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_gameOver) return;
      _timeLeft--;
      if (_timeLeft <= 0) { _gameOver = true; widget.onGameOver(_score); }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _addBlock(double x, double y) {
    AudioService().play(SoundType.click);
    HapticService.light();
    setState(() {
      _blocks.add(_Block(x: x, y: y, color: _selectedColor));
      _score++;
      widget.onScoreChanged(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
              const Spacer(),
              _badge(Icons.emoji_events, '$_score', widget.gameColor),
              const SizedBox(width: 6),
              _badge(Icons.timer, '$_timeLeft', Colors.orange),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) {
                  _addBlock(d.localPosition.dx / constraints.maxWidth, d.localPosition.dy / constraints.maxHeight);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _BuildPainter(blocks: _blocks, gameColor: widget.gameColor),
                ),
              );
            }),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _palette.map((c) => GestureDetector(
                onTap: () {
                  AudioService().play(SoundType.click);
                  HapticService.selection();
                  setState(() => _selectedColor = c);
                },
                child: Container(
                  width: 44, height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedColor == c ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
        ]),
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

class _Block {
  double x, y;
  Color color;
  _Block({required this.x, required this.y, required this.color});
}

class _BuildPainter extends CustomPainter {
  final List<_Block> blocks;
  final Color gameColor;
  _BuildPainter({required this.blocks, required this.gameColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0F0F23));

    for (int y = 0; y < 20; y++) {
      for (int x = 0; x < 20; x++) {
        canvas.drawRect(Rect.fromLTWH(x * size.width / 20, y * size.height / 20, size.width / 20, size.height / 20),
          Paint()..color = Colors.white.withValues(alpha: 0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5);
      }
    }

    for (final b in blocks) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(b.x * size.width, b.y * size.height), width: size.width / 20, height: size.height / 20),
        Paint()..color = b.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
