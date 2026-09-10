# ⚡ Secure Cross-Platform Decentralized File Sharing System

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)
![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)
![License](https://img.shields.io/badge/license-MIT-blue)

A high-speed, end-to-end encrypted peer-to-peer file transfer system engineered with a **Nothing OS / Cyberpunk HUD** design language.

---

#Live website 
https://slrv-beam.vercel.app/

## 🏗️ High-Level System Architecture

```
                       ┌─────────────────────────┐
                       │   Flutter Client UI     │
                       │ (Android, Windows, Web) │
                       └────────────┬────────────┘
                                    │
                                    ├──> Signaling Server (Node.js 20 + TypeScript + WebSocket + JWT)
                                    │
                       ┌────────────┴────────────┐
                       │     Go Core Engine      │
                       │ (TLS 1.3 + AES-256-GCM) │
                       └─────────────────────────┘
```

---

## 🚀 Component Architecture

### 1. Flutter App Client (`lib/`)
- **UI & Aesthetic**: Cyberpunk HUD design with dark obsidian palette (`#0A0A0A`), pumpkin orange (`#FF7A1A`) accents, custom dot-matrix grid backgrounds, and glassmorphism cards.
- **State Management**: Riverpod `StateNotifier` architecture (`app_providers.dart`).
- **Routing**: `GoRouter` 14 with ShellRoute navigation (`/home`, `/send`, `/receive`, `/transfer`, `/history`, `/devices`, `/settings`, `/profile`, `/about`).
- **Services**: `SignalingService` (WebSocket client + offline fallback), `GoBridgeService` (localhost:9000 TCP socket client + simulation), `EncryptionService` (`flutter_secure_storage`).

### 2. Node.js Signaling Server (`signaling-server/`)
- **Runtime**: Node.js 20.x + TypeScript 5.x + Express 4.19+
- **Protocol**: WebSocket `ws` 8.17+ with real-time `DEVICE_UPDATE` broadcasts.
- **Authentication**: JWT token issuance and verification for WebSocket connection upgrades & REST API.
- **Eviction**: 30-second ping/pong heartbeat monitoring for dead peer discovery and cleanup.

### 3. Go Core Engine (`core-engine/`)
- **Runtime**: Go 1.21+
- **Wire Protocol**: Custom 72-byte fixed binary header (`SYN`, `ACK`, `DATA`, `FIN`, `PAUSE`) with 64-bit chunk indexing and SHA-256 chunk integrity verification.
- **Cryptography**: TLS 1.3, AES-256-GCM symmetric chunk encryption with 12-byte random nonces, and ECDH-P256 key exchange.
- **Local Bridge**: TCP socket listener on `127.0.0.1:9000` executing JSON control commands from Flutter.

---

## 🐳 Docker Compose Deployment

To build and run all 3 services in isolated containers:

```bash
# Build and start multi-container mesh
docker compose up --build -d

# Check running container status
docker compose ps

# View live system logs
docker compose logs -f
```

### Active Service Ports

| Service | Protocol / URL | Description |
|---|---|---|
| **Flutter Web HUD** | `http://localhost:8080` | Web App User Interface |
| **Signaling Server** | `http://localhost:3000` / `ws://localhost:3000` | HTTP REST API & WebSocket Signaling Engine |
| **Go Core Engine Bridge** | `tcp://localhost:9000` | Local socket control API |
| **Go Core Engine P2P** | `tcp://localhost:8443` | Direct P2P encrypted file transfer port |

---

## 💻 Local Development

### 1. Run Signaling Server
```bash
cd signaling-server
npm install
npm run dev
```

### 2. Run Go Core Engine
```bash
cd core-engine
go run main.go -port=9000
```

### 3. Run Flutter App
```bash
flutter pub get
flutter run -d chrome # or windows / android
```

---

## 📚 Technical Documentation

In-depth technical architecture, sequence diagrams, wire protocol specs, setup, and security guides are located in `docs/`:

- [Architecture Specification](docs/architecture.md)
- [Setup & Deployment Guide](docs/setup.md)
- [Security Architecture](docs/security.md)

To run the MkDocs documentation site:

```bash
pip install mkdocs-material
mkdocs serve
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
