// ─────────────────────────────────────────────────────────────────────────
// signaling_message.dart — All SignalingMessageType models
// ─────────────────────────────────────────────────────────────────────────

/// All message types supported by the signaling server
enum SignalingMessageType {
  register,
  unregister,
  getDevices,
  sendOffer,
  sendAnswer,
  sendIceCandidate,
  leave,
  keepAlive,
  error,
  deviceUpdate,
  transferComplete,
  unknown,
}

extension SignalingMessageTypeExt on SignalingMessageType {
  static SignalingMessageType fromString(String s) {
    switch (s) {
      case 'REGISTER':
        return SignalingMessageType.register;
      case 'UNREGISTER':
        return SignalingMessageType.unregister;
      case 'GET_DEVICES':
        return SignalingMessageType.getDevices;
      case 'SEND_OFFER':
        return SignalingMessageType.sendOffer;
      case 'SEND_ANSWER':
        return SignalingMessageType.sendAnswer;
      case 'SEND_ICE_CANDIDATE':
        return SignalingMessageType.sendIceCandidate;
      case 'LEAVE':
        return SignalingMessageType.leave;
      case 'KEEP_ALIVE':
        return SignalingMessageType.keepAlive;
      case 'ERROR':
        return SignalingMessageType.error;
      case 'DEVICE_UPDATE':
        return SignalingMessageType.deviceUpdate;
      case 'TRANSFER_COMPLETE':
        return SignalingMessageType.transferComplete;
      default:
        return SignalingMessageType.unknown;
    }
  }

  String get wireValue {
    switch (this) {
      case SignalingMessageType.register:
        return 'REGISTER';
      case SignalingMessageType.unregister:
        return 'UNREGISTER';
      case SignalingMessageType.getDevices:
        return 'GET_DEVICES';
      case SignalingMessageType.sendOffer:
        return 'SEND_OFFER';
      case SignalingMessageType.sendAnswer:
        return 'SEND_ANSWER';
      case SignalingMessageType.sendIceCandidate:
        return 'SEND_ICE_CANDIDATE';
      case SignalingMessageType.leave:
        return 'LEAVE';
      case SignalingMessageType.keepAlive:
        return 'KEEP_ALIVE';
      case SignalingMessageType.error:
        return 'ERROR';
      case SignalingMessageType.deviceUpdate:
        return 'DEVICE_UPDATE';
      case SignalingMessageType.transferComplete:
        return 'TRANSFER_COMPLETE';
      default:
        return 'UNKNOWN';
    }
  }
}

/// Base signaling message envelope
class SignalingMessage {
  final SignalingMessageType type;
  final String? fromDeviceId;
  final String? toDeviceId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const SignalingMessage({
    required this.type,
    this.fromDeviceId,
    this.toDeviceId,
    this.payload = const {},
    required this.timestamp,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: SignalingMessageTypeExt.fromString(json['type'] as String? ?? ''),
      fromDeviceId: json['fromDeviceId'] as String?,
      toDeviceId: json['toDeviceId'] as String?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.wireValue,
        if (fromDeviceId != null) 'fromDeviceId': fromDeviceId,
        if (toDeviceId != null) 'toDeviceId': toDeviceId,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Helpers for constructing specific outgoing messages

class SignalingMessages {
  SignalingMessages._();

  static Map<String, dynamic> register({
    required String deviceId,
    required String name,
    required String type,
    required String platform,
    required String ipAddress,
    required String localIp,
    required int port,
    required String publicKey,
    required Map<String, dynamic> capabilities,
  }) =>
      {
        'type': SignalingMessageType.register.wireValue,
        'payload': {
          'id': deviceId,
          'name': name,
          'type': type,
          'platform': platform,
          'ipAddress': ipAddress,
          'localIp': localIp,
          'port': port,
          'publicKey': publicKey,
          'capabilities': capabilities,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> keepAlive() => {
        'type': SignalingMessageType.keepAlive.wireValue,
        'payload': {},
        'timestamp': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> sendOffer({
    required String toDeviceId,
    required String transferId,
    required String fileName,
    required int fileSize,
    required String fileHash,
    required String mimeType,
    required int chunkSize,
  }) =>
      {
        'type': SignalingMessageType.sendOffer.wireValue,
        'toDeviceId': toDeviceId,
        'payload': {
          'transferId': transferId,
          'fileName': fileName,
          'fileSize': fileSize,
          'fileHash': fileHash,
          'mimeType': mimeType,
          'chunkSize': chunkSize,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> sendAnswer({
    required String toDeviceId,
    required String transferId,
    required bool accepted,
    String? reason,
  }) =>
      {
        'type': SignalingMessageType.sendAnswer.wireValue,
        'toDeviceId': toDeviceId,
        'payload': {
          'transferId': transferId,
          'accepted': accepted,
          // ignore: use_null_aware_elements
          if (reason != null) 'reason': reason,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> sendIceCandidate({
    required String toDeviceId,
    required String transferId,
    required String candidate,
    required String type, // 'host' | 'srflx' | 'relay'
  }) =>
      {
        'type': SignalingMessageType.sendIceCandidate.wireValue,
        'toDeviceId': toDeviceId,
        'payload': {
          'transferId': transferId,
          'candidate': candidate,
          'type': type,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

  static Map<String, dynamic> leave() => {
        'type': SignalingMessageType.leave.wireValue,
        'payload': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
}
