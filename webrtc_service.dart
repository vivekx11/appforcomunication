import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

/// WebRTC service for peer-to-peer video calling
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentRoomId;
  String? _currentTargetUserId;
  final String userId;
  final SignalingService signalingService;
  final Function(MediaStream) onRemoteStreamAdded;
  final Function(String) onLog;

  WebRTCService({
    required this.userId,
    required this.signalingService,
    required this.onRemoteStreamAdded,
    required this.onLog,
  });

  /// Initialize WebRTC connection and get user media
  Future<void> initialize() async {
    try {
      await _createPeerConnection();
      await _getUserMedia();
      onLog('WebRTC initialized successfully');
    } catch (e) {
      onLog('Failed to initialize WebRTC: $e');
      rethrow;
    }
  }

  /// Create RTCPeerConnection with STUN server
  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      onLog('ICE candidate generated');
      if (_currentRoomId == null || _currentTargetUserId == null) {
        return;
      }
      if (candidate.candidate == null) {
        return;
      }
      signalingService
          .sendIceCandidate(_currentRoomId!, _currentTargetUserId!, {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
    };

    // Handle remote stream
    _peerConnection!.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      onRemoteStreamAdded(stream);
      onLog('Remote stream added');
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      onLog('Connection state: $state');
    };
  }

  /// Get user media (camera and microphone)
  Future<void> _getUserMedia() async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      _peerConnection!.addStream(_localStream!);
      onLog('Local media stream obtained');
    } catch (e) {
      onLog('Error getting user media: $e');
      rethrow;
    }
  }

  /// Create WebRTC offer (for caller)
  Future<void> createOffer(String targetUserId, String roomId) async {
    try {
      _currentRoomId = roomId;
      _currentTargetUserId = targetUserId;

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send offer via signaling
      signalingService.sendOffer(roomId, targetUserId, {
        'sdp': offer.sdp,
        'type': offer.type,
      });

      onLog('Offer created and sent');
    } catch (e) {
      onLog('Error creating offer: $e');
    }
  }

  /// Handle incoming WebRTC offer (for callee)
  Future<void> handleOffer(
    Map<String, dynamic> offerData,
    String targetUserId,
    String roomId,
  ) async {
    try {
      _currentRoomId = roomId;
      _currentTargetUserId = targetUserId;

      RTCSessionDescription offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer via signaling
      signalingService.sendAnswer(roomId, targetUserId, {
        'sdp': answer.sdp,
        'type': answer.type,
      });

      onLog('Answer created and sent');
    } catch (e) {
      onLog('Error handling offer: $e');
    }
  }

  /// Handle incoming WebRTC answer
  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );

      await _peerConnection!.setRemoteDescription(answer);
      onLog('Answer set successfully');
    } catch (e) {
      onLog('Error handling answer: $e');
    }
  }

  /// Handle incoming ICE candidate
  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);
      onLog('ICE candidate added');
    } catch (e) {
      onLog('Error handling ICE candidate: $e');
    }
  }

  /// Toggle microphone mute/unmute
  Future<void> toggleAudio() async {
    if (_localStream != null) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
      onLog('Audio ${!enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Toggle camera on/off
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      bool enabled = _localStream!.getVideoTracks()[0].enabled;
      _localStream!.getVideoTracks()[0].enabled = !enabled;
      onLog('Video ${!enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Get current audio state
  bool get isAudioEnabled => _localStream?.getAudioTracks().isNotEmpty == true
      ? _localStream!.getAudioTracks()[0].enabled
      : false;

  /// Get current video state
  bool get isVideoEnabled => _localStream?.getVideoTracks().isNotEmpty == true
      ? _localStream!.getVideoTracks()[0].enabled
      : false;

  /// Get local media stream
  MediaStream? get localStream => _localStream;

  /// Get remote media stream
  MediaStream? get remoteStream => _remoteStream;

  /// Clean up resources
  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    onLog('WebRTC service disposed');
  }
}
