import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  late AnimationController _headerController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    if (mounted) {
      setState(() => _loaded = true);
      _headerController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final level = GameService.getLevel(_gameService.currentXP);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedHeader(level),
                  const SizedBox(height: 24),
                  _buildStatGrid(),
                  const SizedBox(height: 28),
                  _buildFavoriteGame(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('High Scores', Icons.emoji_events),
                  const SizedBox(height: 12),
                  _buildBarChart(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Achievements', Icons.workspace_premium),
                  const SizedBox(height: 12),
                  _buildAchievementRing(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 40,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: const FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.only(top: 48, left: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Your gaming analytics', style: TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(int level) {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, _) {
        final t = _headerController.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.12),
                    const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('📊', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Level $level  •  ${_gameService.totalGamesPlayed} games played',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Games', '${_gameService.totalGamesPlayed}', Icons.games, const Color(0xFFFFD700))),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
              'Streak', '${_gameService.currentStreak} 🔥', Icons.local_fire_department, const Color(0xFFFF6B6B)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ],
      ),
    );
  }

  Widget _buildFavoriteGame() {
    final fav = _gameService.favoriteGame;
    if (fav == null) return const SizedBox.shrink();
    final score = _gameService.highScores[fav.id] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Favorite Game', Icons.favorite),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [fav.color.withValues(alpha: 0.15), fav.color.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: fav.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: fav.color.withValues(alpha: 0.2),
                ),
                child: Icon(fav.icon, size: 28, color: fav.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fav.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Highest score: $score', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 14, color: const Color(0xFFFFD700)),
                    const SizedBox(width: 4),
                    Text('$score', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final scores = _gameService.highScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (scores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text('No scores yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }

    final maxScore = scores.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Column(
        children: scores.take(6).map((e) {
          final game = allGames.firstWhere(
            (g) => g.id == e.key,
            orElse: () => allGames.first,
          );
          final fraction = maxScore > 0 ? e.value / maxScore : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    game.title,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: max(fraction, 0.04),
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    game.color,
                                    game.color.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                '${e.value}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementRing() {
    final total = allBadges.length;
    final unlocked = _gameService.unlockedBadges.length;
    final ratio = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _RingPainter(
                    progress: ratio,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: const Color(0xFFFFD700),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$unlocked',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '/$total',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  '${(ratio * 100).round()}% complete',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFFD700)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
