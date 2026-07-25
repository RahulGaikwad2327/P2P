# Node.js P2P Signaling Server

WebSocket-based signaling backend for the **Secure Cross-Platform Decentralized File Sharing System**.

## Features

- **WebSocket Signaling Engine**: Full relay for `REGISTER`, `UNREGISTER`, `GET_DEVICES`, `DEVICE_UPDATE`, `SEND_OFFER`, `SEND_ANSWER`, `SEND_ICE_CANDIDATE`, `LEAVE`, `KEEP_ALIVE`, and `TRANSFER_COMPLETE`.
- **JWT Authentication**: Secure token issue & verification for WebSocket connection upgrades and REST API endpoints.
- **In-Memory Device Registry**: Real-time tracking of online devices, capabilities (`supportsFolder`, `supportsBatch`, `maxFileSize`), public key fingerprints, and connection IP/ports.
- **Broadcast Engine**: Real-time `DEVICE_UPDATE` broadcasts to all connected nodes on peer join/leave.
- **Heartbeat & Dead Peer Detection**: 30-second ping/pong monitoring with automatic stale device eviction.
- **Security First**: Helmet headers, CORS controls, input validation, and Winston logging.

## Tech Stack

- **Node.js** 20.x + **TypeScript** 5.x
- **Express** 4.19+ (HTTP framework)
- **ws** 8.17+ (WebSocket server)
- **jsonwebtoken** 9.0+ (JWT Auth)
- **bcrypt** 5.1+ (Hashing)
- **winston** 3.13+ (Structured logging)

## Quick Start

### Installation

```bash
cd signaling-server
npm install
```

### Environment Setup

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

### Development Mode

```bash
npm run dev
```

The server will start listening on:
- HTTP API: `http://localhost:3000`
- WebSocket: `ws://localhost:3000`

### Build for Production

```bash
npm run build
npm start
```

## API Endpoints

### HTTP REST

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Server uptime & health check |
| POST | `/api/auth/register-device` | Register device & obtain JWT token |
| GET | `/api/auth/verify` | Verify active JWT token |
| GET | `/api/devices` | List all registered online devices |
| GET | `/api/devices/:id` | Get details for specific device |

### WebSocket Messages

All messages follow the standard envelope format:

```json
{
  "type": "SEND_OFFER",
  "fromDeviceId": "uuid-1",
  "toDeviceId": "uuid-2",
  "payload": {
    "transferId": "tx_123",
    "fileName": "document.pdf",
    "fileSize": 1048576,
    "fileHash": "sha256-hash",
    "mimeType": "application/pdf",
    "chunkSize": 65536
  },
  "timestamp": "2026-07-25T12:00:00.000Z"
}
```
