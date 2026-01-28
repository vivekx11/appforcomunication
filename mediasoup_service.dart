import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';
import 'signaling_service.dart';

class MediasoupService {
  final SignalingService signaling;
  late Device device;
  Transport? sendTransport;
  Transport? recvTransport;
  Map<String, Producer> producers = {};
  Map<String, Consumer> consumers = {};

  MediasoupService(this.signaling);

  Future<void> init(String roomId) async {
    // 1. Get Router RTP Capabilities
    signaling.emit('get-router-rtp-capabilities', {'roomId': roomId}, (data) async {
      final routerRtpCapabilities = RtpCapabilities.fromMap(data);
      
      // 2. Load Device
      device = Device();
      await device.load(routerRtpCapabilities: routerRtpCapabilities);

      // 3. Create Send Transport (Producer side)
      await _createSendTransport(roomId);
      
      // 4. Create Recv Transport (Consumer side)
      await _createRecvTransport(roomId);
    });
  }

  Future<void> _createSendTransport(String roomId) async {
    signaling.emit('create-transport', {'roomId': roomId}, (data) async {
      sendTransport = device.createSendTransportFromMap(
        data,
        producerCallback: (producer) => producers[producer.id] = producer,
      );

      sendTransport!.on('connect', (data) {
        signaling.emit('connect-transport', {
          'roomId': roomId,
          'transportId': sendTransport!.id,
          'dtlsParameters': data['dtlsParameters'].toMap(),
        }, (_) => data['callback']());
      });

      sendTransport!.on('produce', (data) {
        signaling.emit('produce', {
          'roomId': roomId,
          'transportId': sendTransport!.id,
          'kind': data['kind'],
          'rtpParameters': data['rtpParameters'].toMap(),
          'appData': data['appData'],
        }, (resp) => data['callback'](resp['id']));
      });
    });
  }

  Future<void> _createRecvTransport(String roomId) async {
    signaling.emit('create-transport', {'roomId': roomId}, (data) async {
      recvTransport = device.createRecvTransportFromMap(data);

      recvTransport!.on('connect', (data) {
        signaling.emit('connect-transport', {
          'roomId': roomId,
          'transportId': recvTransport!.id,
          'dtlsParameters': data['dtlsParameters'].toMap(),
        }, (_) => data['callback']());
      });
    });
  }

  Future<Producer> produceVideo(MediaStreamTrack track) async {
    return await sendTransport!.produce(
      track: track,
      stream: await createLocalMediaStream('video-stream'),
    );
  }

  Future<Producer> produceAudio(MediaStreamTrack track) async {
    return await sendTransport!.produce(
      track: track,
      stream: await createLocalMediaStream('audio-stream'),
    );
  }

  Future<void> consume(String roomId, String producerId, Function(Consumer) callback) async {
    signaling.emit('consume', {
      'roomId': roomId,
      'transportId': recvTransport!.id,
      'producerId': producerId,
      'rtpCapabilities': device.rtpCapabilities.toMap(),
    }, (data) async {
      final consumer = await recvTransport!.consume(
        id: data['id'],
        producerId: data['producerId'],
        kind: RTCRtpMediaTypeExtension.fromString(data['kind']),
        rtpParameters: RtpParameters.fromMap(data['rtpParameters']),
      );

      consumers[consumer.id] = consumer;
      
      signaling.emit('resume-consumer', {'roomId': roomId, 'consumerId': consumer.id}, (_) {
        callback(consumer);
      });
    });
  }
}
