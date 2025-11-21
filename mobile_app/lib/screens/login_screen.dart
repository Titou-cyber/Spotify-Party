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
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loginWithSpotify() async {
    try {
      if (kIsWeb) {
        // Pour le web : ouvrir dans le même onglet
        final authUrl = '${AppConstants.apiUrl}/api/auth/login';
        await launchUrl(
          Uri.parse(authUrl),
          webOnlyWindowName: '_self', // Ouvre dans le même onglet
        );
      } else {
        // Pour mobile : méthode manuelle avec code (version simplifiée)
        _showManualAuthDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showManualAuthDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentification Spotify'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pour mobile, utilisez cette méthode:'),
            const SizedBox(height: 10),
            const Text(
              '1. Allez sur: ${AppConstants.apiUrl}/api/auth/login\n'
              '2. Autorisez l\'application\n'
              '3. Copiez le code de l\'URL\n'
              '4. Collez-le ci-dessous',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code d\'autorisation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _submitManualCode(codeController.text),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitManualCode(String code) async {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.handleCallback(code);
      await _apiService.saveToken(result['access_token']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, result['user']['id']);
      await prefs.setString(AppConstants.keyUserData, json.encode(result['user']));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
                    'Vérification...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : Padding(
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
                    'Connectez-vous avec Spotify pour commencer',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
                  
                  if (!kIsWeb) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Sur mobile, vous devrez copier-coller le code d\'autorisation',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}