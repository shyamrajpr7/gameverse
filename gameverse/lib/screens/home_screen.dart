import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../services/music_service.dart';
import '../widgets/game_card.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/particle_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/ui_enhancements.dart';
import 'game_detail_screen.dart';
import 'games_list_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'shop_screen.dart';
import '../utils/page_transitions.dart';

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
    MusicService().play(MusicTrack.menu);
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerLoader(width: 120, height: 120, borderRadius: 60),
              const SizedBox(height: 20),
              ShimmerLoader(width: 200, height: 20),
              const SizedBox(height: 8),
              ShimmerLoader(width: 160, height: 14),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ParticleBackground(
        color: const Color(0xFF6C5CE7),
        particleCount: 30,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            const SliverToBoxAdapter(child: DailyChallengeCard()),
            _buildFeaturedSection(),
            _buildCategoriesSection(),
            _buildGamesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 18,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                ),
                child: const Center(
                  child: Text('GV',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GameVerse',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.95))),
                    Text('Discover & Play',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              _buildIconButton(
                  AudioService().isMuted || MusicService().isMuted ? Icons.volume_off : Icons.volume_up,
                  () {
                AudioService().toggleMute();
                MusicService().toggleMute();
                setState(() {});
              }),
              const SizedBox(width: 6),
              _buildIconButton(Icons.settings, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(context,
                    PageTransition.fadeScale(const SettingsScreen()));
              }),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  AudioService().play(SoundType.click);
                  HapticService.light();
                  Navigator.push(context,
                      PageTransition.fadeScale(const ShopScreen()));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        const Color(0xFFFFD700).withValues(alpha: 0.15),
                    border: Border.all(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_bag,
                          color: Color(0xFFFFD700), size: 20),
                      if (_gameService.coins > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFD700),
                            ),
                            child: Text(
                              '${_gameService.coins}',
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  AudioService().play(SoundType.click);
                  HapticService.light();
                  Navigator.push(context,
                      PageTransition.fadeScale(const ProfileScreen()));
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  child: Icon(_gameService.avatarIcon,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.07),
        ),
        child:
            Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
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
                AnimatedGradientText(
                  text: 'Featured',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                    Color(0xFF6C5CE7),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    PageTransition.fadeScale(const GamesListScreen()),
                  ),
                  child: Text('See All',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
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
                      PageTransition.slideUp(
                          GameDetailScreen(game: featured[index])),
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
            child: Text('Categories',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9))),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                CategoryChip(
                  category: const GameCategory(
                      id: 'all',
                      name: 'All',
                      icon: Icons.explore,
                      color: Color(0xFF6366F1)),
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
            return StaggeredFadeIn(
              index: index,
              child: GameCard(
                game: games[index],
                index: index,
                onTap: () {
                  AudioService().play(SoundType.click);
                  HapticService.light();
                  Navigator.push(
                    context,
                    PageTransition.slideUp(
                        GameDetailScreen(game: games[index])),
                  );
                },
              ),
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
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        color: const Color(0xFF0A0A1A),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  Icons.home_filled, 'Home', true, () {}, 0),
              _buildNavItem(
                  Icons.grid_view, 'Games', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(
                    context, PageTransition.fadeScale(const GamesListScreen()));
              }, 1),
              _buildNavItem(
                  Icons.leaderboard, 'Leaderboard', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(
                    context,
                    PageTransition.fadeScale(const LeaderboardScreen()));
              }, 2),
              _buildNavItem(
                  Icons.bar_chart, 'Stats', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(
                    context, PageTransition.fadeScale(const StatsScreen()));
              }, 3),
              _buildNavItem(
                  Icons.person, 'Profile', false, () {
                AudioService().play(SoundType.click);
                HapticService.light();
                Navigator.push(
                    context, PageTransition.fadeScale(const ProfileScreen()));
              }, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool active, VoidCallback onTap, int index) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active
              ? const Color(0xFFFFD700).withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.35),
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active
                        ? const Color(0xFFFFD700)
                        : Colors.white.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }
}
