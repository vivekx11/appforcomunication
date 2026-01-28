import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'screens/video_call_screen.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final String userName;
  final bool isHost;
  const VideoCallPage({
    super.key,
    required this.channelName,
    required this.userName,
    required this.isHost,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  @override
  Widget build(BuildContext context) {
    final serverUrl = kIsWeb
        ? 'ws://localhost:8080'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'ws://10.0.2.2:8080'
              : 'ws://localhost:8080');
    return VideoCallScreen(
      roomId: widget.channelName,
      userId: const Uuid().v4(),
      userName: widget.userName,
      serverUrl: serverUrl,
      isHost: widget.isHost,
    );
  }
}
