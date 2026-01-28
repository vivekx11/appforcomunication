import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/join_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions for camera and microphone
  await [Permission.camera, Permission.microphone].request();

  runApp(
    const ProviderScope(
      child: VideoMeetingApp(),
    ),
  );
}

class VideoMeetingApp extends StatelessWidget {
  const VideoMeetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeetX Advanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Inter', // Assumed font
      ),
      home: const JoinScreen(),
    );
  }
}
