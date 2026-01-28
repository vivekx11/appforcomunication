import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/peer.dart';
import '../services/signaling_service.dart';
import '../services/mediasoup_service.dart';

final signalingProvider = Provider((ref) => SignalingService());
final mediasoupProvider = Provider((ref) => MediasoupService(ref.read(signalingProvider)));

final meetingProvider = StateNotifierProvider<MeetingNotifier, MeetingState>((ref) {
  return MeetingNotifier(ref.read(signalingProvider), ref.read(mediasoupProvider));
});

class MeetingState {
  final bool isJoined;
  final String? role;
  final List<Peer> peers;
  final RTCVideoRenderer localRenderer;
  final Map<String, RTCVideoRenderer> remoteRenderers;

  MeetingState({
    this.isJoined = false,
    this.role,
    this.peers = const [],
    required this.localRenderer,
    this.remoteRenderers = const {},
  });

  MeetingState copyWith({
    bool? isJoined,
    String? role,
    List<Peer>? peers,
    Map<String, RTCVideoRenderer>? remoteRenderers,
  }) {
    return MeetingState(
      isJoined: isJoined ?? this.isJoined,
      role: role ?? this.role,
      peers: peers ?? this.peers,
      localRenderer: this.localRenderer,
      remoteRenderers: remoteRenderers ?? this.remoteRenderers,
    );
  }
}

class MeetingNotifier extends StateNotifier<MeetingState> {
  final SignalingService _signaling;
  final MediasoupService _mediasoup;
  MediaStream? _localStream;

  MeetingNotifier(this._signaling, this._mediasoup)
      : super(MeetingState(localRenderer: RTCVideoRenderer())) {
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await state.localRenderer.initialize();
  }

  Future<void> join(String roomId, String passcode, String userName, bool isHost) async {
    _signaling.connect();

    final callback = (data) async {
      if (data['error'] != null) {
        print('Error: ${data['error']}');
        return;
      }

      state = state.copyWith(isJoined: true, role: data['role']);
      
      await _mediasoup.init(roomId);
      await _setupLocalMedia();

      // Handle existing producers
      final producers = data['producers'] as List;
      for (var p in producers) {
        _handleNewProducer(roomId, p['producerId'], p['peerId']);
      }

      // Listen for new peers
      _signaling.on('new-producer', (data) {
        _handleNewProducer(roomId, data['producerId'], data['peerId']);
      });

      _signaling.on('peer-left', (data) {
        _handlePeerLeft(data['peerId']);
      });

      _signaling.on('mute-action', (data) {
        // Implement auto-mute from host
      });

      _signaling.on('kicked', (_) {
        leave();
      });
    };

    if (isHost) {
      _signaling.createRoom(roomId, passcode, userName, callback);
    } else {
      _signaling.joinRoom(roomId, passcode, userName, callback);
    }
  }

  Future<void> _setupLocalMedia() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });
    state.localRenderer.srcObject = _localStream;

    await _mediasoup.produceVideo(_localStream!.getVideoTracks().first);
    await _mediasoup.produceAudio(_localStream!.getAudioTracks().first);
  }

  Future<void> _handleNewProducer(String roomId, String producerId, String peerId) async {
    await _mediasoup.consume(roomId, producerId, (consumer) async {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = consumer.stream;

      final updatedRenderers = Map<String, RTCVideoRenderer>.from(state.remoteRenderers);
      updatedRenderers[peerId] = renderer;

      state = state.copyWith(remoteRenderers: updatedRenderers);
    });
  }

  void _handlePeerLeft(String peerId) {
    final updatedRenderers = Map<String, RTCVideoRenderer>.from(state.remoteRenderers);
    updatedRenderers.remove(peerId);
    state = state.copyWith(remoteRenderers: updatedRenderers);
  }

  void leave() {
    _signaling.disconnect();
    state = state.copyWith(isJoined: false, remoteRenderers: {});
  }
}
