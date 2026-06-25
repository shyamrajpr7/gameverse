import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_service.dart';

class AchievementOverlay extends StatefulWidget {
  final GameBadge badge;
  final VoidCallback onDismiss;

  const AchievementOverlay({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;

  late Animation<double> _bgFade;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bgFade =
        CurvedAnimation(parent: _bgController, curve: Curves.easeOut);

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _scaleAnim = CurvedAnimation(
        parent: _scaleController, curve: Curves.elasticOut);

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    _particleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    // Sequence: bg → card pop → particles
    _bgController.forward().then((_) {
      _scaleController.forward().then((_) {
        _particleController.forward();
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgFade,
        _scaleAnim,
        _glowController,
        _particleController,
        _shimmerController,
      ]),
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black.withValues(alpha: 0.88 * _bgFade.value),
              child: Stack(
                children: [
                  // Particle burst
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                          progress: _particleController.value),
                    ),
                  ),
                  // Ring decoration behind card
                  Center(
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: _buildRingDecoration(),
                    ),
                  ),
                  // Main card
                  Center(
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: GestureDetector(
                        onTap: () {}, // block dismiss on card tap
                        child: _buildCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingDecoration() {
    return Container(
      width: 320,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(
                alpha: 0.18 + 0.14 * _glowController.value),
            blurRadius: 40 + 30 * _glowController.value,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E40), Color(0xFF0D0D22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(
              alpha: 0.35 + 0.2 * _glowController.value),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top pill badge
          _buildTopPill(),
          const SizedBox(height: 28),
          // Animated icon with rings
          _buildAnimatedIcon(),
          const SizedBox(height: 22),
          // Title
          Text(widget.badge.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(widget.badge.description,
              style: const TextStyle(fontSize: 14, color: Colors.white54),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          // XP chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF00B894).withValues(alpha: 0.15),
              border: Border.all(
                  color: const Color(0xFF00B894).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    size: 13, color: Color(0xFF00B894)),
                SizedBox(width: 5),
                Text('Badge Earned!',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B894))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: widget.onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('AWESOME! 🔥',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3)),
            ),
          ),
          const SizedBox(height: 10),
          Text('Tap anywhere to close',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.2))),
        ],
      ),
    );
  }

  Widget _buildTopPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.2),
            const Color(0xFFFF8C00).withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎉', style: TextStyle(fontSize: 15)),
          SizedBox(width: 6),
          Text('Achievement Unlocked!',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final glow = _glowController.value;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFFD700)
                    .withValues(alpha: 0.1 + 0.08 * glow),
                width: 1),
          ),
        ),
        // Middle ring
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD700)
                .withValues(alpha: 0.05 + 0.05 * glow),
            border: Border.all(
                color: const Color(0xFFFFD700)
                    .withValues(alpha: 0.15 + 0.1 * glow),
                width: 1.5),
          ),
        ),
        // Core glow circle
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD700)
                    .withValues(alpha: 0.18 + 0.12 * glow),
                const Color(0xFFFFD700).withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700)
                    .withValues(alpha: 0.35 + 0.3 * glow),
                blurRadius: 20 + 18 * glow,
                spreadRadius: 2 + 4 * glow,
              ),
            ],
          ),
          child: Icon(widget.badge.icon,
              size: 50, color: const Color(0xFFFFD700)),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────
// PARTICLE PAINTER
// ────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFFFF6B6B),
    Color(0xFF00B894),
    Color(0xFFFF8A5C),
    Color(0xFFA8E6CF),
    Color(0xFFFF4081),
  ];

  const _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);
    const count = 28;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.4;
      final speed = 90.0 + rng.nextDouble() * 200;
      final radius = 3.5 + rng.nextDouble() * 5.5;
      final color = _colors[i % _colors.length];

      final t = progress;
      final dx = cos(angle) * speed * t;
      final dy = sin(angle) * speed * t - 80 * t * t; // arc upward
      final opacity = (1.0 - t * 0.85).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(
        center + Offset(dx, dy),
        radius * (1 - t * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
