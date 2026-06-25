import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gamification_service.dart';

class RacingGamePage extends StatefulWidget {
  const RacingGamePage({super.key});

  @override
  State<RacingGamePage> createState() => _RacingGamePageState();
}

class _RacingGamePageState extends State<RacingGamePage> with TickerProviderStateMixin {
  // Core colors for Synthwave / Neon aesthetic
  static const Color _bgDeep = Color(0xFF04060F);
  static const Color _neonCyan = Color(0xFF00F3FF);
  static const Color _neonPink = Color(0xFFFF00E5);
  static const Color _neonPurple = Color(0xFF9D00FF);
  static const Color _neonGold = Color(0xFFFFD700);
  static const Color _whiteText = Color(0xFFFFFFFF);

  // Game state
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  double speedMultiplier = 1.0;

  // Player state
  int playerLane = 1; // 0: Left, 1: Middle, 2: Right

  // Entities
  final List<_Obstacle> obstacles = [];
  final List<_Coin> coins = [];

  // Loops
  Timer? gameLoop;
  Timer? spawnLoop;

  // Animation controllers for effects
  late AnimationController _gridPhaseController;

  @override
  void initState() {
    super.initState();
    _gridPhaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    spawnLoop?.cancel();
    _gridPhaseController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      speedMultiplier = 1.0;
      playerLane = 1;
      obstacles.clear();
      coins.clear();
    });

    gameLoop?.cancel();
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });

    spawnLoop?.cancel();
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    if (!isPlaying) return;
    
    // Spawn rate increases as speed increases
    final baseDelay = 1200;
    final delay = (baseDelay / speedMultiplier).clamp(400, 1500).toInt();
    
    spawnLoop = Timer(Duration(milliseconds: delay), () {
      _spawnEntity();
      if (isPlaying) _scheduleNextSpawn();
    });
  }

  void _spawnEntity() {
    final random = Random();
    final lane = random.nextInt(3);
    
    // 20% chance for a coin, 80% for obstacle
    if (random.nextDouble() > 0.8) {
      coins.add(_Coin(lane: lane, y: -0.2));
    } else {
      obstacles.add(_Obstacle(lane: lane, y: -0.2));
    }
  }

  void _updateGame() {
    setState(() {
      score += (1 * speedMultiplier).toInt();
      if (score > highScore) highScore = score;

      speedMultiplier += 0.0002; // Gradually increase speed

      final double moveAmount = 0.02 * speedMultiplier;

      // Update obstacles
      for (int i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].y += moveAmount;
        
        // Collision check
        if (obstacles[i].lane == playerLane && obstacles[i].y > 0.75 && obstacles[i].y < 0.95) {
          _gameOver();
          return;
        }
        
        // Remove off-screen
        if (obstacles[i].y > 1.2) {
          obstacles.removeAt(i);
        }
      }

      // Update coins
      for (int i = coins.length - 1; i >= 0; i--) {
        coins[i].y += moveAmount;
        
        // Collision check
        if (coins[i].lane == playerLane && coins[i].y > 0.75 && coins[i].y < 0.95) {
          // Collect coin
          coins.removeAt(i);
          score += 500;
          GamificationService().addXP(1);
          HapticFeedback.lightImpact();
          continue;
        }
        
        // Remove off-screen
        if (coins[i].y > 1.2) {
          coins.removeAt(i);
        }
      }
    });
  }

  void _gameOver() {
    gameLoop?.cancel();
    spawnLoop?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    
    // Award chunk XP on game over based on score
    final earnedXP = (score / 1000).floor();
    if (earnedXP > 0) {
      GamificationService().addXP(earnedXP);
    }
  }

  void _moveLeft() {
    if (playerLane > 0 && isPlaying) {
      setState(() => playerLane--);
      HapticFeedback.selectionClick();
    }
  }

  void _moveRight() {
    if (playerLane < 2 && isPlaying) {
      setState(() => playerLane++);
      HapticFeedback.selectionClick();
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (!isPlaying) return;
    if (details.primaryVelocity! < -300) {
      _moveLeft();
    } else if (details.primaryVelocity! > 300) {
      _moveRight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _moveLeft();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _moveRight();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: _bgDeep,
      body: GestureDetector(
        onHorizontalDragEnd: _handleSwipe,
        child: Stack(
          children: [
            // Background Synthwave Grid
            AnimatedBuilder(
              animation: _gridPhaseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SynthwaveGridPainter(
                    phase: _gridPhaseController.value,
                    speedMultiplier: speedMultiplier,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Sun/Moon glowing orb in background
            Align(
              alignment: const Alignment(0, -0.6),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_neonPink, _neonPurple],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(color: _neonPink.withOpacity(0.5), blurRadius: 60, spreadRadius: 20),
                  ],
                ),
                child: CustomPaint(painter: _SunScanlinesPainter()),
              ),
            ),

            // Horizon Line
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _neonCyan,
                  boxShadow: [
                    BoxShadow(color: _neonCyan, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
              ),
            ),

            // Game Area (Perspective transform wrapper could be added, but relying on visual scaling here)
            SafeArea(
              child: Stack(
                children: [
                  _buildHeader(),
                  
                  // Entities (Obstacles and Coins)
                  ...obstacles.map((obs) => _buildObstacle(obs)),
                  ...coins.map((coin) => _buildCoin(coin)),
                  
                  // Player Car
                  if (!isGameOver) _buildPlayerCar(),
                  
                  // Overlays
                  if (!isPlaying && !isGameOver) _buildStartOverlay(),
                  if (isGameOver) _buildGameOverOverlay(),
                ],
              ),
            ),

            // Controls
            if (isPlaying)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildControlButton(Icons.keyboard_double_arrow_left_rounded, _moveLeft, playerLane > 0),
                      _buildControlButton(Icons.keyboard_double_arrow_right_rounded, _moveRight, playerLane < 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildPlayerCar() {
    // 0 -> -0.6, 1 -> 0, 2 -> 0.6
    final alignX = (playerLane - 1) * 0.6;
    
    return AnimatedAlign(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      alignment: Alignment(alignX, 0.8),
      child: Container(
        width: 60,
        height: 100,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: _neonCyan.withOpacity(0.8), blurRadius: 30, spreadRadius: 5),
            BoxShadow(color: _whiteText.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        child: CustomPaint(painter: _PlayerCarPainter()),
      ),
    );
  }

  Widget _buildObstacle(_Obstacle obs) {
    final alignX = (obs.lane - 1) * 0.6;
    
    // Scale based on Y to give fake 3D depth (smaller at top, larger at bottom)
    // Map y from -0.2 (horizon) to 1.0 (bottom)
    // Horizon is roughly center screen (y=0 in Align coordinates? No, Align is -1 to 1).
    // Let's manually map our obs.y (0 to 1) to Align coordinates (-1 to 1).
    // Wait, obs.y in our logic goes from -0.2 to 1.2.
    // We map y=0 to Align.y=0 (center), y=1 to Align.y=1 (bottom).
    final screenY = (obs.y * 2) - 1; 
    
    // Scale factor: 0.2 at horizon, 1.0 at bottom
    final scale = (obs.y + 0.2).clamp(0.1, 1.5);
    
    return Align(
      alignment: Alignment(alignX, screenY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _bgDeep,
            border: Border.all(color: _neonPink, width: 3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: _neonPink.withOpacity(0.8), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: const Center(
            child: Icon(Icons.warning_rounded, color: _neonPink, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildCoin(_Coin coin) {
    final alignX = (coin.lane - 1) * 0.6;
    final screenY = (coin.y * 2) - 1; 
    final scale = (coin.y + 0.2).clamp(0.1, 1.5);

    return Align(
      alignment: Alignment(alignX, screenY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _neonGold.withOpacity(0.2),
            border: Border.all(color: _neonGold, width: 2),
            boxShadow: [
              BoxShadow(color: _neonGold.withOpacity(0.8), blurRadius: 15, spreadRadius: 3),
            ],
          ),
          child: const Center(
            child: Icon(Icons.stars_rounded, color: _neonGold, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgDeep.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _neonCyan.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: _neonCyan.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _neonCyan, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _bgDeep.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _neonPink.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: _neonPink.withOpacity(0.3), blurRadius: 20),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded, color: _neonPink, size: 24),
                const SizedBox(width: 12),
                Text(
                  score.toString().padLeft(6, '0'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    color: _whiteText,
                    letterSpacing: 2,
                    shadows: [Shadow(color: _neonPink, blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _bgDeep.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _neonCyan.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: _neonCyan.withOpacity(0.2), blurRadius: 50, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.electric_car_rounded, color: _neonCyan, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'NEON RACER',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _whiteText,
                    letterSpacing: 6,
                    shadows: [Shadow(color: _neonCyan, blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Swipe or tap to dodge',
                  style: TextStyle(color: _neonCyan, fontSize: 16, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: startGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_neonCyan, _neonPurple]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _neonCyan.withOpacity(0.6), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const Text('IGNITE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _bgDeep, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _bgDeep.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _neonPink.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: _neonPink.withOpacity(0.2), blurRadius: 50, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WRECKED',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: _neonPink,
                    letterSpacing: 8,
                    shadows: [Shadow(color: _neonPink, blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SCORE\n$score',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, color: _whiteText, fontWeight: FontWeight.w900, letterSpacing: 4),
                ),
                const SizedBox(height: 16),
                Text(
                  'BEST: $highScore',
                  style: TextStyle(fontSize: 14, color: _neonCyan.withOpacity(0.8), fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: startGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: _neonPink, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _neonPink.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _neonPink, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: active ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgDeep.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: _neonCyan.withOpacity(0.5), width: 2),
            boxShadow: [
              if (active) BoxShadow(color: _neonCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Icon(icon, color: _neonCyan, size: 36),
        ),
      ),
    );
  }
}

class _Obstacle {
  int lane;
  double y; // 0.0 to 1.0
  _Obstacle({required this.lane, required this.y});
}

class _Coin {
  int lane;
  double y;
  _Coin({required this.lane, required this.y});
}

// ─── Custom Painters for 1000x UI Effects ───

class _SynthwaveGridPainter extends CustomPainter {
  final double phase;
  final double speedMultiplier;

  _SynthwaveGridPainter({required this.phase, required this.speedMultiplier});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF00E5).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final glowPaint = Paint()
      ..color = const Color(0xFFFF00E5).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final horizonY = size.height * 0.5;
    
    // Draw radiating perspective lines
    final vanishingPoint = Offset(size.width / 2, horizonY);
    
    // We want lines to radiate outwards below the horizon
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      final bottomPoint = Offset(x, size.height);
      
      // Calculate intersection at horizon
      // Since they all converge at vanishingPoint, we just draw from vanishingPoint to bottomPoint
      canvas.drawLine(vanishingPoint, bottomPoint, glowPaint);
      canvas.drawLine(vanishingPoint, bottomPoint, paint);
    }

    // Draw horizontal moving lines
    // We use exponential spacing to simulate perspective
    final numLines = 15;
    for (int i = 0; i < numLines; i++) {
      // Add phase to make them move downwards
      double normalizedY = (i + phase) / numLines; // 0.0 to 1.0
      
      // Apply perspective curve (exponential)
      double perspectiveY = pow(normalizedY, 3).toDouble(); 
      
      final y = horizonY + (size.height - horizonY) * perspectiveY;
      
      if (y > horizonY && y <= size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SynthwaveGridPainter oldDelegate) => true;
}

class _SunScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF04060F)
      ..strokeWidth = 3;

    // Draw horizontal cuts across the sun
    for (double y = size.height * 0.4; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerCarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    // A sleek futuristic wedge shape pointing upwards
    path.moveTo(size.width / 2, 0); // Top center
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(size.width / 2, size.height * 0.8); // Inner bottom center
    path.lineTo(0, size.height); // Bottom left
    path.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00F3FF), Color(0xFF9D00FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    
    // Engine glow at bottom
    final glowPath = Path();
    glowPath.moveTo(size.width * 0.3, size.height * 0.9);
    glowPath.lineTo(size.width * 0.7, size.height * 0.9);
    glowPath.lineTo(size.width * 0.5, size.height * 1.2);
    glowPath.close();
    
    final engineGlow = Paint()
      ..color = const Color(0xFFFF00E5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
    canvas.drawPath(glowPath, engineGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
