// ─────────────────────────────────────────────────────────────────────────
// signaling_service.dart
// WebSocket client for the Node.js Signaling Server.
// Falls back to mock peer list if the server is unreachable.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:p2p_transfer/models/peer_device.dart';
import 'package:p2p_transfer/models/signaling_message.dart';
import 'package:p2p_transfer/models/session_model.dart';

/// Connection state of the WebSocket to the signaling server
enum SignalingStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class SignalingService {
  // ── Config ────────────────────────────────────────────────────────────
  static const Duration _keepAliveInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 5;

  // ── State ─────────────────────────────────────────────────────────────
  String _serverUrl = 'ws://localhost:3000';
  WebSocketChannel? _channel;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  AppSession? _session;

  // ── Streams ───────────────────────────────────────────────────────────
  final _statusController = StreamController<SignalingStatus>.broadcast();
  final _devicesController = StreamController<List<PeerDevice>>.broadcast();
  final _messagesController = StreamController<SignalingMessage>.broadcast();

  Stream<SignalingStatus> get statusStream => _statusController.stream;
  Stream<List<PeerDevice>> get devicesStream => _devicesController.stream;
  Stream<SignalingMessage> get messagesStream => _messagesController.stream;

  SignalingStatus _status = SignalingStatus.disconnected;
  SignalingStatus get status => _status;

  AppSession? get session => _session;
  String get serverUrl => _serverUrl;

  // ── Connect ───────────────────────────────────────────────────────────
  Future<void> connect({
    required String serverUrl,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String localIp,
    required int port,
    required String publicKey,
    String? jwtToken,
  }) async {
    _serverUrl = serverUrl;
    _intentionalDisconnect = false;
    _setStatus(SignalingStatus.connecting);

    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection or error
      await _channel!.ready.timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('WebSocket connection timed out'),
      );

      _reconnectAttempts = 0;
      _setStatus(SignalingStatus.connected);

      // Send REGISTER
      _send(SignalingMessages.register(
        deviceId: deviceId,
        name: deviceName,
        type: platform,
        platform: platform,
        ipAddress: '',
        localIp: localIp,
        port: port,
        publicKey: publicKey,
        capabilities: {
          'supportsFolder': true,
          'supportsBatch': true,
          'maxFileSize': 10 * 1024 * 1024 * 1024,
        },
      ));

      // Start keep-alive
      _startKeepAlive();

