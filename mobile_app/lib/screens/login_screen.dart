import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    if (token != null && token.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }
    
    // Afficher l'interface immédiatement
    setState(() {
      _isLoading = false;
    });
    
    // Charger l'URL en arrière-plan
    _getAuthUrl();
  }

  Future<void> _getAuthUrl() async {
    try {
      final response = await _apiService.getAuthUrl().timeout(
        const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          _authUrl = response['auth_url'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchBrowser() async {
    if (_authUrl != null) {
      await launchUrl(Uri.parse(_authUrl!));
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    
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
      // handleCallback sauvegarde automatiquement token + userId
      final result = await _apiService.handleCallback(code);
      
      // Sauvegarder les données utilisateur supplémentaires
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserData, result['user'].toString());
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      body: SafeArea(
        child: _isLoading
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
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
                        
                        // Bouton principal Spotify
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _launchBrowser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_browser, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Ouvrir Spotify',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Séparateur
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Section code d'autorisation
                        const Text(
                          'Entrez le code d\'autorisation:',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            hintText: 'Collez le code ici...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF1DB954)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Bloc d'instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📋 Instructions:',
                                style: TextStyle(
                                  color: Color(0xFF1DB954),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '1. Cliquez sur "Ouvrir Spotify"\n'
                                '2. Autorisez l\'application\n'
                                '3. Copiez le code de redirection\n'
                                '4. Collez-le ci-dessus et connectez-vous',
                                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }
}