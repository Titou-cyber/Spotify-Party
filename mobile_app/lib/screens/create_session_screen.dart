import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _apiService.getUserPlaylists();
      setState(() {
        _playlists = playlists;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement playlists: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      final session = await _apiService.createSession(_selectedPlaylists);
      
      Navigator.pushReplacementNamed(
        context,
        '/session',
        arguments: session,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur création session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            const SizedBox(height: 20),
            
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
                                ? Image.network(
                                    playlist['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[800],
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