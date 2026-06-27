import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class BrickBreakerGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const BrickBreakerGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame>
    with SingleTickerProviderStateMixin {
  static const int _brickRows = 5;
  static const int _brickCols = 7;
  static const double _paddleHeight = 14;
  static const double _paddleWidth = 100;
  static const double _ballRadius = 7;
  static const double _baseSpeed = 350;
  static const double _speedIncrement = 20;
  static const int _speedUpInterval = 10;
  static const double _brickH = 22;
  static const double _brickGap = 6;
  static const double _topOffset = 80;

  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  bool _launched = false;

  double _paddleX = 0;
  double _ballX = 0;
  double _ballY = 0;
  double _ballVx = 0;
  double _ballVy = 0;
  double _ballSpeed = _baseSpeed;
  int _bricksBroken = 0;

  late Ticker _ticker;
  final Random _rng = Random();
  List<List<bool>> _bricks = [];
  double _gameWidth = 0;
  double _gameHeight = 0;
  bool _initialized = false;
  double _paddleTargetX = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
    _resetGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    _score = 0;
    _lives = 3;
    _gameOver = false;
    _launched = false;
    _bricksBroken = 0;
    _ballSpeed = _baseSpeed;
    _bricks = List.generate(
      _brickRows,
      (_) => List.filled(_brickCols, true),
    );
  }

  void _initDimensions(double w, double h) {
    if (_initialized) return;
    _initialized = true;
    _gameWidth = w;
    _gameHeight = h;
    _paddleX = w / 2;
    _paddleTargetX = w / 2;
    _resetBall();
  }

  void _resetBall() {
    _ballX = _paddleX;
    _ballY = _gameHeight - 40 - _paddleHeight / 2 - _ballRadius;
    _ballVx = 0;
    _ballVy = 0;
    _launched = false;
  }

  void _launchBall() {
    if (_launched) return;
    _launched = true;
    final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi / 3;
    _ballVx = cos(angle) * _ballSpeed;
    _ballVy = sin(angle) * _ballSpeed;
    AudioService().play(SoundType.swipe);
    HapticService.light();
  }

  double _brickW() => _gameWidth / _brickCols;

  void _onTick(Duration elapsed) {
    if (_gameOver || !_initialized) return;

    final dt = 1 / 60;

    _paddleX += (_paddleTargetX - _paddleX) * 0.3;

    if (!_launched) {
      _ballX = _paddleX;
      if (mounted) setState(() {});
      return;
    }

    _ballX += _ballVx * dt;
    _ballY += _ballVy * dt;

    if (_ballX - _ballRadius <= 0) {
      _ballX = _ballRadius;
      _ballVx = _ballVx.abs();
    }
    if (_ballX + _ballRadius >= _gameWidth) {
      _ballX = _gameWidth - _ballRadius;
      _ballVx = -_ballVx.abs();
    }
    if (_ballY - _ballRadius <= 0) {
      _ballY = _ballRadius;
      _ballVy = _ballVy.abs();
    }

    final paddleTop = _gameHeight - 40 - _paddleHeight;
    if (_ballVy > 0 &&
        _ballY + _ballRadius >= paddleTop &&
        _ballY + _ballRadius <= paddleTop + 10 &&
        _ballX >= _paddleX - _paddleWidth / 2 &&
        _ballX <= _paddleX + _paddleWidth / 2) {
      _ballY = paddleTop - _ballRadius;
      final hitPos = (_ballX - _paddleX) / (_paddleWidth / 2);
      final angle = -pi / 2 + hitPos * pi / 3;
      final speed = _ballSpeed;
      _ballVx = cos(angle) * speed;
      _ballVy = sin(angle) * speed;
      AudioService().play(SoundType.click);
      HapticService.light();
    }

    final bw = _brickW();
    for (int r = 0; r < _brickRows; r++) {
      for (int c = 0; c < _brickCols; c++) {
        if (!_bricks[r][c]) continue;
        final bx = c * bw;
        final by = _topOffset + r * (_brickH + _brickGap);
        if (_ballX + _ballRadius > bx &&
            _ballX - _ballRadius < bx + bw &&
            _ballY + _ballRadius > by &&
            _ballY - _ballRadius < by + _brickH) {
          _bricks[r][c] = false;
          _score += 10;
          _bricksBroken++;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.collect);
          HapticService.medium();

          if (_bricksBroken % _speedUpInterval == 0) {
            _ballSpeed += _speedIncrement;
            final currentAngle = atan2(_ballVy, _ballVx);
            _ballVx = cos(currentAngle) * _ballSpeed;
            _ballVy = sin(currentAngle) * _ballSpeed;
          }

          final overlapLeft = (_ballX + _ballRadius) - bx;
          final overlapRight = (bx + bw) - (_ballX - _ballRadius);
          final overlapTop = (_ballY + _ballRadius) - by;
          final overlapBottom = (by + _brickH) - (_ballY - _ballRadius);
          final minOverlapX = min(overlapLeft, overlapRight);
          final minOverlapY = min(overlapTop, overlapBottom);
          if (minOverlapX < minOverlapY) {
            _ballVx = -_ballVx;
          } else {
            _ballVy = -_ballVy;
          }

          // prevent double-hit
          break;
        }
      }
    }

    if (_ballY - _ballRadius > _gameHeight) {
      _lives--;
      AudioService().play(SoundType.notification);
      HapticService.medium();
      if (_lives <= 0) {
        _gameOver = true;
        _ticker.stop();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onGameOver(_score);
        });
      } else {
        _resetBall();
      }
    }

    if (!_bricks.any((row) => row.any((b) => b))) {
      _gameOver = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onGameOver(_score);
      });
    }

    if (mounted) setState(() {});
  }

  void _onPanStart(DragStartDetails details) {
    _launchBall();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _paddleTargetX = (_paddleTargetX + details.delta.dx).clamp(
      _paddleWidth / 2,
      _gameWidth - _paddleWidth / 2,
    );
    if (!_launched) {
      _ballX = _paddleTargetX;
      _paddleX = _paddleTargetX;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GestureDetector(
                onTap: _launchBall,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    _initDimensions(w, h);
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: CustomPaint(
                        size: Size(w, h),
                        painter: _BrickBreakerPainter(
                          gameColor: widget.gameColor,
                          paddleX: _paddleX,
                          paddleWidth: _paddleWidth,
                          paddleHeight: _paddleHeight,
                          ballX: _ballX,
                          ballY: _ballY,
                          ballRadius: _ballRadius,
                          bricks: _bricks,
                          brickRows: _brickRows,
                          brickCols: _brickCols,
                          lives: _lives,
                          launched: _launched,
                          gameWidth: w,
                          gameHeight: h,
                          brickH: _brickH,
                          brickGap: _brickGap,
                          topOffset: _topOffset,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
          ...List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < _lives ? Icons.favorite : Icons.favorite_border,
                color: i < _lives ? Colors.red : Colors.red.withValues(alpha: 0.3),
                size: 20,
              ),
            );
          }),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: widget.gameColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _launched ? '← Drag to move paddle →' : 'Tap or drag to launch',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BrickBreakerPainter extends CustomPainter {
  final Color gameColor;
  final double paddleX, paddleWidth, paddleHeight;
  final double ballX, ballY, ballRadius;
  final List<List<bool>> bricks;
  final int brickRows, brickCols;
  final int lives;
  final bool launched;
  final double gameWidth, gameHeight;
  final double brickH, brickGap, topOffset;

  _BrickBreakerPainter({
    required this.gameColor,
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.bricks,
    required this.brickRows,
    required this.brickCols,
    required this.lives,
    required this.launched,
    required this.gameWidth,
    required this.gameHeight,
    required this.brickH,
    required this.brickGap,
    required this.topOffset,
  });

  static const List<Color> _brickColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6C5CE7),
    Color(0xFF4ECDC4),
    Color(0xFFFF8A5C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBricks(canvas);
    _drawPaddle(canvas);
    _drawBall(canvas);
    if (!launched) {
      _drawLaunchPrompt(canvas);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F0F23);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawBricks(Canvas canvas) {
    final bw = gameWidth / brickCols;
    for (int r = 0; r < brickRows; r++) {
      final color = _brickColors[r % _brickColors.length];
      for (int c = 0; c < brickCols; c++) {
        if (!bricks[r][c]) continue;
        final x = c * bw + 2;
        final y = topOffset + r * (brickH + brickGap);
        final w = bw - 4;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, brickH),
          const Radius.circular(4),
        );

        final gradient = LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        canvas.drawRRect(
          rect,
          Paint()..shader = gradient.createShader(rect.outerRect),
        );

        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = color.withValues(alpha: 0.4);
        canvas.drawRRect(rect, borderPaint);

        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.15);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 3, y + 2, w - 6, brickH * 0.4),
            const Radius.circular(2),
          ),
          highlightPaint,
        );
      }
    }
  }

  void _drawPaddle(Canvas canvas) {
    final y = gameHeight - 40 - paddleHeight;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(paddleX, y + paddleHeight / 2),
        width: paddleWidth,
        height: paddleHeight,
      ),
      Radius.circular(paddleHeight / 2),
    );

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = gameColor.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(paddleX, y + paddleHeight / 2),
          width: paddleWidth + 8,
          height: paddleHeight + 4,
        ),
        Radius.circular(paddleHeight / 2 + 2),
      ),
      glowPaint,
    );

    final gradient = LinearGradient(
      colors: [gameColor, gameColor.withValues(alpha: 0.6)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawRRect(
      rect,
      Paint()..shader = gradient.createShader(rect.outerRect),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawRRect(rect, borderPaint);
  }

  void _drawBall(Canvas canvas) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(ballX, ballY), ballRadius * 2, glowPaint);

    final outerGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(ballX, ballY), ballRadius * 1.3, outerGlow);

    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(ballX, ballY), ballRadius, ballPaint);

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(ballX - ballRadius * 0.25, ballY - ballRadius * 0.25),
      ballRadius * 0.35,
      highlightPaint,
    );
  }

  void _drawLaunchPrompt(Canvas canvas) {
    final y = gameHeight - 40 - paddleHeight - 30;
    final tp = TextPainter(
      text: TextSpan(
        text: '▲ TAP TO LAUNCH',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      (gameWidth - tp.width) / 2,
      y - tp.height - 8,
    ));

    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(gameWidth / 2, y - 14)
      ..lineTo(gameWidth / 2 - 8, y - 4)
      ..moveTo(gameWidth / 2, y - 14)
      ..lineTo(gameWidth / 2 + 8, y - 4);
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _BrickBreakerPainter oldDelegate) => true;
}
