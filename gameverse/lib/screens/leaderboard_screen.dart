
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GameService _gameService = GameService();
  late AnimationController _headerGlowController;
  late AnimationController _entryController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    if (mounted) {
      setState(() => _loaded = true);
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerGlowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  List<MapEntry<Game, int>> get _sortedScores {
    return allGames
        .map((g) => MapEntry(g, _gameService.getHighScore(g.id)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Column(
        children: [
          _buildHeader(topPad),
          _buildTabBar(),
          Expanded(
            child: _loaded
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _HighScoresTab(
                        sortedScores: _sortedScores,
                        gameService: _gameService,
                      ),
                      _AchievementsTab(gameService: _gameService),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPad) {
    return AnimatedBuilder(
      animation: _headerGlowController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(
                    alpha: 0.04 + 0.03 * _headerGlowController.value),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(
                          alpha: 0.3 + 0.25 * _headerGlowController.value),
                      blurRadius: 14 + 8 * _headerGlowController.value,
                    ),
                  ],
                ),
                child: const Icon(Icons.leaderboard,
                    color: Colors.black, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leaderboard',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Rankings & Achievements',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.38))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: '🏆  High Scores'),
          Tab(text: '🎖️  Achievements'),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// HIGH SCORES TAB
// ══════════════════════════════════════════════
class _HighScoresTab extends StatefulWidget {
  final List<MapEntry<Game, int>> sortedScores;
  final GameService gameService;
  const _HighScoresTab(
      {required this.sortedScores, required this.gameService});

  @override
  State<_HighScoresTab> createState() => _HighScoresTabState();
}

class _HighScoresTabState extends State<_HighScoresTab>
    with TickerProviderStateMixin {
  final List<AnimationController> _rowControllers = [];
  final List<Animation<Offset>> _slides = [];
  final List<Animation<double>> _fades = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.sortedScores.length; i++) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 450));
      _rowControllers.add(c);
      _slides.add(Tween<Offset>(
              begin: const Offset(0.35, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)));
      _fades.add(Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)));
      Future.delayed(Duration(milliseconds: 50 + 65 * i), () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _rowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = widget.gameService.highScores.values
        .fold(0, (a, b) => a + b);
    final level = GameService.getLevel(widget.gameService.currentXP);
    final gamesPlayed = widget.gameService.playedGames.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: widget.sortedScores.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return _PlayerSummaryCard(
            level: level,
            totalScore: totalScore,
            gamesPlayed: gamesPlayed,
            xp: widget.gameService.currentXP,
          );
        }
        final rank = i;
        final entry = widget.sortedScores[i - 1];
        return FadeTransition(
          opacity: _fades[i - 1],
          child: SlideTransition(
            position: _slides[i - 1],
            child: _ScoreRow(rank: rank, game: entry.key, score: entry.value),
          ),
        );
      },
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  final int level, totalScore, gamesPlayed, xp;
  const _PlayerSummaryCard({
    required this.level,
    required this.totalScore,
    required this.gamesPlayed,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C3E), Color(0xFF0F0F23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
            ),
            child: Center(
              child: Text('$level',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text('Level $level  ·  $xp XP total',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$totalScore',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700))),
              Text('$gamesPlayed games played',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final Game game;
  final int score;
  const _ScoreRow(
      {required this.rank, required this.game, required this.score});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white30;
  }

  String get _rankLabel {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = score > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: rank <= 3
            ? _rankColor.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: rank <= 3
              ? _rankColor.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(_rankLabel,
                style: TextStyle(
                    fontSize: rank <= 3 ? 22 : 13,
                    fontWeight: FontWeight.bold,
                    color: _rankColor),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: game.color
                  .withValues(alpha: hasScore ? 0.2 : 0.07),
            ),
            child: Icon(game.icon,
                color: game.color
                    .withValues(alpha: hasScore ? 1.0 : 0.25),
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(game.title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasScore
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3))),
          ),
          if (hasScore)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _rankColor.withValues(alpha: 0.14),
              ),
              child: Text('$score',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _rankColor)),
            )
          else
            Text('Not played',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ACHIEVEMENTS TAB
// ══════════════════════════════════════════════
class _AchievementsTab extends StatefulWidget {
  final GameService gameService;
  const _AchievementsTab({required this.gameService});

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.gameService.unlockedBadges;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _ProgressHeader(
          unlockedCount: unlocked.length,
          total: allBadges.length,
          xp: widget.gameService.currentXP,
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.92,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: allBadges.length,
          itemBuilder: (ctx, i) {
            final badge = allBadges[i];
            final isUnlocked = badge.isUnlocked(unlocked);
            return _BadgeTile(
              badge: badge,
              unlocked: isUnlocked,
              pulseController: _pulseController,
            );
          },
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlockedCount, total, xp;
  const _ProgressHeader(
      {required this.unlockedCount,
      required this.total,
      required this.xp});

  @override
  Widget build(BuildContext context) {
    final progress = unlockedCount / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C3E), Color(0xFF0F0F23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achievement Progress',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                ),
                child: Text('$unlockedCount / $total',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('$xp XP total  ·  Keep playing to unlock more!',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.38))),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final GameBadge badge;
  final bool unlocked;
  final AnimationController pulseController;
  const _BadgeTile(
      {required this.badge,
      required this.unlocked,
      required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final glow = pulseController.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: unlocked
                ? const Color(0xFF1A1A2E)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: unlocked
                  ? const Color(0xFFFFD700)
                      .withValues(alpha: 0.28 + 0.18 * glow)
                  : Colors.white.withValues(alpha: 0.07),
              width: unlocked ? 1.5 : 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700)
                          .withValues(alpha: 0.06 + 0.07 * glow),
                      blurRadius: 14 + 10 * glow,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (unlocked)
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.06 + 0.05 * glow),
                      ),
                    ),
                  Icon(badge.icon,
                      size: 38,
                      color: unlocked
                          ? const Color(0xFFFFD700)
                          : Colors.white.withValues(alpha: 0.12)),
                  if (!unlocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A0A1A),
                          border: Border.all(
                              color: Colors.white12, width: 1),
                        ),
                        child: const Icon(Icons.lock,
                            size: 11, color: Colors.white24),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(badge.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: unlocked
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(badge.description,
                  style: TextStyle(
                      fontSize: 11,
                      color: unlocked
                          ? Colors.white54
                          : Colors.white.withValues(alpha: 0.13)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}
