// ─────────────────────────────────────────────────────────────────────────
// transfer_session.dart — Matches the Transfer interface from the architecture
// ─────────────────────────────────────────────────────────────────────────

enum TransferDirection { sending, receiving }

enum TransferState {
  pending,
  connecting,
  transferring,
  paused,
  completed,
  cancelled,
  failed,
}

/// Maps Transfer.status string from signaling server → TransferState enum
extension TransferStateExt on TransferState {
  static TransferState fromString(String s) {
    switch (s) {
      case 'pending':
        return TransferState.pending;
      case 'inProgress':
        return TransferState.transferring;
      case 'paused':
        return TransferState.paused;
      case 'completed':
        return TransferState.completed;
      case 'failed':
        return TransferState.failed;
      case 'cancelled':
        return TransferState.cancelled;
      default:
        return TransferState.pending;
    }
  }

  String toStatusString() {
    switch (this) {
      case TransferState.transferring:
        return 'inProgress';
      case TransferState.pending:
        return 'pending';
      case TransferState.paused:
        return 'paused';
      case TransferState.completed:
        return 'completed';
      case TransferState.failed:
        return 'failed';
      case TransferState.cancelled:
        return 'cancelled';
      default:
        return 'pending';
    }
  }
}

/// Individual file in a transfer session
class TransferFileItem {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;

  /// Absolute local path on device
  final String? localPath;

  /// SHA-256 hash for integrity verification (set by Go engine)
  final String fileHash;

  const TransferFileItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    this.localPath,
    this.fileHash = '',
  });

  factory TransferFileItem.fromJson(Map<String, dynamic> json) {
    return TransferFileItem(
      id: json['id'] as String,
      name: json['fileName'] as String? ?? json['name'] as String,
      sizeBytes: json['fileSize'] as int? ?? json['sizeBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      localPath: json['filePath'] as String?,
      fileHash: json['fileHash'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': name,
        'filePath': localPath ?? '',
        'fileSize': sizeBytes,
        'mimeType': mimeType,
        'fileHash': fileHash,
      };

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  TransferFileItem copyWith({
    String? id,
    String? name,
    int? sizeBytes,
    String? mimeType,
    String? localPath,
    String? fileHash,
  }) {
    return TransferFileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      fileHash: fileHash ?? this.fileHash,
    );
  }
}

/// Active or historical transfer session — matches the Transfer interface
class TransferSession {
  final String id;
  final String peerDeviceId;
  final String peerDeviceName;
  final TransferDirection direction;
  final List<TransferFileItem> files;
  final int bytesTransferred;
  final int totalBytes;
  final double currentSpeedBytesPerSec;
  final TransferState state;
  final DateTime startTime;
  final DateTime? endTime;

  /// AES-256-GCM encrypted (handled by Go engine)
  final bool isEncrypted;

  /// SHA-256 of the primary file (from Go engine)
  final String verificationHash;

  /// Chunk size used by the Go engine for this transfer
  final int chunkSize;

  /// Number of chunk retransmissions
  final int retryCount;

  /// Number of current chunk being transferred
  final int currentChunk;

  /// Total chunks in this transfer
  final int totalChunks;

  const TransferSession({
    required this.id,
    required this.peerDeviceId,
    required this.peerDeviceName,
    required this.direction,
    required this.files,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.currentSpeedBytesPerSec,
    required this.state,
    required this.startTime,
    this.endTime,
    this.isEncrypted = true,
    required this.verificationHash,
    this.chunkSize = 65536, // 64 KB default
    this.retryCount = 0,
    this.currentChunk = 0,
    this.totalChunks = 0,
  });

  double get progress =>
      totalBytes == 0 ? 0.0 : (bytesTransferred / totalBytes).clamp(0.0, 1.0);

  int get remainingBytes => (totalBytes - bytesTransferred).clamp(0, totalBytes);

  int get estimatedSecondsRemaining {
    if (currentSpeedBytesPerSec <= 0) return 0;
    return (remainingBytes / currentSpeedBytesPerSec).ceil();
  }

  String get formattedSpeed {
    if (currentSpeedBytesPerSec < 1024) {
      return '${currentSpeedBytesPerSec.toStringAsFixed(0)} B/s';
    }
    if (currentSpeedBytesPerSec < 1024 * 1024) {
      return '${(currentSpeedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(currentSpeedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get statusString => state.toStatusString();

  TransferSession copyWith({
    String? id,
    String? peerDeviceId,
    String? peerDeviceName,
    TransferDirection? direction,
    List<TransferFileItem>? files,
    int? bytesTransferred,
    int? totalBytes,
    double? currentSpeedBytesPerSec,
    TransferState? state,
    DateTime? startTime,
    DateTime? endTime,
    bool? isEncrypted,
    String? verificationHash,
    int? chunkSize,
    int? retryCount,
    int? currentChunk,
    int? totalChunks,
  }) {
    return TransferSession(
      id: id ?? this.id,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      direction: direction ?? this.direction,
      files: files ?? this.files,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      currentSpeedBytesPerSec: currentSpeedBytesPerSec ?? this.currentSpeedBytesPerSec,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      verificationHash: verificationHash ?? this.verificationHash,
      chunkSize: chunkSize ?? this.chunkSize,
      retryCount: retryCount ?? this.retryCount,
      currentChunk: currentChunk ?? this.currentChunk,
      totalChunks: totalChunks ?? this.totalChunks,
    );
  }
}
