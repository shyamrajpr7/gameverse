import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class PuzzleQuestGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const PuzzleQuestGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<PuzzleQuestGame> createState() => _PuzzleQuestGameState();
}

class _PuzzleQuestGameState extends State<PuzzleQuestGame> {
  static const int _gridSize = 4;
  late List<_Tile> _tiles;
  int _score = 0;
  int _selectedIndex = -1;

  bool _gameOver = false;
  final Random _rng = Random();
  late Timer _timer;
  int _timeLeft = 60;

  final List<Color> _colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD93D),
    const Color(0xFF6C5CE7),
    const Color(0xFFFF8A5C),
    const Color(0xFF45B7D1),
    const Color(0xFFA8E6CF),
    const Color(0xFFFF4081),
  ];

  @override
  void initState() {
    super.initState();
    _initBoard();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_gameOver) return;
      _timeLeft--;
      if (_timeLeft <= 0) {
        _gameOver = true;
        widget.onGameOver(_score);
      }
      setState(() {});
    });
  }

  void _initBoard() {
    _tiles = [];
    final colors = [..._colors, ..._colors]..shuffle(_rng);
    for (int i = 0; i < _gridSize * _gridSize; i++) {
      _tiles.add(_Tile(color: colors[i], matched: false));
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTileTap(int index) {
    if (_gameOver) return;
    if (_tiles[index].matched) return;

    if (_selectedIndex == -1) {
      AudioService().play(SoundType.click);
      setState(() => _selectedIndex = index);
      return;
    }

    if (_selectedIndex == index) {
      setState(() => _selectedIndex = -1);
      return;
    }

    if (_tiles[_selectedIndex].color == _tiles[index].color) {
      setState(() {
        _tiles[_selectedIndex].matched = true;
        _tiles[index].matched = true;
        _score += 10;
        _selectedIndex = -1;
        widget.onScoreChanged(_score);
      });

      if (_tiles.every((t) => t.matched)) {
        _gameOver = true;
        _score += _timeLeft * 2;
        widget.onGameOver(_score);
      }
    } else {
      AudioService().play(SoundType.notification);
      setState(() => _selectedIndex = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => widget.onGameOver(_score),
                  ),
                  const Spacer(),
                  _buildStat(Icons.star, '$_score', widget.gameColor),
                  const SizedBox(width: 16),
                  _buildStat(Icons.timer, '$_timeLeft', Colors.white70),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _tiles.length,
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    final isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => _onTileTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: tile.matched
                              ? tile.color.withValues(alpha: 0.1)
                              : isSelected
                                  ? tile.color.withValues(alpha: 0.8)
                                  : tile.color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tile.matched
                                ? Colors.transparent
                                : isSelected
                                    ? tile.color
                                    : tile.color.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: tile.matched
                            ? const Icon(Icons.check, color: Colors.white24, size: 28)
                            : Icon(
                                _getIconForColor(tile.color),
                                color: isSelected ? Colors.white : tile.color,
                                size: 28,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Match pairs of same color', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  IconData _getIconForColor(Color color) {
    const icons = [
      Icons.star, Icons.favorite, Icons.flash_on, Icons.diamond,
      Icons.circle, Icons.square,
    ];
    return icons[_colors.indexOf(color) % icons.length];
  }
}

class _Tile {
  final Color color;
  bool matched;
  _Tile({required this.color, this.matched = false});
}
