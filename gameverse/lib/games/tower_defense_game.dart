import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class TowerDefenseGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const TowerDefenseGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<TowerDefenseGame> createState() => _TowerDefenseGameState();
}

class _TowerDefenseGameState extends State<TowerDefenseGame>
    with SingleTickerProviderStateMixin {
  static const List<Offset> _path = [
    Offset(1.05, 0.50),
    Offset(0.78, 0.50),
    Offset(0.78, 0.28),
    Offset(0.50, 0.28),
    Offset(0.50, 0.72),
    Offset(0.22, 0.72),
    Offset(0.22, 0.38),
    Offset(-0.05, 0.38),
  ];

  static const double _towerCost = 20;
  static const double _towerRange = 0.12;
  static const double _fireCooldown = 0.45;

  final List<_Enemy> _enemies = [];
  final List<_Tower> _towers = [];
  final List<_Laser> _lasers = [];
  final Random _rng = Random();

  int _score = 0;
  int _gold = 50;
  int _lives = 20;
  int _wave = 0;
  bool _gameOver = false;
  bool _playing = false;

  int _enemiesSpawnedThisWave = 0;
  int _enemiesPerWave = 5;
  double _spawnTimer = 0;
  double _waveAnnounceTimer = 0;
  double _placingRange = 0;

  late Ticker _ticker;

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
      _gold = 50;
      _lives = 20;
      _wave = 0;
      _enemies.clear();
      _towers.clear();
      _lasers.clear();
      _enemiesSpawnedThisWave = 0;
      _enemiesPerWave = 5;
      _spawnTimer = 0;
      _waveAnnounceTimer = 2;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_playing || _gameOver) return;

    final dt = 1 / 60;

    _waveAnnounceTimer = max(0, _waveAnnounceTimer - dt);
    _placingRange = max(0, _placingRange - dt);

    if (_waveAnnounceTimer <= 0) {
      _updateSpawning(dt);
    }

    _updateEnemies(dt);
    _updateTowers(dt);
    _updateLasers(dt);

    if (mounted) setState(() {});
  }

  void _updateSpawning(double dt) {
    if (_enemiesSpawnedThisWave >= _enemiesPerWave) {
      if (_enemies.isEmpty) {
        _wave++;
        _enemiesSpawnedThisWave = 0;
        _enemiesPerWave = 5 + _wave * 2;
        _gold += 10 + _wave * 2;
        _waveAnnounceTimer = 1.5;
        AudioService().play(SoundType.notification);
      }
      return;
    }

    final interval = max(0.3, 1.0 - _wave * 0.04);
    _spawnTimer += dt;
    if (_spawnTimer >= interval) {
      _spawnTimer = 0;
      _enemiesSpawnedThisWave++;
      final isTank = _wave >= 3 && _rng.nextDouble() < 0.2 + _wave * 0.02;
      _enemies.add(_Enemy(
        pathIndex: 0,
        x: _path[0].dx,
        y: _path[0].dy,
        hp: (isTank ? 4 + (_wave ~/ 2) : 1 + (_wave ~/ 3)).toDouble(),
        maxHp: (isTank ? 4 + (_wave ~/ 2) : 1 + (_wave ~/ 3)).toDouble(),
        speed: (isTank ? 0.04 : 0.06) + _wave * 0.004,
        isTank: isTank,
        goldValue: isTank ? 10 : 5,
      ));
    }
  }

  void _updateEnemies(double dt) {
    for (int i = _enemies.length - 1; i >= 0; i--) {
      final e = _enemies[i];
      if (e.pathIndex >= _path.length - 1) {
        _lives--;
        AudioService().play(SoundType.notification);
        HapticService.medium();
        _enemies.removeAt(i);
        if (_lives <= 0) {
          _gameOver = true;
          AudioService().play(SoundType.gameOver);
          HapticService.heavy();
          _ticker.stop();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) widget.onGameOver(_score);
          });
        }
        continue;
      }

      final target = _path[e.pathIndex + 1];
      final dx = target.dx - e.x;
      final dy = target.dy - e.y;
      final dist = sqrt(dx * dx + dy * dy);
      final step = e.speed * dt;

      if (dist < step) {
        e.x = target.dx;
        e.y = target.dy;
        e.pathIndex++;
      } else {
        e.x += (dx / dist) * step;
        e.y += (dy / dist) * step;
      }
    }
  }

  void _updateTowers(double dt) {
    for (final t in _towers) {
      t.cooldown = max(0, t.cooldown - dt);

      _Enemy? closest;
      double closestDist = double.infinity;
      for (final e in _enemies) {
        final dx = e.x - t.x;
        final dy = e.y - t.y;
        final d = dx * dx + dy * dy;
        if (d < t.range * t.range && d < closestDist) {
          closestDist = d;
          closest = e;
        }
      }

      if (closest != null && t.cooldown <= 0) {
        t.cooldown = _fireCooldown;
        closest.hp--;
        _lasers.add(_Laser(
          x1: t.x,
          y1: t.y,
          x2: closest.x,
          y2: closest.y,
        ));
        AudioService().play(SoundType.shoot);

        if (closest.hp <= 0) {
          _enemies.remove(closest);
          _score++;
          _gold += closest.goldValue;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.collect);
          HapticService.medium();
        } else {
          HapticService.light();
        }
      }
    }
  }

  void _updateLasers(double dt) {
    for (int i = _lasers.length - 1; i >= 0; i--) {
      _lasers[i].life += dt;
      if (_lasers[i].life > 0.1) _lasers.removeAt(i);
    }
  }

  void _placeTower(TapDownDetails details, Size size) {
    if (!_playing || _gameOver) return;
    if (_gold < _towerCost) return;

    final tx = details.localPosition.dx / size.width;
    final ty = details.localPosition.dy / size.height;

    for (final t in _towers) {
      if ((t.x - tx).abs() < 0.04 && (t.y - ty).abs() < 0.04) return;
    }

    for (final wp in _path) {
      if ((wp.dx - tx).abs() < 0.03 && (wp.dy - ty).abs() < 0.03) return;
    }

    AudioService().play(SoundType.click);
    HapticService.light();
    setState(() {
      _towers.add(_Tower(x: tx, y: ty, range: _towerRange));
      _gold -= _towerCost.toInt();
      _placingRange = 1.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_playing) return _buildStartScreen();
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
              child: Icon(Icons.shield, size: 50, color: widget.gameColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tower Defense',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to place towers · Defend the path',
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
                    Text('Start',
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onTapDown: (d) => _placeTower(d, size),
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _TDPainter(
                      enemies: _enemies,
                      towers: _towers,
                      lasers: _lasers,
                      path: _path,
                      gameColor: widget.gameColor,
                      placingRange: _placingRange,
                      wave: _wave,
                      waveAnnounceTimer: _waveAnnounceTimer,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
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
                        _badge(Icons.favorite, '$_lives', Colors.red),
                        const SizedBox(width: 4),
                        _badge(Icons.monetization_on, '$_gold', widget.gameColor),
                        const SizedBox(width: 4),
                        _badge(Icons.waves, 'Wave $_wave', Colors.blueAccent),
                        const SizedBox(width: 4),
                        _badge(Icons.emoji_events, '$_score', Colors.amberAccent),
                      ],
                    ),
                  ),
                  if (_gold < _towerCost)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Not enough gold!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Tap to place tower (${_towerCost.toInt()} gold)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Enemy {
  int pathIndex;
  double x, y, hp, maxHp, speed;
  bool isTank;
  int goldValue;

  _Enemy({
    required this.pathIndex,
    required this.x,
    required this.y,
    required this.hp,
    required this.maxHp,
    required this.speed,
    this.isTank = false,
    this.goldValue = 5,
  });
}

class _Tower {
  final double x, y, range;
  double cooldown = 0;

  _Tower({required this.x, required this.y, required this.range});
}

class _Laser {
  final double x1, y1, x2, y2;
  double life = 0;

  _Laser({required this.x1, required this.y1, required this.x2, required this.y2});
}

class _TDPainter extends CustomPainter {
  final List<_Enemy> enemies;
  final List<_Tower> towers;
  final List<_Laser> lasers;
  final List<Offset> path;
  final Color gameColor;
  final double placingRange;
  final int wave;
  final double waveAnnounceTimer;

  _TDPainter({
    required this.enemies,
    required this.towers,
    required this.lasers,
    required this.path,
    required this.gameColor,
    required this.placingRange,
    required this.wave,
    required this.waveAnnounceTimer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPath(canvas, size);
    _drawLasers(canvas, size);
    _drawTowers(canvas, size);
    _drawEnemies(canvas, size);
    _drawWaveAnnouncement(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF0A0A1A), Color(0xFF0F2A0F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    final gs = size.width / 12;
    for (double x = 0; x <= size.width; x += gs) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gs) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF2A1A0A)
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p = Path();
    for (int i = 0; i < path.length; i++) {
      final pt = Offset(path[i].dx * size.width, path[i].dy * size.height);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p, pathPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFF3D2B1A)
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(p, innerPaint);

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final ax = a.dx * size.width;
      final ay = a.dy * size.height;
      final bx = b.dx * size.width;
      final by = b.dy * size.height;
      final segLen = sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
      final nx = (by - ay) / segLen;
      final ny = (ax - bx) / segLen;

      for (double t = 0; t < 1; t += 0.06) {
        final lx = ax + (bx - ax) * t + nx * size.width * 0.015;
        final ly = ay + (by - ay) * t + ny * size.width * 0.015;
        canvas.drawCircle(Offset(lx, ly), 1.5, dashPaint);
      }
    }
  }

  void _drawLasers(Canvas canvas, Size size) {
    for (final l in lasers) {
      final t = (l.life / 0.1).clamp(0.0, 1.0);
      final alpha = (1 - t).toDouble();
      final glow = Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: alpha * 0.3)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(l.x1 * size.width, l.y1 * size.height),
        Offset(l.x2 * size.width, l.y2 * size.height),
        glow,
      );

      final line = Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: alpha * 0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(l.x1 * size.width, l.y1 * size.height),
        Offset(l.x2 * size.width, l.y2 * size.height),
        line,
      );
    }
  }

  void _drawTowers(Canvas canvas, Size size) {
    for (final t in towers) {
      final cx = t.x * size.width;
      final cy = t.y * size.height;

      final rangePaint = Paint()
        ..color = gameColor.withValues(alpha: 0.06);
      canvas.drawCircle(Offset(cx, cy), t.range * size.width, rangePaint);

      final rangeBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = gameColor.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(cx, cy), t.range * size.width, rangeBorder);

      final basePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            gameColor.withValues(alpha: 0.9),
            gameColor.withValues(alpha: 0.4),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 14));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 24),
          const Radius.circular(4),
        ),
        basePaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 24),
          const Radius.circular(4),
        ),
        borderPaint,
      );

      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );

      final gunPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + 6, cy - 8),
        gunPaint,
      );
    }
  }

  void _drawEnemies(Canvas canvas, Size size) {
    for (final e in enemies) {
      final cx = e.x * size.width;
      final cy = e.y * size.height;
      final r = e.isTank ? 12.0 : 8.0;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx + 2, cy + 2), r, shadowPaint);

      if (!e.isTank) {
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFE74C3C).withValues(alpha: 0.9),
              const Color(0xFFC0392B).withValues(alpha: 0.7),
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

        canvas.drawCircle(
          Offset(cx - r * 0.2, cy - r * 0.2),
          r * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.15),
        );
      } else {
        final bodyPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF8E44AD).withValues(alpha: 0.9),
              const Color(0xFF6C3483).withValues(alpha: 0.7),
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFBB8FCE).withValues(alpha: 0.5);
        canvas.drawCircle(Offset(cx, cy), r, ringPaint);
      }

      if (e.hp < e.maxHp) {
        final barW = r * 2.5;
        final barH = 3.0;
        final barY = cy - r - 6;
        final ratio = (e.hp / e.maxHp).clamp(0.0, 1.0);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, barY),
              width: barW + 2,
              height: barH,
            ),
            const Radius.circular(1.5),
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.5),
        );

        final hpColor = ratio > 0.5
            ? Color.lerp(Colors.yellow, Colors.green, (ratio - 0.5) * 2)!
            : Color.lerp(Colors.red, Colors.yellow, ratio * 2)!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx - (1 - ratio) * barW / 2, barY),
              width: barW * ratio,
              height: barH - 1,
            ),
            const Radius.circular(1),
          ),
          Paint()..color = hpColor,
        );
      }
    }
  }

  void _drawWaveAnnouncement(Canvas canvas, Size size) {
    if (waveAnnounceTimer <= 0) return;
    final t = (1.5 - waveAnnounceTimer) / 1.5;
    final alpha = t < 0.15
        ? (t / 0.15 * 255).round().clamp(0, 255)
        : t > 0.7
            ? ((1 - t) / 0.3 * 255).round().clamp(0, 255)
            : 255;
    final scale = t < 0.15
        ? 0.5 + t / 0.15 * 0.5
        : t < 0.35
            ? 1.0
            : 1.0 - (t - 0.35) * 0.2;

    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.25);
    canvas.scale(scale, scale);

    final shadowPaint = Paint()
      ..color = gameColor.withAlpha(alpha ~/ 3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset.zero, 50, shadowPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'WAVE $wave',
        style: TextStyle(
          color: gameColor.withAlpha(alpha),
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: Colors.orange.withValues(alpha: alpha / 255 * 0.4),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TDPainter oldDelegate) => true;
}
