import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/audio_service.dart';
import 'services/game_service.dart';
import 'services/multiplayer_service.dart';
import 'services/music_service.dart';

Color _themeColor(String id) {
  switch (id) {
    case 'theme_crimson':
      return const Color(0xFFE53935);
    case 'theme_neon_blue':
      return const Color(0xFF00BCD4);
    case 'theme_forest_green':
      return const Color(0xFF43A047);
    default:
      return const Color(0xFFFFD700);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GameVerseApp());
}

class GameVerseApp extends StatefulWidget {
  const GameVerseApp({super.key});

  @override
  State<GameVerseApp> createState() => _GameVerseAppState();
}

class _GameVerseAppState extends State<GameVerseApp> {
  final GameService _gameService = GameService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AudioService().init();
    MusicService().init();
    Future.wait([
      _gameService.load(),
      MultiplayerService().load(),
    ]).then((_) {
      if (mounted) setState(() => _loaded = true);
    });
    _gameService.onDataChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _themeColor(_gameService.equippedTheme);
    return MaterialApp(
      title: 'GameVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.dark(
          primary: accent,
          secondary: const Color(0xFF6C5CE7),
          surface: const Color(0xFF0F0F23),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: _loaded
          ? (_gameService.hasSeenOnboarding
              ? const HomeScreen()
              : const OnboardingScreen())
          : const _SplashLoader(),
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
