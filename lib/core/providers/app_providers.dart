// ─────────────────────────────────────────────────────────────────────────
// app_providers.dart — Central Riverpod provider hub
// Architecture: WebSocket Signaling Server + Go Core Engine
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:p2p_transfer/models/peer_device.dart';
import 'package:p2p_transfer/models/session_model.dart';
import 'package:p2p_transfer/models/transfer_session.dart';
import 'package:p2p_transfer/services/encryption_service.dart';
import 'package:p2p_transfer/services/go_bridge_service.dart';
import 'package:p2p_transfer/services/signaling_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final signalingServiceProvider = Provider<SignalingService>((ref) {
  final service = SignalingService();
  ref.onDispose(service.dispose);
  return service;
});

final goBridgeServiceProvider = Provider<GoBridgeService>((ref) {
  final service = GoBridgeService();
  ref.onDispose(service.dispose);
  return service;
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS
// ═══════════════════════════════════════════════════════════════════════════

class AppSettings {
  final String signalingServerUrl;
  final int goEnginePort;
  final bool useRelay;
  final bool encryptionEnabled;
  final bool autoAccept;
  final String deviceName;
  final int chunkSize; // bytes

  const AppSettings({
    this.signalingServerUrl = 'ws://localhost:3000',
    this.goEnginePort = 9000,
    this.useRelay = true,
    this.encryptionEnabled = true,
    this.autoAccept = false,
    this.deviceName = 'My Device',
    this.chunkSize = 65536,
  });

  AppSettings copyWith({
    String? signalingServerUrl,
    int? goEnginePort,
    bool? useRelay,
    bool? encryptionEnabled,
    bool? autoAccept,
    String? deviceName,
    int? chunkSize,
  }) {
    return AppSettings(
      signalingServerUrl: signalingServerUrl ?? this.signalingServerUrl,
      goEnginePort: goEnginePort ?? this.goEnginePort,
      useRelay: useRelay ?? this.useRelay,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      autoAccept: autoAccept ?? this.autoAccept,
      deviceName: deviceName ?? this.deviceName,
      chunkSize: chunkSize ?? this.chunkSize,
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void updateSignalingUrl(String url) => state = state.copyWith(signalingServerUrl: url);
  void updateGoEnginePort(int port) => state = state.copyWith(goEnginePort: port);
  void updateUseRelay(bool v) => state = state.copyWith(useRelay: v);
  void updateEncryption(bool v) => state = state.copyWith(encryptionEnabled: v);
  void updateAutoAccept(bool v) => state = state.copyWith(autoAccept: v);
  void updateDeviceName(String n) => state = state.copyWith(deviceName: n);
  void updateChunkSize(int s) => state = state.copyWith(chunkSize: s);
}

// ═══════════════════════════════════════════════════════════════════════════
// CONNECTIVITY
// ═══════════════════════════════════════════════════════════════════════════

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((list) => list.first);
});

// ═══════════════════════════════════════════════════════════════════════════
// SIGNALING STATUS
// ═══════════════════════════════════════════════════════════════════════════

final signalingStatusProvider = StreamProvider<SignalingStatus>((ref) {
  return ref.watch(signalingServiceProvider).statusStream;
});

// ═══════════════════════════════════════════════════════════════════════════
// SESSION (JWT + Device ID)
// ═══════════════════════════════════════════════════════════════════════════

final sessionProvider = StateNotifierProvider<SessionNotifier, AppSession?>((ref) {
  return SessionNotifier(ref);
});

class SessionNotifier extends StateNotifier<AppSession?> {
  final Ref _ref;

  SessionNotifier(this._ref) : super(null);

  /// Connect to the signaling server using stored/generated credentials
  Future<void> connectToSignalingServer() async {
    final encryption = _ref.read(encryptionServiceProvider);
    final settings = _ref.read(appSettingsProvider);
    final signaling = _ref.read(signalingServiceProvider);

    final deviceId = await encryption.getOrCreateDeviceId();
    final publicKey = await encryption.getPublicKey();

    String localIp = '127.0.0.1';
    if (!kIsWeb) {
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              localIp = addr.address;
              break;
            }
          }
        }
      } catch (_) {}
    }

    await signaling.connect(
      serverUrl: settings.signalingServerUrl,
      deviceId: deviceId,
      deviceName: settings.deviceName,
      platform: Platform.isAndroid
          ? 'android'
          : Platform.isWindows
              ? 'windows'
              : Platform.isLinux
                  ? 'linux'
                  : 'windows',
      localIp: localIp,
      port: settings.goEnginePort,
      publicKey: publicKey,
    );

    // Update session state when server responds
    _ref.read(signalingServiceProvider).messagesStream.listen((_) {
      final session = _ref.read(signalingServiceProvider).session;
      if (session != null) state = session;
    });
  }

  void clearSession() {
    state = null;
    _ref.read(signalingServiceProvider).disconnect();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PEER DEVICES (driven by DEVICE_UPDATE from signaling server)
// ═══════════════════════════════════════════════════════════════════════════

final peerDevicesProvider = StateNotifierProvider<PeerDevicesNotifier, List<PeerDevice>>((ref) {
  return PeerDevicesNotifier(ref);
});

class PeerDevicesNotifier extends StateNotifier<List<PeerDevice>> {
  final Ref _ref;
  StreamSubscription<List<PeerDevice>>? _sub;

  PeerDevicesNotifier(this._ref) : super(SignalingService.buildMockPeers()) {
    _listenToSignaling();
  }

  void _listenToSignaling() {
    _sub = _ref.read(signalingServiceProvider).devicesStream.listen((devices) {
      state = devices;
    });
  }

  void updateDevice(PeerDevice updated) {
    state = [
      for (final d in state)
        if (d.id == updated.id) updated else d,
    ];
  }

  void setTrust(String deviceId, TrustStatus trust) {
    state = [
      for (final d in state)
        if (d.id == deviceId) d.copyWith(trustStatus: trust) else d,
    ];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVE TRANSFER (driven by Go Bridge progress stream)
// ═══════════════════════════════════════════════════════════════════════════

final activeTransferProvider =
    StateNotifierProvider<ActiveTransferNotifier, TransferSession?>((ref) {
  return ActiveTransferNotifier(ref);
});

class ActiveTransferNotifier extends StateNotifier<TransferSession?> {
  final Ref _ref;
  StreamSubscription<GoProgressUpdate>? _progressSub;

  ActiveTransferNotifier(this._ref) : super(null);

  /// Initiate a new outgoing transfer via the Go engine
  Future<void> startTransfer({
    required PeerDevice targetDevice,
    required List<TransferFileItem> files,
    required String transferId,
  }) async {
    if (files.isEmpty) return;

    final primaryFile = files.first;
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    final settings = _ref.read(appSettingsProvider);
    final bridge = _ref.read(goBridgeServiceProvider);

    // Initial session state
    state = TransferSession(
      id: transferId,
      peerDeviceId: targetDevice.id,
      peerDeviceName: targetDevice.name,
      direction: TransferDirection.sending,
      files: files,
      bytesTransferred: 0,
      totalBytes: totalBytes,
      currentSpeedBytesPerSec: 0,
      state: TransferState.connecting,
      startTime: DateTime.now(),
      verificationHash: primaryFile.fileHash.isEmpty
          ? 'pending_hash_from_go_engine'
          : primaryFile.fileHash,
      chunkSize: settings.chunkSize,
    );

    // Connect to Go engine (or simulation)
    final progressStream = await bridge.startTransfer(
      transferId: transferId,
      peerIp: targetDevice.localIp.isNotEmpty
          ? targetDevice.localIp
          : targetDevice.ipAddress,
      peerPort: settings.goEnginePort,
      filePath: primaryFile.localPath ?? '',
      fileSize: totalBytes,
      fileHash: primaryFile.fileHash,
      chunkSize: settings.chunkSize,
      isSending: true,
      peerPublicKey: targetDevice.publicKey,
    );

    _progressSub?.cancel();
    _progressSub = progressStream.listen(
      _onProgress,
      onDone: _onDone,
      onError: (e) {
        debugPrint('[Transfer] Stream error: $e');
        _onFailed();
      },
    );
  }

  /// Set up receiving side (triggered by SEND_OFFER from signaling)
  Future<void> startReceiving({
    required String transferId,
    required String peerDeviceId,
    required String peerDeviceName,
    required String fileName,
    required int fileSize,
    required String fileHash,
    required String mimeType,
    required int chunkSize,
  }) async {
    final bridge = _ref.read(goBridgeServiceProvider);
    final settings = _ref.read(appSettingsProvider);

    state = TransferSession(
      id: transferId,
      peerDeviceId: peerDeviceId,
      peerDeviceName: peerDeviceName,
      direction: TransferDirection.receiving,
      files: [
        TransferFileItem(
          id: 'incoming_$transferId',
          name: fileName,
          sizeBytes: fileSize,
          mimeType: mimeType,
          fileHash: fileHash,
        ),
      ],
      bytesTransferred: 0,
      totalBytes: fileSize,
      currentSpeedBytesPerSec: 0,
      state: TransferState.connecting,
      startTime: DateTime.now(),
      verificationHash: fileHash,
      chunkSize: chunkSize,
    );

    final progressStream = await bridge.startTransfer(
      transferId: transferId,
      peerIp: '0.0.0.0',
      peerPort: settings.goEnginePort,
      filePath: '',
      fileSize: fileSize,
      fileHash: fileHash,
      chunkSize: chunkSize,
      isSending: false,
      peerPublicKey: '',
    );

    _progressSub?.cancel();
    _progressSub = progressStream.listen(_onProgress, onDone: _onDone);
  }

  void _onProgress(GoProgressUpdate update) {
    if (state == null) return;
    final newState = switch (update.state) {
      'transferring' => TransferState.transferring,
      'paused' => TransferState.paused,
      'completed' => TransferState.completed,
      'cancelled' => TransferState.cancelled,
      'failed' => TransferState.failed,
      _ => TransferState.transferring,
    };

    state = state!.copyWith(
      bytesTransferred: update.bytesTransferred,
      currentSpeedBytesPerSec: update.speedBytesPerSec,
      state: newState,
      currentChunk: update.currentChunk,
      totalChunks: update.totalChunks,
      retryCount: update.retryCount,
      endTime: newState == TransferState.completed ? DateTime.now() : null,
    );
  }

  void _onDone() {
    if (state != null && state!.state == TransferState.transferring) {
      state = state!.copyWith(
        state: TransferState.completed,
        bytesTransferred: state!.totalBytes,
        endTime: DateTime.now(),
      );
    }
  }

  void _onFailed() {
    if (state != null) {
      state = state!.copyWith(state: TransferState.failed);
    }
  }

  void pauseTransfer() {
    if (state == null) return;
    _ref.read(goBridgeServiceProvider).pauseTransfer(state!.id);
    _ref.read(goBridgeServiceProvider).simulatePause(state!.id);
    state = state!.copyWith(state: TransferState.paused);
  }

  void resumeTransfer() {
    if (state == null) return;
    _ref.read(goBridgeServiceProvider).resumeTransfer(state!.id);
    _ref.read(goBridgeServiceProvider).simulateResume(state!.id);
    state = state!.copyWith(state: TransferState.transferring);
  }

  void cancelTransfer() {
    if (state == null) return;
    _ref.read(goBridgeServiceProvider).cancelTransfer(state!.id);
    _ref.read(goBridgeServiceProvider).simulateCancel(state!.id);
    state = state!.copyWith(state: TransferState.cancelled);
  }

  void clearTransfer() {
    _progressSub?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRANSFER HISTORY
// ═══════════════════════════════════════════════════════════════════════════

final transferHistoryProvider =
    StateNotifierProvider<TransferHistoryNotifier, List<TransferSession>>((ref) {
  return TransferHistoryNotifier(ref);
});

class TransferHistoryNotifier extends StateNotifier<List<TransferSession>> {
  final Ref _ref;

  TransferHistoryNotifier(this._ref)
      : super(_ref.read(goBridgeServiceProvider).getMockHistory()) {
    // Watch active transfer for completion → add to history
    _ref.listen(activeTransferProvider, (previous, next) {
      if (next != null &&
          (next.state == TransferState.completed ||
              next.state == TransferState.cancelled ||
              next.state == TransferState.failed)) {
        if (previous?.state != next.state) {
          _addToHistory(next);
        }
      }
    });
  }

  void _addToHistory(TransferSession session) {
    final exists = state.any((s) => s.id == session.id);
    if (!exists) {
      state = [session, ...state];
    }
  }

  void clearHistory() => state = [];
}

// ═══════════════════════════════════════════════════════════════════════════
// GO ENGINE STATUS
// ═══════════════════════════════════════════════════════════════════════════

final goEngineStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(goBridgeServiceProvider).checkEngineAvailable();
});

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL DEVICE INFO
// ═══════════════════════════════════════════════════════════════════════════

final localDeviceProvider = FutureProvider<PeerDevice>((ref) async {
  final encryption = ref.read(encryptionServiceProvider);
  final settings = ref.read(appSettingsProvider);

  final deviceId = await encryption.getOrCreateDeviceId();
  final publicKey = await encryption.getPublicKey();

  String localIp = '127.0.0.1';
  if (!kIsWeb) {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {}
  }

  final osName = kIsWeb
      ? 'Web'
      : Platform.isWindows
          ? 'Windows'
          : Platform.isAndroid
              ? 'Android'
              : Platform.isLinux
                  ? 'Linux'
                  : Platform.isMacOS
                      ? 'macOS'
                      : 'Unknown';

  final platform = kIsWeb
      ? DevicePlatform.unknown
      : Platform.isWindows
          ? DevicePlatform.windows
          : Platform.isAndroid
              ? DevicePlatform.android
              : Platform.isLinux
                  ? DevicePlatform.linux
                  : Platform.isMacOS
                      ? DevicePlatform.macos
                      : DevicePlatform.unknown;

  return PeerDevice(
    id: deviceId,
    name: settings.deviceName,
    deviceType: Platform.isAndroid ? 'Mobile' : 'Desktop',
    platform: platform,
    osName: osName,
    ipAddress: localIp,
    localIp: localIp,
    port: settings.goEnginePort,
    publicKey: publicKey,
    latencyMs: 0,
    trustStatus: TrustStatus.trusted,
    isOnline: true,
    lastSeen: DateTime.now(),
    connectionMode: 'direct',
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// SELECTION STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final selectedFilesProvider = StateProvider<List<TransferFileItem>>((ref) => []);
final selectedPeerProvider = StateProvider<PeerDevice?>((ref) => null);

