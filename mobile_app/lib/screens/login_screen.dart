import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _authUrl;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    if (token != null && token.isNotEmpty) {
      // Token existant, aller directement à l'accueil
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    
    await _getAuthUrl();
  }

  Future<void> _getAuthUrl() async {
    try {
      final response = await _apiService.getAuthUrl();
      setState(() {
        _authUrl = response['auth_url'];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCallback(String code) async {
    if (code.contains('code=')) {
      final uri = Uri.parse(code);
      final codeParam = uri.queryParameters['code'];
      
      if (codeParam != null) {
        code = codeParam;
      }
    }

    try {
      final result = await _apiService.handleCallback(code);
      await _apiService.saveToken(result['access_token']);
      
      // Sauvegarder les infos utilisateur
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, result['user']['id']);
      await prefs.setString(AppConstants.keyUserData, result['user'].toString());
      
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'authentification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1DB954)),
                  SizedBox(height: 20),
                  Text(
                    'Connexion à Spotify...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _authUrl == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Erreur de connexion',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _getAuthUrl,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : WebView(
                  initialUrl: _authUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                  navigationDelegate: (navigation) {
                    // Capturer le code depuis n'importe quelle URL contenant 'code='
                    if (navigation.url.contains('code=')) {
                      try {
                        final uri = Uri.parse(navigation.url);
                        final code = uri.queryParameters['code'];
                        
                        if (code != null && code.isNotEmpty) {
                          print('Code Spotify reçu: ${code.substring(0, 10)}...');
                          _handleCallback(code);
                          return NavigationDecision.prevent;
                        }
                      } catch (e) {
                        print('Erreur parsing URL: $e');
                      }
                    }
                    
                    // Bloquer les URLs Postman pour éviter la boucle
                    if (navigation.url.contains('oauth.pstmn.io')) {
                      return NavigationDecision.prevent;
                    }
                    
                    return NavigationDecision.navigate;
                  },
                ),
    );
  }
}