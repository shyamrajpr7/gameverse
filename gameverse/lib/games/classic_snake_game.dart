import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../utils/particle_system.dart';

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

class _ClassicSnakeGameState extends State<ClassicSnakeGame>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 15;

  List<_SnakeSeg> _snake = [];
  _Point _food = _Point(x: 7, y: 7);
  int _score = 0;
  bool _gameOver = false;
  bool _dead = false;
  String _direction = 'right';
  String _nextDirection = 'right';
  final Random _rng = Random();

  late Ticker _ticker;
  double _gameTime = 0;
  double _moveAccum = 0;
  static const double _moveInterval = 0.18;

  List<Offset> _prevPositions = [];
  List<Offset> _nextPositions = [];
  double _moveProgress = 1;

  final ParticleEmitter _emitter = ParticleEmitter();
  final ScreenShake _shake = ScreenShake();
  final TrailEffect _trail = TrailEffect();

  double _foodPulse = 0;
  final List<_FloatingText> _floatingTexts = [];
  final List<_ExplodingSeg> _explodingSegs = [];

  double _redFlash = 0;
  double _scoreBounce = 1;

  @override
  void initState() {
    super.initState();
    _resetGame();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    _snake = [
      _SnakeSeg(x: 2, y: 7),
      _SnakeSeg(x: 1, y: 7),
      _SnakeSeg(x: 0, y: 7),
    ];
    _direction = 'right';
    _nextDirection = 'right';
    _score = 0;
    _gameOver = false;
    _dead = false;
    _moveProgress = 1;
    _moveAccum = 0;
    _redFlash = 0;
    _scoreBounce = 1;
    _emitter.particles.clear();
    _trail.clear();
    _floatingTexts.clear();
    _explodingSegs.clear();
    _updatePositions();
    _spawnFood();
  }

  void _updatePositions() {
    _prevPositions = _snake.map((s) => Offset(s.x, s.y)).toList();
    _nextPositions = List.from(_prevPositions);
  }

  void _spawnFood() {
    final occupied = _snake.map((s) => '${s.x.toInt()},${s.y.toInt()}').toSet();
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

  void _onTick(Duration elapsed) {
    final dt = 1 / 60;
    _gameTime += dt;

    _foodPulse += dt;
    _redFlash = max(0, _redFlash - dt * 4);
    _scoreBounce += (1 - _scoreBounce) * 0.15;

    if (!_dead && !_gameOver) {
      _moveAccum += dt;
      if (_moveAccum >= _moveInterval) {
        _moveAccum -= _moveInterval;
        _tickGame();
      }
      _moveProgress = (_moveAccum / _moveInterval).clamp(0, 1);
    }

    if (_dead) {
      _moveProgress = 1;
      for (final e in _explodingSegs) {
        e.delay -= dt;
        if (e.delay <= 0 && !e.done) {
          e.done = true;
          _emitter.emit(
            position: e.position,
            count: 4,
            color: widget.gameColor,
            speed: 100,
            spread: pi,
            minSize: 2,
            maxSize: 5,
            type: ParticleType.spark,
            lifespan: 0.6,
          );
          HapticService.light();
        }
      }
    }

    _emitter.update(dt);
    _shake.update(dt);

    for (final ft in _floatingTexts) {
      ft.life += dt;
    }
    _floatingTexts.removeWhere((ft) => ft.life >= ft.maxLife);

    if (mounted) setState(() {});
  }

  void _tickGame() {
    _direction = _nextDirection;
    final head = _snake.first;
    _Point newHead;

    switch (_direction) {
      case 'up':
        newHead = _Point(x: head.x.toInt(), y: head.y.toInt() - 1);
        break;
      case 'down':
        newHead = _Point(x: head.x.toInt(), y: head.y.toInt() + 1);
        break;
      case 'left':
        newHead = _Point(x: head.x.toInt() - 1, y: head.y.toInt());
        break;
      case 'right':
      default:
        newHead = _Point(x: head.x.toInt() + 1, y: head.y.toInt());
        break;
    }

    if (newHead.x < 0 || newHead.x >= _gridSize ||
        newHead.y < 0 || newHead.y >= _gridSize) {
      _die();
      return;
    }

    if (_snake.any((s) => s.x.toInt() == newHead.x && s.y.toInt() == newHead.y)) {
      _die();
      return;
    }

    _prevPositions = _snake.map((s) => Offset(s.x, s.y)).toList();
    _snake.insert(0, _SnakeSeg(x: newHead.x.toDouble(), y: newHead.y.toDouble()));

    if (newHead.x.toInt() == _food.x && newHead.y.toInt() == _food.y) {
      _score++;
      widget.onScoreChanged(_score);
      AudioService().play(SoundType.collect);
      HapticService.light();
      _scoreBounce = 1.3;

      final cellSize = _getCellSize();
      final c = _getGameAreaCenter();
      final fx = c.dx + (_food.x - _gridSize / 2 + 0.5) * cellSize;
      final fy = c.dy + (_food.y - _gridSize / 2 + 0.5) * cellSize;

      _emitter.emit(
        position: Offset(fx, fy),
        count: 15,
        color: const Color(0xFFFFD700),
        speed: 130,
        spread: 2 * pi,
        minSize: 2,
        maxSize: 6,
        type: ParticleType.star,
        lifespan: 0.7,
      );

      _floatingTexts.add(_FloatingText(px: fx, py: fy));
      _spawnFood();
    } else {
      _snake.removeLast();
    }

    _nextPositions = _snake.map((s) => Offset(s.x, s.y)).toList();
  }

  void _die() {
    _dead = true;
    _gameOver = true;
    _redFlash = 1;
    _shake.trigger(8, 300);
    AudioService().play(SoundType.gameOver);
    HapticService.heavy();

    final cellSize = _getCellSize();
    final c = _getGameAreaCenter();
    for (int i = 0; i < _snake.length; i++) {
      final s = _snake[i];
      final sx = c.dx + (s.x - _gridSize / 2 + 0.5) * cellSize;
      final sy = c.dy + (s.y - _gridSize / 2 + 0.5) * cellSize;
      _explodingSegs.add(_ExplodingSeg(
        position: Offset(sx, sy),
        delay: i * 0.06,
      ));
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _ticker.stop();
        widget.onGameOver(_score);
      }
    });
  }

  double _getCellSize() {
    final size = MediaQuery.of(context).size.shortestSide - 32;
    return size / _gridSize;
  }

  Offset _getGameAreaCenter() {
    final size = MediaQuery.of(context).size.shortestSide - 32;
    final areaSize = size;
    final available = MediaQuery.of(context).size.width - 32;
    final xOff = (available - areaSize) / 2 + 16;
    final yOff = 16;
    return Offset(xOff + areaSize / 2, yOff + areaSize / 2);
  }

  void _onSwipe(String dir) {
    AudioService().play(SoundType.click);
    if ((dir == 'up' && _direction != 'down') ||
        (dir == 'down' && _direction != 'up') ||
        (dir == 'left' && _direction != 'right') ||
        (dir == 'right' && _direction != 'left')) {
      _nextDirection = dir;
    }
  }

  int _headDirX() {
    if (_direction == 'left') return -1;
    if (_direction == 'right') return 1;
    return 0;
  }

  int _headDirY() {
    if (_direction == 'up') return -1;
    if (_direction == 'down') return 1;
    return 0;
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
                    onPressed: () {
                      _ticker.stop();
                      widget.onGameOver(_score);
                    },
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: AlwaysStoppedAnimation(_scoreBounce),
                    builder: (context, _) => Transform.scale(
                      scale: _scoreBounce,
                      child: Container(
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomPaint(
                              size: Size(size, size),
                              painter: _SnakePainter(
                                snake: _snake,
                                food: _food,
                                gridSize: _gridSize,
                                gameColor: widget.gameColor,
                                moveProgress: _moveProgress,
                                prevPositions: _prevPositions,
                                nextPositions: _nextPositions,
                                foodPulse: _foodPulse,
                                emitter: _emitter,
                                trail: _trail,
                                shake: _shake,
                                redFlash: _redFlash,
                                floatingTexts: _floatingTexts,
                                gameTime: _gameTime,
                                headDirX: _headDirX(),
                                headDirY: _headDirY(),
                              ),
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

class _SnakeSeg {
  double x;
  double y;
  _SnakeSeg({required this.x, required this.y});
}

class _FloatingText {
  double px;
  double py;
  double life = 0;
  final double maxLife = 0.7;
  _FloatingText({required this.px, required this.py});
}

class _ExplodingSeg {
  final Offset position;
  double delay;
  bool done = false;
  _ExplodingSeg({required this.position, required this.delay});
}

class _SnakePainter extends CustomPainter {
  final List<_SnakeSeg> snake;
  final _Point food;
  final int gridSize;
  final Color gameColor;
  final double moveProgress;
  final List<Offset> prevPositions;
  final List<Offset> nextPositions;
  final double foodPulse;
  final ParticleEmitter emitter;
  final TrailEffect trail;
  final ScreenShake shake;
  final double redFlash;
  final List<_FloatingText> floatingTexts;
  final double gameTime;
  final int headDirX;
  final int headDirY;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.gridSize,
    required this.gameColor,
    required this.moveProgress,
    required this.prevPositions,
    required this.nextPositions,
    required this.foodPulse,
    required this.emitter,
    required this.trail,
    required this.shake,
    required this.redFlash,
    required this.floatingTexts,
    required this.gameTime,
    required this.headDirX,
    required this.headDirY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    canvas.save();
    canvas.translate(shake.offset.dx, shake.offset.dy);

    _drawGrid(canvas, size, cellSize);
    _drawFood(canvas, cellSize);
    _drawSnake(canvas, cellSize);
    _drawParticles(canvas);
    _drawFloatingTexts(canvas, cellSize);
    _drawRedFlash(canvas, size);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize) {
    final gridPulse = 0.5 + 0.5 * sin(gameTime * 1.5);

    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final checker = (x + y) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          Paint()..color = checker
              ? Colors.white.withValues(alpha: 0.025)
              : Colors.transparent,
        );
      }
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03 + 0.02 * gridPulse)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), linePaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), linePaint);
    }

    if (snake.isNotEmpty) {
      final head = snake.first;
      final lerpX = prevPositions.isNotEmpty && nextPositions.isNotEmpty
          ? prevPositions[0].dx + (nextPositions[0].dx - prevPositions[0].dx) * moveProgress
          : head.x;
      final lerpY = prevPositions.isNotEmpty && nextPositions.isNotEmpty
          ? prevPositions[0].dy + (nextPositions[0].dy - prevPositions[0].dy) * moveProgress
          : head.y;
      final hx = lerpX * cellSize + cellSize / 2;
      final hy = lerpY * cellSize + cellSize / 2;

      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = gameColor.withValues(alpha: 0.1 + 0.08 * gridPulse);
      canvas.drawCircle(Offset(hx, hy), cellSize * 1.0, glowPaint);
    }
  }

  void _drawFood(Canvas canvas, double cellSize) {
    final fx = food.x * cellSize + cellSize / 2;
    final fy = food.y * cellSize + cellSize / 2;
    final pulse = 0.8 + 0.2 * sin(foodPulse * 5);

    final haloPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.2 + 0.15 * sin(foodPulse * 3));
    canvas.drawCircle(Offset(fx, fy), cellSize * 0.6 * pulse, haloPaint);

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(fx, fy), cellSize * 0.35 * pulse, glowPaint);

    final foodPaint = Paint()..color = const Color(0xFFFF6B6B);
    canvas.drawCircle(Offset(fx, fy), cellSize * 0.3 * pulse, foodPaint);

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(
      Offset(fx - cellSize * 0.08, fy - cellSize * 0.08),
      cellSize * 0.08 * pulse,
      highlightPaint,
    );
  }

  void _drawSnake(Canvas canvas, double cellSize) {
    if (snake.isEmpty) return;

    // interpolate positions
    final positions = <Offset>[];
    for (int i = 0; i < snake.length; i++) {
      final px = i < prevPositions.length ? prevPositions[i].dx : snake[i].x;
      final py = i < prevPositions.length ? prevPositions[i].dy : snake[i].y;
      final nx = i < nextPositions.length ? nextPositions[i].dx : snake[i].x;
      final ny = i < nextPositions.length ? nextPositions[i].dy : snake[i].y;
      final lx = px + (nx - px) * moveProgress;
      final ly = py + (ny - py) * moveProgress;
      positions.add(Offset(lx * cellSize + cellSize / 2, ly * cellSize + cellSize / 2));
    }

    // trail behind tail
    if (snake.length >= 2) {
      trail.draw(canvas, gameColor.withValues(alpha: 0.3), cellSize * 0.3);
    }
    trail.addPoint(positions.last);

    // body
    for (int i = snake.length - 1; i >= 0; i--) {
      final t = i / max(snake.length - 1, 1);
      final pos = positions[i];

      // body wave
      var wx = pos.dx;
      var wy = pos.dy;
      if (i > 0) {
        final waveAmp = cellSize * 0.06 * sin(gameTime * 6 + i * 0.5);
        if (headDirX != 0) {
          wy += waveAmp;
        } else {
          wx += waveAmp;
        }
      }

      final segSize = i == 0 ? cellSize * 0.85 : cellSize * (0.75 - t * 0.2);

      // gradient
      final gradient = RadialGradient(
        colors: [
          gameColor.withValues(alpha: i == 0 ? 1 : 0.9 - t * 0.5),
          gameColor.withValues(alpha: i == 0 ? 0.7 : 0.3 - t * 0.25),
          gameColor.withValues(alpha: 0.05),
        ],
        stops: const [0, 0.6, 1],
      );

      final rect = Rect.fromCenter(center: Offset(wx, wy), width: segSize, height: segSize);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(i == 0 ? segSize * 0.35 : segSize * 0.25));

      canvas.drawRRect(
        rr,
        Paint()
          ..shader = gradient.createShader(rect)
          ..maskFilter = i == 0 ? const MaskFilter.blur(BlurStyle.normal, 1) : null,
      );
    }

    // head eyes
    if (snake.isNotEmpty) {
      final headPos = positions[0];
      final eyeOff = cellSize * 0.18;
      final eyeSize = cellSize * 0.08;
      final pupilSize = cellSize * 0.045;

      for (final side in [-1, 1]) {
        double ex, ey;
        if (headDirX != 0) {
          ex = headPos.dx + headDirX * eyeOff * 0.5;
          ey = headPos.dy + side * eyeOff;
        } else {
          ex = headPos.dx + side * eyeOff;
          ey = headPos.dy + headDirY * eyeOff * 0.5;
        }

        canvas.drawCircle(Offset(ex, ey), eyeSize, Paint()..color = Colors.white);
        canvas.drawCircle(
          Offset(ex + headDirX * pupilSize * 0.5, ey + headDirY * pupilSize * 0.5),
          pupilSize,
          Paint()..color = Colors.black,
        );
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    emitter.draw(canvas);
  }

  void _drawFloatingTexts(Canvas canvas, double cellSize) {
    for (final ft in floatingTexts) {
      final progress = ft.life / ft.maxLife;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final yOff = -20 * progress;

      final tp = TextPainter(
        text: TextSpan(
          text: '+1',
          style: TextStyle(
            color: const Color(0xFFFFD700).withValues(alpha: alpha),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withValues(alpha: alpha * 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(ft.px - tp.width / 2, ft.py - 10 + yOff));
    }
  }

  void _drawRedFlash(Canvas canvas, Size size) {
    if (redFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.red.withValues(alpha: redFlash * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
