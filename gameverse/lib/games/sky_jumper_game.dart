import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class SkyJumperGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const SkyJumperGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<SkyJumperGame> createState() => _SkyJumperGameState();
}

class _SkyJumperGameState extends State<SkyJumperGame> with TickerProviderStateMixin {
  double _playerX = 0.5;
  double _playerY = 0.8;
  double _velocityY = 0;
  double _velocityX = 0;
  final List<_Platform> _platforms = [];
  double _cameraOffset = 0;
  int _score = 0;
  bool _playing = true;
  double? _tapX;
  late Timer _gameTimer;

  @override
  void initState() {
    super.initState();
    _platforms.add(_Platform(x: 0.3, y: 0.9, width: 0.2));
    _platforms.add(_Platform(x: 0.5, y: 0.7, width: 0.2));
    _platforms.add(_Platform(x: 0.2, y: 0.5, width: 0.2));
    _platforms.add(_Platform(x: 0.6, y: 0.3, width: 0.2));
    _platforms.add(_Platform(x: 0.3, y: 0.1, width: 0.2));
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _update(Timer timer) {
    if (!_playing) return;
    const gravity = 0.002;
    const jumpVelocity = -0.025;
    const moveSpeed = 0.008;

    _velocityY += gravity;
    _playerY += _velocityY;
    _playerX += _velocityX;

    if (_tapX != null) {
      final target = _tapX!;
      final diff = target - _playerX;
      if (diff.abs() > 0.02) {
        _velocityX = diff.sign * moveSpeed;
      } else {
        _velocityX = 0;
        _tapX = null;
      }
    } else {
      _velocityX *= 0.9;
    }

    _playerX = _playerX.clamp(0.05, 0.95);

    for (final platform in _platforms) {
      if (_velocityY > 0 &&
          _playerY >= platform.y - _cameraOffset &&
          _playerY <= platform.y - _cameraOffset + 0.03 &&
          _playerX >= platform.x &&
          _playerX <= platform.x + platform.width) {
        _velocityY = jumpVelocity;
        _score++;
        widget.onScoreChanged(_score);
        AudioService().play(SoundType.jump);
        HapticService.light();
      }
    }

    if (_playerY > 1.2) {
      _playing = false;
      widget.onGameOver(_score);
      return;
    }

    if (_playerY < 0.3) {
      _cameraOffset += (0.3 - _playerY);
      _playerY = 0.3;
      final lastPlatform = _platforms.last.y;
      if (lastPlatform < _cameraOffset + 1.5) {
        final rng = Random();
        _platforms.add(_Platform(
          x: rng.nextDouble() * 0.7,
          y: lastPlatform + 0.15 + rng.nextDouble() * 0.1,
          width: 0.12 + rng.nextDouble() * 0.1,
        ));
      }
    }

    _platforms.removeWhere((p) => p.y < _cameraOffset - 0.2);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: GestureDetector(
        onTapDown: (details) {
          AudioService().play(SoundType.click);
          final renderBox = context.findRenderObject() as RenderBox;
          final pos = details.localPosition;
          _tapX = pos.dx / renderBox.size.width;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {

            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _SkyJumperPainter(
                    playerX: _playerX,
                    playerY: _playerY,
                    platforms: _platforms,
                    cameraOffset: _cameraOffset,
                    gameColor: widget.gameColor,
                    score: _score,
                  ),
                ),
                Positioned(
                  top: 44,
                  left: 16,
                  child: SafeArea(
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
                              Icon(Icons.star, color: widget.gameColor, size: 18),
                              const SizedBox(width: 6),
                              Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Platform {
  final double x;
  final double y;
  final double width;
  _Platform({required this.x, required this.y, required this.width});
}

class _SkyJumperPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<_Platform> platforms;
  final double cameraOffset;
  final Color gameColor;
  final int score;

  _SkyJumperPainter({
    required this.playerX,
    required this.playerY,
    required this.platforms,
    required this.cameraOffset,
    required this.gameColor,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = LinearGradient(
      colors: [const Color(0xFF0A0A1A), gameColor.withValues(alpha: 0.3)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (int i = 0; i < 20; i++) {
      final starX = (i * 137.5 + 50) % size.width;
      final starY = (i * 97.3 + 20) % size.height;
      canvas.drawCircle(
        Offset(starX, starY),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.3 + (i % 3) * 0.2),
      );
    }

    for (final platform in platforms) {
      final py = (platform.y - cameraOffset) * size.height;
      if (py < -20 || py > size.height + 20) continue;
      final rect = Rect.fromLTWH(
        platform.x * size.width,
        py,
        platform.width * size.width,
        10,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
      canvas.drawRRect(
        rrect,
        Paint()..shader = LinearGradient(
          colors: [gameColor, gameColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = gameColor.withValues(alpha: 0.3),
      );
    }

    final px = playerX * size.width;
    final py = (playerY - cameraOffset) * size.height;
    final playerPaint = Paint()..shader = RadialGradient(
      colors: [gameColor, gameColor.withValues(alpha: 0.5)],
    ).createShader(Rect.fromCircle(center: Offset(px, py), radius: 14));
    canvas.drawCircle(Offset(px, py), 14, playerPaint);
    canvas.drawCircle(
      Offset(px, py),
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.drawCircle(Offset(px - 3, py - 3), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
