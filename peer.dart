import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class Peer {
  final String id;
  final String userName;
  final String role;
  final Map<String, Consumer> consumers;
  bool isAudioMuted;
  bool isVideoDisabled;
  bool isScreenSharing;

  Peer({
    required this.id,
    required this.userName,
    required this.role,
    this.consumers = const {},
    this.isAudioMuted = false,
    this.isVideoDisabled = false,
    this.isScreenSharing = false,
  });
}
