import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/gamification_service.dart';

const Color _bgCanvas = Color(0xFF0F172A);
const Color _violet = Color(0xFF8B5CF6);
const Color _cyan = Color(0xFF06B6D4);
const Color _rose = Color(0xFFF43F5E);
const Color _whiteText = Color(0xFFF1F5F9);

class FlappyBirdPage extends StatefulWidget {
  const FlappyBirdPage({super.key});

  @override
  State<FlappyBirdPage> createState() => _FlappyBirdPageState();
}

class _FlappyBirdPageState extends State<FlappyBirdPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  
  double birdY = 0;
  double birdVelocity = 0;
  final double gravity = -0.04;
  final double jumpStrength = 0.45;

  double pipeX = 1.5;
  double pipeGapHeight = 0.0;
  final double pipeWidth = 0.2;
  final double gapSize = 0.5;

  bool gameStarted = false;
  bool gameOver = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (gameOver || !gameStarted) return;

    setState(() {
      birdVelocity += gravity;
      birdY -= birdVelocity * 0.1;

      pipeX -= 0.015;

      if (pipeX < -1.5) {
        pipeX = 1.5;
        pipeGapHeight = -0.4 + (Random().nextDouble() * 0.8);
        score++;
        GamificationService().addXP(5);
      }

      if (_checkCollision()) {
        _gameOver();
      }

      if (birdY > 1 || birdY < -1) {
        _gameOver();
      }
    });
  }

  bool _checkCollision() {
    const double birdRadiusX = 0.1;
    const double birdRadiusY = 0.05;
    
    if (pipeX < birdRadiusX && pipeX + pipeWidth > -birdRadiusX) {
      double gapTop = pipeGapHeight - gapSize / 2;
      double gapBottom = pipeGapHeight + gapSize / 2;
      
      if (birdY < gapTop || birdY > gapBottom) {
        return true;
      }
    }
    return false;
  }

  void _jump() {
    if (gameOver) {
      setState(() {
        birdY = 0;
        birdVelocity = 0;
        pipeX = 1.5;
        score = 0;
        gameStarted = false;
        gameOver = false;
      });
      return;
    }

    if (!gameStarted) {
      setState(() => gameStarted = true);
      _ticker.start();
    }

    setState(() {
      birdVelocity = jumpStrength;
    });
  }

  void _gameOver() {
    gameOver = true;
    _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            // Bird
            Container(
              alignment: Alignment(0, birdY),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _violet,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _violet.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
              ),
            ),
            
            // Top Pipe
            Container(
              alignment: Alignment(pipeX, -1),
              child: Container(
                width: MediaQuery.of(context).size.width * pipeWidth / 2,
                height: (MediaQuery.of(context).size.height * (0.5 + pipeGapHeight - gapSize / 2) / 2).clamp(0, double.infinity),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(color: _cyan.withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
              ),
            ),
            
            // Bottom Pipe
            Container(
              alignment: Alignment(pipeX, 1),
              child: Container(
                width: MediaQuery.of(context).size.width * pipeWidth / 2,
                height: (MediaQuery.of(context).size.height * (0.5 - pipeGapHeight - gapSize / 2) / 2).clamp(0, double.infinity),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(color: _cyan.withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
              ),
            ),

            // Score and UI overlays
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: _whiteText),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _whiteText,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            if (!gameStarted && !gameOver)
              Center(
                child: Text(
                  'TAP TO START',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _whiteText.withValues(alpha: 0.5),
                    letterSpacing: 4,
                  ),
                ),
              ),

            if (gameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _bgCanvas.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _rose.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CRASHED',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _rose, letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      Text('Score: $score', style: const TextStyle(fontSize: 24, color: _whiteText)),
                      const SizedBox(height: 8),
                      Text('+${score * 5} XP Earned!', style: const TextStyle(fontSize: 16, color: _cyan, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      const Text('Tap anywhere to try again', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
