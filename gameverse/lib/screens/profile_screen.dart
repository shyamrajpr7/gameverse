import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../models/game.dart';
import '../widgets/badge_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GameService _gameService = GameService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final level = GameService.getLevel(_gameService.currentXP);
    final progress = GameService.getProgress(_gameService.currentXP);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LevelBadge(level: level, xp: _gameService.currentXP, progress: progress),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Recent Activity', Icons.history),
                  const SizedBox(height: 12),
                  _buildActivityList(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Badges (${_gameService.unlockedBadges.length}/${allBadges.length})', Icons.workspace_premium),
                  const SizedBox(height: 12),
                  _buildBadgesGrid(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('High Scores', Icons.emoji_events),
                  const SizedBox(height: 12),
                  _buildHighScoresList(),
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
              Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Your gaming journey', style: TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),
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

  Widget _buildActivityList() {
    final played = _gameService.playedGames;
    if (played.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text('No games played yet. Start exploring!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }
    return Column(
      children: played.reversed.take(5).map((gameId) {
        final game = allGames.firstWhere((g) => g.id == gameId, orElse: () => allGames.first);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: game.color.withValues(alpha: 0.2),
                ),
                child: Icon(game.icon, color: game.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('+${game.xpReward} XP earned', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: const Color(0xFFFFD700)),
                    const SizedBox(width: 4),
                    Text('+${game.xpReward}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final unlocked = badge.isUnlocked(_gameService.unlockedBadges);
        return BadgeCard(badge: badge, unlocked: unlocked);
      },
    );
  }

  Widget _buildHighScoresList() {
    if (_gameService.highScores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text('No high scores yet. Play some games!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
        ),
      );
    }
    return Column(
      children: _gameService.highScores.entries.map((entry) {
        final game = allGames.firstWhere((g) => g.id == entry.key, orElse: () => allGames.first);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: game.color.withValues(alpha: 0.2),
                ),
                child: Icon(game.icon, color: game.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(game.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, size: 14, color: const Color(0xFFFFD700)),
                    const SizedBox(width: 4),
                    Text('${entry.value}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
