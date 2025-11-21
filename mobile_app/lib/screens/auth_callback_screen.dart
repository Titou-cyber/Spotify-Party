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
  String _status = 'Traitement de l\'authentification...';

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      // Récupérer les paramètres depuis l'URL
      final uri = Uri.base;
      final accessToken = uri.queryParameters['access_token'];
      final userId = uri.queryParameters['user_id'];
      final authError = uri.queryParameters['auth_error'];
      
      if (authError != null) {
        setState(() {
          _status = 'Erreur d\'authentification: ${authError.replaceAll('_', ' ')}';
          _isLoading = false;
        });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      }
      
      if (accessToken != null && userId != null) {
        setState(() => _status = 'Sauvegarde des informations...');
        
        await _apiService.saveToken(accessToken);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserId, userId);
        
        // Nettoyer l'URL (web seulement)
        if (mounted) {
          _cleanUrl();
        }
        
        setState(() => _status = 'Authentification réussie!');
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Paramètres d\'authentification manquants');
      }
    } catch (e) {
      print('❌ Erreur AuthCallback: $e');
      if (mounted) {
        setState(() {
          _status = 'Erreur: $e';
          _isLoading = false;
        });
        
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  void _cleanUrl() {
    // Nettoyer l'URL des paramètres d'authentification
    final cleanUrl = '${AppConstants.apiUrl}/';
    // L'implémentation spécifique dépend de votre setup Flutter Web
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFF1DB954)),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text('Retour'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}