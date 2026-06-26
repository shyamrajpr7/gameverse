import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../widgets/game_card.dart';
import '../widgets/daily_challenge_card.dart';
import 'game_detail_screen.dart';
import 'games_list_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameService _gameService = GameService();
  String? _selectedCategory;
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

  List<Game> get _filteredGames {
    if (_selectedCategory == null) return allGames;
    return allGames.where((g) => g.categoryId == _selectedCategory).toList();
  }

  List<Game> get _featuredGames {
    return allGames.where((g) => g.rating >= 4.5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          const SliverToBoxAdapter(child: DailyChallengeCard()),
          _buildFeaturedSection(),
          _buildCategoriesSection(),
          _buildGamesSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
              ),
              child: const Center(
                child: Text('GV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GameVerse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Discover & Play', style: TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
            const Spacer(),
            _buildIconButton(AudioService().isMuted ? Icons.volume_off : Icons.volume_up, () {
              AudioService().toggleMute();
              setState(() {});
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(_gameService.avatarIcon, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featured = _featuredGames;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Text('🔥 Featured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('See All', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              itemCount: featured.length,
              itemBuilder: (context, index) {
                return FeaturedGameCard(
                  game: featured[index],
                  onTap: () {
                    AudioService().play(SoundType.swipe);
                    HapticService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GameDetailScreen(game: featured[index])),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('📂 Categories', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                CategoryChip(
                  category: const GameCategory(id: 'all', name: 'All', icon: Icons.explore, color: Color(0xFF6366F1)),
                  selected: _selectedCategory == null,
                  onTap: () {
                    AudioService().play(SoundType.click);
                    HapticService.selection();
                    setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    category: cat,
                    selected: _selectedCategory == cat.id,
                    onTap: () {
                      AudioService().play(SoundType.click);
                      HapticService.selection();
                      setState(() => _selectedCategory = cat.id);
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection() {
    final games = _filteredGames;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return GameCard(
              game: games[index],
              onTap: () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameDetailScreen(game: games[index])),
                );
              },
            );
          },
          childCount: games.length,
        ),
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        color: const Color(0xFF0A0A1A),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, 'Home', true, () {}),
              _buildNavItem(Icons.grid_view, 'Games', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesListScreen()));
              }),
              _buildNavItem(Icons.leaderboard, 'Leaderboard', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              }),
              _buildNavItem(Icons.person, 'Profile', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFFFD700) : Colors.white38, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFFFD700) : Colors.white38)),
        ],
      ),
    );
  }
}
