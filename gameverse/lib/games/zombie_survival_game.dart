import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

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

class _ZombieSurvivalGameState extends State<ZombieSurvivalGame>
    with SingleTickerProviderStateMixin {
  static const double _bulletSpeed = 0.9;
  static const double _playerRadius = 0.025;
  static const double _zombieContactDist = 0.035;

  final List<_Zombie> _zombies = [];
  final List<_Bullet> _bullets = [];
  final List<_BloodSplatter> _bloodSplatters = [];
  final List<_FogParticle> _fogParticles = [];
  final List<_KillText> _killTexts = [];
  final Random _rng = Random();

  double _playerX = 0.5;
  double _playerY = 0.5;
  double _playerDirX = 0;
  double _playerDirY = 0;

  int _score = 0;
  int _health = 100;
  double _healthDisplay = 100;
  int _wave = 1;
  double _waveAnnounceTimer = 0;
  double _damageFlash = 0;
  double _time = 0;
  double _spawnTimer = 0;
  bool _gameOver = false;
  bool _playing = false;

  late Ticker _ticker;
  Size _gameSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
    _initFog();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initFog() {
    for (int i = 0; i < 10; i++) {
      _fogParticles.add(_FogParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 0.1 + _rng.nextDouble() * 0.25,
        dx: (-0.15 + _rng.nextDouble() * 0.3) * 0.001,
        dy: (-0.08 + _rng.nextDouble() * 0.16) * 0.001,
        opacity: 0.06 + _rng.nextDouble() * 0.1,
      ));
    }
  }

  void _startGame() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    setState(() {
      _playing = true;
      _gameOver = false;
      _health = 100;
      _healthDisplay = 100;
      _score = 0;
      _wave = 1;
      _waveAnnounceTimer = 0;
      _damageFlash = 0;
      _time = 0;
      _spawnTimer = 0;
      _zombies.clear();
      _bullets.clear();
      _bloodSplatters.clear();
      _killTexts.clear();
      _playerX = 0.5;
      _playerY = 0.5;
      _playerDirX = 0;
      _playerDirY = 0;
    });
  }

  int get _waveFromScore => (_score ~/ 15) + 1;

  void _onTick(Duration elapsed) {
    if (!_playing || _gameOver) return;

    final dt = 1 / 60;
    _time += dt;

    final newWave = _waveFromScore;
    if (newWave > _wave) {
      _wave = newWave;
      _waveAnnounceTimer = 2.5;
    }
    _waveAnnounceTimer = max(0, _waveAnnounceTimer - dt);
    _damageFlash = max(0, _damageFlash - dt * 2.5);

    _updateSpawn(dt);
    _updateBullets(dt);
    _updateZombies(dt);
    _updateFog(dt);
    _updateBlood(dt);
    _updateKillTexts(dt);
    _healthDisplay += (_health - _healthDisplay) * 6 * dt;

    if (mounted) setState(() {});
  }

  void _updateSpawn(double dt) {
    final interval = max(0.3, 1.8 - _wave * 0.12);
    _spawnTimer += dt;
    if (_spawnTimer >= interval) {
      _spawnTimer = 0;
      _spawnZombie();
    }
  }

  void _spawnZombie() {
    final side = _rng.nextInt(4);
    double x, y;
    switch (side) {
      case 0: x = -0.05 - _rng.nextDouble() * 0.1; y = _rng.nextDouble(); break;
      case 1: x = 1.05 + _rng.nextDouble() * 0.1; y = _rng.nextDouble(); break;
      case 2: x = _rng.nextDouble(); y = -0.05 - _rng.nextDouble() * 0.1; break;
      case 3: x = _rng.nextDouble(); y = 1.05 + _rng.nextDouble() * 0.1; break;
      default: x = _rng.nextDouble(); y = -0.05; break;
    }
    final isTank = _rng.nextDouble() < (0.15 + _wave * 0.03);
    final speedMult = 1.0 + (_wave - 1) * 0.08;
    _zombies.add(_Zombie(
      x: x,
      y: y,
      speed: isTank
          ? (0.07 + _rng.nextDouble() * 0.04) * speedMult
          : (0.12 + _rng.nextDouble() * 0.08) * speedMult,
      health: isTank ? 5 + _wave ~/ 2 : 1,
      maxHealth: isTank ? 5 + _wave ~/ 2 : 1,
      size: isTank ? 0.038 + _rng.nextDouble() * 0.012 : 0.022 + _rng.nextDouble() * 0.01,
      isTank: isTank,
      shamblePhase: _rng.nextDouble() * pi * 2,
    ));
  }

  void _updateBullets(double dt) {
    for (int i = _bullets.length - 1; i >= 0; i--) {
      final b = _bullets[i];
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.life += dt;

      if (b.x < -0.05 || b.x > 1.05 || b.y < -0.05 || b.y > 1.05 || b.life > 2) {
        _bullets.removeAt(i);
        continue;
      }

      for (int j = _zombies.length - 1; j >= 0; j--) {
        final z = _zombies[j];
        final dx = b.x - z.x;
        final dy = b.y - z.y;
        if (dx * dx + dy * dy < (z.size + 0.015) * (z.size + 0.015)) {
          z.health--;
          _spawnBlood(b.x, b.y, z.isTank ? 8 : 4);
          _bullets.removeAt(i);
          if (z.health <= 0) {
            _killZombie(j);
          } else {
            AudioService().play(SoundType.collect);
            HapticService.light();
          }
          break;
        }
      }
    }
  }

  void _killZombie(int index) {
    final z = _zombies[index];
    final zx = z.x;
    final zy = z.y;

    _spawnBlood(zx, zy, z.isTank ? 20 : 10);
    _zombies.removeAt(index);
    _score++;
    widget.onScoreChanged(_score);

    _killTexts.add(_KillText(px: zx, py: zy));
    AudioService().play(SoundType.shoot);
    HapticService.medium();
  }

  void _spawnBlood(double x, double y, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 0.05 + _rng.nextDouble() * 0.15;
      final size = 2 + _rng.nextDouble() * 5;
      _bloodSplatters.add(_BloodSplatter(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: size,
        life: 0,
      ));
    }
  }

  void _updateZombies(double dt) {
    for (int i = _zombies.length - 1; i >= 0; i--) {
      final z = _zombies[i];
      final dx = _playerX - z.x;
      final dy = _playerY - z.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 0.001) {
        z.x += (dx / dist) * z.speed * dt;
        z.y += (dy / dist) * z.speed * dt;
      }
      z.shamblePhase += dt * (z.isTank ? 2.5 : 5);
      final wobble = sin(z.shamblePhase * 4) * z.size * 0.25;
      z.x += wobble * dt;
      z.y += cos(z.shamblePhase * 3.5) * z.size * 0.2 * dt;

      final cdx = _playerX - z.x;
      final cdy = _playerY - z.y;
      if (cdx * cdx + cdy * cdy < _zombieContactDist * _zombieContactDist) {
        _health -= 8;
        _damageFlash = 1.0;
        AudioService().play(SoundType.notification);
        HapticService.heavy();
        if (_health <= 0) {
          _gameOver = true;
          AudioService().play(SoundType.gameOver);
          HapticService.heavy();
          _ticker.stop();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) widget.onGameOver(_score);
          });
          return;
        }
        _zombies.removeAt(i);
      }
    }
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

  void _updateBlood(double dt) {
    for (int i = _bloodSplatters.length - 1; i >= 0; i--) {
      final b = _bloodSplatters[i];
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.vy += 0.04 * dt;
      b.life += dt;
      if (b.life > 0.8) _bloodSplatters.removeAt(i);
    }
  }

  void _updateKillTexts(double dt) {
    for (int i = _killTexts.length - 1; i >= 0; i--) {
      final kt = _killTexts[i];
      kt.life += dt;
      kt.py -= 0.03 * dt;
      if (kt.life > 1.0) _killTexts.removeAt(i);
    }
  }

  void _fireBullet(double tapX, double tapY) {
    final dx = tapX - _playerX;
    final dy = tapY - _playerY;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.01) return;
    final nx = dx / dist;
    final ny = dy / dist;
    _bullets.add(_Bullet(
      x: _playerX + nx * _playerRadius * 2,
      y: _playerY + ny * _playerRadius * 2,
      vx: nx * _bulletSpeed,
      vy: ny * _bulletSpeed,
    ));
    AudioService().play(SoundType.shoot);
    HapticService.light();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_playing || _gameOver) return;
    final tx = details.localPosition.dx / _gameSize.width;
    final ty = details.localPosition.dy / _gameSize.height;
    _fireBullet(tx, ty);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_playing || _gameOver) return;
    _playerX = (_playerX + details.delta.dx / _gameSize.width).clamp(0.04, 0.96);
    _playerY = (_playerY + details.delta.dy / _gameSize.height).clamp(0.04, 0.96);
    final dx = details.delta.dx;
    final dy = details.delta.dy;
    if (dx.abs() > 0.1 || dy.abs() > 0.1) {
      _playerDirX = dx;
      _playerDirY = dy;
    }
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
      backgroundColor: const Color(0xFF050510),
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
              child: Icon(Icons.dangerous, size: 50, color: widget.gameColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Zombie Survival',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag to move · Tap to shoot',
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
                    Text('Survive!',
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
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _gameSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onTapDown: _onTapDown,
              onPanUpdate: _onPanUpdate,
              child: Stack(
                children: [
                  CustomPaint(
                    size: _gameSize,
                    painter: _ZombieSurvivalPainter(
                      zombies: _zombies,
                      bullets: _bullets,
                      playerX: _playerX,
                      playerY: _playerY,
                      playerDirX: _playerDirX,
                      playerDirY: _playerDirY,
                      health: _health,
                      healthDisplay: _healthDisplay,
                      gameColor: widget.gameColor,
                      bloodSplatters: _bloodSplatters,
                      fogParticles: _fogParticles,
                      killTexts: _killTexts,
                      waveAnnounceTimer: _waveAnnounceTimer,
                      wave: _wave,
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
                          onPressed: () {
                            _ticker.stop();
                            widget.onGameOver(_score);
                          },
                        ),
                        const Spacer(),
                        _buildStat(Icons.favorite, '$_health', Colors.red),
                        const SizedBox(width: 6),
                        _buildStat(Icons.emoji_events, '$_score', widget.gameColor),
                        const SizedBox(width: 6),
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
                        'Drag to move · Tap to shoot',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 11,
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
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet {
  double x, y, vx, vy, life;
  _Bullet({required this.x, required this.y, required this.vx, required this.vy})
      : life = 0;
}

class _Zombie {
  double x, y, speed, size, shamblePhase;
  int health, maxHealth;
  bool isTank;

  _Zombie({
    required this.x,
    required this.y,
    required this.speed,
    required this.health,
    required this.maxHealth,
    required this.size,
    required this.isTank,
    required this.shamblePhase,
  });
}

class _BloodSplatter {
  double x, y, vx, vy, size, life;
  _BloodSplatter({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
  });
}

class _FogParticle {
  double x, y;
  final double radius, dx, dy, opacity;
  _FogParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.dx,
    required this.dy,
    required this.opacity,
  });
}

class _KillText {
  double px, py, life;
  _KillText({required this.px, required this.py}) : life = 0;
}

class _ZombieSurvivalPainter extends CustomPainter {
  final List<_Zombie> zombies;
  final List<_Bullet> bullets;
  final double playerX, playerY, playerDirX, playerDirY;
  final int health;
  final double healthDisplay;
  final Color gameColor;
  final List<_BloodSplatter> bloodSplatters;
  final List<_FogParticle> fogParticles;
  final List<_KillText> killTexts;
  final double waveAnnounceTimer;
  final int wave;
  final double damageFlash;
  final double time;

  _ZombieSurvivalPainter({
    required this.zombies,
    required this.bullets,
    required this.playerX,
    required this.playerY,
    required this.playerDirX,
    required this.playerDirY,
    required this.health,
    required this.healthDisplay,
    required this.gameColor,
    required this.bloodSplatters,
    required this.fogParticles,
    required this.killTexts,
    required this.waveAnnounceTimer,
    required this.wave,
    required this.damageFlash,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawFog(canvas, size);
    _drawBloodSplatters(canvas);
    _drawBullets(canvas, size);
    _drawZombies(canvas, size);
    _drawPlayer(canvas, size);
    _drawKillTexts(canvas);
    _drawWaveAnnouncement(canvas, size);
    _drawVignette(canvas, size);
    _drawDamageFlash(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final danger = (zombies.length / 20).clamp(0.0, 1.0);
    final r = 0.02 + danger * 0.08;
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromARGB(255, 8 + (r * 255).round(), 8, 20),
          Color.fromARGB(255, 5 + (r * 127).round(), 5, 16),
        ],
        center: Alignment.center,
        radius: 1.2,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    for (final f in fogParticles) {
      final fx = f.x * size.width;
      final fy = f.y * size.height;
      final r = f.radius * size.width;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: f.opacity * 0.4),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(fx, fy), radius: r));
      canvas.drawCircle(Offset(fx, fy), r, paint);
    }
  }

  void _drawBloodSplatters(Canvas canvas) {
    for (final b in bloodSplatters) {
      final t = (b.life / 0.8).clamp(0.0, 1.0);
      final alpha = ((1 - t) * 200).round().clamp(0, 200);
      final paint = Paint()
        ..color = const Color(0xFF2ECC71).withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(b.x * 500, b.y * 500), b.size * (1 - t * 0.5), paint);

      final darkPaint = Paint()
        ..color = const Color(0xFF1A6B37).withAlpha((alpha * 0.7).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(
        Offset(b.x * 500 + 1, b.y * 500 + 1),
        b.size * (1 - t * 0.5) * 0.7,
        darkPaint,
      );
    }
  }

  void _drawBullets(Canvas canvas, Size size) {
    for (final b in bullets) {
      final bx = b.x * size.width;
      final by = b.y * size.height;
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = const Color(0xFFFFF176).withValues(alpha: 0.5);
      canvas.drawCircle(Offset(bx, by), 4, glow);
      canvas.drawCircle(Offset(bx, by), 2.5, Paint()..color = const Color(0xFFFFF176));
      canvas.drawCircle(
        Offset(bx - 1, by - 1),
        1,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  void _drawZombies(Canvas canvas, Size size) {
    for (final z in zombies) {
      final zx = z.x * size.width;
      final zy = z.y * size.height;
      final sz = z.size * size.width;

      canvas.save();
      canvas.translate(zx, zy);

      _drawZombieBody(canvas, sz, z);
      _drawZombieEyes(canvas, sz);

      canvas.restore();
    }
  }

  void _drawZombieBody(Canvas canvas, double sz, _Zombie z) {
    if (!z.isTank) {
      final color = Color.lerp(
        const Color(0xFF2ECC71),
        const Color(0xFF27AE60),
        sin(time * 3 + z.shamblePhase) * 0.1 + 0.5,
      )!;
      final body = Path()
        ..addOval(Rect.fromCenter(
          center: Offset.zero,
          width: sz * 1.1,
          height: sz * 1.2,
        ));
      canvas.drawPath(body, Paint()..color = color.withValues(alpha: 0.85));

      final head = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(0, -sz * 0.35),
          width: sz * 0.6,
          height: sz * 0.55,
        ));
      canvas.drawPath(
        head,
        Paint()..color = const Color(0xFF6B8E6B),
      );
    } else {
      final bodyColor = const Color(0xFF1E6B3A);
      final body = Path()
        ..addOval(Rect.fromCenter(
          center: Offset.zero,
          width: sz * 1.6,
          height: sz * 1.8,
        ));
      canvas.drawPath(body, Paint()..color = bodyColor.withValues(alpha: 0.85));

      final head = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(0, -sz * 0.4),
          width: sz * 0.8,
          height: sz * 0.7,
        ));
      canvas.drawPath(
        head,
        Paint()..color = const Color(0xFF5A7A5A),
      );

      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.orange.withValues(alpha: 0.5);
      canvas.drawCircle(Offset.zero, sz * 0.8, outline);

      final hpRatio = z.health / z.maxHealth;
      final hpW = sz * 1.2;
      final bgHp = Paint()..color = Colors.black.withValues(alpha: 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -sz * 0.7),
            width: hpW + 2,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        bgHp,
      );
      final hpColor = hpRatio > 0.5
          ? Color.lerp(Colors.yellow, Colors.green, (hpRatio - 0.5) * 2)!
          : Color.lerp(Colors.red, Colors.yellow, hpRatio * 2)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(-(1 - hpRatio) * hpW / 2, -sz * 0.7),
            width: hpW * hpRatio,
            height: 2,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = hpColor,
      );
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, sz * 0.55),
        width: sz * 0.8,
        height: sz * 0.2,
      ),
      shadowPaint,
    );
  }

  void _drawZombieEyes(Canvas canvas, double sz) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF00).withValues(alpha: 0.95),
          const Color(0xFF00FF00).withValues(alpha: 0.4),
          const Color(0xFF00FF00).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(-sz * 0.2, -sz * 0.3),
        radius: sz * 0.22,
      ));
    canvas.drawCircle(Offset(-sz * 0.2, -sz * 0.32), sz * 0.2, glowPaint);

    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF00).withValues(alpha: 0.95),
          const Color(0xFF00FF00).withValues(alpha: 0.4),
          const Color(0xFF00FF00).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(sz * 0.2, -sz * 0.32),
        radius: sz * 0.22,
      ));
    canvas.drawCircle(Offset(sz * 0.2, -sz * 0.32), sz * 0.2, glowPaint2);

    canvas.drawCircle(
      Offset(-sz * 0.2, -sz * 0.32),
      sz * 0.05,
      Paint()..color = const Color(0xFF00FF00),
    );
    canvas.drawCircle(
      Offset(sz * 0.2, -sz * 0.32),
      sz * 0.05,
      Paint()..color = const Color(0xFF00FF00),
    );
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final px = playerX * size.width;
    final py = playerY * size.height;
    final flicker = 0.95 + sin(time * 13 + playerX * 100) * 0.05;

    final flashlight = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF8E1).withValues(alpha: 0.10 * flicker),
          const Color(0xFFFFF8E1).withValues(alpha: 0.02 * flicker),
          Colors.transparent,
        ],
        stops: const [0, 0.3, 0.7],
      ).createShader(Rect.fromCircle(
        center: Offset(px, py),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(Offset(px, py), size.width * 0.5, flashlight);

    final angle = atan2(playerDirY, playerDirX);

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(px, healthBarY),
          width: healthBarWidth + 4,
          height: 5,
        ),
        const Radius.circular(2.5),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(px - (1 - healthRatio) * healthBarWidth / 2, healthBarY),
          width: healthBarWidth * healthRatio,
          height: 3,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = healthColor,
    );
  }

  void _drawKillTexts(Canvas canvas) {
    for (final kt in killTexts) {
      final t = (kt.life / 1.0).clamp(0.0, 1.0);
      final alpha = ((1 - t) * 255).round().clamp(0, 255);
      final scale = 1.0 + t * 0.3;

      canvas.save();
      canvas.translate(kt.px * 500, kt.py * 500);
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
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawDamageFlash(Canvas canvas, Size size) {
    if (damageFlash <= 0) return;
    final alpha = (damageFlash * 180).round().clamp(0, 180);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.red.withAlpha(alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _ZombieSurvivalPainter oldDelegate) => true;
}
