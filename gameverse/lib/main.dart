import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/splash_onboarding_screen.dart';
import 'services/audio_service.dart';
import 'services/game_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    _gameService.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFD700),
          secondary: const Color(0xFF6C5CE7),
          surface: const Color(0xFF0F0F23),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: _loaded
          ? (_gameService.hasSeenOnboarding
              ? const HomeScreen()
              : const SplashOnboardingScreen())
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
