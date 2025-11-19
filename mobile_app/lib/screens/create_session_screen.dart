import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/session.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _playlists = [];
  List<String> _selectedPlaylists = [];
  int _votesRequired = 5;
  Session? _createdSession;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 🆕 Initialisation avec chargement du token
  Future<void> _initialize() async {
    try {
      // Charger le token d'abord
      await _apiService.loadToken();
      
      // Ensuite charger les playlists
      await _loadPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _apiService.getUserPlaylists();
      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement playlists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSession() async {
    if (_selectedPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins une playlist'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await _apiService.createSession(
        playlistIds: _selectedPlaylists,
        name: _nameController.text.isEmpty ? null : _nameController.text,
        votesRequired: _votesRequired,
      );
      
      setState(() {
        _createdSession = session;
      });

      // Afficher le code de session
      _showSessionCodeDialog(session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur création session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSessionCodeDialog(Session session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 28),
            SizedBox(width: 10),
            Text(
              'Session créée !',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Partagez ce code avec vos amis :',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.code,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.black),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: session.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copié !'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${session.participants.length} participant(s)',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Votes requis: ${session.votesRequired}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pushReplacementNamed(
                context,
                '/session',
                arguments: session,
              );
            },
            child: const Text(
              'Continuer',
              style: TextStyle(color: Color(0xFF1DB954)),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlaylist(String playlistId) {
    setState(() {
      if (_selectedPlaylists.contains(playlistId)) {
        _selectedPlaylists.remove(playlistId);
      } else {
        _selectedPlaylists.add(playlistId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Créer une session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom de la session
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nom de la session (optionnel)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1DB954)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Nombre de votes requis
            Row(
              children: [
                const Text(
                  'Votes requis:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _votesRequired.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: const Color(0xFF1DB954),
                    label: _votesRequired.toString(),
                    onChanged: (value) {
                      setState(() {
                        _votesRequired = value.toInt();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _votesRequired.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Liste des playlists
            const Text(
              'Sélectionnez vos playlists:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: _playlists.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1DB954)),
                          SizedBox(height: 20),
                          Text(
                            'Chargement des playlists...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists[index];
                        final isSelected = _selectedPlaylists.contains(playlist['id']);
                        
                        return Card(
                          color: const Color(0xFF282828),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: playlist['image_url'] != null && playlist['image_url'].isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      playlist['image_url'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                    ),
                                  ),
                            title: Text(
                              playlist['name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist['tracks_total']} titres',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFF1DB954) : Colors.grey,
                            ),
                            onTap: () => _togglePlaylist(playlist['id']),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton créer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSession,
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
                        'Créer la session',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}