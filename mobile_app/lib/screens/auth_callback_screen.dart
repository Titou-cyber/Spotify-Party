import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Récupérer le code depuis l'URL
      final uri = Uri.base;
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        print('🔍 Code reçu dans AuthCallback: $code');
        final result = await _apiService.handleCallback(code);
        await _apiService.saveToken(result['access_token']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserId, result['user']['id']);
        await prefs.setString(AppConstants.keyUserData, json.encode(result['user']));
        
        // Rediriger vers home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Aucun code trouvé dans l\'URL');
      }
    } catch (e) {
      print('❌ Erreur AuthCallback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'authentification: $e')),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1DB954)),
            SizedBox(height: 20),
            Text(
              'Connexion en cours...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}