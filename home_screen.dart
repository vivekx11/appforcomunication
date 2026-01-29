import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../screens/video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _createRoomController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoading = false;

  // WebSocket server URL - update with your server IP
  late final String _defaultServerUrl = kIsWeb
      ? 'ws://localhost:8080'
      : (defaultTargetPlatform == TargetPlatform.android
            ? 'ws://10.0.2.2:8080'
            : 'ws://localhost:8080');
  final String _userId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = _defaultServerUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Meeting App'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.blue[600]!, Colors.blue[400]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App Logo/Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.video_call, size: 80, color: Colors.blue[600]),
                    const SizedBox(height: 10),
                    Text(
                      'Start Video Meeting',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: 'Signaling Server URL',
                  prefixIcon: const Icon(Icons.dns),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Create Meeting Section
              _buildSectionCard(
                title: 'Create Meeting',
                icon: Icons.add_circle,
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createMeeting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_call),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Meeting',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Join Meeting Section
              _buildSectionCard(
                title: 'Join Meeting',
                icon: Icons.login,
                child: Column(
                  children: [
                    TextField(
                      controller: _roomIdController,
                      decoration: InputDecoration(
                        labelText: 'Meeting Room ID',
                        prefixIcon: const Icon(Icons.meeting_room),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _joinMeeting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_call),
                                  SizedBox(width: 8),
                                  Text(
                                    'Join Meeting',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Future<void> _createMeeting() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate random room ID
      final roomId = const Uuid().v4().substring(0, 8);

      // Navigate to video call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              roomId: roomId,
              userId: _userId,
              userName: _nameController.text.trim(),
              serverUrl: _serverUrlController.text.trim().isEmpty
                  ? _defaultServerUrl
                  : _serverUrlController.text.trim(),
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create meeting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinMeeting() async {
    if (_roomIdController.text.trim().isEmpty) {
      _showError('Please enter a room ID');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Navigate to video call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              roomId: _roomIdController.text.trim(),
              userId: _userId,
              userName: _nameController.text.trim(),
              serverUrl: _serverUrlController.text.trim().isEmpty
                  ? _defaultServerUrl
                  : _serverUrlController.text.trim(),
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to join meeting: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _nameController.dispose();
    _createRoomController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }
}
