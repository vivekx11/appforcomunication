import 'package:flutter/material.dart';
import '../services/signaling_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String userName;
  final String serverUrl;
  final bool isHost;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.serverUrl,
    required this.isHost,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  SignalingService? _signalingService;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeSignaling();
  }

  void _initializeSignaling() {
    _signalingService = SignalingService(
      serverUrl: widget.serverUrl,
      onConnected: () {
        if (mounted) {
          setState(() => _isConnected = true);
          if (widget.isHost) {
            _signalingService!.createRoomWithPasscode(widget.roomId, widget.roomId, widget.userName, (response) {
              if (response['error'] != null) {
                setState(() => _initError = response['error']);
              }
            });
          } else {
            _signalingService!.joinRoomWithPasscode(widget.roomId, widget.roomId, widget.userName, (response) {
              if (response['error'] != null) {
                setState(() => _initError = response['error']);
              }
            });
          }
        }
      },
    );
    _signalingService!.connect();

    _signalingService!.onNewMessage((data) {
      if (mounted) {
        setState(() {
          _messages.add(data);
        });
      }
    });

    _signalingService!.onUserJoined((data) {
      _addSystemMessage("${data['userName']} joined the chat");
    });

    _signalingService!.onPeerLeft((data) {
      _addSystemMessage("A user left the chat");
    });

    _signalingService!.onKicked(() {
      _showError("You have been removed from the room");
      Navigator.pop(context);
    });
  }

  void _addSystemMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add({
          'isSystem': true,
          'text': text,
        });
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _signalingService!.sendMessage(widget.roomId, _messageController.text, (response) {
        if (response['error'] != null) {
          _showError(response['error']);
        }
      });
      _messageController.clear();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _signalingService?.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.roomId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isConnected && _initError == null)
            const LinearProgressIndicator(),
          if (_initError != null)
            Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                _initError!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['isSystem'] == true) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        msg['text'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                }

                final isMe = msg['senderId'] == _signalingService?.socket.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(
                            msg['senderName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        Text(msg['text']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