      // Listen to incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } on Exception catch (e) {
      debugPrint('[Signaling] Connection failed: $e — using mock fallback');
      _setStatus(SignalingStatus.error);
      _emitMockPeers();
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      _send(SignalingMessages.leave());
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setStatus(SignalingStatus.disconnected);
  }

  // ── Send message ──────────────────────────────────────────────────────
  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('[Signaling] Send error: $e');
    }
  }

  void sendRaw(Map<String, dynamic> data) => _send(data);

  void sendOffer({
    required String toDeviceId,
    required String transferId,
    required String fileName,
    required int fileSize,
    required String fileHash,
    required String mimeType,
    required int chunkSize,
  }) {
    _send(SignalingMessages.sendOffer(
      toDeviceId: toDeviceId,
      transferId: transferId,
      fileName: fileName,
      fileSize: fileSize,
      fileHash: fileHash,
      mimeType: mimeType,
      chunkSize: chunkSize,
    ));
  }

  void sendAnswer({
    required String toDeviceId,
    required String transferId,
    required bool accepted,
    String? reason,
  }) {
    _send(SignalingMessages.sendAnswer(
      toDeviceId: toDeviceId,
      transferId: transferId,
      accepted: accepted,
      reason: reason,
    ));
  }

  void sendIceCandidate({
    required String toDeviceId,
    required String transferId,
    required String candidate,
    required String type,
  }) {
    _send(SignalingMessages.sendIceCandidate(
      toDeviceId: toDeviceId,
      transferId: transferId,
      candidate: candidate,
      type: type,
    ));
  }

  // ── Message handler ───────────────────────────────────────────────────
  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = SignalingMessage.fromJson(json);

      switch (msg.type) {
        case SignalingMessageType.register:
          // Server confirms registration, may include session info
          if (json['sessionId'] != null) {
            _session = AppSession(
              sessionId: json['sessionId'] as String,
              deviceId: json['deviceId'] as String? ?? '',
              token: json['token'] as String? ?? '',
              connectedAt: DateTime.now(),
            );
          }

        case SignalingMessageType.deviceUpdate:
          // Server broadcasts updated device list
          final devicesJson = msg.payload['devices'] as List<dynamic>? ?? [];
          final devices = devicesJson
              .map((d) => PeerDevice.fromJson(d as Map<String, dynamic>))
              .toList();
          _devicesController.add(devices);

        case SignalingMessageType.error:
          debugPrint('[Signaling] Server error: ${msg.payload['message']}');

        default:
          // Forward all other messages (offers, answers, ICE) to consumer
          _messagesController.add(msg);
      }
    } catch (e) {
      debugPrint('[Signaling] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[Signaling] WebSocket error: $error');
    _setStatus(SignalingStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (_intentionalDisconnect) return;
    debugPrint('[Signaling] Connection closed — scheduling reconnect');
    _setStatus(SignalingStatus.disconnected);
    _scheduleReconnect();
  }

  // ── Keep-alive ────────────────────────────────────────────────────────
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
      if (_status == SignalingStatus.connected) {
        _send(SignalingMessages.keepAlive());
      }
    });
  }

  // ── Auto-reconnect ────────────────────────────────────────────────────
  void _scheduleReconnect() {
    if (_intentionalDisconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[Signaling] Max reconnect attempts reached — using mock fallback');
      _emitMockPeers();
      return;
    }
    _reconnectAttempts++;
    _setStatus(SignalingStatus.reconnecting);
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () async {
      debugPrint('[Signaling] Reconnect attempt $_reconnectAttempts...');
      try {
        final uri = Uri.parse(_serverUrl);
        _channel = WebSocketChannel.connect(uri);
        await _channel!.ready.timeout(const Duration(seconds: 8));
        _reconnectAttempts = 0;
        _setStatus(SignalingStatus.connected);
        _startKeepAlive();
        _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
      } on Exception catch (_) {
        _scheduleReconnect();
      }
    });
  }

  // ── Mock fallback (demo mode) ─────────────────────────────────────────
  void _emitMockPeers() {
    _devicesController.add(_buildMockPeers());
  }

  static List<PeerDevice> buildMockPeers() => _buildMockPeers();

  static List<PeerDevice> _buildMockPeers() {
    return [
      PeerDevice(
        id: 'node_alpha_9',
        name: 'CyberBook Pro 16',
        deviceType: 'Desktop',
        platform: DevicePlatform.macos,
        osName: 'macOS',
        ipAddress: '203.0.113.42',
        localIp: '192.168.1.104',
        port: 9000,
        publicKey: 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE',
        latencyMs: 3,
        trustStatus: TrustStatus.trusted,
        isOnline: true,
        lastSeen: DateTime.now(),
        capabilities: const DeviceCapabilities(
          supportsFolder: true,
          supportsBatch: true,
          maxFileSize: 10 * 1024 * 1024 * 1024,
        ),
        connectionMode: 'direct',
      ),
      PeerDevice(
        id: 'node_beta_2',
        name: 'Nothing Phone (2)',
        deviceType: 'Mobile',
        platform: DevicePlatform.android,
        osName: 'Android',
        ipAddress: '203.0.113.88',
        localIp: '192.168.1.189',
        port: 9000,
        publicKey: 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAF',
        latencyMs: 12,
        trustStatus: TrustStatus.trusted,
        isOnline: true,
        lastSeen: DateTime.now(),
        capabilities: const DeviceCapabilities(
          supportsFolder: false,
          supportsBatch: true,
          maxFileSize: 2 * 1024 * 1024 * 1024,
        ),
        connectionMode: 'relay',
      ),
      PeerDevice(
        id: 'node_gamma_5',
        name: 'Raycast Workstation',
        deviceType: 'Desktop',
        platform: DevicePlatform.windows,
        osName: 'Windows',
        ipAddress: '203.0.113.210',
        localIp: '192.168.1.210',
        port: 9000,
        publicKey: 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAG',
        latencyMs: 5,
        trustStatus: TrustStatus.untrusted,
        isOnline: true,
        lastSeen: DateTime.now(),
        capabilities: const DeviceCapabilities(
          supportsFolder: true,
          supportsBatch: true,
          maxFileSize: 50 * 1024 * 1024 * 1024,
        ),
        connectionMode: 'direct',
      ),
      PeerDevice(
        id: 'node_delta_7',
        name: 'iPad Pro Matrix',
        deviceType: 'Tablet',
        platform: DevicePlatform.ios,
        osName: 'iOS',
        ipAddress: '203.0.113.145',
        localIp: '192.168.1.145',
        port: 9000,
        publicKey: 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAH',
        latencyMs: 42,
        trustStatus: TrustStatus.blocked,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        capabilities: const DeviceCapabilities(
          supportsFolder: false,
          supportsBatch: false,
          maxFileSize: 1 * 1024 * 1024 * 1024,
        ),
        connectionMode: 'unknown',
      ),
    ];
  }

  // ── Status helper ─────────────────────────────────────────────────────
  void _setStatus(SignalingStatus s) {
    _status = s;
    _statusController.add(s);
  }

  // ── Pair code ─────────────────────────────────────────────────────────
  String generatePairCode() {
    final code = Random().nextInt(900000) + 100000;
    return code.toString();
  }

  void dispose() {
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _statusController.close();
    _devicesController.close();
    _messagesController.close();
    _channel?.sink.close();
  }
}
