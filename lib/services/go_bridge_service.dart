// ─────────────────────────────────────────────────────────────────────────
// go_bridge_service.dart
// Bridge to the local Go Core Engine running on localhost:9000.
// Handles file transfer sessions, progress streaming, pause/resume/cancel.
// Falls back to simulation when Go engine is not running.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:p2p_transfer/models/transfer_session.dart';

/// Progress update from the Go engine (one per chunk ACK)
class GoProgressUpdate {
  final String transferId;
  final int currentChunk;
  final int totalChunks;
  final int bytesTransferred;
  final int totalBytes;
  final double speedBytesPerSec;
  final int retryCount;
  final String state; // 'transferring' | 'paused' | 'completed' | 'failed'

  const GoProgressUpdate({
    required this.transferId,
    required this.currentChunk,
    required this.totalChunks,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.speedBytesPerSec,
    required this.retryCount,
    required this.state,
  });

  factory GoProgressUpdate.fromJson(Map<String, dynamic> json) {
    return GoProgressUpdate(
      transferId: json['transferId'] as String,
      currentChunk: json['currentChunk'] as int? ?? 0,
      totalChunks: json['totalChunks'] as int? ?? 0,
      bytesTransferred: json['bytesTransferred'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      speedBytesPerSec: (json['speedBytesPerSec'] as num?)?.toDouble() ?? 0.0,
      retryCount: json['retryCount'] as int? ?? 0,
      state: json['state'] as String? ?? 'transferring',
    );
  }
}

class GoBridgeService {
  static const int _enginePort = 9000;
  static const String _engineHost = '127.0.0.1';

  Socket? _socket;
  bool _engineAvailable = false;

  final _progressController = StreamController<GoProgressUpdate>.broadcast();
  Stream<GoProgressUpdate> get progressStream => _progressController.stream;

  // ── Check engine availability ─────────────────────────────────────────
  Future<bool> checkEngineAvailable() async {
    if (kIsWeb) {
      _engineAvailable = false;
      return false;
    }
    try {
      final sock = await Socket.connect(
        _engineHost,
        _enginePort,
        timeout: const Duration(seconds: 2),
      );
      sock.destroy();
      _engineAvailable = true;
      return true;
    } on SocketException catch (_) {
      _engineAvailable = false;
      return false;
    }
  }

  // ── Start Transfer ────────────────────────────────────────────────────
  /// Tells the Go engine to initiate a file transfer session.
  /// Returns a stream of progress updates.
  Future<Stream<GoProgressUpdate>> startTransfer({
    required String transferId,
    required String peerIp,
    required int peerPort,
    required String filePath,
    required int fileSize,
    required String fileHash,
    required int chunkSize,
    required bool isSending,
    required String peerPublicKey,
  }) async {
    if (!_engineAvailable) {
      return _simulateTransfer(
        transferId: transferId,
        fileSize: fileSize,
        chunkSize: chunkSize,
        isSending: isSending,
      );
    }

    try {
      _socket = await Socket.connect(_engineHost, _enginePort);
      final command = jsonEncode({
        'command': isSending ? 'SEND' : 'RECEIVE',
        'transferId': transferId,
        'peerIp': peerIp,
        'peerPort': peerPort,
        'filePath': filePath,
        'fileSize': fileSize,
        'fileHash': fileHash,
        'chunkSize': chunkSize,
        'peerPublicKey': peerPublicKey,
      });
      _socket!.write('$command\n');

      // Parse JSON lines from Go engine
      _socket!
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen((line) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          _progressController.add(GoProgressUpdate.fromJson(json));
        } catch (e) {
          debugPrint('[GoBridge] Parse error: $e');
        }
      });

