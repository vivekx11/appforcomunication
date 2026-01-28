import 'package:flutter/material.dart';

/// Video controls widget for mute/unmute and camera on/off functionality
class VideoControls extends StatelessWidget {
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onLeaveCall;

  const VideoControls({
    super.key,
    required this.isAudioEnabled,
    required this.isVideoEnabled,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onLeaveCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(204),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute button
          GestureDetector(
            onTap: onToggleAudio,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAudioEnabled ? Colors.grey[700] : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAudioEnabled ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Camera On/Off button
          GestureDetector(
            onTap: onToggleVideo,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isVideoEnabled ? Colors.grey[700] : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Leave call button
          GestureDetector(
            onTap: onLeaveCall,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
