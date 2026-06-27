import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../utils/particle_system.dart';

class ZombieSurvivalGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const ZombieSurvivalGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<ZombieSurvivalGame> createState() => _ZombieSurvivalGameState();
}

class _ZombieSurvivalGameState extends State<ZombieSurvivalGame> {
  final List<_Zombie> _zombies = [];
  final Random _rng = Random();
  int _score = 0;
  int _health = 100;
  double _healthDisplay = 100;
  bool _gameOver = false;
  double _playerX = 0.5;
  double _playerY = 0.85;
  double _playerDirX = 0;
  double _playerDirY = -1;
  late Timer _gameTimer;
  int _spawnCounter = 0;
  int _wave = 1;
  double _waveAnnounceTimer = 0;
  double _time = 0;
  double _damageFlash = 0;

  final ParticleEmitter _emitter = ParticleEmitter();
  final ScreenShake _shake = ScreenShake();
  final List<_FogParticle> _fogParticles = [];
  final List<_BodyPart> _bodyParts = [];
  final List<_KillText> _killTexts = [];

  late Stopwatch _stopwatch;
  double _lastTime = 0;
  Size _gameSize = Size.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _initFog();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _update);
  }

  void _initFog() {
    for (int i = 0; i < 8; i++) {
      _fogParticles.add(_FogParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 0.12 + _rng.nextDouble() * 0.2,
        dx: (-0.15 + _rng.nextDouble() * 0.3) * 0.001,
        dy: (-0.08 + _rng.nextDouble() * 0.16) * 0.001,
        opacity: 0.06 + _rng.nextDouble() * 0.08,
      ));
    }
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _update(Timer timer) {
    final now = _stopwatch.elapsedMilliseconds / 1000;
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    _time += dt;

    if (_gameOver) return;

    setState(() {
      _updateWave();
      _updateSpawn();
      _updateZombies(dt);
      _emitter.update(dt);
      _updateFog(dt);
      _updateBodyParts(dt);
      _updateKillTexts(dt);
      _shake.update(dt);
      _healthDisplay += (_health - _healthDisplay) * 6 * dt;
      _waveAnnounceTimer = max(0, _waveAnnounceTimer - dt);
      _damageFlash = max(0, _damageFlash - dt * 2.5);
    });
  }

  void _updateWave() {
    final expected = (_score ~/ 20) + 1;
    if (_score > 0 && expected > _wave) {
      _wave = expected;
      _waveAnnounceTimer = 2.5;
    }
  }

  void _updateSpawn() {
    _spawnCounter++;
    final interval = (55 - _wave * 3).clamp(12, 55);
    if (_spawnCounter % interval == 0) {
      final isBig = _rng.nextDouble() < 0.3 + _wave * 0.02;
      _zombies.add(_Zombie(
        x: 0.05 + _rng.nextDouble() * 0.9,
        y: -0.08 - _rng.nextDouble() * 0.06,
        speed: isBig
            ? 0.0008 + _rng.nextDouble() * 0.002 + _wave * 0.00025
            : 0.003 + _rng.nextDouble() * 0.004 + _wave * 0.0004,
        health: isBig ? (2 + _wave ~/ 2) : 1,
        size: isBig ? 0.05 + _rng.nextDouble() * 0.025 : 0.022 + _rng.nextDouble() * 0.016,
        isBig: isBig,
      ));
    }
  }

  void _updateZombies(double dt) {
    for (int i = _zombies.length - 1; i >= 0; i--) {
      final z = _zombies[i];
      z.y += z.speed;
      z.x += sin(_score * 0.1 + i * 1.7) * 0.0008;
      z.shamblePhase += dt * (z.isBig ? 2.5 : 5);

      z.trailPoints.insert(0, Offset(z.x * _gameSize.width, z.y * _gameSize.height));
      if (z.trailPoints.length > 12) z.trailPoints.removeLast();

      final dx = (_playerX - z.x).abs();
      final dy = (_playerY - z.y).abs();
      if (dx < 0.04 && dy < 0.04) {
        _health -= 10;
        _damageFlash = 1.0;
        _shake.trigger(10, 250);
        HapticService.heavy();
        if (z.health > 0) {
          z.health = 0;
          final px = z.x * _gameSize.width;
          final py = z.y * _gameSize.height;
          _emitter.emit(
            position: Offset(px, py),
            count: 12,
            color: const Color(0xFF2ECC71),
            speed: 50,
            spread: pi,
            lifespan: 0.5,
          );
        }
        if (_health <= 0) {
          _gameOver = true;
          widget.onGameOver(_score);
          return;
        }
      }
    }
    _zombies.removeWhere((z) => z.y > 1.15 || z.health <= 0);
  }

  void _updateFog(double dt) {
    for (final f in _fogParticles) {
      f.x += f.dx * dt * 60;
      f.y += f.dy * dt * 60;
      if (f.x < -0.3) f.x = 1.3;
      if (f.x > 1.3) f.x = -0.3;
      if (f.y < -0.3) f.y = 1.3;
      if (f.y > 1.3) f.y = -0.3;
    }
  }

  void _updateBodyParts(double dt) {
    for (int i = _bodyParts.length - 1; i >= 0; i--) {
      final bp = _bodyParts[i];
      bp.vy += 350 * dt;
      bp.x += bp.vx * dt;
      bp.y += bp.vy * dt;
      bp.rotation += bp.rotationSpeed * dt;
      bp.life += dt;
      if (bp.life >= bp.maxLife) _bodyParts.removeAt(i);
    }
  }

  void _updateKillTexts(double dt) {
    for (int i = _killTexts.length - 1; i >= 0; i--) {
      final kt = _killTexts[i];
      kt.life += dt;
      kt.py -= 40 * dt;
      if (kt.life >= kt.maxLife) _killTexts.removeAt(i);
    }
  }

  void _onTap(TapDownDetails details, Size size) {
    if (_gameOver) return;
    _gameSize = size;
    final tx = details.localPosition.dx / size.width;
    final ty = details.localPosition.dy / size.height;

    for (int i = _zombies.length - 1; i >= 0; i--) {
      final z = _zombies[i];
      if ((tx - z.x).abs() < z.size * 2 && (ty - z.y).abs() < z.size * 2) {
        z.health--;
        if (z.health <= 0) {
          final zx = z.x * size.width;
          final zy = z.y * size.height;
          _emitter.emitBurst(
            position: Offset(zx, zy),
            color: const Color(0xFF2ECC71),
            baseSpeed: 180,
            lifespan: 0.8,
          );
          _emitter.emit(
            position: Offset(zx, zy),
            count: 25,
            color: const Color(0xFF66FF66),
            speed: 220,
            spread: 2 * pi,
            minSize: 3,
            maxSize: 9,
            type: ParticleType.spark,
            lifespan: 0.6,
          );
          _emitter.emit(
            position: Offset(zx, zy),
            count: 12,
            color: Colors.red.withValues(alpha: 0.8),
            speed: 100,
            spread: pi * 0.8,
            minSize: 2,
            maxSize: 6,
            type: ParticleType.circle,
            lifespan: 0.3,
          );
          for (int j = 0; j < 6; j++) {
            _bodyParts.add(_BodyPart(
              x: zx,
              y: zy,
              vx: (_rng.nextDouble() - 0.5) * 250,
              vy: -100 - _rng.nextDouble() * 200,
              size: 4 + _rng.nextDouble() * 7,
              color: const Color(0xFF2ECC71).withValues(alpha: 0.9),
              rotationSpeed: (_rng.nextDouble() - 0.5) * 12,
            ));
          }
          _killTexts.add(_KillText(px: tx, py: ty));
          _shake.trigger(5, 150);
          _zombies.removeAt(i);
          _score++;
          widget.onScoreChanged(_score);
          AudioService().play(SoundType.shoot);
          HapticService.light();
        }
        return;
      }
    }

    final dx = (tx - _playerX) * 3;
    final dy = (ty - _playerY) * 3;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 0.001) {
      _playerDirX = dx / dist;
      _playerDirY = dy / dist;
      _playerX += _playerDirX * 0.02;
      _playerY += _playerDirY * 0.02;
      _playerX = _playerX.clamp(0.05, 0.95);
      _playerY = _playerY.clamp(0.4, 0.95);

      final px = _playerX * _gameSize.width;
      final py = _playerY * _gameSize.height;
      _emitter.emit(
        position: Offset(px, py + 8),
        count: 1,
        color: Colors.brown.withValues(alpha: 0.25),
        speed: 12,
        spread: pi * 0.4,
        minSize: 1,
        maxSize: 3,
        type: ParticleType.square,
        gravity: 25,
        lifespan: 0.35,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (!_initialized) _initialized = true;
            return GestureDetector(
              onTapDown: (d) => _onTap(d, _gameSize),
              child: Stack(
                children: [
                  CustomPaint(
                    size: _gameSize,
                    painter: _ZombieSurvivalPainter(
                      zombies: _zombies,
                      playerX: _playerX,
                      playerY: _playerY,
                      playerDirX: _playerDirX,
                      playerDirY: _playerDirY,
                      health: _health,
                      healthDisplay: _healthDisplay,
                      gameColor: widget.gameColor,
                      particles: _emitter.particles,
                      fogParticles: _fogParticles,
                      bodyParts: _bodyParts,
                      killTexts: _killTexts,
                      waveAnnounceTimer: _waveAnnounceTimer,
                      wave: _wave,
                      shake: _shake,
                      damageFlash: _damageFlash,
                      time: _time,
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
                          onPressed: () => widget.onGameOver(_score),
                        ),
                        const Spacer(),
                        _buildStat(Icons.favorite, '$_health', Colors.red),
                        const SizedBox(width: 8),
                        _buildStat(Icons.emoji_events, '$_score', widget.gameColor),
                        const SizedBox(width: 8),
                        _buildStat(Icons.waves, 'Wave $_wave', Colors.blueAccent),
                      ],
                    ),
                  ),
                  if (!_gameOver)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Tap zombies to shoot | Tap ground to move',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
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

  Widget _buildStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Zombie {
  double x;
  double y;
  double speed;
  int health;
  double size;
  bool isBig;
  double shamblePhase = 0;
  final List<Offset> trailPoints = [];

  _Zombie({
    required this.x,
    required this.y,
    required this.speed,
    required this.health,
    required this.size,
    required this.isBig,
  });
}

class _FogParticle {
  double x;
  double y;
  final double radius;
  final double dx;
  final double dy;
  final double opacity;

  _FogParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.dx,
    required this.dy,
    required this.opacity,
  });
}

class _BodyPart {
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final Color color;
  final double rotationSpeed;
  double rotation = 0;
  double life = 0;
  final double maxLife = 0.7;

  _BodyPart({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

class _KillText {
  double px;
  double py;
  double life = 0;
  final double maxLife = 0.9;

  _KillText({required this.px, required this.py});
}

class _ZombieSurvivalPainter extends CustomPainter {
  final List<_Zombie> zombies;
  final double playerX;
  final double playerY;
  final double playerDirX;
  final double playerDirY;
  final int health;
  final double healthDisplay;
  final Color gameColor;
  final List<Particle> particles;
  final List<_FogParticle> fogParticles;
  final List<_BodyPart> bodyParts;
  final List<_KillText> killTexts;
  final double waveAnnounceTimer;
  final int wave;
  final ScreenShake shake;
  final double damageFlash;
  final double time;

  _ZombieSurvivalPainter({
    required this.zombies,
    required this.playerX,
    required this.playerY,
    required this.playerDirX,
    required this.playerDirY,
    required this.health,
    required this.healthDisplay,
    required this.gameColor,
    required this.particles,
    required this.fogParticles,
    required this.bodyParts,
    required this.killTexts,
    required this.waveAnnounceTimer,
    required this.wave,
    required this.shake,
    required this.damageFlash,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(shake.offset.dx, shake.offset.dy);

    _drawBackground(canvas, size);
    _drawFog(canvas, size);
    _drawZombieTrails(canvas, size);
    _drawZombies(canvas, size);
    _drawBodyParts(canvas);
    _drawParticles(canvas);
    _drawGround(canvas, size);
    _drawPlayer(canvas, size);
    _drawKillTexts(canvas, size);
    _drawWaveAnnouncement(canvas, size);
    _drawVignette(canvas, size);
    _drawDamageFlash(canvas, size);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final danger = (zombies.length / 15).clamp(0.0, 1.0);
    final r = (0.02 + danger * 0.06).toDouble();
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromARGB(255, 8 + (r * 255).round(), 8, 20),
          Color.fromARGB(255, 5 + (r * 127).round(), 5, 16),
        ],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
  }

  void _drawFog(Canvas canvas, Size size) {
    for (final f in fogParticles) {
      final fx = f.x * size.width;
      final fy = f.y * size.height;
      final r = f.radius * size.width;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: f.opacity * 0.5),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(fx, fy), radius: r));
      canvas.drawCircle(Offset(fx, fy), r, paint);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundY = size.height * 0.82;
    final groundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF14140A),
          const Color(0xFF0A140A),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, groundY, size.width, size.height * 0.18));
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height * 0.18), groundPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (int i = 0; i < size.width / 40; i++) {
      final lx = i * 40.0 + (time * 20 % 40);
      canvas.drawLine(Offset(lx, groundY + 5), Offset(lx, size.height), linePaint);
    }
  }

  void _drawZombieTrails(Canvas canvas, Size size) {
    for (final z in zombies) {
      final pts = z.trailPoints;
      if (pts.length < 2) continue;
      for (int i = 0; i < pts.length - 1; i++) {
        final t = i / (pts.length - 1);
        final alpha = ((1 - t) * 0.35 * 255).round().clamp(0, 255);
        final w = 3 + (1 - t) * 5;
        final paint = Paint()
          ..color = const Color(0xFF2ECC71).withAlpha(alpha)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.4);
        canvas.drawLine(pts[i], pts[i + 1], paint);
      }
    }
  }

  void _drawZombies(Canvas canvas, Size size) {
    for (final z in zombies) {
      final zx = z.x * size.width;
      final zy = z.y * size.height;
      final sz = z.size * size.width;
      final shambleX = sin(z.shamblePhase * 3) * sz * 0.08;
      final shambleY = cos(z.shamblePhase * 2.5).abs() * sz * 0.06;

      canvas.save();
      canvas.translate(zx + shambleX, zy + shambleY);

      _drawZombieBody(canvas, sz, z);

      canvas.restore();
    }
  }

  void _drawZombieBody(Canvas canvas, double sz, _Zombie z) {
    if (!z.isBig) {
      _drawFastZombie(canvas, sz, z);
    } else {
      _drawBigZombie(canvas, sz, z);
    }

    final eyeGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF00).withValues(alpha: 0.9),
          const Color(0xFF00FF00).withValues(alpha: 0.4),
          const Color(0xFF00FF00).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(-sz * 0.22, -sz * 0.25), radius: sz * 0.25));
    canvas.drawCircle(Offset(-sz * 0.22, -sz * 0.25), sz * 0.2, eyeGlow);

    final eyeGlow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF00).withValues(alpha: 0.9),
          const Color(0xFF00FF00).withValues(alpha: 0.4),
          const Color(0xFF00FF00).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(sz * 0.22, -sz * 0.25), radius: sz * 0.25));
    canvas.drawCircle(Offset(sz * 0.22, -sz * 0.25), sz * 0.2, eyeGlow2);

    const eyeDot = Color(0xCC00FF00);
    canvas.drawCircle(Offset(-sz * 0.22, -sz * 0.25), sz * 0.06, Paint()..color = eyeDot);
    canvas.drawCircle(Offset(sz * 0.22, -sz * 0.25), sz * 0.06, Paint()..color = eyeDot);
  }

  void _drawFastZombie(Canvas canvas, double sz, _Zombie z) {
    final bodyColor = const Color(0xFF2ECC71).withValues(alpha: z.health > 1 ? 0.65 : 0.85);
    final skinColor = const Color(0xFF6B8E6B);
    final darkSkin = const Color(0xFF4A6B4A);

    final body = Path()
      ..moveTo(0, -sz * 0.35)
      ..quadraticBezierTo(sz * 0.3, -sz * 0.2, sz * 0.25, sz * 0.2)
      ..lineTo(sz * 0.15, sz * 0.35)
      ..lineTo(-sz * 0.15, sz * 0.35)
      ..lineTo(-sz * 0.25, sz * 0.2)
      ..quadraticBezierTo(-sz * 0.3, -sz * 0.2, 0, -sz * 0.35)
      ..close();
    canvas.drawPath(body, Paint()..color = bodyColor);

    final head = Path()
      ..addOval(Rect.fromCenter(center: Offset(0, -sz * 0.45), width: sz * 0.5, height: sz * 0.45));
    canvas.drawPath(head, Paint()..color = skinColor);

    canvas.drawCircle(Offset(-sz * 0.15, -sz * 0.35), sz * 0.06, Paint()..color = darkSkin);
    canvas.drawCircle(Offset(sz * 0.15, -sz * 0.35), sz * 0.06, Paint()..color = darkSkin);

    if (z.health > 1) {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.orange.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(0, 0), sz * 0.5, outline);
    }
  }

  void _drawBigZombie(Canvas canvas, double sz, _Zombie z) {
    final bodyColor = const Color(0xFF27AE60).withValues(alpha: 0.8);
    final skinColor = const Color(0xFF5A7A5A);
    final darkSkin = const Color(0xFF3A5A3A);

    final body = Path()
      ..moveTo(0, -sz * 0.4)
      ..quadraticBezierTo(sz * 0.35, -sz * 0.15, sz * 0.3, sz * 0.25)
      ..lineTo(sz * 0.2, sz * 0.45)
      ..lineTo(-sz * 0.2, sz * 0.45)
      ..lineTo(-sz * 0.3, sz * 0.25)
      ..quadraticBezierTo(-sz * 0.35, -sz * 0.15, 0, -sz * 0.4)
      ..close();
    canvas.drawPath(body, Paint()..color = bodyColor);

    final head = Path()
      ..addOval(Rect.fromCenter(center: Offset(0, -sz * 0.55), width: sz * 0.6, height: sz * 0.55));
    canvas.drawPath(head, Paint()..color = skinColor);

    canvas.drawCircle(Offset(-sz * 0.18, -sz * 0.45), sz * 0.08, Paint()..color = darkSkin);
    canvas.drawCircle(Offset(sz * 0.18, -sz * 0.45), sz * 0.08, Paint()..color = darkSkin);

    final mouth = Path()
      ..moveTo(-sz * 0.12, -sz * 0.3)
      ..quadraticBezierTo(0, -sz * 0.22, sz * 0.12, -sz * 0.3)
      ..quadraticBezierTo(0, -sz * 0.28, -sz * 0.12, -sz * 0.3)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFF1A3A1A));

    canvas.drawLine(
      Offset(-sz * 0.15, sz * 0.3),
      Offset(-sz * 0.3, sz * 0.55),
      Paint()
        ..color = darkSkin
        ..strokeWidth = sz * 0.12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(sz * 0.15, sz * 0.3),
      Offset(sz * 0.3, sz * 0.55),
      Paint()
        ..color = darkSkin
        ..strokeWidth = sz * 0.12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(-sz * 0.1, sz * 0.35),
      Offset(-sz * 0.2, sz * 0.6),
      Paint()
        ..color = darkSkin
        ..strokeWidth = sz * 0.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(sz * 0.1, sz * 0.35),
      Offset(sz * 0.2, sz * 0.6),
      Paint()
        ..color = darkSkin
        ..strokeWidth = sz * 0.1
        ..strokeCap = StrokeCap.round,
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.orange.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(0, 0), sz * 0.55, outline);
  }

  void _drawBodyParts(Canvas canvas) {
    for (final bp in bodyParts) {
      canvas.save();
      canvas.translate(bp.x, bp.y);
      canvas.rotate(bp.rotation);
      final t = (bp.life / bp.maxLife).clamp(0.0, 1.0);
      final alpha = ((1 - t) * bp.color.a).round().clamp(0, 255);
      final paint = Paint()
        ..color = bp.color.withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: bp.size, height: bp.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final alpha = (p.alpha * p.color.a * 255).round().clamp(0, 255);
      final drawColor = p.color.withAlpha(alpha);
      final s = p.size * p.scale;

      switch (p.type) {
        case ParticleType.circle:
          final paint = Paint()
            ..color = drawColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case ParticleType.square:
          final paint = Paint()
            ..color = drawColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), paint);
        case ParticleType.spark:
          final paint = Paint()
            ..color = drawColor
            ..strokeWidth = s * 0.3
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawLine(Offset(-s / 2, 0), Offset(s / 2, 0), paint);
        case ParticleType.star:
          _drawStar(canvas, drawColor, s);
        case ParticleType.ring:
          final paint = Paint()
            ..color = drawColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.25;
          canvas.drawCircle(Offset.zero, s / 2, paint);
        case ParticleType.trail:
          final paint = Paint()
            ..color = drawColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), paint);
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final r = size / 2;
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * pi / 5) - pi / 2;
      final innerAngle = outerAngle + (2 * pi / 5) / 2;
      final ox = cos(outerAngle) * r;
      final oy = sin(outerAngle) * r;
      final ix = cos(innerAngle) * r * 0.4;
      final iy = sin(innerAngle) * r * 0.4;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final px = playerX * size.width;
    final py = playerY * size.height;
    final angle = atan2(playerDirY, playerDirX);
    final flicker = 0.95 + sin(time * 13 + playerX * 100) * 0.05;

    final flashlight = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF8E1).withValues(alpha: 0.12 * flicker),
          const Color(0xFFFFF8E1).withValues(alpha: 0.03 * flicker),
          Colors.transparent,
        ],
        stops: const [0, 0.3, 0.7],
      ).createShader(Rect.fromCircle(center: Offset(px, py), radius: size.width * 0.4));
    canvas.drawCircle(Offset(px, py), size.width * 0.4, flashlight);

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(angle + pi / 2);
    canvas.scale(-1, 1);

    final bodyPaint = Paint()..color = gameColor;
    final darkPaint = Paint()..color = gameColor.withValues(alpha: 0.7);

    final legs = Path()
      ..moveTo(-5, 5)
      ..lineTo(-4, 16)
      ..lineTo(-2, 16)
      ..lineTo(-2, 7)
      ..lineTo(2, 7)
      ..lineTo(2, 16)
      ..lineTo(4, 16)
      ..lineTo(5, 5)
      ..close();
    canvas.drawPath(legs, darkPaint);

    final torso = Path()
      ..moveTo(-7, -2)
      ..lineTo(-8, 8)
      ..lineTo(-5, 10)
      ..lineTo(-2, 8)
      ..lineTo(2, 8)
      ..lineTo(5, 10)
      ..lineTo(8, 8)
      ..lineTo(7, -2)
      ..close();
    canvas.drawPath(torso, bodyPaint);

    final arms = Path()
      ..moveTo(-8, 0)
      ..lineTo(-12, 6)
      ..lineTo(-11, 8)
      ..lineTo(-7, 4)
      ..lineTo(-7, 2)
      ..close()
      ..moveTo(8, 0)
      ..lineTo(12, 6)
      ..lineTo(11, 8)
      ..lineTo(7, 4)
      ..lineTo(7, 2)
      ..close();
    canvas.drawPath(arms, darkPaint);

    final head = Path()
      ..addOval(Rect.fromCenter(center: Offset(0, -6), width: 10, height: 9));
    canvas.drawPath(head, Paint()..color = const Color(0xFFFFDBB4));

    canvas.drawCircle(Offset(-2.5, -7), 1.5, Paint()..color = const Color(0xFF333333));
    canvas.drawCircle(Offset(2.5, -7), 1.5, Paint()..color = const Color(0xFF333333));

    canvas.restore();

    final healthBarWidth = 30.0;
    final healthBarY = py - 30;
    final healthRatio = (healthDisplay / 100).clamp(0.0, 1.0);
    final healthColor = healthRatio > 0.5
        ? Color.lerp(Colors.yellow, Colors.green, (healthRatio - 0.5) * 2)!
        : Color.lerp(Colors.red, Colors.yellow, healthRatio * 2)!;

    final bgBar = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px, healthBarY), width: healthBarWidth + 4, height: 5),
        const Radius.circular(2.5),
      ),
      bgBar,
    );

    final fillBar = Paint()..color = healthColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px - (1 - healthRatio) * healthBarWidth / 2, healthBarY),
            width: healthBarWidth * healthRatio, height: 3),
        const Radius.circular(1.5),
      ),
      fillBar,
    );
  }

  void _drawKillTexts(Canvas canvas, Size size) {
    for (final kt in killTexts) {
      final t = (kt.life / kt.maxLife).clamp(0.0, 1.0);
      final alpha = ((1 - t) * 255).round().clamp(0, 255);
      final scale = 1.0 + t * 0.3;

      canvas.save();
      canvas.translate(kt.px * size.width, kt.py * size.height);
      canvas.scale(scale, scale);

      final tp = TextPainter(
        text: TextSpan(
          text: 'KILL!',
          style: TextStyle(
            color: Colors.red.withAlpha(alpha),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.yellow.withValues(alpha: alpha / 255 * 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  void _drawWaveAnnouncement(Canvas canvas, Size size) {
    if (waveAnnounceTimer <= 0) return;
    final t = (2.5 - waveAnnounceTimer) / 2.5;
    final alpha = t < 0.15
        ? (t / 0.15 * 255).round().clamp(0, 255)
        : t > 0.7
            ? ((1 - t) / 0.3 * 255).round().clamp(0, 255)
            : 255;
    final scale = t < 0.15
        ? t / 0.15 * 1.2
        : t < 0.35
            ? 1.2 - (t - 0.15) / 0.2 * 0.2
            : 1.0;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2.5);
    canvas.scale(scale, scale);

    final shadowPaint = Paint()
      ..color = Colors.red.withAlpha(alpha ~/ 3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 60, shadowPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'WAVE $wave',
        style: TextStyle(
          color: Colors.red.withAlpha(alpha),
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: Colors.orange.withValues(alpha: alpha / 255 * 0.5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  void _drawVignette(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.5),
          Colors.black.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
        center: Alignment.center,
        radius: 0.7,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  void _drawDamageFlash(Canvas canvas, Size size) {
    if (damageFlash <= 0) return;
    final alpha = (damageFlash * 180).round().clamp(0, 180);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.red.withAlpha(alpha),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
