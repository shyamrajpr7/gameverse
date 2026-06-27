import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class RacingRivalsGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const RacingRivalsGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<RacingRivalsGame> createState() => _RacingRivalsGameState();
}

class _RacingRivalsGameState extends State<RacingRivalsGame>
    with SingleTickerProviderStateMixin {
  static const double _playerYFrac = 0.78;
  static const int _lanes = 3;
  static const List<double> _laneCenters = [0.25, 0.50, 0.75];
  static const double _carW = 0.07;
  static const double _carH = 0.10;
  static const double _baseSpeed = 0.25;
  static const double _speedPerScore = 0.008;
  static const double _maxSpeed = 0.7;
  static const double _spawnInterval = 1.2;
  static const double _minSpawnInterval = 0.5;
  static const double _opponentChance = 0.35;

  double _playerX = 0.5;
  double _roadSpeed = _baseSpeed;
  double _trackOffset = 0;
  int _score = 0;
  bool _gameOver = false;
  bool _playing = false;

  final List<_RoadObject> _obstacles = [];
  double _spawnTimer = 0;
  double _gameWidth = 1;
  double _gameHeight = 1;

  late Ticker _ticker;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    setState(() {
      _playing = true;
      _gameOver = false;
      _score = 0;
      _playerX = 0.5;
      _roadSpeed = _baseSpeed;
      _trackOffset = 0;
      _obstacles.clear();
      _spawnTimer = 0;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_playing || _gameOver) return;

    final dt = 1 / 60;

    _trackOffset = (_trackOffset + _roadSpeed * dt) % 0.15;
    _roadSpeed = min(_baseSpeed + _score * _speedPerScore, _maxSpeed);

    _spawnTimer += dt;
    final interval = max(_minSpawnInterval, _spawnInterval - _score * 0.015);
    if (_spawnTimer >= interval) {
      _spawnTimer = 0;
      _spawnObject();
    }

    for (int i = _obstacles.length - 1; i >= 0; i--) {
      final obj = _obstacles[i];
      final speed = obj.type == 'opponent' ? _roadSpeed * 0.55 : _roadSpeed;
      obj.y += speed * dt;
      if (obj.y > 1.15) {
        _obstacles.removeAt(i);
        if (obj.type != 'opponent') {
          _score++;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.score);
        }
      }
    }

    for (final obj in _obstacles) {
      if (_checkCollision(obj)) {
        _gameOver = true;
        AudioService().play(SoundType.gameOver);
        HapticService.heavy();
        _ticker.stop();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onGameOver(_score);
        });
        return;
      }
    }

    if (mounted) setState(() {});
  }

  bool _checkCollision(_RoadObject obj) {
    final pW = _carW * _gameWidth;
    final pH = _carH * _gameHeight;
    final pX = _playerX * _gameWidth - pW / 2;
    final pY = _playerYFrac * _gameHeight - pH / 2;

    final oW = obj.type == 'barrier' ? _carW * 1.5 * _gameWidth : _carW * 0.8 * _gameWidth;
    final oH = obj.type == 'cone' ? _carH * 0.5 * _gameHeight : _carH * 0.9 * _gameHeight;
    final laneCenter = _laneCenters[obj.lane] * _gameWidth;
    final oX = laneCenter - oW / 2;
    final oY = obj.y * _gameHeight - oH / 2;

    return pX < oX + oW && pX + pW > oX && pY < oY + oH && pY + pH > oY;
  }

  void _spawnObject() {
    final lane = _rng.nextInt(_lanes);
    final isOpponent = _rng.nextDouble() < _opponentChance;
    _obstacles.add(_RoadObject(
      type: isOpponent ? 'opponent' : (_rng.nextDouble() < 0.5 ? 'cone' : 'barrier'),
      lane: lane,
      y: -0.1 - _rng.nextDouble() * 0.05,
    ));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_playing || _gameOver) return;
    _playerX = (_playerX + details.delta.dx / _gameWidth).clamp(0.08, 0.92);
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
      return _buildStartScreen();
    }
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.gameColor.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.speed, size: 50, color: widget.gameColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Racing Rivals',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag left/right to steer · Avoid obstacles',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.gameColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: widget.gameColor.withValues(alpha: 0.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text('Race!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _gameWidth = constraints.maxWidth;
                    _gameHeight = constraints.maxHeight;
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: CustomPaint(
                        size: Size(_gameWidth, _gameHeight),
                        painter: _RacingPainter(
                          gameColor: widget.gameColor,
                          playerX: _playerX,
                          playerYFrac: _playerYFrac,
                          obstacles: _obstacles,
                          trackOffset: _trackOffset,
                          roadSpeed: _roadSpeed,
                          baseSpeed: _baseSpeed,
                          maxSpeed: _maxSpeed,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, color: widget.gameColor, size: 16),
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: _speedColor(), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${(_roadSpeed / _maxSpeed * 100).toInt()}',
                  style: TextStyle(
                    color: _speedColor(),
                    fontSize: 14,
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

  Color _speedColor() {
    final ratio = _roadSpeed / _maxSpeed;
    if (ratio < 0.4) return const Color(0xFF4ECDC4);
    if (ratio < 0.7) return const Color(0xFFFFD93D);
    return const Color(0xFFFF6B6B);
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '← Drag to steer →',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RoadObject {
  final String type;
  final int lane;
  double y;

  _RoadObject({
    required this.type,
    required this.lane,
    required this.y,
  });
}

class _RacingPainter extends CustomPainter {
  final Color gameColor;
  final double playerX;
  final double playerYFrac;
  final List<_RoadObject> obstacles;
  final double trackOffset;
  final double roadSpeed;
  final double baseSpeed;
  final double maxSpeed;

  _RacingPainter({
    required this.gameColor,
    required this.playerX,
    required this.playerYFrac,
    required this.obstacles,
    required this.trackOffset,
    required this.roadSpeed,
    required this.baseSpeed,
    required this.maxSpeed,
  });

  static const List<double> _laneCenters = [0.25, 0.50, 0.75];

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawRoad(canvas, size);
    _drawTrackMarkings(canvas, size);
    _drawObjects(canvas, size);
    _drawPlayerCar(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0A0A1A);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final groundPaint = Paint()..color = const Color(0xFF0F0F23);
    canvas.drawRect(Offset.zero & size, groundPaint);
  }

  void _drawRoad(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = const Color(0xFF1A1A2E);
    final roadRect = Rect.fromLTWH(
      size.width * 0.12, 0,
      size.width * 0.76, size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(12)),
      roadPaint,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(12)),
      borderPaint,
    );

    final leftLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.15, size.height),
      leftLine,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, 0),
      Offset(size.width * 0.85, size.height),
      leftLine,
    );
  }

  void _drawTrackMarkings(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 3;

    for (int lane = 0; lane < 2; lane++) {
      final x = size.width * (0.30 + lane * 0.20);
      double y = trackOffset * size.height;
      while (y < size.height) {
        final dashH = size.height * 0.04;
        canvas.drawLine(
          Offset(x, y),
          Offset(x, min(y + dashH, size.height)),
          dashPaint,
        );
        y += dashH + size.height * 0.06;
      }
    }
  }

  void _drawObjects(Canvas canvas, Size size) {
    for (final obj in obstacles) {
      final laneX = _laneCenters[obj.lane] * size.width;
      final objY = obj.y * size.height;

      if (obj.type == 'cone') {
        _drawCone(canvas, laneX, objY, size);
      } else if (obj.type == 'barrier') {
        _drawBarrier(canvas, laneX, objY, size);
      } else if (obj.type == 'opponent') {
        _drawOpponentCar(canvas, laneX, objY, size);
      }
    }
  }

  void _drawCone(Canvas canvas, double x, double y, Size size) {
    final w = size.width * 0.04;
    final h = size.height * 0.04;
    final paint = Paint()..color = const Color(0xFFFF8C00);

    final path = Path()
      ..moveTo(x, y - h / 2)
      ..lineTo(x - w / 2, y + h / 2)
      ..lineTo(x + w / 2, y + h / 2)
      ..close();
    canvas.drawPath(path, paint);

    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawLine(
      Offset(x - w * 0.2, y),
      Offset(x + w * 0.2, y),
      stripePaint,
    );
  }

  void _drawBarrier(Canvas canvas, double x, double y, Size size) {
    final w = size.width * 0.1;
    final h = size.height * 0.04;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(width: w, height: h, center: Offset(x, y)),
      const Radius.circular(4),
    );

    final paint = Paint()..color = const Color(0xFFFF6B6B);
    canvas.drawRRect(rect, paint);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rect, stripePaint);

    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(x + i * w * 0.25, y - h / 2),
        Offset(x + i * w * 0.25, y + h / 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawOpponentCar(Canvas canvas, double x, double y, Size size) {
    final w = size.width * 0.07;
    final h = size.height * 0.09;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(width: w, height: h, center: Offset(x, y)),
      const Radius.circular(6),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFE53935), const Color(0xFFB71C1C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);

    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        width: w * 0.6,
        height: h * 0.35,
        center: Offset(x, y - h * 0.05),
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      roofRect,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    final windowPaint = Paint()..color = const Color(0xFF64B5F6).withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          width: w * 0.4,
          height: h * 0.2,
          center: Offset(x, y - h * 0.05),
        ),
        const Radius.circular(2),
      ),
      windowPaint,
    );

    final wheelPaint = Paint()..color = const Color(0xFF212121);
    for (final side in [-1, 1]) {
      canvas.drawCircle(
        Offset(x + side * w * 0.35, y - h * 0.25),
        w * 0.1,
        wheelPaint,
      );
      canvas.drawCircle(
        Offset(x + side * w * 0.35, y + h * 0.25),
        w * 0.1,
        wheelPaint,
      );
    }

    final tailPaint = Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(x, y + h / 2 - 2), w * 0.06, tailPaint);
    canvas.drawCircle(Offset(x - w * 0.15, y + h / 2 - 2), w * 0.04, tailPaint);
    canvas.drawCircle(Offset(x + w * 0.15, y + h / 2 - 2), w * 0.04, tailPaint);
  }

  void _drawPlayerCar(Canvas canvas, Size size) {
    final w = size.width * 0.07;
    final h = size.height * 0.10;
    final x = playerX * size.width;
    final y = playerYFrac * size.height;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(width: w, height: h, center: Offset(x, y)),
      const Radius.circular(8),
    );

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = gameColor.withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(width: w + 10, height: h + 6, center: Offset(x, y)),
        const Radius.circular(10),
      ),
      glowPaint,
    );

    final gradient = LinearGradient(
      colors: [gameColor, gameColor.withValues(alpha: 0.5)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..shader = gradient.createShader(bodyRect.outerRect),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawRRect(bodyRect, borderPaint);

    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        width: w * 0.55,
        height: h * 0.35,
        center: Offset(x, y - h * 0.03),
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      roofRect,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    final windowPaint = Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          width: w * 0.35,
          height: h * 0.2,
          center: Offset(x, y - h * 0.03),
        ),
        const Radius.circular(2),
      ),
      windowPaint,
    );

    final headlightPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(x - w * 0.25, y - h / 2 + 2), w * 0.04, headlightPaint);
    canvas.drawCircle(Offset(x + w * 0.25, y - h / 2 + 2), w * 0.04, headlightPaint);

    final wheelPaint = Paint()..color = const Color(0xFF212121);
    for (final side in [-1, 1]) {
      canvas.drawCircle(
        Offset(x + side * w * 0.32, y - h * 0.25),
        w * 0.09,
        wheelPaint,
      );
      canvas.drawCircle(
        Offset(x + side * w * 0.32, y + h * 0.25),
        w * 0.09,
        wheelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RacingPainter oldDelegate) => true;
}
