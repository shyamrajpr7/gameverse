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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Leaderboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'High Scores'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: _loaded
          ? TabBarView(
              controller: _tabController,
              children: [
                _HighScoresTab(gameService: _gameService),
                _AchievementsTab(gameService: _gameService),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _HighScoresTab extends StatefulWidget {
  final GameService gameService;
  const _HighScoresTab({required this.gameService});

  @override
  State<_HighScoresTab> createState() => _HighScoresTabState();
}

class _HighScoresTabState extends State<_HighScoresTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Game> _sortedGames;

  @override
  void initState() {
    super.initState();
    _sortedGames = [...allGames]..sort((a, b) {
      final scoreA = widget.gameService.getHighScore(a.id);
      final scoreB = widget.gameService.getHighScore(b.id);
      return scoreB.compareTo(scoreA);
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimations = List.generate(_sortedGames.length, (index) {
      final double start = (index * 0.08).clamp(0.0, 1.0);
      final double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sortedGames.length,
      itemBuilder: (context, index) {
        final game = _sortedGames[index];
        final score = widget.gameService.getHighScore(game.id);
        return SlideTransition(
          position: _slideAnimations[index],
          child: _ScoreRow(rank: index + 1, game: game, score: score),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final Game game;
  final int score;

  const _ScoreRow({
    required this.rank,
    required this.game,
    required this.score,
  });

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0F0F23),
        border: Border.all(
          color: rank <= 3
              ? _rankColor().withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _rankColor(),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: game.color.withValues(alpha: 0.2),
            ),
            child: Icon(game.icon, color: game.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              game.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (score > 0)
            Text(
              '$score',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          else
            Text(
              'Not played yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  final GameService gameService;
  const _AchievementsTab({required this.gameService});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final unlocked = badge.isUnlocked(gameService.unlockedBadges);
        return _BadgeCard(badge: badge, unlocked: unlocked);
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final GameBadge badge;
  final bool unlocked;

  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: unlocked
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFFFD700).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                size: 42,
                color: unlocked
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 10),
              Text(
                badge.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: unlocked ? Colors.white : Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 11,
                  color: unlocked ? Colors.white60 : Colors.white.withValues(alpha: 0.2),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (!unlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.lock,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
