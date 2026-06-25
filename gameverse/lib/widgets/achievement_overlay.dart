import 'package:flutter/material.dart';
import 'dart:math';
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
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController.forward();
    _glowController.repeat(reverse: true);
    _particleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: _buildCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A1A2E),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉 Achievement Unlocked!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 24),
          _buildGlowIcon(),
          const SizedBox(height: 20),
          Text(
            widget.badge.title,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.badge.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'AWESOME!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowIcon() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A0A1A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700)
                    .withValues(alpha: 0.4 * _glowAnimation.value),
                blurRadius: 10 + 15 * _glowAnimation.value,
                spreadRadius: 2 * _glowAnimation.value,
              ),
            ],
          ),
          child: Icon(
            widget.badge.icon,
            size: 64,
            color: const Color(0xFFFFD700),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter({required this.progress});

  static const List<Color> _colors = [
    Color(0xFFFFD700),
    Color(0xFF6C5CE7),
    Color(0xFF00CED1),
    Color(0xFFFF6B6B),
    Color(0xFF00FF7F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 12; i++) {
      final angle = (2 * pi / 12) * i;
      final distance = progress * (80 + random.nextDouble() * 60);
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;
      paint.color = _colors[i % _colors.length]
          .withValues(alpha: 1.0 - progress * 0.7);
      canvas.drawCircle(Offset(x, y), 5 - progress * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
