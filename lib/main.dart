import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/map_screen.dart';


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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFDEFF9A),
          secondary: const Color(0xFFDEFF9A),
          surface: const Color(0xFF242424),
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
      home: const FirebaseInitWrapper(),
    );
  }
}

/// Wrapper que inicializa o Firebase antes de exibir o mapa.
class FirebaseInitWrapper extends StatefulWidget {
  const FirebaseInitWrapper({super.key});

  @override
  State<FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<FirebaseInitWrapper> {
  late Future<FirebaseApp> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initFuture,
      builder: (context, snapshot) {
        // Carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFDEFF9A)),
            ),
          );
        }

        // Erro ao inicializar Firebase
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Color(0xFFDEFF9A), size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível conectar ao Firebase.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifique o arquivo google-services.json / GoogleService-Info.plist '
                      'e as configurações do Firebase.\n\nErro: ${snapshot.error}',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Firebase OK — exibe o mapa
        return const MapScreen();
      },
    );
  }
}
