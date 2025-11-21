import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_callback_screen.dart';
import 'screens/create_session_screen.dart';
import 'screens/join_session_screen.dart';
import 'screens/session_screen.dart';

// Services
import 'services/api_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiService _apiService = ApiService();
  String? _initialRoute = '/';
  Map<String, dynamic>? _initialRouteArgs;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await _apiService.loadToken();
    
    // Vérifier si on a un token valide
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    final userId = prefs.getString(AppConstants.keyUserId);
    
    if (token != null && userId != null && token.isNotEmpty) {
      setState(() {
        _initialRoute = '/home';
      });
    } else {
      // Vérifier les paramètres d'URL pour l'authentification (web seulement)
      if (kIsWeb) {
        final uri = Uri.base;
        final accessToken = uri.queryParameters['access_token'];
        
        if (accessToken != null) {
          setState(() {
            _initialRoute = '/auth-callback';
          });
        } else {
          setState(() {
            _initialRoute = '/';
          });
        }
      } else {
        setState(() {
          _initialRoute = '/';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Party',
      theme: ThemeData(
        primaryColor: const Color(0xFF1DB954),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1DB954),
          background: Color(0xFF191414),
          surface: Color(0xFF282828),
        ),
        scaffoldBackgroundColor: const Color(0xFF191414),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF191414),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
        useMaterial3: true,
      ),
      initialRoute: _initialRoute,
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/auth-callback': (context) => const AuthCallbackScreen(),
        '/create-session': (context) => const CreateSessionScreen(),
        '/join-session': (context) => const JoinSessionScreen(),
        '/session': (context) => const SessionScreen(),
      },
      onGenerateRoute: (settings) {
        // Gestion des routes avec arguments
        if (settings.name == '/session' && settings.arguments != null) {
          return MaterialPageRoute(
            builder: (context) => SessionScreen(),
            settings: settings,
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        // Rediriger vers la page de login si route inconnue
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }
}