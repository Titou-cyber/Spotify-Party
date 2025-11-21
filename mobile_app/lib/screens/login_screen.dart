import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // 1. Vérifier l'authentification existante
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 2. Vérifier si on est dans un callback Spotify (web seulement)
    if (kIsWeb) {
      _checkForSpotifyCallback();
    }
    
    setState(() => _isLoading = false);
  }

  void _checkForSpotifyCallback() {
    final currentUrl = Uri.base.toString();
    if (currentUrl.contains('/api/auth/callback?code=')) {
      _handleSpotifyCallback(currentUrl);
    }
  }

  Future<void> _handleSpotifyCallback(String callbackUrl) async {
    try {
      setState(() => _isLoading = true);
      
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        final result = await _apiService.handleCallback(code);
        await _apiService.saveToken(result['access_token']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyUserId, result['user']['id']);
        await prefs.setString(AppConstants.keyUserData, json.encode(result['user']));
        
        // Nettoyer l'URL
        if (kIsWeb) {
          // Retirer le code de l'URL
          const newUrl = '${AppConstants.apiUrl}/';
          // history.replaceState ne marche pas directement en Flutter web
          // On utilise une redirection
          Future.delayed(Duration.zero, () {
            Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('Erreur auth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithSpotify() async {
    try {
      final authUrl = '${AppConstants.apiUrl}/api/auth/login';
      
      if (kIsWeb) {
        // Web: ouvrir dans le même onglet
        await launchUrl(
          Uri.parse(authUrl),
          webOnlyWindowName: '_self',
        );
      } else {
        // Mobile: méthode manuelle simple
        _showCodeInputDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showCodeInputDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Spotify'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Collez le code Spotify ici',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitCode(codeController.text);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCode(String code) async {
    if (code.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.handleCallback(code);
      await _apiService.saveToken(result['access_token']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, result['user']['id']);
      await prefs.setString(AppConstants.keyUserData, json.encode(result['user']));
      
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    'Chargement...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.music_note,
                      size: 80,
                      color: Color(0xFF1DB954),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Spotify Party',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Écoutez et votez pour la musique ensemble',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _loginWithSpotify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Se connecter avec Spotify',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}