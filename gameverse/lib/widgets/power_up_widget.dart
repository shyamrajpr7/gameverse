import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/power_up.dart';

class PowerUpItem extends StatefulWidget {
  final PowerUp powerUp;
  final double size;
  final VoidCallback? onTap;

  const PowerUpItem({
    super.key,
    required this.powerUp,
    required this.size,
    this.onTap,
  });

  @override
  State<PowerUpItem> createState() => _PowerUpItemState();
}

class _PowerUpItemState extends State<PowerUpItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bobController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bobController,
      builder: (context, _) {
        final bob = math.sin(_bobController.value * math.pi) * widget.size * 0.12;
        final pulse = 0.85 + 0.15 * math.sin(_bobController.value * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, bob),
          child: GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _PowerUpGlowPainter(
                  color: widget.powerUp.color,
                  pulse: pulse,
                ),
                child: Center(
                  child: Icon(
                    widget.powerUp.icon,
                    color: Colors.white,
                    size: widget.size * 0.45,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PowerUpGlowPainter extends CustomPainter {
  final Color color;
  final double pulse;

  _PowerUpGlowPainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = color.withValues(alpha: 0.3 * pulse);
    canvas.drawCircle(center, radius * 0.9, auraPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(center, radius * 0.85, ringPaint);

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, radius * 0.75, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PowerUpHUD extends StatelessWidget {
  final List<ActivePowerUpDisplay> activePowerUps;

  const PowerUpHUD({super.key, required this.activePowerUps});

  @override
  Widget build(BuildContext context) {
    if (activePowerUps.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: activePowerUps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final ap = activePowerUps[index];
          final powerUp = powerUpForType(ap.type);
          final progress = ap.total > 0 ? ap.remaining / ap.total : 0.0;
          return _PowerUpHudItem(
            powerUp: powerUp,
            progress: progress,
            remaining: ap.remaining,
          );
        },
      ),
    );
  }
}

class ActivePowerUpDisplay {
  final PowerUpType type;
  final double remaining;
  final double total;

  ActivePowerUpDisplay({
    required this.type,
    required this.remaining,
    required this.total,
  });
}

class _PowerUpHudItem extends StatelessWidget {
  final PowerUp powerUp;
  final double progress;
  final double remaining;

  const _PowerUpHudItem({
    required this.powerUp,
    required this.progress,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(28, 28),
            painter: _RadialTimerPainter(
              color: powerUp.color,
              progress: progress,
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: powerUp.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(powerUp.icon, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

class _RadialTimerPainter extends CustomPainter {
  final Color color;
  final double progress;

  _RadialTimerPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 1, bgPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      -math.pi / 2,
      -progress * 2 * math.pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

List<ActivePowerUpDisplay> buildActivePowerUpDisplays(
  List<PowerUpType> types,
  double Function(PowerUpType) remainingTime,
  double Function(PowerUpType) totalDuration,
) {
  return types.map((type) {
    return ActivePowerUpDisplay(
      type: type,
      remaining: remainingTime(type),
      total: totalDuration(type),
    );
  }).toList();
}
