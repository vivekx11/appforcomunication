import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/meeting_provider.dart';
import 'meeting_screen.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _roomIdController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _userNameController = TextEditingController();
  bool _isHost = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_camera_front, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'MeetX Advanced',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _roleButton('Host', true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _roleButton('Guest', false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _userNameController,
                      decoration: _inputDecoration('Your Name', Icons.person),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roomIdController,
                      decoration: _inputDecoration('Room Name', Icons.meeting_room),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passcodeController,
                      decoration: _inputDecoration('4-Digit Passcode', Icons.lock),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _handleJoin,
                        child: Text(_isHost ? 'Create Meeting' : 'Join Meeting', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _roleButton(String text, bool isHost) {
    final isSelected = _isHost == isHost;
    return GestureDetector(
      onTap: () => setState(() => _isHost = isHost),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      counterText: '',
    );
  }

  void _handleJoin() {
    if (_userNameController.text.isEmpty || _roomIdController.text.isEmpty || _passcodeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields correctly')));
      return;
    }

    ref.read(meetingProvider.notifier).join(
          _roomIdController.text,
          _passcodeController.text,
          _userNameController.text,
          _isHost,
        );

    Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingScreen()));
  }
}
