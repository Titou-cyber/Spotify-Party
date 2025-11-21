import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

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
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    await _apiService.loadToken();
    
    // Vérifier les paramètres d'URL pour l'authentification (web seulement)
    if (kIsWeb) {
      final uri = Uri.base;
      final accessToken = uri.queryParameters['access_token'];
      final authError = uri.queryParameters['auth_error'];
      
      print('🌐 URL détectée: ${uri.toString()}');
      print('🔑 AccessToken dans URL: $accessToken');
      print('❌ AuthError dans URL: $authError');
      
      if (accessToken != null && accessToken.isNotEmpty) {
        print('🔑 Token détecté dans l\'URL, connexion automatique...');
        await _handleUrlAuth(uri.queryParameters);
        setState(() {
          _initialRoute = '/home';
          _isCheckingAuth = false;
        });
        return;
      } else if (authError != null) {
        print('❌ Erreur d\'auth dans l\'URL: $authError');
        // Nettoyer l'URL et rester sur login
        _cleanUrl();
      }
    }
    
    // Vérifier l'authentification existante
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    final userId = prefs.getString(AppConstants.keyUserId);
    
    print('📝 Token stocké: $token');
    print('👤 UserId stocké: $userId');
    
    if (token != null && userId != null && token.isNotEmpty) {
      setState(() {
        _initialRoute = '/home';
        _isCheckingAuth = false;
      });
    } else {
      setState(() {
        _initialRoute = '/';
        _isCheckingAuth = false;
      });
    }
  }

  Future<void> _handleUrlAuth(Map<String, String> params) async {
    try {
      final accessToken = params['access_token'];
      final userId = params['user_id'];
      
      // VÉRIFICATION DE NULLITÉ AVANT D'UTILISER !
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ AccessToken manquant dans les paramètres');
        return;
      }
      
      if (userId == null || userId.isEmpty) {
        print('❌ UserId manquant dans les paramètres');
        return;
      }
      
      print('✅ Paramètres valides, sauvegarde du token...');
      
      await _apiService.saveToken(accessToken);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, userId);
      
      // Nettoyer l'URL
      _cleanUrl();
      
      print('✅ Connexion automatique réussie pour l\'utilisateur: $userId');
    } catch (e) {
      print('❌ Erreur lors de la connexion automatique: $e');
    }
  }

  void _cleanUrl() {
    // Nettoyer l'URL des paramètres d'authentification
    if (kIsWeb) {
      try {
        final cleanUrl = '${AppConstants.apiUrl}/';
        // Utiliser l'API History pour changer l'URL sans recharger
        js.context.callMethod('history.replaceState', [null, '', cleanUrl]);
        print('🔧 URL nettoyée: $cleanUrl');
      } catch (e) {
        print('⚠️ Impossible de nettoyer l\'URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loading pendant la vérification de l'authentification
    if (_isCheckingAuth) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF191414),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1DB954)),
                const SizedBox(height: 20),
                const Text(
                  'Connexion en cours...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

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