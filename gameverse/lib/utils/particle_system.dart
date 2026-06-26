import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleType { circle, square, star, spark, ring, trail }

class Particle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double life;
  double maxLife;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  ParticleType type;
  double gravity;
  bool fadeOut;
  bool scaleDown;

  Particle({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.velocityY = 0,
    double? life,
    double? maxLife,
    this.size = 4,
    this.color = Colors.white,
    this.rotation = 0,
    this.rotationSpeed = 0,
    this.type = ParticleType.circle,
    this.gravity = 0,
    this.fadeOut = true,
    this.scaleDown = true,
  })  : life = life ?? 0,
        maxLife = maxLife ?? 1;

  double get progress => life / maxLife;
  double get alpha => fadeOut ? (1 - progress) : 1.0;
  double get scale => scaleDown ? (1 - progress * 0.6) : 1.0;
  bool get isDead => life >= maxLife;
}

class ParticleEmitter {
  final List<Particle> particles = [];
  final Random _rng = Random();

  void emit({
    required Offset position,
    int count = 10,
    Color color = Colors.white,
    double spread = 2 * pi,
    double speed = 80,
    double minSize = 2,
    double maxSize = 6,
    ParticleType type = ParticleType.circle,
    double gravity = 0,
    double lifespan = 1,
  }) {
    for (int i = 0; i < count; i++) {
      final angle = -spread / 2 + _rng.nextDouble() * spread;
      final vel = speed * (0.4 + _rng.nextDouble() * 0.6);

      particles.add(Particle(
        x: position.dx + _rng.nextDouble() * 4 - 2,
        y: position.dy + _rng.nextDouble() * 4 - 2,
        velocityX: cos(angle) * vel,
        velocityY: sin(angle) * vel,
        size: minSize + _rng.nextDouble() * (maxSize - minSize),
        color: color,
        type: type,
        gravity: gravity,
        life: 0,
        maxLife: lifespan * (0.6 + _rng.nextDouble() * 0.4),
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
        fadeOut: true,
        scaleDown: type != ParticleType.star,
      ));
    }
  }

  void emitBurst({
    required Offset position,
    int rings = 3,
    int particlesPerRing = 12,
    Color color = Colors.white,
    double baseSpeed = 120,
    double spread = 2 * pi,
    double lifespan = 1,
  }) {
    for (int ring = 0; ring < rings; ring++) {
      final r = ring / rings;
      for (int i = 0; i < particlesPerRing; i++) {
        final angle = (i / particlesPerRing) * 2 * pi;
        final vel = baseSpeed * (0.6 + r * 0.8);
        final size = 2.0 + (1 - r) * 4;
        particles.add(Particle(
          x: position.dx,
          y: position.dy,
          velocityX: cos(angle) * vel,
          velocityY: sin(angle) * vel,
          size: size,
          color: color.withValues(alpha: 1.0 - r * 0.4),
          type: ParticleType.circle,
          life: 0,
          maxLife: lifespan * (0.5 + r * 0.5),
          rotation: angle,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 4,
          fadeOut: true,
          scaleDown: true,
        ));
      }
    }
  }

  void update(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life += dt;

      if (p.isDead) {
        particles.removeAt(i);
        continue;
      }

      p.velocityY += p.gravity * dt;
      p.x += p.velocityX * dt;
      p.y += p.velocityY * dt;
      p.rotation += p.rotationSpeed * dt;
    }
  }

  void draw(Canvas canvas) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final alpha = (p.alpha * p.color.a * 255).round().clamp(0, 255);
      final drawColor = p.color.withAlpha(alpha);
      final s = p.size * p.scale;

      switch (p.type) {
        case ParticleType.circle:
          _drawCircle(canvas, drawColor, s);
        case ParticleType.square:
          _drawSquare(canvas, drawColor, s);
        case ParticleType.star:
          _drawStar(canvas, drawColor, s);
        case ParticleType.spark:
          _drawSpark(canvas, drawColor, s);
        case ParticleType.ring:
          _drawRing(canvas, drawColor, s);
        case ParticleType.trail:
          _drawSquare(canvas, drawColor, s);
      }

      canvas.restore();
    }
  }

  void _drawCircle(Canvas canvas, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset.zero, size / 2, paint);
  }

  void _drawSquare(Canvas canvas, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size, height: size),
        const Radius.circular(1),
      ),
      paint,
    );
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

  void _drawSpark(Canvas canvas, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size * 0.3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(
      Offset(-size / 2, 0),
      Offset(size / 2, 0),
      paint,
    );
  }

  void _drawRing(Canvas canvas, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.25;
    canvas.drawCircle(Offset.zero, size / 2, paint);
  }
}

class ScreenShake {
  double _offsetX = 0;
  double _offsetY = 0;
  double _intensity = 0;
  double _duration = 0;
  double _elapsed = 0;
  final Random _rng = Random();

  Offset get offset => Offset(_offsetX, _offsetY);

  void trigger(double intensity, int durationMs) {
    _intensity = intensity;
    _duration = durationMs / 1000;
    _elapsed = 0;
  }

  void update(double dt) {
    if (_elapsed >= _duration) {
      _offsetX = 0;
      _offsetY = 0;
      return;
    }

    _elapsed += dt;
    final t = _elapsed / _duration;
    final decay = 1 - t;
    final dampened = decay * decay;
    final angle = _rng.nextDouble() * 2 * pi;
    final mag = sin(t * pi * 8) * _intensity * dampened;

    _offsetX = cos(angle) * mag;
    _offsetY = sin(angle) * mag;
  }

  bool get isShaking => _elapsed < _duration;
}

class TrailEffect {
  final List<_TrailPoint> _points = [];
  static const int maxPoints = 20;

  void addPoint(Offset p) {
    _points.insert(0, _TrailPoint(position: p));

    while (_points.length > maxPoints) {
      _points.removeLast();
    }
  }

  void draw(Canvas canvas, Color color, double width) {
    if (_points.length < 2) return;

    for (int i = 0; i < _points.length - 1; i++) {
      final t = i / (_points.length - 1);
      final alpha = ((1 - t) * color.a * 255).round().clamp(0, 255);
      final w = width * (1 - t * 0.7);

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.5);

      final a = _points[i].position;
      final b = _points[i + 1].position;
      canvas.drawLine(a, b, paint);
    }
  }

  void clear() => _points.clear();
}

class _TrailPoint {
  final Offset position;
  const _TrailPoint({required this.position});
}
