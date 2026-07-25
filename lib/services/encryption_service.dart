// ─────────────────────────────────────────────────────────────────────────
// encryption_service.dart
// Key management only — actual AES-256-GCM encryption is handled by the
// Go Core Engine. This service generates ECDH key pairs, persists them
// via flutter_secure_storage, and provides the local public key for
// registration with the signaling server.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static const _privateKeyStorageKey = 'ecdh_private_key';
  static const _publicKeyStorageKey = 'ecdh_public_key';
  static const _deviceIdKey = 'device_id';

  // ── Key generation ────────────────────────────────────────────────────
  /// Returns the persisted ECDH key pair, generating a new one if missing.
  Future<({String publicKey, String privateKey})> getOrCreateKeyPair() async {
    String? existingPub;
    String? existingPriv;

    try {
      existingPub = await _storage.read(key: _publicKeyStorageKey);
      existingPriv = await _storage.read(key: _privateKeyStorageKey);
    } catch (e) {
      debugPrint('[Encryption] Storage read error: $e');
    }

    if (existingPub != null && existingPriv != null) {
      return (publicKey: existingPub, privateKey: existingPriv);
    }

    // Generate a mock ECDH-P256 key pair (placeholder until Go engine FFI)
    final pair = _generateMockKeyPair();

    try {
      await _storage.write(key: _publicKeyStorageKey, value: pair.publicKey);
      await _storage.write(key: _privateKeyStorageKey, value: pair.privateKey);
    } catch (e) {
      debugPrint('[Encryption] Storage write error: $e');
    }

    return pair;
  }

  /// Returns just the public key (for REGISTER message)
  Future<String> getPublicKey() async {
    try {
      final pub = await _storage.read(key: _publicKeyStorageKey);
      if (pub != null) return pub;
    } catch (e) {
      debugPrint('[Encryption] Could not read public key: $e');
    }
    final pair = await getOrCreateKeyPair();
    return pair.publicKey;
  }

  // ── Device ID ─────────────────────────────────────────────────────────
  Future<String> getOrCreateDeviceId() async {
    try {
      final existing = await _storage.read(key: _deviceIdKey);
      if (existing != null) return existing;
    } catch (e) {
      debugPrint('[Encryption] Could not read device ID: $e');
    }
    final id = _generateDeviceId();
    try {
      await _storage.write(key: _deviceIdKey, value: id);
    } catch (e) {
      debugPrint('[Encryption] Could not save device ID: $e');
    }
    return id;
  }

  // ── Key rotation ──────────────────────────────────────────────────────
  Future<void> rotateKeys() async {
    try {
      await _storage.delete(key: _publicKeyStorageKey);
      await _storage.delete(key: _privateKeyStorageKey);
      await getOrCreateKeyPair();
    } catch (e) {
      debugPrint('[Encryption] Key rotation error: $e');
    }
  }

  // ── Clear all secrets ──────────────────────────────────────────────────
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[Encryption] Clear error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  /// Generates a mock ECDH-P256 key pair (Base64 encoded).
  /// The real implementation happens in the Go engine via crypto/ecdh.
  static ({String publicKey, String privateKey}) _generateMockKeyPair() {
    final rand = Random.secure();
    final pubBytes = List<int>.generate(65, (i) => rand.nextInt(256));
    final privBytes = List<int>.generate(32, (i) => rand.nextInt(256));
    pubBytes[0] = 0x04; // Uncompressed point marker
    return (
      publicKey: base64Encode(pubBytes),
      privateKey: base64Encode(privBytes),
    );
  }

  static String _generateDeviceId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (i) => rand.nextInt(256));
    // UUID v4 format
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
