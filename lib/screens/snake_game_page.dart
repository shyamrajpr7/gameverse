import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gamification_service.dart';

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

enum Direction { up, down, left, right }

class _SnakeGamePageState extends State<SnakeGamePage> with TickerProviderStateMixin {
  static const int rows = 20;
  static const int columns = 20;
  
  // Colors for a premium neon aesthetic
  static const Color _bgCanvas = Color(0xFF0F172A);
  static const Color _boardBg = Color(0xFF1E293B);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _rose = Color(0xFFF43F5E);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _whiteText = Color(0xFFF1F5F9);
  static const Color _slateText = Color(0xFF94A3B8);

  List<Point<int>> snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
  Point<int> food = const Point(5, 5);
  Direction direction = Direction.up;
  Direction nextDirection = Direction.up;
  
  Timer? gameTimer;
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;

  late AnimationController _foodPulseController;
  late Animation<double> _foodPulseAnimation;

  @override
  void initState() {
    super.initState();
    _foodPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _foodPulseAnimation = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _foodPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _foodPulseController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
      direction = Direction.up;
      nextDirection = Direction.up;
      score = 0;
      isPlaying = true;
      isGameOver = false;
      _spawnFood();
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _moveSnake();
    });
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(newFood));
    setState(() {
      food = newFood;
    });
  }

  void _moveSnake() {
    setState(() {
      direction = nextDirection;
      final head = snake.first;
      Point<int> newHead;

      switch (direction) {
        case Direction.up:
          newHead = Point(head.x, head.y - 1);
          break;
        case Direction.down:
          newHead = Point(head.x, head.y + 1);
          break;
        case Direction.left:
          newHead = Point(head.x - 1, head.y);
          break;
        case Direction.right:
          newHead = Point(head.x + 1, head.y);
          break;
      }

      // Check collision with walls
      if (newHead.x < 0 || newHead.x >= columns || newHead.y < 0 || newHead.y >= rows) {
        _gameOver();
        return;
      }

      // Check collision with itself
      if (snake.contains(newHead)) {
        _gameOver();
        return;
      }

      snake.insert(0, newHead);

      // Check if food eaten
      if (newHead == food) {
        score += 10;
        if (score > highScore) highScore = score;
        
        // Award XP via GamificationService
        GamificationService().addXP(2);
        
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _gameOver() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    HapticFeedback.heavyImpact();
  }

  void _handleSwipe(DragEndDetails details) {
    if (!isPlaying) return;
    
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    
    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 0 && direction != Direction.left) {
        nextDirection = Direction.right;
      } else if (dx < 0 && direction != Direction.right) {
        nextDirection = Direction.left;
      }
    } else {
      // Vertical swipe
      if (dy > 0 && direction != Direction.up) {
        nextDirection = Direction.down;
      } else if (dy < 0 && direction != Direction.down) {
        nextDirection = Direction.up;
      }
    }
  }

  Widget _buildCell(Point<int> p) {
    final isHead = p == snake.first;
    final isFood = p == food;
    final isBody = snake.contains(p) && !isHead;

    if (isFood) {
      return AnimatedBuilder(
        animation: _foodPulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _foodPulseAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _rose,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _rose.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (isHead) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(0.9),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
      );
    } else if (isBody) {
      final index = snake.indexOf(p);
      final opacity = 1.0 - (index / snake.length) * 0.5; // Fade out towards tail
      
      return Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: _cyan.withOpacity(opacity),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(opacity * 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _boardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: columns / rows,
                  child: GestureDetector(
                    onPanEnd: _handleSwipe,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _boardBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cyan.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                            ),
                            itemCount: rows * columns,
                            itemBuilder: (context, index) {
                              final x = index % columns;
                              final y = index ~/ columns;
                              return _buildCell(Point(x, y));
                            },
                          ),
                          if (!isPlaying && !isGameOver) _buildStartOverlay(),
                          if (isGameOver) _buildGameOverOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _boardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slateText.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _whiteText, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _boardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: _cyan.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: _cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  score.toString().padLeft(3, '0'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _whiteText,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _boardBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('HIGH', style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w800)),
                Text(
                  highScore.toString(),
                  style: const TextStyle(color: _emerald, fontSize: 16, fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _bgCanvas.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyan.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded, color: _cyan, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'NEON SNAKE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _whiteText,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swipe or use buttons to move',
                  style: TextStyle(color: _slateText, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bgCanvas,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: _cyan.withOpacity(0.5),
                  ),
                  child: const Text('START GAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _bgCanvas.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _rose.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: _rose.withOpacity(0.1), blurRadius: 30, spreadRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CRASHED',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _rose,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SCORE: $score',
                  style: const TextStyle(fontSize: 18, color: _whiteText, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+XP Awarded!',
                  style: TextStyle(fontSize: 14, color: _emerald, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _whiteText,
                    foregroundColor: _bgCanvas,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(Icons.keyboard_arrow_left_rounded, () {
            if (direction != Direction.right) nextDirection = Direction.left;
          }),
          const SizedBox(width: 16),
          Column(
            children: [
              _buildControlButton(Icons.keyboard_arrow_up_rounded, () {
                if (direction != Direction.down) nextDirection = Direction.up;
              }),
              const SizedBox(height: 16),
              _buildControlButton(Icons.keyboard_arrow_down_rounded, () {
                if (direction != Direction.up) nextDirection = Direction.down;
              }),
            ],
          ),
          const SizedBox(width: 16),
          _buildControlButton(Icons.keyboard_arrow_right_rounded, () {
            if (direction != Direction.left) nextDirection = Direction.right;
          }),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _boardBg,
          shape: BoxShape.circle,
          border: Border.all(color: _cyan.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: _cyan, size: 32),
      ),
    );
  }
}
