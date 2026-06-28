import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/multiplayer.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/multiplayer_service.dart';
import '../services/game_service.dart';

class MultiplayerResultsScreen extends StatefulWidget {
  final Game game;
  final MultiplayerSession session;

  const MultiplayerResultsScreen({
    super.key,
    required this.game,
    required this.session,
  });

  @override
  State<MultiplayerResultsScreen> createState() => _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends State<MultiplayerResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _saveResults();
  }

  Future<void> _saveResults() async {
    if (_saved) return;
    _saved = true;
    await MultiplayerService().load();
    await MultiplayerService().saveSession(widget.session);
    await GameService().load();
    await GameService().addXP(30);
    await GameService().addCoins(10);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ranked = widget.session.rankedPlayers;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildTrophy(ranked),
            const SizedBox(height: 20),
            Text(
              widget.game.title,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 4,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: ranked.length,
                itemBuilder: (context, index) {
                  return _buildRankCard(ranked[index], index, ranked.length);
                },
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophy(List<MultiplayerPlayer> ranked) {
    final winner = ranked.isNotEmpty ? ranked.first : null;
    final isTie = ranked.length > 1 && ranked[0].score == ranked[1].score;

    return Column(
      children: [
        Icon(
          isTie ? Icons.emoji_events : Icons.emoji_events,
          size: 64,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 12),
        Text(
          isTie ? "It's a Tie!" : '${winner?.name} Wins!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        if (winner?.score != null)
          Text(
            'Score: ${winner!.score}',
            style: const TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
          ),
      ],
    );
  }

  Widget _buildRankCard(MultiplayerPlayer player, int rank, int total) {
    final score = player.score ?? 0;
    final maxScore = widget.session.rankedPlayers.first.score ?? 1;
    final fraction = maxScore > 0 ? score / maxScore : 0.0;

    final medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
    final isTop3 = rank < 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: rank == 0
                ? widget.game.color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 0
                  ? widget.game.color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  isTop3 ? medals[rank] : '#${rank + 1}',
                  style: TextStyle(
                    fontSize: isTop3 ? 20 : 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rank == 0 ? const Color(0xFFFFD700) : widget.game.color,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AudioService().play(SoundType.click);
                  HapticService.light();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home, size: 20),
                label: const Text('Home', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AudioService().play(SoundType.swipe);
                  HapticService.medium();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.replay, size: 20),
                label: const Text('Rematch', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
