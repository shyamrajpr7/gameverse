import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../services/share_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'share_card.dart';

class SharePreviewDialog extends StatefulWidget {
  final Game game;
  final int score;

  const SharePreviewDialog({
    super.key,
    required this.game,
    required this.score,
  });

  @override
  State<SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<SharePreviewDialog> {
  late TextEditingController _messageController;
  final GameService _gameService = GameService();
  final ShareService _shareService = ShareService();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: 'Can you beat my score?');
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onShare() async {
    setState(() => _sharing = true);
    AudioService().play(SoundType.achievement);
    HapticService.medium();

    final result = await _shareService.capturePng();
    if (!mounted) return;

    if (result != null) {
      ShareService.showSavedToast(context);
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not capture card. Try again.'),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = GameService.getLevel(_gameService.currentXP);
    final screenW = MediaQuery.of(context).size.width;
    final previewScale = (screenW - 48) / ShareCard.cardWidth;
    final previewH = ShareCard.cardHeight * previewScale;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: ShareCard.cardWidth * previewScale,
                    height: previewH,
                    child: RepaintBoundary(
                      key: _shareService.repaintKey,
                      child: ShareCard(
                        game: widget.game,
                        score: widget.score,
                        message: _messageController.text,
                        playerName: _gameService.username,
                        level: level,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF0F0F23),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLength: 60,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a message...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.6),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _sharing ? null : _onShare,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black87,
                                  ),
                                )
                              : const Icon(Icons.image, size: 22),
                          label: Text(
                            _sharing ? 'Saving...' : 'Save Image',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
