import 'package:flutter/material.dart';
import '../models/game_tutorial.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class GameTutorialOverlay extends StatefulWidget {
  final GameTutorial tutorial;
  final VoidCallback onDismiss;

  const GameTutorialOverlay({
    super.key,
    required this.tutorial,
    required this.onDismiss,
  });

  @override
  State<GameTutorialOverlay> createState() => _GameTutorialOverlayState();
}

class _GameTutorialOverlayState extends State<GameTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    AudioService().play(SoundType.click);
    HapticService.light();
    if (_currentStep < widget.tutorial.steps.length - 1) {
      _animController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentStep++);
        _animController.forward();
      });
    } else {
      widget.onDismiss();
    }
  }

  void _skip() {
    AudioService().play(SoundType.swipe);
    HapticService.medium();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.tutorial.steps[_currentStep];
    final isLast = _currentStep == widget.tutorial.steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isLast),
            const Spacer(),
            SlideTransition(
              position: _slideIn,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(_currentStep),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            step.icon,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            _buildFooter(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          const Spacer(),
          Text(
            '${_currentStep + 1} / ${widget.tutorial.steps.length}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.tutorial.steps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentStep ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _currentStep
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                isLast ? 'Got it!' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
