import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../screens/game_detail_screen.dart';
import 'ui_enhancements.dart';

class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  final Game _game = GameService.getDailyChallenge();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    setState(() => _remaining = midnight.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final completed = GameService().isDailyCompleted;
    final glow = _game.color;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final pulse = _glowController.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GlowContainer(
            color: glow,
            blurRadius: 16,
            spreadRadius: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    glow.withValues(alpha: 0.2 + 0.1 * pulse),
                    glow.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: glow.withValues(alpha: 0.2 + 0.2 * pulse),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AudioService().play(SoundType.click);
                      HapticService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameDetailScreen(game: _game),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _game.color.withValues(alpha: 0.15 + 0.1 * pulse),
                                ),
                              ),
                              Transform.rotate(
                                angle: pulse * 0.1,
                                child: Icon(
                                  _game.icon,
                                  size: 32,
                                  color: _game.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    AnimatedGradientText(
                                      text: 'Daily Challenge',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                      colors: const [
                                        Color(0xFFFFD700),
                                        Color(0xFFFF6B6B),
                                        Color(0xFF6C5CE7),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    if (!completed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: const Color(0xFFFFD700)
                                              .withValues(alpha: 0.15),
                                        ),
                                        child: const Text(
                                          'XP x2',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFD700),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: const Color(0xFF6C5CE7)
                                              .withValues(alpha: 0.15),
                                        ),
                                        child: const Text(
                                          'Done',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6C5CE7),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _game.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  completed
                                      ? 'Come back tomorrow for a new challenge'
                                      : '${_game.xpReward}xp — ${_format(_remaining)} remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!completed)
                            GlowContainer(
                              color: _game.color,
                              blurRadius: 8,
                              spreadRadius: 0,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      _game.color,
                                      _game.color.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 26,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
