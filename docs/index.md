# Secure Cross-Platform Decentralized File Sharing System

Welcome to the documentation for the **Secure Cross-Platform Decentralized File Sharing System**.

This system enables high-speed, end-to-end encrypted peer-to-peer file transfer across Android, Windows, and Linux devices without routing file payloads through cloud storage servers.

---

## 🚀 Key Features

- 🔒 **End-to-End Encryption**: AES-256-GCM symmetric encryption with ECDH-P256 key exchange.
- ⚡ **High Performance**: Native Go Core Engine delivering maximum TCP throughput in 64 KB chunks.
- 🌐 **Decentralized Discovery**: Node.js WebSocket signaling server for device discovery & NAT traversal without payload access.
- 📱 **Cross-Platform HUD UI**: Built with Flutter for desktop and mobile with a Nothing OS / Cyberpunk HUD aesthetic.
- 🐳 **Containerized**: Production Docker Compose orchestration for seamless multi-node deployment.

---

## 🛠️ System Components

```
Device A (Flutter + Go Engine) ──┐
                                  ├──> Signaling Server (WebSocket, JWT Auth, Device Registry)
Device B (Flutter + Go Engine) ──┘
        │                                                    │
        └──────────── Direct P2P (Go Engine <-> Go Engine) ──┘
```

| Component | Tech Stack | Purpose |
|---|---|---|
| **Flutter App** | Flutter 3.16+, Riverpod 2.5 | Cross-platform user interface (Android & Windows) |
| **Signaling Server** | Node.js 20, TypeScript 5, Express, `ws` | WebSocket discovery, device registry, JWT auth |
| **Core Engine** | Go 1.21+, TLS 1.3, AES-256-GCM, ECDH-P256 | High-speed encrypted P2P file transfer engine |