      return _progressController.stream.where((p) => p.transferId == transferId);
    } on SocketException catch (e) {
      debugPrint('[GoBridge] Engine not reachable: $e — simulating');
      return _simulateTransfer(
        transferId: transferId,
        fileSize: fileSize,
        chunkSize: chunkSize,
        isSending: isSending,
      );
    }
  }

  // ── Control Commands ──────────────────────────────────────────────────
  void pauseTransfer(String transferId) {
    _sendCommand({'command': 'PAUSE', 'transferId': transferId});
  }

  void resumeTransfer(String transferId) {
    _sendCommand({'command': 'RESUME', 'transferId': transferId});
  }

  void cancelTransfer(String transferId) {
    _sendCommand({'command': 'CANCEL', 'transferId': transferId});
  }

  void _sendCommand(Map<String, dynamic> cmd) {
    if (_socket != null) {
      try {
        _socket!.write('${jsonEncode(cmd)}\n');
      } catch (e) {
        debugPrint('[GoBridge] Command error: $e');
      }
    }
  }

  // ── Simulation Mode ───────────────────────────────────────────────────
  /// Simulates Go engine output for UI testing without a real Go binary.
  Stream<GoProgressUpdate> _simulateTransfer({
    required String transferId,
    required int fileSize,
    required int chunkSize,
    required bool isSending,
  }) {
    final controller = StreamController<GoProgressUpdate>();
    final totalChunks = (fileSize / chunkSize).ceil().clamp(1, 999999);
    final random = Random();
    int currentChunk = 0;
    int bytesTransferred = 0;
    int retryCount = 0;
    bool isPaused = false;
    bool isCancelled = false;

    // Register pause/cancel handlers
    _simulationPauseHandler = (tid, pause) {
      if (tid == transferId) isPaused = pause;
    };
    _simulationCancelHandler = (tid) {
      if (tid == transferId) isCancelled = true;
    };

    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (isCancelled) {
        controller.add(GoProgressUpdate(
          transferId: transferId,
          currentChunk: currentChunk,
          totalChunks: totalChunks,
          bytesTransferred: bytesTransferred,
          totalBytes: fileSize,
          speedBytesPerSec: 0,
          retryCount: retryCount,
          state: 'cancelled',
        ));
        timer.cancel();
        controller.close();
        return;
      }

      if (isPaused) {
        controller.add(GoProgressUpdate(
          transferId: transferId,
          currentChunk: currentChunk,
          totalChunks: totalChunks,
          bytesTransferred: bytesTransferred,
          totalBytes: fileSize,
          speedBytesPerSec: 0,
          retryCount: retryCount,
          state: 'paused',
        ));
        return;
      }

      // Simulate chunk progress (4–12 chunks per tick)
      final chunksThisTick = random.nextInt(8) + 4;
      currentChunk = (currentChunk + chunksThisTick).clamp(0, totalChunks);
      bytesTransferred = (currentChunk * chunkSize).clamp(0, fileSize);

      // Occasionally simulate a retry
      if (random.nextDouble() < 0.02) retryCount++;

      // Speed: 20–80 MB/s
      final speed = (20 + random.nextDouble() * 60) * 1024 * 1024;

      final isComplete = currentChunk >= totalChunks;

      controller.add(GoProgressUpdate(
        transferId: transferId,
        currentChunk: currentChunk,
        totalChunks: totalChunks,
        bytesTransferred: isComplete ? fileSize : bytesTransferred,
        totalBytes: fileSize,
        speedBytesPerSec: isComplete ? 0 : speed,
        retryCount: retryCount,
        state: isComplete ? 'completed' : 'transferring',
      ));

      if (isComplete) {
        timer.cancel();
        controller.close();
      }
    });

    return controller.stream;
  }

  // Simple simulation control callbacks
  void Function(String transferId, bool pause)? _simulationPauseHandler;
  void Function(String transferId)? _simulationCancelHandler;

  void simulatePause(String transferId) =>
      _simulationPauseHandler?.call(transferId, true);
  void simulateResume(String transferId) =>
      _simulationPauseHandler?.call(transferId, false);
  void simulateCancel(String transferId) =>
      _simulationCancelHandler?.call(transferId);

  // ── Mock History ──────────────────────────────────────────────────────
  List<TransferSession> getMockHistory() {
    return [
      TransferSession(
        id: 'tx_99812',
        peerDeviceId: 'node_alpha_9',
        peerDeviceName: 'CyberBook Pro 16',
        direction: TransferDirection.sending,
        files: const [
          TransferFileItem(
            id: 'f1',
            name: 'cyberpunk_wallpaper_4k.png',
            sizeBytes: 14200000,
            mimeType: 'image/png',
            fileHash: 'e3b0c44298fc1c149afbf4c8996fb924',
          ),
          TransferFileItem(
            id: 'f2',
            name: 'p2p_protocol_v2_spec.pdf',
            sizeBytes: 2400000,
            mimeType: 'application/pdf',
            fileHash: '9f86d081884c7d659a2feaa0c55ad015',
          ),
        ],
        bytesTransferred: 16600000,
        totalBytes: 16600000,
        currentSpeedBytesPerSec: 48500000,
        state: TransferState.completed,
        startTime: DateTime.now().subtract(const Duration(minutes: 45)),
        endTime: DateTime.now().subtract(const Duration(minutes: 44)),
        verificationHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        chunkSize: 65536,
        retryCount: 0,
        currentChunk: 254,
        totalChunks: 254,
      ),
      TransferSession(
        id: 'tx_99811',
        peerDeviceId: 'node_beta_2',
        peerDeviceName: 'Nothing Phone (2)',
        direction: TransferDirection.receiving,
        files: const [
          TransferFileItem(
            id: 'f3',
            name: 'system_firmware_dump.iso',
            sizeBytes: 850000000,
            mimeType: 'application/x-iso9660-image',
            fileHash: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b',
          ),
        ],
        bytesTransferred: 850000000,
        totalBytes: 850000000,
        currentSpeedBytesPerSec: 62000000,
        state: TransferState.completed,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 58)),
        verificationHash: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
        chunkSize: 65536,
        retryCount: 2,
        currentChunk: 12970,
        totalChunks: 12970,
      ),
    ];
  }

  void dispose() {
    _progressController.close();
    _socket?.destroy();
  }
}
