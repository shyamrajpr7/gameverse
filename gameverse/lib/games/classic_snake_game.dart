import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class ClassicSnakeGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const ClassicSnakeGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<ClassicSnakeGame> createState() => _ClassicSnakeGameState();
}

class _ClassicSnakeGameState extends State<ClassicSnakeGame> {
  static const int _gridSize = 15;
  List<_SnakeSegment> _snake = [];
  _Point _food = _Point(x: 0, y: 0);
  int _score = 0;
  bool _gameOver = false;
  String _direction = 'right';
  String _nextDirection = 'right';
  late Timer _gameTimer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _resetGame();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 180), _update);
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _resetGame() {
    _snake = [
      _SnakeSegment(x: 2, y: 7),
      _SnakeSegment(x: 1, y: 7),
      _SnakeSegment(x: 0, y: 7),
    ];
    _direction = 'right';
    _nextDirection = 'right';
    _score = 0;
    _gameOver = false;
    _spawnFood();
  }

  void _spawnFood() {
    final occupied = _snake.map((s) => '${s.x},${s.y}').toSet();
    final available = <_Point>[];
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (!occupied.contains('$x,$y')) {
          available.add(_Point(x: x, y: y));
        }
      }
    }
    if (available.isEmpty) {
      _gameOver = true;
      widget.onGameOver(_score);
      return;
    }
    _food = available[_rng.nextInt(available.length)];
  }

  void _update(Timer timer) {
    if (_gameOver) return;

    _direction = _nextDirection;
    final head = _snake.first;
    _Point newHead;

    switch (_direction) {
      case 'up':
        newHead = _Point(x: head.x, y: head.y - 1);
        break;
      case 'down':
        newHead = _Point(x: head.x, y: head.y + 1);
        break;
      case 'left':
        newHead = _Point(x: head.x - 1, y: head.y);
        break;
      case 'right':
      default:
        newHead = _Point(x: head.x + 1, y: head.y);
        break;
    }

    if (newHead.x < 0 || newHead.x >= _gridSize ||
        newHead.y < 0 || newHead.y >= _gridSize) {
      _gameOver = true;
      widget.onGameOver(_score);
      setState(() {});
      return;
    }

    if (_snake.any((s) => s.x == newHead.x && s.y == newHead.y)) {
      _gameOver = true;
      widget.onGameOver(_score);
      setState(() {});
      return;
    }

    _snake.insert(0, _SnakeSegment(x: newHead.x, y: newHead.y));

    if (newHead.x == _food.x && newHead.y == _food.y) {
      _score++;
      widget.onScoreChanged(_score);
      AudioService().play(SoundType.collect);
      HapticService.light();
      _spawnFood();
    } else {
      _snake.removeLast();
    }

    setState(() {});
  }

  void _onSwipe(String direction) {
    AudioService().play(SoundType.click);
    if ((direction == 'up' && _direction != 'down') ||
        (direction == 'down' && _direction != 'up') ||
        (direction == 'left' && _direction != 'right') ||
        (direction == 'right' && _direction != 'left')) {
      _nextDirection = direction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => widget.onGameOver(_score),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.catching_pokemon, color: widget.gameColor, size: 18),
                        const SizedBox(width: 6),
                        Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onPanEnd: (details) {
                    final dx = details.velocity.pixelsPerSecond.dx;
                    final dy = details.velocity.pixelsPerSecond.dy;
                    if (dx.abs() > dy.abs()) {
                      _onSwipe(dx > 0 ? 'right' : 'left');
                    } else {
                      _onSwipe(dy > 0 ? 'down' : 'up');
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = min(constraints.maxWidth, constraints.maxHeight);
                      return Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0F23),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.gameColor.withValues(alpha: 0.3)),
                          ),
                          child: CustomPaint(
                            size: Size(size, size),
                            painter: _SnakePainter(
                              snake: _snake,
                              food: _food,
                              gridSize: _gridSize,
                              gameColor: widget.gameColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dirBtn(Icons.keyboard_arrow_up, () => _onSwipe('up')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dirBtn(Icons.keyboard_arrow_left, () => _onSwipe('left')),
                  const SizedBox(width: 16),
                  _dirBtn(Icons.keyboard_arrow_down, () => _onSwipe('down')),
                  const SizedBox(width: 16),
                  _dirBtn(Icons.keyboard_arrow_right, () => _onSwipe('right')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dirBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: widget.gameColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.gameColor.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: widget.gameColor, size: 28),
      ),
    );
  }
}

class _Point {
  final int x;
  final int y;
  _Point({required this.x, required this.y});
}

class _SnakeSegment {
  final int x;
  final int y;
  _SnakeSegment({required this.x, required this.y});
}

class _SnakePainter extends CustomPainter {
  final List<_SnakeSegment> snake;
  final _Point food;
  final int gridSize;
  final Color gameColor;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.gridSize,
    required this.gameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          Paint()..color = ((x + y) % 2 == 0
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.transparent),
        );
      }
    }

    for (int i = 0; i < snake.length; i++) {
      final seg = snake[i];
      final alpha = 1.0 - (i / snake.length) * 0.4;
      final padding = i == 0 ? 1.0 : 2.0;
      final rect = Rect.fromLTWH(
        seg.x * cellSize + padding,
        seg.y * cellSize + padding,
        cellSize - padding * 2,
        cellSize - padding * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(i == 0 ? 6 : 4)),
        Paint()
          ..color = i == 0
              ? gameColor
              : gameColor.withValues(alpha: alpha),
      );
    }

    final fRect = Rect.fromLTWH(
      food.x * cellSize + 3,
      food.y * cellSize + 3,
      cellSize - 6,
      cellSize - 6,
    );
    canvas.drawCircle(
      fRect.center,
      cellSize / 2 - 3,
      Paint()..color = Colors.red,
    );
    canvas.drawCircle(
      fRect.center,
      cellSize / 2 - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
