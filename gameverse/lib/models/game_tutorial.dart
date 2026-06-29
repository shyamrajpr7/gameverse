import 'package:flutter/material.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class GameTutorial {
  final String gameId;
  final List<TutorialStep> steps;

  const GameTutorial({required this.gameId, required this.steps});

  static const Map<String, GameTutorial> all = {
    'brick_breaker': GameTutorial(
      gameId: 'brick_breaker',
      steps: [
        TutorialStep(
          title: 'Move the Paddle',
          description: 'Drag left or right on the screen to move the paddle. Keep the ball bouncing to break bricks.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Break Bricks',
          description: 'Hit all the bricks to clear each level. Tougher bricks may need multiple hits.',
          icon: Icons.grid_on,
        ),
        TutorialStep(
          title: 'Don\'t Drop the Ball',
          description: 'You have 3 lives. If the ball falls past your paddle, you lose a life. Lose all 3 and it\'s game over.',
          icon: Icons.favorite,
        ),
        TutorialStep(
          title: 'Score & Speed',
          description: 'Each brick gives points. The ball speeds up as you progress, making it harder to keep up.',
          icon: Icons.speed,
        ),
      ],
    ),
    'classic_snake': GameTutorial(
      gameId: 'classic_snake',
      steps: [
        TutorialStep(
          title: 'Swipe to Move',
          description: 'Swipe up, down, left, or right to change the snake\'s direction. The snake keeps moving in the set direction.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Eat Food to Grow',
          description: 'Guide the snake\'s head to the red food pellets. Each pellet makes the snake longer and increases your score.',
          icon: Icons.restaurant,
        ),
        TutorialStep(
          title: 'Avoid Collisions',
          description: 'Don\'t hit the walls or the snake\'s own body. Crashing into either ends the game immediately.',
          icon: Icons.warning,
        ),
        TutorialStep(
          title: 'Speed Increases',
          description: 'As your score grows, the snake moves faster. Plan your moves ahead to survive longer.',
          icon: Icons.trending_up,
        ),
      ],
    ),
    'racing_rivals': GameTutorial(
      gameId: 'racing_rivals',
      steps: [
        TutorialStep(
          title: 'Steer Your Car',
          description: 'Drag left and right on the screen to move your car between lanes. Dodge everything in your way.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Avoid Obstacles',
          description: 'Cones, barriers, and opponent cars block your path. Hit them and it\'s game over.',
          icon: Icons.error_outline,
        ),
        TutorialStep(
          title: 'Score by Surviving',
          description: 'Your score increases the longer you survive and the faster you go. Pass opponents for bonus points.',
          icon: Icons.emoji_events,
        ),
        TutorialStep(
          title: 'Speed Builds Up',
          description: 'The car gets faster over time. The speedometer shows your current pace — stay in control!',
          icon: Icons.speed,
        ),
      ],
    ),
    'pixel_battle': GameTutorial(
      gameId: 'pixel_battle',
      steps: [
        TutorialStep(
          title: 'Tap Enemies to Attack',
          description: 'Tap directly on the red pixel enemies to eliminate them. Each kill scores a point.',
          icon: Icons.touch_app,
        ),
        TutorialStep(
          title: 'Tap Ground to Move',
          description: 'Tap on empty ground to move your character there. Keep dodging incoming enemies.',
          icon: Icons.near_me,
        ),
        TutorialStep(
          title: 'Watch Your Health',
          description: 'Your health bar shows 5 hearts. Enemies that reach you drain health. At 0, it\'s game over.',
          icon: Icons.favorite,
        ),
        TutorialStep(
          title: 'Enemies Get Faster',
          description: 'More enemies spawn as time goes on, and they move faster. Stay sharp!',
          icon: Icons.dangerous,
        ),
      ],
    ),
    'tower_defense': GameTutorial(
      gameId: 'tower_defense',
      steps: [
        TutorialStep(
          title: 'Build Towers',
          description: 'Tap empty grass tiles to build towers. Towers auto-attack enemies that walk along the path.',
          icon: Icons.shield,
        ),
        TutorialStep(
          title: 'Earn & Spend Gold',
          description: 'Kill enemies for gold. Use gold to build more towers or upgrade existing ones. Stronger towers cost more.',
          icon: Icons.monetization_on,
        ),
        TutorialStep(
          title: 'Defend the Base',
          description: 'Enemies follow the winding path toward your base. If too many get through, you lose.',
          icon: Icons.home,
        ),
        TutorialStep(
          title: 'Survive All Waves',
          description: 'Each wave brings tougher enemies. Survive all waves to win with bonus points.',
          icon: Icons.waves,
        ),
      ],
    ),
    'zombie_survival': GameTutorial(
      gameId: 'zombie_survival',
      steps: [
        TutorialStep(
          title: 'Drag to Move',
          description: 'Drag your finger across the screen to move your survivor. Zombies chase you down.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Tap to Shoot',
          description: 'Quickly tap on approaching zombies to shoot them. Each zombie takes 1 hit to kill.',
          icon: Icons.touch_app,
        ),
        TutorialStep(
          title: 'Watch for Tanks',
          description: 'Big green zombies have health bars — they take multiple hits. Prioritize them before they get close.',
          icon: Icons.dangerous,
        ),
        TutorialStep(
          title: 'Survive the Waves',
          description: 'Zombies come in waves. Clear each wave to survive. The game announces incoming waves.',
          icon: Icons.waves,
        ),
      ],
    ),
    'space_wars': GameTutorial(
      gameId: 'space_wars',
      steps: [
        TutorialStep(
          title: 'Move Your Ship',
          description: 'Drag left or right across the screen to move your spaceship. Stay in the play area.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Auto-Fire Shots',
          description: 'Your ship fires automatically. Hit the alien ships to score points.',
          icon: Icons.rocket_launch,
        ),
        TutorialStep(
          title: 'Dodge Enemy Fire',
          description: 'Aliens shoot back and move faster over time. Dodge their projectiles to stay alive.',
          icon: Icons.flash_on,
        ),
        TutorialStep(
          title: '3 Lives',
          description: 'You start with 3 lives. Each hit costs a life. Lose all 3 and it\'s game over.',
          icon: Icons.favorite,
        ),
      ],
    ),
    'ocean_explorer': GameTutorial(
      gameId: 'ocean_explorer',
      steps: [
        TutorialStep(
          title: 'Drag to Dive',
          description: 'Drag your finger to move the diver around. Explore the ocean and avoid dangerous fish.',
          icon: Icons.swipe,
        ),
        TutorialStep(
          title: 'Collect Treasure',
          description: 'Swim over treasure chests and pearls to score points. The deeper you go, the more valuable they are.',
          icon: Icons.sailing,
        ),
        TutorialStep(
          title: 'Watch Your Oxygen',
          description: 'Your oxygen bar slowly depletes. Collect air bubbles to refill it. Running out ends your dive.',
          icon: Icons.air,
        ),
        TutorialStep(
          title: 'Avoid Hazards',
          description: 'Predatory fish and jellyfish damage your oxygen. Dodge them to survive longer.',
          icon: Icons.warning,
        ),
      ],
    ),
    'farm_life': GameTutorial(
      gameId: 'farm_life',
      steps: [
        TutorialStep(
          title: 'Plant Crops',
          description: 'Tap an empty plot to plant a crop. Each crop costs money but sells for more when ready.',
          icon: Icons.agriculture,
        ),
        TutorialStep(
          title: 'Water & Wait',
          description: 'Crops grow over time. Tap them to water and speed up growth. Watch them go from seed to harvest.',
          icon: Icons.opacity,
        ),
        TutorialStep(
          title: 'Harvest & Earn',
          description: 'When crops are fully grown (golden), tap to harvest them. Sell for profit to buy more seeds.',
          icon: Icons.monetization_on,
        ),
        TutorialStep(
          title: 'Grow Your Farm',
          description: 'Plan your farm wisely. Different crops grow at different rates. Maximize your earnings each day.',
          icon: Icons.trending_up,
        ),
      ],
    ),
    'build_world': GameTutorial(
      gameId: 'build_world',
      steps: [
        TutorialStep(
          title: 'Tap to Place Blocks',
          description: 'Tap anywhere in the world to place a block. Build anything you can imagine.',
          icon: Icons.touch_app,
        ),
        TutorialStep(
          title: 'Choose Colors',
          description: 'Pick from the color palette at the bottom. Each tap places a block in the selected color.',
          icon: Icons.palette,
        ),
        TutorialStep(
          title: 'Build & Create',
          description: 'No rules — just build! Stack blocks, make shapes, or create pixel art. Your imagination is the limit.',
          icon: Icons.construction,
        ),
        TutorialStep(
          title: 'Score Over Time',
          description: 'Your score increases for every block placed. Build fast before time runs out!',
          icon: Icons.timer,
        ),
      ],
    ),
    'sky_jumper': GameTutorial(
      gameId: 'sky_jumper',
      steps: [
        TutorialStep(
          title: 'Tap to Jump',
          description: 'Tap the left or right side of the screen to jump in that direction. Time your jumps to land on platforms.',
          icon: Icons.touch_app,
        ),
        TutorialStep(
          title: 'Land on Platforms',
          description: 'Jump onto platforms to stay alive. Missing a platform means falling into the void.',
          icon: Icons.cloud,
        ),
        TutorialStep(
          title: 'Collect Stars',
          description: 'Grab floating stars for bonus points. They\'re worth more the higher you climb.',
          icon: Icons.star,
        ),
        TutorialStep(
          title: 'Climb Higher',
          description: 'The camera scrolls up as you climb. Your score equals your height — how high can you go?',
          icon: Icons.trending_up,
        ),
      ],
    ),
    'puzzle_quest': GameTutorial(
      gameId: 'puzzle_quest',
      steps: [
        TutorialStep(
          title: 'Match Tiles',
          description: 'Tap two tiles to swap them. Match 3 or more tiles of the same color to clear them and score.',
          icon: Icons.extension,
        ),
        TutorialStep(
          title: 'Chain Reactions',
          description: 'Clearing tiles can trigger chain reactions when new matches form. Chain bigger combos for more points.',
          icon: Icons.auto_awesome,
        ),
        TutorialStep(
          title: 'Race the Clock',
          description: 'You have 60 seconds to score as many points as possible. Every match matters.',
          icon: Icons.timer,
        ),
        TutorialStep(
          title: 'Plan Your Moves',
          description: 'Look ahead for the best matches. Matching more tiles at once gives higher scores.',
          icon: Icons.psychology,
        ),
      ],
    ),
  };
}
