import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../screens/chat_screen.dart';

class MeetingService {
  String generatePin() {
    final random = Random();
    return (1000 + random.nextInt(8999)).toString();
  }

  Future<void> createMeeting(
    String name,
    String purpose,
    BuildContext context,
  ) async {
    String pin = generatePin();

    // Create meeting document
    await FirebaseFirestore.instance.collection('meetings').doc(pin).set({
      'host': name,
      'purpose': purpose,
      'pin': pin,
      'status': 'waiting',
      'guests': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Meeting created! PIN: $pin")));

    final serverUrl = kIsWeb
        ? 'http://localhost:3000'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:3000'
              : 'http://localhost:3000');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          roomId: pin,
          userName: name,
          isHost: true,
          userId: const Uuid().v4(),
          serverUrl: serverUrl,
        ),
      ),
    );
  }

  Future<void> joinMeeting(
    String name,
    String pin,
    BuildContext context,
  ) async {
    var doc = await FirebaseFirestore.instance
        .collection('meetings')
        .doc(pin)
        .get();

    if (!context.mounted) return;

    if (doc.exists) {
      // Add guest to meeting
      await FirebaseFirestore.instance.collection('meetings').doc(pin).update({
        'guests': FieldValue.arrayUnion([name]),
        'status': 'active',
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Joining meeting...")));

      final serverUrl = kIsWeb
          ? 'http://localhost:3000'
          : (defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:3000'
                : 'http://localhost:3000');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: pin,
            userName: name,
            isHost: false,
            userId: const Uuid().v4(),
            serverUrl: serverUrl,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid PIN")));
    }
  }
}
