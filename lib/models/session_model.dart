// ─────────────────────────────────────────────────────────────────────────
// session_model.dart — Session interface from the signaling server
// ─────────────────────────────────────────────────────────────────────────

class AppSession {
  final String sessionId;
  final String deviceId;
  final String token; // JWT
  final DateTime connectedAt;
  final bool isActive;

  const AppSession({
    required this.sessionId,
    required this.deviceId,
    required this.token,
    required this.connectedAt,
    this.isActive = true,
  });

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      sessionId: json['sessionId'] as String,
      deviceId: json['deviceId'] as String,
      token: json['token'] as String,
      connectedAt: json['connectedAt'] != null
          ? DateTime.tryParse(json['connectedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceId': deviceId,
        'token': token,
        'connectedAt': connectedAt.toIso8601String(),
        'isActive': isActive,
      };

  AppSession copyWith({
    String? sessionId,
    String? deviceId,
    String? token,
    DateTime? connectedAt,
    bool? isActive,
  }) {
    return AppSession(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      token: token ?? this.token,
      connectedAt: connectedAt ?? this.connectedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
