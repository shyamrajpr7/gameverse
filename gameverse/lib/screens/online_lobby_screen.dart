import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../services/online_multiplayer_service.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../utils/page_transitions.dart';
import 'online_match_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  final Game game;

  const OnlineLobbyScreen({super.key, required this.game});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final OnlineMultiplayerService _onlineService = OnlineMultiplayerService();
  final GameService _gameService = GameService();
  final TextEditingController _joinCodeController = TextEditingController();

  bool _creating = false;
  bool _joining = false;
  String? _createdMatchId;
  String? _createdJoinCode;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _createMatch() async {
    setState(() => _creating = true);
    try {
      if (!_onlineService.isSignedIn) {
        await _onlineService.signInAnonymously();
      }
      final matchId = await _onlineService.createMatch(
        widget.game.id,
        _gameService.username,
      );
      final match = await _onlineService.getMatch(matchId);
      setState(() {
        _createdMatchId = matchId;
        _createdJoinCode = match.joinCode;
        _creating = false;
      });
    } catch (e) {
      setState(() => _creating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create match: $e')),
        );
      }
    }
  }

  Future<void> _joinMatch() async {
    final code = _joinCodeController.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 4-digit code')),
      );
      return;
    }

    setState(() => _joining = true);
    try {
      if (!_onlineService.isSignedIn) {
        await _onlineService.signInAnonymously();
      }
      final match = await _onlineService.joinMatch(code);
      if (match == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No match found with that code')),
          );
        }
        setState(() => _joining = false);
        return;
      }
      if (mounted) {
        _goToMatch(match.id);
      }
    } catch (e) {
      setState(() => _joining = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join match: $e')),
        );
      }
    }
  }

  void _goToMatch(String matchId) {
    Navigator.pushReplacement(
      context,
      PageTransition.slideUp(OnlineMatchScreen(
        game: widget.game,
        matchId: matchId,
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
          '${widget.game.title} · Online',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          if (_createdMatchId != null && _createdJoinCode != null)
            _buildWaitingRoom()
          else ...[
            _buildCreateSection(),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),
            _buildJoinSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.game.color.withValues(alpha: 0.2),
          ),
          child: Icon(Icons.language, size: 40, color: widget.game.color),
        ),
        const SizedBox(height: 16),
        const Text(
          'Online Multiplayer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a match or join a friend\'s game\nusing a 4-digit code.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildCreateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a Match',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Host a new game and share the code with a friend.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _creating ? null : _createMatch,
            icon: _creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_circle_outline, size: 22),
            label: Text(
              _creating ? 'Creating...' : 'Create Match',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.game.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: widget.game.color.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join a Match',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 4-digit code shared by the host.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _joinCodeController,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '0000',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              width: 100,
              child: ElevatedButton(
                onPressed: _joining ? null : _joinMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.game.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaitingRoom() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.game.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.game.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for opponent...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with a friend:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: _createdJoinCode!),
                  );
                  AudioService().play(SoundType.click);
                  HapticService.light();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copied!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _createdJoinCode!,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.copy,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to copy',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _createdMatchId = null;
                _createdJoinCode = null;
              });
            },
            icon: const Icon(Icons.close, size: 20),
            label: const Text(
              'Cancel Match',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        StreamBuilder<OnlineMatch>(
          stream: _onlineService.watchMatch(_createdMatchId!),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.guest != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _goToMatch(_createdMatchId!);
              });
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
