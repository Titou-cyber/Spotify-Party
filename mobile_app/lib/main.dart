import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_session_screen.dart';
import 'screens/join_session_screen.dart';
import 'screens/session_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger le token sauvegardé
  await ApiService().loadToken();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1DB954), // Spotify Green
          secondary: const Color(0xFF1DB954),
          background: const Color(0xFF191414), // Spotify Black
          surface: const Color(0xFF282828), // Spotify Dark Gray
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF191414),
        cardTheme: CardThemeData( // CHANGÉ ICI
          color: const Color(0xFF282828),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1DB954),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1DB954),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-session': (context) => const CreateSessionScreen(),
        '/join-session': (context) => const JoinSessionScreen(),
        '/session': (context) => const SessionScreen(),
      },
    );
  }
}