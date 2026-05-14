import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JacaMapApp());
}

// ── Theme notifier (accessible globally via ThemeController.of(context)) ────

class ThemeController extends InheritedWidget {
  final bool isDark;
  final VoidCallback toggleTheme;

  const ThemeController({
    super.key,
    required this.isDark,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeController>()!;

  @override
  bool updateShouldNotify(ThemeController old) => isDark != old.isDark;
}

// ── App ────────────────────────────────────────────────────────────────────

class JacaMapApp extends StatefulWidget {
  const JacaMapApp({super.key});

  @override
  State<JacaMapApp> createState() => _JacaMapAppState();
}

class _JacaMapAppState extends State<JacaMapApp> {
  bool _isDark = true;

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      isDark: _isDark,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        title: 'JacaMap',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        home: const AppRoot(),
      ),
    );
  }

  // ── Dark theme ──────────────────────────────────────────────────────────

  static ThemeData _buildDarkTheme() {
    const accent = Color(0xFFDEFF9A);
    const surface = Color(0xFF242424);
    const inputFill = Color(0xFF2E2E2E);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Color(0xFF1A1A1A),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2E2E2E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        hintStyle: const TextStyle(color: Color(0xFF616161)),
      ),
    );
  }

  // ── Light theme ─────────────────────────────────────────────────────────

  static ThemeData _buildLightTheme() {
    const accent = Color(0xFF4A7C1F);       // green darker for light bg
    const accentLight = Color(0xFF6BAF2E);  // lighter variant
    const surface = Color(0xFFF5F5F5);
    const inputFill = Color(0xFFEEEEEE);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: surface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF212121)),
        bodyLarge: TextStyle(color: Color(0xFF212121)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Non-blocking anonymous auth — map loads as soon as auth completes
    await AuthService().signInAnonymously();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.of(context).isDark;

    if (!_ready) {
      final accent = isDark ? const Color(0xFFDEFF9A) : const Color(0xFF4A7C1F);
      final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);

      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_city_rounded, color: accent, size: 56),
              const SizedBox(height: 20),
              CircularProgressIndicator(color: accent),
              const SizedBox(height: 16),
              Text(
                'JacaMap',
                style: TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const MapScreen();
  }
}
