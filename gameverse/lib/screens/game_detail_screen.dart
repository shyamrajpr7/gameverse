import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../games/game_player_screen.dart';
import '../utils/page_transitions.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameService _gameService = GameService();
  int _highScore = 0;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    setState(() {
      _highScore = _gameService.getHighScore(widget.game.id);
      _hasPlayed = _gameService.hasPlayed(widget.game.id);
    });
  }

  void _playGame() async {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    await Navigator.push(
      context,
      PageTransition.slideUp(GamePlayerScreen(game: widget.game)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: widget.game.color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.game.color, widget.game.color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Icon(widget.game.icon, size: 200, color: Colors.white.withValues(alpha: 0.1)),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(widget.game.icon, size: 150, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                left: 20,
                bottom: 80,
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Icon(widget.game.icon, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.game.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('${widget.game.rating}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                            const SizedBox(width: 12),
                            Icon(Icons.people, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(_formatNumber(widget.game.playerCount), style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    );
  }

  Widget _buildContent() {
    final category = categories.firstWhere((c) => c.id == widget.game.categoryId);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayButton(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            const SizedBox(height: 8),
            Text(widget.game.description, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), height: 1.6)),
            const SizedBox(height: 24),
            _buildSectionTitle('Details'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.category, 'Category', category.name, category.color),
            _buildInfoRow(Icons.stars, 'XP Reward', '${widget.game.xpReward} XP', const Color(0xFFFFD700)),
            _buildInfoRow(Icons.visibility, 'Total Visits', _formatNumber(widget.game.visits), Colors.white70),
            _buildInfoRow(Icons.rate_review, 'Reviews', '${widget.game.ratingCount}', Colors.white70),
            if (_hasPlayed) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('Your Stats'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.emoji_events, 'High Score', _highScore.toString(), const Color(0xFFFFD700)),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('Screenshots'),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          widget.game.color.withValues(alpha: 0.3),
                          widget.game.color.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.game.icon, size: 40, color: widget.game.color.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text(
                            'Screenshot ${index + 1}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return PulsingGlow(
      color: widget.game.color,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _playGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.game.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: widget.game.color.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, size: 28),
              const SizedBox(width: 8),
              Text(_hasPlayed ? 'Play Again' : 'Play Now', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(Icons.visibility, _formatNumber(widget.game.visits), 'Visits'),
        _buildStatItem(Icons.people, _formatNumber(widget.game.playerCount), 'Players'),
        _buildStatItem(Icons.star, widget.game.rating.toStringAsFixed(1), 'Rating'),
        _buildStatItem(Icons.stars, '${widget.game.xpReward}', 'XP'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: widget.game.color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
