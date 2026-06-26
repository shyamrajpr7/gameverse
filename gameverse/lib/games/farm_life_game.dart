import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class FarmLifeGame extends StatefulWidget {
  final Color gameColor;
  final Function(int) onScoreChanged;
  final Function(int) onGameOver;

  const FarmLifeGame({
    super.key,
    required this.gameColor,
    required this.onScoreChanged,
    required this.onGameOver,
  });

  @override
  State<FarmLifeGame> createState() => _FarmLifeGameState();
}

class _FarmLifeGameState extends State<FarmLifeGame> {
  final List<_Crop> _crops = [];
  int _score = 0;
  int _money = 30;
  int _day = 1;
  bool _gameOver = false;
  int _frame = 0;
  late Timer _gameTimer;
  final Random _rng = Random();
  String _mode = 'plant';

  @override
  void initState() {
    super.initState();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), _update);
    for (int i = 0; i < 6; i++) {
      _crops.add(_Crop(
        x: 0.1 + (i % 3) * 0.35,
        y: 0.15 + (i ~/ 3) * 0.35,
        state: 'empty',
      ));
    }
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _update(Timer timer) {
    if (_gameOver) return;
    _frame++;

    if (_frame % 50 == 0) {
      for (final c in _crops) {
        if (c.state == 'planted' && _rng.nextDouble() < 0.3) c.state = 'grown';
        if (c.state == 'grown' && _rng.nextDouble() < 0.2) c.state = 'ready';
      }
    }

    if (_frame % 200 == 0) {
      _day++;
      _money += 5;
    }

    if (_money <= 0 && _crops.every((c) => c.state == 'empty')) {
      _gameOver = true;
      widget.onGameOver(_score);
    }

    setState(() {});
  }

  void _onPlotTap(int index) {
    if (_gameOver) return;
    final crop = _crops[index];
    if (_mode == 'plant' && crop.state == 'empty' && _money >= 5) {
      crop.state = 'planted';
      _money -= 5;
      AudioService().play(SoundType.collect);
      HapticService.light();
    } else if (_mode == 'harvest' && crop.state == 'ready') {
      crop.state = 'empty';
      _score += 10;
      _money += 15;
      widget.onScoreChanged(_score);
      AudioService().play(SoundType.achievement);
      HapticService.medium();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => widget.onGameOver(_score)),
              const Spacer(),
              _badge(Icons.attach_money, '$_money', widget.gameColor),
              const SizedBox(width: 6),
              _badge(Icons.emoji_events, '$_score', Colors.amberAccent),
              const SizedBox(width: 6),
              _badge(Icons.wb_sunny, 'Day $_day', Colors.orange),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: _crops.length,
              itemBuilder: (context, index) {
                final crop = _crops[index];
                return GestureDetector(
                  onTap: () => _onPlotTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: crop.state == 'empty' ? const Color(0xFF3D2B1F).withValues(alpha: 0.5) :
                             crop.state == 'planted' ? const Color(0xFF2D5A27) :
                             crop.state == 'grown' ? const Color(0xFF4CAF50) :
                             const Color(0xFFFFD700),
                      border: Border.all(color: crop.state == 'ready' ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Icon(
                        crop.state == 'empty' ? Icons.grass :
                        crop.state == 'planted' ? Icons.eco :
                        crop.state == 'grown' ? Icons.local_florist :
                        Icons.agriculture,
                        color: crop.state == 'ready' ? Colors.brown :
                               crop.state == 'empty' ? Colors.brown.withValues(alpha: 0.3) :
                               Colors.green.withValues(alpha: 0.7),
                        size: 36,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeBtn('plant', Icons.eco, 'Plant (\$5)'),
                const SizedBox(width: 12),
                _modeBtn('harvest', Icons.back_hand, 'Harvest'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16), const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _modeBtn(String id, IconData icon, String label) {
    final active = _mode == id;
    return GestureDetector(
      onTap: () {
        AudioService().play(SoundType.click);
        HapticService.selection();
        setState(() => _mode = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? widget.gameColor : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? Colors.white : Colors.white54, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _Crop {
  double x, y;
  String state; // empty, planted, grown, ready
  _Crop({required this.x, required this.y, required this.state});
}
