import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.keyUserData);
    
    if (userData != null) {
      try {
        final userMap = json.decode(userData);
        setState(() {
          _userName = userMap['display_name'] ?? 'Utilisateur Spotify';
          _userEmail = userMap['email'];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _userName = 'Utilisateur';
          _isLoading = false;
        });
      }
    } else {
      final userId = prefs.getString(AppConstants.keyUserId);
      setState(() {
        _userName = userId != null ? 'Utilisateur Spotify' : 'Utilisateur';
        _isLoading = false;
      });
    }
  }

  void _createSession() {
    Navigator.pushNamed(context, '/create-session');
  }

  void _joinSession() {
    Navigator.pushNamed(context, '/join-session');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAccessToken);
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserData);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF191414),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1DB954)),
              const SizedBox(height: 20),
              const Text(
                'Chargement...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Spotify Party'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userName != null)
              Column(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1DB954),
                    radius: 40,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bonjour, $_userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userEmail != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _userEmail!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            
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
              'Créez ou rejoignez une session musicale collaborative',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            
            _buildActionButton(
              "Créer une session",
              Icons.add,
              const Color(0xFF1DB954),
              _createSession,
            ),
            const SizedBox(height: 20),
            
            _buildActionButton(
              "Rejoindre une session",
              Icons.group,
              Colors.blue,
              _joinSession,
            ),
            const SizedBox(height: 30),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Partagez vos playlists et votez pour la prochaine musique en temps réel!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}