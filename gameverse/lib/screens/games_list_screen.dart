import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import 'game_detail_screen.dart';
import '../utils/page_transitions.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  String _searchQuery = '';
  String? _sortBy;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Game> get _filteredGames {
    var games = List<Game>.from(allGames);
    if (_selectedCategory != null) {
      games = games.where((g) => g.categoryId == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      games = games.where((g) =>
        g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        g.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    switch (_sortBy) {
      case 'popular':
        games.sort((a, b) => b.visits.compareTo(a.visits));
        break;
      case 'rating':
        games.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'players':
        games.sort((a, b) => b.playerCount.compareTo(a.playerCount));
        break;
      default:
        break;
    }
    return games;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Games', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterRow(),
          Expanded(child: _buildGamesGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search games...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.4)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('Category', _selectedCategory, () => _showCategoryPicker()),
          const SizedBox(width: 8),
          _buildFilterChip('Sort', _sortBy ?? 'Relevance', () => _showSortPicker()),
          const Spacer(),
          Text('${_filteredGames.length} games', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(width: 4),
            Text(value ?? 'All', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text('All', style: TextStyle(color: _selectedCategory == null ? Colors.white : Colors.white60)),
                  backgroundColor: _selectedCategory == null ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.1),
                  onPressed: () { setState(() => _selectedCategory = null); Navigator.pop(ctx); },
                ),
                ...categories.map((cat) => ActionChip(
                  label: Text(cat.name, style: TextStyle(color: _selectedCategory == cat.id ? Colors.white : cat.color)),
                  backgroundColor: _selectedCategory == cat.id ? cat.color : Colors.white.withValues(alpha: 0.1),
                  onPressed: () { setState(() => _selectedCategory = cat.id); Navigator.pop(ctx); },
                )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...['Relevance', 'popular', 'rating', 'players'].map((opt) => ListTile(
              leading: Icon(
                opt == 'Relevance' ? Icons.arrow_upward :
                opt == 'popular' ? Icons.trending_up :
                opt == 'rating' ? Icons.star : Icons.people,
                color: Colors.white60,
              ),
              title: Text(
                opt == 'popular' ? 'Most Popular' :
                opt == 'rating' ? 'Highest Rated' :
                opt == 'players' ? 'Most Players' : 'Relevance',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: (_sortBy == null && opt == 'Relevance') || _sortBy == opt
                  ? const Icon(Icons.check, color: Color(0xFFFFD700))
                  : null,
              onTap: () {
                setState(() => _sortBy = opt == 'Relevance' ? null : opt);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesGrid() {
    final games = _filteredGames;
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No games found', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) => StaggeredFadeIn(
          index: index,
          child: GameCard(
            game: games[index],
            onTap: () => Navigator.push(
              context,
              PageTransition.slideUp(GameDetailScreen(game: games[index])),
            ),
          ),
        ),
      ),
    );
  }
}
