import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  late IO.Socket socket;
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Desktop
  final String serverUrl;

  SignalingService({required this.serverUrl});

  void connect() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    socket.onConnect((_) => print('Connected to signaling server'));
    socket.onDisconnect((_) => print('Disconnected from signaling server'));
  }

  void createRoom(String roomId, String passcode, String userName, Function callback) {
    socket.emitWithAck('create-room', {
      'roomId': roomId,
      'passcode': passcode,
      'userName': userName,
    }, ack: (data) => callback(data));
  }

  void joinRoom(String roomId, String passcode, String userName, Function callback) {
    socket.emitWithAck('join-room', {
      'roomId': roomId,
      'passcode': passcode,
      'userName': userName,
    }, ack: (data) => callback(data));
  }

  void sendMessage(String roomId, String message, Function? callback) {
    socket.emitWithAck('send-message', {
      'roomId': roomId,
      'message': message,
    }, ack: (data) => callback?.call(data));
  }

  void onNewMessage(Function(dynamic) callback) {
    socket.on('new-message', (data) => callback(data));
  }

  void onUserJoined(Function(dynamic) callback) {
    socket.on('user-joined', (data) => callback(data));
  }

  void onPeerLeft(Function(dynamic) callback) {
    socket.on('peer-left', (data) => callback(data));
  }

  void onKicked(Function callback) {
    socket.on('kicked', (_) => callback());
  }

  void emit(String event, dynamic data, [Function? callback]) {
    if (callback != null) {
      socket.emitWithAck(event, data, ack: (resp) => callback(resp));
    } else {
      socket.emit(event, data);
    }
  }

  void on(String event, Function callback) {
    socket.on(event, (data) => callback(data));
  }

  void disconnect() {
    socket.disconnect();
  }

  void leaveRoom(String roomId) {
    socket.emit('leave-room', {'roomId': roomId});
  }
}
