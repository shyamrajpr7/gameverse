import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart';

class ShareCard extends StatelessWidget {
  final Game game;
  final int score;
  final String message;
  final String playerName;
  final int level;

  static const double cardWidth = 360;
  static const double cardHeight = 640;

  const ShareCard({
    super.key,
    required this.game,
    required this.score,
    this.message = 'Can you beat my score?',
    this.playerName = 'Player',
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A2E),
              Color(0xFF0F0F23),
              Color(0xFF1A0A2E),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundGlow(),
            _buildContent(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CardGlowPainter(),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 70),
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(flex: 2),
          _buildScore(),
          const Spacer(),
          _buildPlayerInfo(),
          const Spacer(flex: 2),
          _buildMessage(),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                game.color,
                game.color.withValues(alpha: 0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: game.color.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(game.icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          game.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    return Column(
      children: [
        Text(
          'SCORE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                blurRadius: 24,
              ),
              Shadow(
                color: game.color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: game.color.withValues(alpha: 0.3),
            ),
            color: game.color.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: 16),
              const SizedBox(width: 6),
              Text(
                'New High Score!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
          ),
          child: Icon(GameService().avatarIcon, size: 18, color: const Color(0xFF6C5CE7)),
        ),
        const SizedBox(width: 10),
        Text(
          playerName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'Lv.$level',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C5CE7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF0A0A1A).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
              ),
              child: const Center(
                child: Text('GV', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                )),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Play on GameVerse',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final center = Offset(size.width / 2, size.height * 0.35);
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFD700).withValues(alpha: 0.06),
        const Color(0xFF6C5CE7).withValues(alpha: 0.03),
        Colors.transparent,
      ],
      stops: const [0, 0.4, 1],
    ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));
    canvas.drawCircle(center, size.width * 0.6, paint);

    final bottomGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6C5CE7).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0, 0.6],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.85),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.85),
      size.width * 0.5,
      bottomGlow,
    );

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.2),
          const Color(0xFF6C5CE7).withValues(alpha: 0.1),
          const Color(0xFFFFD700).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(
      rrect,
      borderPaint..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    const cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final corner in [
      Offset(12, 12),
      Offset(size.width - 12, 12),
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
    ]) {
      canvas.drawCircle(corner, cornerSize, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
