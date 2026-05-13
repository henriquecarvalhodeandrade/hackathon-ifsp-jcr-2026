import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/map_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBhWVGh6ilnUwiQUIxYpyWTlq4NlVdeRbI",
      authDomain: "hackathon-ifsp-jcr-2026.firebaseapp.com",
      projectId: "hackathon-ifsp-jcr-2026",
      storageBucket: "hackathon-ifsp-jcr-2026.firebasestorage.app",
      messagingSenderId: "257325050721",
      appId: "1:257325050721:web:75b95679d27424d089b320",
      measurementId: "G-90QHMKC757",
    ),
  );

  runApp(const ZeladoriaApp());
}

class ZeladoriaApp extends StatelessWidget {
  const ZeladoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeladoria Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDEFF9A),
          secondary: Color(0xFFDEFF9A),
          surface: Color(0xFF242424),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFDEFF9A),
          foregroundColor: Color(0xFF1A1A1A),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E2E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDEFF9A), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          hintStyle: const TextStyle(color: Color(0xFF616161)),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AuthService _authService = AuthService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _authService.signInAnonymously();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_city_rounded, color: Color(0xFFDEFF9A), size: 56),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFFDEFF9A)),
              SizedBox(height: 16),
              Text(
                'Zeladoria Digital',
                style: TextStyle(
                  color: Color(0xFFDEFF9A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        return const MapScreen();
      },
    );
  }
}
