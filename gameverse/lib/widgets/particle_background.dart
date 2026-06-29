import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  double x, y, vx, vy, size, opacity, baseOpacity;
  double pulseSpeed;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.size, required this.opacity, this.pulseSpeed = 0.02})
    : baseOpacity = opacity;
}

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final Color color;
  final int particleCount;
  final bool disableInteraction;

  const ParticleBackground({
    super.key,
    required this.child,
    this.color = const Color(0xFF6C5CE7),
    this.particleCount = 40,
    this.disableInteraction = false,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _createParticle());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  Particle _createParticle() {
    return Particle(
      x: _rng.nextDouble() * 400,
      y: _rng.nextDouble() * 900,
      vx: (_rng.nextDouble() - 0.5) * 0.15,
      vy: (_rng.nextDouble() - 0.5) * 0.15 - 0.05,
      size: 0.5 + _rng.nextDouble() * 2.5,
      opacity: 0.1 + _rng.nextDouble() * 0.4,
      pulseSpeed: 0.005 + _rng.nextDouble() * 0.015,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final time = _controller.value * 2 * pi;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                size: size,
                color: widget.color,
                time: time,
              ),
            ),
          ),
        ),
        if (widget.disableInteraction)
          Positioned.fill(child: widget.child)
        else
          widget.child,
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Size size;
  final Color color;
  final double time;

  _ParticlePainter({
    required this.particles,
    required this.size,
    required this.color,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size _) {
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.opacity = p.baseOpacity + sin(time * p.pulseSpeed) * 0.15;
      p.opacity = p.opacity.clamp(0.0, 0.6);

      if (p.x < -10) p.x = size.width + 10;
      if (p.x > size.width + 10) p.x = -10;
      if (p.y < -10) p.y = size.height + 10;
      if (p.y > size.height + 10) p.y = -10;

      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
