import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

class _RacingRivalsGameState extends State<RacingRivalsGame> with TickerProviderStateMixin {
  double _playerY = 0.5;
  double _opponentY = 0.5;
  double _playerSpeed = 0;
  double _obstacleX = 1;
  double _obstacleY = 0.3 + Random().nextDouble() * 0.4;
  int _score = 0;
  bool _playing = false;
  bool _gameOver = false;
  late Timer _gameTimer;
  bool _leftPressed = false;
  bool _rightPressed = false;
  final double _laneWidth = 0.15;
  double _playerLane = 0;

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
    if (!_playing || _gameOver) return;

    setState(() {
      _playerSpeed += 0.0005;
      _playerY -= _playerSpeed;

      if (_leftPressed) _playerLane = (_playerLane - 0.02).clamp(-1.0, 1.0);
      if (_rightPressed) _playerLane = (_playerLane + 0.02).clamp(-1.0, 1.0);

      _opponentY -= _playerSpeed * 0.85;
      if (_opponentY < 0) {
        _opponentY = 1 + Random().nextDouble() * 0.3;
        _score++;
        widget.onScoreChanged(_score);
        AudioService().play(SoundType.notification);
        HapticService.light();
      }

      _obstacleX -= _playerSpeed * 1.2;
      if (_obstacleX < -0.1) {
        _obstacleX = 1;
        _obstacleY = 0.2 + Random().nextDouble() * 0.6;
      }

      final px = _playerLane * _laneWidth;
      final ox = _obstacleX;
      if ((px - ox).abs() < _laneWidth * 0.8 &&
          (_playerY - _obstacleY).abs() < 0.08) {
        _gameOver = true;
        _playing = false;
        widget.onGameOver(_score);
      }

      if (_playerY < -0.1) {
        _gameOver = true;
        _playing = false;
        widget.onGameOver(_score);
      }
    });
  }

  void _startGame() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    setState(() {
      _playing = true;
      _playerY = 0.5;
      _score = 0;
      _playerLane = 0;
      _playerSpeed = 0.005;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) {
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
              const Text('Tap both sides to steer!', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.gameColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Race!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => widget.onGameOver(_score),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, color: widget.gameColor, size: 18),
                        const SizedBox(width: 6),
                        Text('$_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (d) {
                      final mid = constraints.maxWidth / 2;
                      if (d.localPosition.dx < mid) {
                        _leftPressed = true;
                      } else {
                        _rightPressed = true;
                      }
                    },
                    onTapUp: (_) {
                      _leftPressed = false;
                      _rightPressed = false;
                    },
                    onTapCancel: () {
                      _leftPressed = false;
                      _rightPressed = false;
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _RacingPainter(
                        playerY: _playerY,
                        opponentY: _opponentY,
                        playerLane: _playerLane,
                        obstacleX: _obstacleX,
                        obstacleY: _obstacleY,
                        gameColor: widget.gameColor,
                        laneWidth: _laneWidth,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlLabel('LEFT'),
                  Text('Steer', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  _buildControlLabel('RIGHT'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _RacingPainter extends CustomPainter {
  final double playerY;
  final double opponentY;
  final double playerLane;
  final double obstacleX;
  final double obstacleY;
  final Color gameColor;
  final double laneWidth;

  _RacingPainter({
    required this.playerY,
    required this.opponentY,
    required this.playerLane,
    required this.obstacleX,
    required this.obstacleY,
    required this.gameColor,
    required this.laneWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0F0F23);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final trackPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.1, 0, size.width * 0.8, size.height), const Radius.circular(20)),
      trackPaint,
    );

    for (int i = 0; i < 10; i++) {
      final ly = (i * 0.1 * size.height) % size.height;
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.48, ly, size.width * 0.04, size.height * 0.05),
        Paint()..color = Colors.white.withValues(alpha: 0.1),
      );
    }

    final carWidth = size.width * 0.08;
    final carHeight = size.height * 0.06;

    final oppX = size.width * 0.5 - carWidth / 2;
    final oppY = opponentY * size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(oppX, oppY, carWidth, carHeight), const Radius.circular(6)),
      Paint()..color = Colors.red.withValues(alpha: 0.6),
    );

    final px = size.width * 0.5 + playerLane * laneWidth * size.width - carWidth / 2;
    final py = playerY * size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(px, py, carWidth, carHeight), const Radius.circular(6)),
      Paint()..shader = LinearGradient(
        colors: [gameColor, gameColor.withValues(alpha: 0.5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(px, py, carWidth, carHeight)),
    );

    final ox = obstacleX * size.width;
    final oy = obstacleY * size.height;
    canvas.drawCircle(
      Offset(ox, oy),
      8,
      Paint()..color = Colors.orange.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
