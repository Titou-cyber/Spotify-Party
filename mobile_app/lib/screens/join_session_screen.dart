import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinSession() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code doit contenir 6 caractères'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await _apiService.joinSession(code);
      
      Navigator.pushReplacementNamed(
        context,
        '/session',
        arguments: session,
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Rejoindre une session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_add,
              size: 80,
              color: Color(0xFF1DB954),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Rejoindre une session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            const Text(
              'Entrez le code de session partagé par l\'hôte',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _codeController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'ABCDEF',
                hintStyle: TextStyle(color: Colors.grey),
                counterText: '',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1DB954)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Rejoindre',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Le code de session est affiché sur l\'écran de l\'hôte',
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
}