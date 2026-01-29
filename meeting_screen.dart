import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/meeting_provider.dart';

class MeetingScreen extends ConsumerWidget {
  const MeetingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingState = ref.watch(meetingProvider);
    final remoteRenderers = meetingState.remoteRenderers;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Meeting: ${meetingState.isJoined ? "Connected" : "Connecting..."}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () {
              ref.read(meetingProvider.notifier).leave();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: remoteRenderers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _VideoTile(
                    renderer: meetingState.localRenderer,
                    label: 'You (Host: ${meetingState.role == 'host'})',
                    isLocal: true,
                  );
                }
                final peerId = remoteRenderers.keys.elementAt(index - 1);
                return _VideoTile(
                  renderer: remoteRenderers[peerId]!,
                  label: 'Participant $peerId',
                  isLocal: false,
                  onRemove: meetingState.role == 'host'
                      ? () => _showHostControls(context, ref, peerId)
                      : null,
                );
              },
            ),
          ),
          _ControlBar(),
        ],
      ),
    );
  }

  void _showHostControls(BuildContext context, WidgetRef ref, String peerId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mic_off),
            title: const Text('Mute Participant'),
            onTap: () {
              // ref.read(meetingProvider.notifier).mutePeer(peerId);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('Remove from Meeting'),
            onTap: () {
              // ref.read(meetingProvider.notifier).kickPeer(peerId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final String label;
  final bool isLocal;
  final VoidCallback? onRemove;

  const _VideoTile({
    required this.renderer,
    required this.label,
    required this.isLocal,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: isLocal,
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                onPressed: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.grey[950],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(icon: Icons.mic, onPressed: () {}),
          _ActionButton(icon: Icons.videocam, onPressed: () {}),
          _ActionButton(icon: Icons.screen_share, onPressed: () {}),
          _ActionButton(icon: Icons.chat, onPressed: () {}),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
