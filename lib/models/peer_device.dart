// ─────────────────────────────────────────────────────────────────────────
// peer_device.dart — Matches the Device interface from the signaling server
// ─────────────────────────────────────────────────────────────────────────

enum TrustStatus { trusted, untrusted, blocked }

enum DevicePlatform { android, windows, linux, ios, macos, unknown }

class DeviceCapabilities {
  final bool supportsFolder;
  final bool supportsBatch;
  final int maxFileSize; // bytes

  const DeviceCapabilities({
    this.supportsFolder = true,
    this.supportsBatch = true,
    this.maxFileSize = 10 * 1024 * 1024 * 1024, // 10 GB default
  });

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilities(
      supportsFolder: json['supportsFolder'] as bool? ?? true,
      supportsBatch: json['supportsBatch'] as bool? ?? true,
      maxFileSize: json['maxFileSize'] as int? ?? 10 * 1024 * 1024 * 1024,
    );
  }

  Map<String, dynamic> toJson() => {
        'supportsFolder': supportsFolder,
        'supportsBatch': supportsBatch,
        'maxFileSize': maxFileSize,
      };

  DeviceCapabilities copyWith({
    bool? supportsFolder,
    bool? supportsBatch,
    int? maxFileSize,
  }) {
    return DeviceCapabilities(
      supportsFolder: supportsFolder ?? this.supportsFolder,
      supportsBatch: supportsBatch ?? this.supportsBatch,
      maxFileSize: maxFileSize ?? this.maxFileSize,
    );
  }
}

class PeerDevice {
  final String id;
  final String name;

  /// Device type label for UI: 'Desktop', 'Mobile', 'Tablet', 'Server'
  final String deviceType;

  /// Platform enum
  final DevicePlatform platform;

  /// OS display name: 'Android', 'Windows', 'Linux', 'iOS', 'macOS'
  final String osName;

  /// Public IP / signaling-reported IP
  final String ipAddress;

  /// Local LAN IP (for direct P2P)
  final String localIp;

  final int port;

  /// ECDH public key (base64), used for key exchange before transfer
  final String publicKey;

  final int latencyMs;
  final TrustStatus trustStatus;
  final bool isOnline;
  final DateTime lastSeen;
  final DeviceCapabilities capabilities;

  /// Connection mode resolved after NAT traversal: 'direct' | 'relay' | 'unknown'
  final String connectionMode;

  const PeerDevice({
    required this.id,
    required this.name,
    this.deviceType = 'Desktop',
    this.platform = DevicePlatform.windows,
    this.osName = 'Windows',
    required this.ipAddress,
    this.localIp = '',
    this.port = 8443,
    this.publicKey = '',
    required this.latencyMs,
    this.trustStatus = TrustStatus.untrusted,
    this.isOnline = true,
    required this.lastSeen,
    this.capabilities = const DeviceCapabilities(),
    this.connectionMode = 'unknown',
  });

  factory PeerDevice.fromJson(Map<String, dynamic> json) {
    return PeerDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceType: _resolveDeviceType(json['type'] as String? ?? 'desktop'),
      platform: _parsePlatform(json['type'] as String? ?? 'windows'),
      osName: json['platform'] as String? ?? 'Windows',
      ipAddress: json['ipAddress'] as String? ?? '0.0.0.0',
      localIp: json['localIp'] as String? ?? '',
      port: json['port'] as int? ?? 8443,
      publicKey: json['publicKey'] as String? ?? '',
      latencyMs: json['latencyMs'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String) ?? DateTime.now()
          : DateTime.now(),
      capabilities: json['capabilities'] != null
          ? DeviceCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>)
          : const DeviceCapabilities(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': platform.name,
        'platform': osName,
        'ipAddress': ipAddress,
        'localIp': localIp,
        'port': port,
        'publicKey': publicKey,
        'isOnline': isOnline,
        'lastSeen': lastSeen.toIso8601String(),
        'capabilities': capabilities.toJson(),
      };

  static String _resolveDeviceType(String type) {
    switch (type.toLowerCase()) {
      case 'android':
      case 'ios':
        return 'Mobile';
      case 'linux':
        return 'Server';
      default:
        return 'Desktop';
    }
  }

  static DevicePlatform _parsePlatform(String type) {
    switch (type.toLowerCase()) {
      case 'android':
        return DevicePlatform.android;
      case 'ios':
        return DevicePlatform.ios;
      case 'linux':
        return DevicePlatform.linux;
      case 'macos':
        return DevicePlatform.macos;
      case 'windows':
        return DevicePlatform.windows;
      default:
        return DevicePlatform.unknown;
    }
  }

  String get formattedMaxFileSize {
    final gb = capabilities.maxFileSize / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(0)} GB max';
    final mb = capabilities.maxFileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB max';
  }

  String get publicKeyFingerprint {
    if (publicKey.isEmpty) return 'NO KEY';
    final raw = publicKey.replaceAll(RegExp(r'\s'), '');
    if (raw.length < 16) return raw.toUpperCase();
    return '${raw.substring(0, 8)}:${raw.substring(8, 16)}...'.toUpperCase();
  }

  PeerDevice copyWith({
    String? id,
    String? name,
    String? deviceType,
    DevicePlatform? platform,
    String? osName,
    String? ipAddress,
    String? localIp,
    int? port,
    String? publicKey,
    int? latencyMs,
    TrustStatus? trustStatus,
    bool? isOnline,
    DateTime? lastSeen,
    DeviceCapabilities? capabilities,
    String? connectionMode,
  }) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      osName: osName ?? this.osName,
      ipAddress: ipAddress ?? this.ipAddress,
      localIp: localIp ?? this.localIp,
      port: port ?? this.port,
      publicKey: publicKey ?? this.publicKey,
      latencyMs: latencyMs ?? this.latencyMs,
      trustStatus: trustStatus ?? this.trustStatus,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      capabilities: capabilities ?? this.capabilities,
      connectionMode: connectionMode ?? this.connectionMode,
    );
  }
}
