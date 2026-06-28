import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/multiplayer.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../utils/page_transitions.dart';
import 'multiplayer_play_screen.dart';

class MultiplayerSetupScreen extends StatefulWidget {
  final Game game;

  const MultiplayerSetupScreen({super.key, required this.game});

  @override
  State<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends State<MultiplayerSetupScreen> {
  int _playerCount = 2;
  final List<TextEditingController> _nameControllers = [];

  static const _avatars = [
    Icons.face,
    Icons.pets,
    Icons.rocket_launch,
    Icons.sports_esports,
    Icons.auto_awesome,
    Icons.bolt,
    Icons.diamond,
    Icons.local_fire_department,
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameControllers.clear();
    for (int i = 0; i < _playerCount; i++) {
      _nameControllers.add(TextEditingController(text: 'Player ${i + 1}'));
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updatePlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _initControllers();
    });
  }

  void _startMatch() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();

    final players = <MultiplayerPlayer>[];
    for (int i = 0; i < _playerCount; i++) {
      final name =
          _nameControllers[i].text.trim().isEmpty
              ? 'Player ${i + 1}'
              : _nameControllers[i].text.trim();
      players.add(MultiplayerPlayer(
        id: 'p${DateTime.now().millisecondsSinceEpoch}_$i',
        name: name,
      ));
    }

    final session = MultiplayerSession(
      gameId: widget.game.id,
      players: players,
    );

    Navigator.pushReplacement(
      context,
      PageTransition.slideUp(MultiplayerPlayScreen(
        game: widget.game,
        session: session,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.game.title} · Multiplayer',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPlayerCountSelector(),
                const SizedBox(height: 24),
                ...List.generate(_playerCount, (i) => _buildPlayerField(i)),
              ],
            ),
          ),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.game.color.withValues(alpha: 0.2),
          ),
          child: Icon(Icons.people, size: 40, color: widget.game.color),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hot-Seat Mode',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Pass the device between players.\nHighest score wins!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPlayerCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Players', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [2, 3, 4].map((count) {
            final selected = _playerCount == count;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _updatePlayerCount(count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? widget.game.color
                        : Colors.white.withValues(alpha: 0.1),
                    border: selected
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayerField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(_avatars[index % _avatars.length], color: widget.game.color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameControllers[index],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Player ${index + 1}',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.game.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'P${index + 1}',
                style: TextStyle(color: widget.game.color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text('Start Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.game.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: widget.game.color.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
