# Security Architecture & Cryptography

The **Secure Cross-Platform Decentralized File Sharing System** employs multi-layered cryptographic protection to guarantee confidentiality, integrity, and authenticity.

---

## Security Layers

| Layer | Protocol / Tech | Description |
|---|---|---|
| **Transport** | TLS 1.3 | Encrypted socket transport for signaling & P2P channels |
| **Application Payload** | AES-256-GCM | Symmetric encryption of 64 KB file chunks |
| **Key Exchange** | ECDH-P256 | Ephemeral Elliptic Curve Diffie-Hellman key agreement |
| **Integrity** | SHA-256 | Per-chunk and full-file cryptographic checksum verification |
| **Authentication** | JWT (JSON Web Token) | Signed device session authentication with 7-day expiration |
| **Credential Storage** | `flutter_secure_storage` | OS-backed encrypted storage (Android EncryptedSharedPreferences / Windows DPAPI) |

---

## End-to-End Encryption Flow

1. **Key Generation**:
   - Each device generates a persistent ECDH-P256 key pair upon initial boot.
   - The public key is stored securely and registered with the signaling server.
2. **Key Agreement**:
   - Before file transfer begins, Device A and Device B exchange public keys via `SEND_OFFER` / `SEND_ANSWER`.
   - Both devices derive an identical 32-byte shared secret using ECDH-P256 and SHA-256 key derivation.
3. **Payload Encryption**:
   - Every 64 KB chunk is encrypted with AES-256-GCM using a unique 12-byte random initialization vector (nonce).
   - Auth tag guarantees ciphertext tampering is instantly detected upon receipt.
