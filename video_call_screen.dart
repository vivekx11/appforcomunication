import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import '../widgets/video_controls.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String userName;
  final String serverUrl;
  final bool isHost;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.serverUrl,
    required this.isHost,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  SignalingService? _signalingService;
  WebRTCService? _webrtcService;

  // Video renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Connection state
  bool _isConnected = false;
  bool _isInitializing = true;
  final List<String> _logs = [];
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _isInitializing = false);
      });
      return;
    }
    _initializeServices();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initializeServices() async {
    try {
      if (!mounted) return;
      setState(() {
        _isInitializing = true;
        _initError = null;
      });

      // Initialize signaling service
      _signalingService = SignalingService(
        serverUrl: widget.serverUrl,
        onConnected: _onSignalingConnected,
        onError: _onSignalingError,
      );

      // Initialize WebRTC service
      _webrtcService = WebRTCService(
        userId: widget.userId,
        signalingService: _signalingService!,
        onRemoteStreamAdded: _onRemoteStreamAdded,
        onLog: _addLog,
      );

      // Connect to signaling server
      _signalingService!.connect();

      // Initialize WebRTC
      await _webrtcService!.initialize();

      // Set local video source
      if (_webrtcService!.localStream != null) {
        _localRenderer.srcObject = _webrtcService!.localStream;
      }

      if (!mounted) return;
      setState(() => _isInitializing = false);
    } catch (e) {
      _addLog('Initialization error: $e');
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  void _onSignalingConnected() {
    _addLog('Connected to signaling server');

    if (widget.isHost) {
      // Host creates the room
      _signalingService!.createRoom(widget.roomId, widget.userName);
    } else {
      // Guest joins the room
      _signalingService!.joinRoom(widget.roomId, widget.userName);
    }
  }

  void _onSignalingError(String error) {
    _addLog('Signaling error: $error');
    setState(() => _initError ??= error);
    _showError(error);
  }

  void _onRemoteStreamAdded(MediaStream stream) {
    _remoteRenderer.srcObject = stream;
    setState(() => _isConnected = true);
    _addLog('Remote video connected');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 20) _logs.removeAt(0); // Keep only last 20 logs
    });
  }

  void _toggleAudio() {
    _webrtcService?.toggleAudio();
    setState(() {});
  }

  void _toggleVideo() {
    _webrtcService?.toggleVideo();
    setState(() {});
  }

  void _leaveMeeting() {
    _signalingService?.leaveRoom(widget.roomId);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _isConnected
                  ? RTCVideoView(_remoteRenderer)
                  : Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isInitializing
                                  ? 'Connecting...'
                                  : 'Waiting for participant...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                            ),
                            if (_initError != null) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  _initError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (kIsWeb && !_isInitializing) ...[
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _initializeServices,
                                child: Text(
                                  _initError == null ? 'Start' : 'Retry',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),

            // Local video (picture-in-picture)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _webrtcService?.localStream != null
                      ? RTCVideoView(_localRenderer)
                      : Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Meeting info
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room: ${widget.roomId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'User: ${widget.userName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (_isConnected)
                      const Text(
                        'Connected',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

            // Video controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: VideoControls(
                isAudioEnabled: _webrtcService?.isAudioEnabled ?? false,
                isVideoEnabled: _webrtcService?.isVideoEnabled ?? false,
                onToggleAudio: _toggleAudio,
                onToggleVideo: _toggleVideo,
                onLeaveCall: _leaveMeeting,
              ),
            ),

            // Debug logs (optional - can be removed in production)
            if (_logs.isNotEmpty)
              Positioned(
                bottom: 150,
                left: 10,
                right: 10,
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(204),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _webrtcService?.dispose();
    _signalingService?.disconnect();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}
