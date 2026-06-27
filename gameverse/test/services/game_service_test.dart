import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameverse/services/game_service.dart';
import 'package:gameverse/models/game.dart';

void main() {
  group('GameService static helpers', () {
    test('xpForLevel returns correct cumulative XP', () {
      expect(GameService.xpForLevel(1), equals(0));
      expect(GameService.xpForLevel(2), equals(200));
      expect(GameService.xpForLevel(3), equals(600));
      expect(GameService.xpForLevel(4), equals(1200));
      expect(GameService.xpForLevel(5), equals(2000));
      expect(GameService.xpForLevel(10), equals(9000));
    });

    test('getLevel returns correct level for XP', () {
      expect(GameService.getLevel(0), equals(1));
      expect(GameService.getLevel(199), equals(1));
      expect(GameService.getLevel(200), equals(2));
      expect(GameService.getLevel(599), equals(2));
      expect(GameService.getLevel(600), equals(3));
      expect(GameService.getLevel(2000), equals(5));
      expect(GameService.getLevel(9000), equals(10));
    });

    test('getProgress returns 0 at start of level', () {
      final p = GameService.getProgress(200);
      expect(p, closeTo(0.0, 0.001));
    });

    test('getProgress returns ~0.5 mid-level', () {
      final p = GameService.getProgress(400);
      expect(p, closeTo(0.5, 0.01));
    });

    test('getProgress caps at 1.0 when next level XP is unreachable', () {
      final p = GameService.getProgress(599);
      expect(p, closeTo(0.9975, 0.01));
    });
  });

  group('GameService instance', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameService().load();
    });

    test('starts with default values', () {
      final gs = GameService();
      expect(gs.currentXP, equals(0));
      expect(gs.unlockedBadges, isEmpty);
      expect(gs.highScores, isEmpty);
      expect(gs.coins, equals(0));
      expect(gs.username, equals('Player'));
      expect(gs.avatarIndex, equals(0));
      expect(gs.totalGamesPlayed, equals(0));
      expect(gs.currentStreak, equals(0));
      expect(gs.bestStreak, equals(0));
    });

    test('has not seen onboarding by default', () {
      expect(GameService().hasSeenOnboarding, isFalse);
    });

    test('markOnboardingSeen updates state', () async {
      await GameService().markOnboardingSeen();
      expect(GameService().hasSeenOnboarding, isTrue);
    });

    test('updateUsername changes username', () async {
      await GameService().updateUsername('TestUser');
      expect(GameService().username, equals('TestUser'));
    });

    test('updateAvatarIndex changes avatar', () async {
      await GameService().updateAvatarIndex(5);
      expect(GameService().avatarIndex, equals(5));
    });

    test('addXP increases XP', () async {
      await GameService().addXP(500);
      expect(GameService().currentXP, equals(500));
    });

    test('addXP returns first matching badge', () async {
      await GameService().recordGamePlayed('classic_snake');
      final badge = await GameService().addXP(2000);
      // Badge order: first_game > five_games > all_games > level_5 > level_10
      expect(badge, equals('first_game'));
    });

    test('addXP returns level badge after first-game is unlocked', () async {
      await GameService().recordGamePlayed('classic_snake');
      await GameService().addXP(2000); // unlocks 'first_game', currentXP=2000
      final badge = await GameService().addXP(1); // first_game already unlocked, level_5 triggers
      expect(badge, equals('level_5'));
      expect(GameService().unlockedBadges, contains('level_5'));
    });

    test('five_games badge unlocks after playing 5 distinct games', () async {
      // Play 4 games, unlock first_game
      for (int i = 0; i < 4; i++) {
        await GameService().recordGamePlayed('game_$i');
      }
      await GameService().addXP(1); // unlocks 'first_game'

      // Play 5th distinct game
      await GameService().recordGamePlayed('game_4');
      final badge = await GameService().addXP(1);
      expect(badge, equals('five_games'));
      expect(GameService().unlockedBadges, contains('five_games'));
    });

    test('recordGamePlayed increments counter and tracks unique games', () async {
      await GameService().recordGamePlayed('classic_snake');
      expect(GameService().totalGamesPlayed, equals(1));
      expect(GameService().playedGames, contains('classic_snake'));

      await GameService().recordGamePlayed('classic_snake');
      expect(GameService().totalGamesPlayed, equals(2));
      expect(GameService().playedGames, hasLength(1));
    });

    test('updateHighScore stores best score', () async {
      await GameService().updateHighScore('classic_snake', 100);
      expect(GameService().getHighScore('classic_snake'), equals(100));

      await GameService().updateHighScore('classic_snake', 50);
      expect(GameService().getHighScore('classic_snake'), equals(100));

      await GameService().updateHighScore('classic_snake', 200);
      expect(GameService().getHighScore('classic_snake'), equals(200));
    });

    test('updateHighScore awards badge at 1000+', () async {
      await GameService().updateHighScore('classic_snake', 1500);
      expect(GameService().unlockedBadges, contains('high_score'));
    });

    test('favoriteGame returns game with highest score', () async {
      await GameService().updateHighScore('classic_snake', 100);
      await GameService().updateHighScore('sky_jumper', 50);

      final fav = GameService().favoriteGame;
      expect(fav, isNotNull);
      expect(fav!.id, equals('classic_snake'));
    });

    test('favoriteGame returns null when no scores exist', () async {
      SharedPreferences.setMockInitialValues({});
      await GameService().load();
      expect(GameService().highScores, isEmpty);
      expect(GameService().favoriteGame, isNull);
    });

    test('addCoins increases balance', () async {
      await GameService().addCoins(100);
      expect(GameService().coins, equals(100));
    });

    test('spendCoins deducts when sufficient', () async {
      await GameService().addCoins(100);
      final success = await GameService().spendCoins(30);
      expect(success, isTrue);
      expect(GameService().coins, equals(70));
    });

    test('spendCoins fails when insufficient', () async {
      await GameService().addCoins(10);
      final success = await GameService().spendCoins(30);
      expect(success, isFalse);
      expect(GameService().coins, equals(10));
    });

    test('unlockCosmetic and isCosmeticUnlocked', () async {
      expect(GameService().isCosmeticUnlocked('theme_neon'), isFalse);
      await GameService().unlockCosmetic('theme_neon');
      expect(GameService().isCosmeticUnlocked('theme_neon'), isTrue);
    });

    test('equipCosmetic sets theme', () async {
      await GameService().equipCosmetic('theme_crimson');
      expect(GameService().equippedTheme, equals('theme_crimson'));
    });

    test('equipCosmetic sets snake skin', () async {
      await GameService().equipCosmetic('snake_rainbow');
      expect(GameService().equippedSnakeSkin, equals('snake_rainbow'));
    });

    test('getDailyChallenge is deterministic for a given date', () {
      final challenge1 = GameService.getDailyChallenge();
      final challenge2 = GameService.getDailyChallenge();
      expect(challenge1.id, equals(challenge2.id));
      expect(allGames.map((g) => g.id), contains(challenge1.id));
    });

    test('dailyMultiplier returns 2 for daily challenge game', () {
      final challenge = GameService.getDailyChallenge();
      final multiplier = GameService().dailyMultiplier(challenge.id);
      expect(multiplier, equals(2));
    });

    test('dailyMultiplier returns 1 for non-challenge game', () {
      final challenge = GameService.getDailyChallenge();
      final otherGame = allGames.firstWhere((g) => g.id != challenge.id);
      final multiplier = GameService().dailyMultiplier(otherGame.id);
      expect(multiplier, equals(1));
    });

    test('dailyMultiplier returns 1 when daily already completed', () async {
      await GameService().markDailyCompleted();
      final challenge = GameService.getDailyChallenge();
      expect(GameService().dailyMultiplier(challenge.id), equals(1));
    });

    test('streak starts at 1 on first play', () async {
      await GameService().recordGamePlayed('classic_snake');
      expect(GameService().currentStreak, equals(1));
      expect(GameService().bestStreak, equals(1));
    });

    test('avatarIcons has 12 entries', () {
      expect(GameService.avatarIcons, hasLength(12));
    });

    test('avatarIcon returns correct icon', () async {
      await GameService().updateAvatarIndex(0);
      expect(GameService().avatarIcon, equals(GameService.avatarIcons[0]));
    });

    test('playedGames tracks unique game IDs', () async {
      await GameService().recordGamePlayed('game_a');
      await GameService().recordGamePlayed('game_b');
      await GameService().recordGamePlayed('game_a');
      expect(GameService().playedGames, hasLength(2));
      expect(GameService().playedGames, containsAll(['game_a', 'game_b']));
    });
  });
}
