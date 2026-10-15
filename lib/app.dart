import 'package:flutter/material.dart';

import 'core/game_controller.dart';
import 'core/local_store.dart';
import 'core/models.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';

class LudoApp extends StatefulWidget {
  const LudoApp({super.key});

  @override
  State<LudoApp> createState() => _LudoAppState();
}

class _LudoAppState extends State<LudoApp> {
  final _store = LocalStore();
  GameController? _controller;
  GameState? _restored;
  String? _initializationError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    late final GameSettings settings;
    try {
      settings = await _store.loadSettings();
    } on Exception catch (error) {
      _showInitializationError(error);
      return;
    }

    final controller = GameController(store: _store, settings: settings);
    try {
      await controller.restoreGame();
    } on Exception catch (error) {
      controller.dispose();
      _showInitializationError(error);
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _restored = controller.state;
      _loading = false;
    });
  }

  void _showInitializationError(Exception error) {
    if (!mounted) return;
    setState(() {
      _initializationError = error.toString();
      _loading = false;
    });
  }

  ThemeData _theme(GameSettings settings) {
    final dark = settings.theme == GameTheme.dark;
    final seed = switch (settings.theme) {
      GameTheme.neon => const Color(0xff9b5de5),
      GameTheme.wooden => const Color(0xff9a6235),
      GameTheme.classic => const Color(0xff4267b2),
      GameTheme.dark => const Color(0xff8ab4f8),
    };
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    final background = settings.theme == GameTheme.wooden
        ? const Color(0xfff1e4d1)
        : settings.theme == GameTheme.neon
            ? const Color(0xfff6f0ff)
            : null;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: background ?? scheme.surface,
        titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load your saved game settings.'),
                  const SizedBox(height: 8),
                  Text(_initializationError!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _initializationError = null;
                        _loading = true;
                      });
                      _initialize();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_loading || _controller == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: const Color(0xff4267b2), useMaterial3: true),
        home: const _SplashScreen(),
      );
    }
    final controller = _controller!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        title: 'Offline Ludo',
        debugShowCheckedModeBanner: false,
        theme: _theme(controller.settings),
        home: HomeScreen(
          controller: controller,
          hasSavedGame: _restored != null && controller.state != null,
          onGameStarted: () => setState(() => _restored = null),
          onContinue: () {
            if (controller.state != null) {
              controller.resumeCurrentTurn();
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => GameScreen(controller: controller),
              ));
            }
          },
          onSettings: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => SettingsScreen(controller: controller),
          )),
          onStatistics: () =>
              Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => StatisticsScreen(store: _store),
          )),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: .75, end: 1).animate(CurvedAnimation(
                  parent: _animation, curve: Curves.elasticOut)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 76)),
                  const SizedBox(height: 12),
                  Text('LUDO',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w900, letterSpacing: 8)),
                  const Text('PLAY TOGETHER · ANYWHERE'),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}
