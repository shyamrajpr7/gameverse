import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoScaleController;
  late AnimationController _logoFadeController;
  late AnimationController _taglineController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _transitionController;
  late PageController _pageController;

  bool _showSplash = true;
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPageData(
      icon: Icons.explore,
      title: 'Discover Games',
      description:
          'Explore 12 retro and modern arcade mini-games.',
      color: Color(0xFFFFD700),
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome,
      title: 'Earn XP & Levels',
      description:
          'Play games to level up your profile.',
      color: Color(0xFF6C5CE7),
    ),
    _OnboardingPageData(
      icon: Icons.workspace_premium,
      title: 'Unlock Badges',
      description:
          'Complete challenges and earn rare achievements.',
      color: Color(0xFFFF6B6B),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pageController = PageController();

    _startSplash();
  }

  void _startSplash() {
    _logoFadeController.forward().then((_) {
      _logoScaleController.forward().then((_) {
        _taglineController.forward().then((_) {
          _particleController.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _transitionController.forward().then((_) {
                  if (mounted) {
                    setState(() => _showSplash = false);
                  }
                });
              }
            });
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _logoFadeController.dispose();
    _logoScaleController.dispose();
    _taglineController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _transitionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _complete() async {
    await GameService().markOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          if (_showSplash) _buildSplash(),
          AnimatedBuilder(
            animation: _transitionController,
            builder: (context, _) {
              return Opacity(
                opacity: _showSplash ? 1.0 - _transitionController.value : 1.0,
                child: _showSplash ? const SizedBox.shrink() : _buildCarousel(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── SPLASH ──

  Widget _buildSplash() {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _SplashParticlePainter(
                progress: _particleController.value,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  _logoFadeController,
                  _logoScaleController,
                  _glowController,
                ]),
                builder: (context, _) => Opacity(
                  opacity: _logoFadeController.value,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * _logoScaleController.value,
                    child: _buildLogo(),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, _) => Opacity(
                  opacity: _taglineController.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _taglineController.value)),
                    child: const Column(
                      children: [
                        Text(
                          'GameVerse',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Discover & Play',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white38,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(
              alpha: 0.25 + 0.2 * _glowController.value,
            ),
            blurRadius: 30 + 25 * _glowController.value,
            spreadRadius: 2 + 5 * _glowController.value,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'GV',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 52,
              color: Colors.black,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }

  // ── CAROUSEL ──

  Widget _buildCarousel() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  _currentPage == 2 ? '' : 'Skip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return _buildPage(p, i);
            }).toList(),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDots(),
                const SizedBox(height: 28),
                _currentPage == 2
                    ? _buildGetStarted()
                    : _buildNextButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage(_OnboardingPageData p, int i) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.color.withValues(alpha: 0.08 + 0.06 * glow),
                        width: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 138, height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color.withValues(alpha: 0.04 + 0.04 * glow),
                      border: Border.all(
                        color: p.color.withValues(alpha: 0.12 + 0.08 * glow),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        p.color.withValues(alpha: 0.15 + 0.1 * glow),
                        p.color.withValues(alpha: 0),
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withValues(alpha: 0.2 + 0.2 * glow),
                          blurRadius: 20 + 18 * glow,
                          spreadRadius: 2 + 3 * glow,
                        ),
                      ],
                    ),
                    child: Icon(p.icon, size: 56, color: p.color),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                p.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: () {
        AudioService().play(SoundType.swipe);
        HapticService.light();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.black,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildGetStarted() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _complete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'GET STARTED',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// ── SPLASH PARTICLES ──

class _SplashParticlePainter extends CustomPainter {
  final double progress;

  const _SplashParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);
    const count = 18;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.6;
      final speed = 60.0 + rng.nextDouble() * 140;
      final radius = 2.0 + rng.nextDouble() * 3.5;
      final colorIndex = rng.nextDouble();
      final t = progress;
      final dx = cos(angle) * speed * t;
      final dy = sin(angle) * speed * t - 50 * t * t;
      final opacity = (1.0 - t * 0.85).clamp(0.0, 1.0);

      paint.color = Color.lerp(
        const Color(0xFFFFD700),
        const Color(0xFF6C5CE7),
        colorIndex,
      )!.withValues(alpha: opacity);

      canvas.drawCircle(
        center + Offset(dx, dy),
        radius * (1 - t * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashParticlePainter old) => old.progress != progress;
}
