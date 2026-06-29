import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

enum _BlockShape { square, circle, triangle, diamond, star }

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
  _BlockShape _selectedShape = _BlockShape.square;
  double _rotation = 0;

  final List<Color> _palette = [
    Colors.red, Colors.orange, Colors.yellow, Colors.green,
    Colors.blue, Colors.purple, Colors.white, Colors.brown,
  ];

  final List<_BlockShape> _shapes = _BlockShape.values;

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

  void _addBlock(double gridX, double gridY) {
    AudioService().play(SoundType.click);
    HapticService.light();
    setState(() {
      _blocks.add(_Block(
        gridX: gridX.round().clamp(0, 19),
        gridY: gridY.round().clamp(0, 19),
        color: _selectedColor,
        shape: _selectedShape,
        rotation: _rotation,
      ));
      _score++;
      widget.onScoreChanged(_score);
    });
  }

  void _removeBlockAt(double gridX, double gridY) {
    final gx = gridX.round().clamp(0, 19);
    final gy = gridY.round().clamp(0, 19);
    final idx = _blocks.indexWhere((b) => b.gridX == gx && b.gridY == gy);
    if (idx >= 0) {
      setState(() => _blocks.removeAt(idx));
    }
  }

  void _incrementRotation(double deg) {
    setState(() => _rotation = (_rotation + deg) % 360);
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
              const SizedBox(width: 6),
              _badge(Icons.widgets, '${_blocks.length}', Colors.cyan),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) => _addBlock(
                  d.localPosition.dx / (constraints.maxWidth / 20),
                  d.localPosition.dy / (constraints.maxHeight / 20),
                ),
                onLongPressStart: (d) => _removeBlockAt(
                  d.localPosition.dx / (constraints.maxWidth / 20),
                  d.localPosition.dy / (constraints.maxHeight / 20),
                ),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _BuildPainter(blocks: _blocks, gameColor: widget.gameColor),
                ),
              );
            }),
          ),
          // Color palette
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _palette.map((c) => GestureDetector(
                onTap: () {
                  AudioService().play(SoundType.click);
                  HapticService.selection();
                  setState(() => _selectedColor = c);
                },
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedColor == c ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: _selectedColor == c
                        ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                ),
              )).toList(),
            ),
          ),
          // Shape selector + rotation controls
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                ..._shapes.map((s) => GestureDetector(
                  onTap: () {
                    AudioService().play(SoundType.click);
                    HapticService.selection();
                    setState(() => _selectedShape = s);
                  },
                  child: Container(
                    width: 38, height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _selectedShape == s
                          ? widget.gameColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedShape == s ? widget.gameColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: _shapeIcon(s),
                  ),
                )),
                const Spacer(),
                Text('${_rotation.toInt()}°', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(width: 4),
                _rotButton(Icons.rotate_left, -45),
                const SizedBox(width: 2),
                _rotButton(Icons.rotate_right, 45),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _rotation = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Reset', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _rotButton(IconData icon, double deg) {
    return GestureDetector(
      onTap: () => _incrementRotation(deg),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white54, size: 18),
      ),
    );
  }

  Widget _shapeIcon(_BlockShape shape) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _ShapeIconPainter(shape: shape, color: Colors.white70),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14), const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class _Block {
  final int gridX, gridY;
  final Color color;
  final _BlockShape shape;
  final double rotation;

  _Block({
    required this.gridX,
    required this.gridY,
    required this.color,
    this.shape = _BlockShape.square,
    this.rotation = 0,
  });
}

class _BuildPainter extends CustomPainter {
  final List<_Block> blocks;
  final Color gameColor;
  _BuildPainter({required this.blocks, required this.gameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 20;
    final cellH = size.height / 20;
    final bgPaint = Paint()..color = const Color(0xFF0F0F23);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (int y = 0; y < 20; y++) {
      for (int x = 0; x < 20; x++) {
        final gridPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH), gridPaint);
      }
    }

    for (final b in blocks) {
      final cx = b.gridX * cellW + cellW / 2;
      final cy = b.gridY * cellH + cellH / 2;
      final paint = Paint()..color = b.color;
      final rad = b.rotation * math.pi / 180;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rad);
      final half = math.min(cellW, cellH) * 0.4;

      switch (b.shape) {
        case _BlockShape.square:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2), paint);
          break;
        case _BlockShape.circle:
          canvas.drawCircle(Offset.zero, half, paint);
          break;
        case _BlockShape.triangle:
          final path = Path()
            ..moveTo(0, -half)
            ..lineTo(-half, half)
            ..lineTo(half, half)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _BlockShape.diamond:
          final path = Path()
            ..moveTo(0, -half)
            ..lineTo(half, 0)
            ..lineTo(0, half)
            ..lineTo(-half, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _BlockShape.star:
          final star = Path();
          for (int i = 0; i < 10; i++) {
            final angle = -math.pi / 2 + i * math.pi / 5;
            final r = i.isEven ? half : half * 0.45;
            final pt = Offset(r * math.cos(angle), r * math.sin(angle));
            if (i == 0) {
              star.moveTo(pt.dx, pt.dy);
            } else {
              star.lineTo(pt.dx, pt.dy);
            }
          }
          star.close();
          canvas.drawPath(star, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ShapeIconPainter extends CustomPainter {
  final _BlockShape shape;
  final Color color;
  _ShapeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = size.width * 0.35;

    canvas.save();
    canvas.translate(cx, cy);

    switch (shape) {
      case _BlockShape.square:
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2), paint);
        break;
      case _BlockShape.circle:
        canvas.drawCircle(Offset.zero, half, paint);
        break;
      case _BlockShape.triangle:
        final path = Path()
          ..moveTo(0, -half)
          ..lineTo(-half, half)
          ..lineTo(half, half)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _BlockShape.diamond:
        final path = Path()
          ..moveTo(0, -half)
          ..lineTo(half, 0)
          ..lineTo(0, half)
          ..lineTo(-half, 0)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _BlockShape.star:
        final star = Path();
        for (int i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? half : half * 0.45;
          final pt = Offset(r * math.cos(angle), r * math.sin(angle));
          if (i == 0) {
            star.moveTo(pt.dx, pt.dy);
          } else {
            star.lineTo(pt.dx, pt.dy);
          }
        }
        star.close();
        canvas.drawPath(star, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
