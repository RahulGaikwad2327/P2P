# Setup & Deployment Guide

## Prerequisites

- **Flutter SDK** 3.16+
- **Node.js** 20.x & **npm** 10.x
- **Go** 1.21+
- **Docker** & **Docker Compose**

---

## Local Development Setup

### 1. Node.js Signaling Server

```bash
cd signaling-server
npm install
npm run dev
```

Server binds to `http://localhost:3000` (API) & `ws://localhost:3000` (WebSocket).

### 2. Go Core Engine

```bash
cd core-engine
go build -o p2p-engine main.go
./p2p-engine -port=9000
```

Engine binds to `127.0.0.1:9000` for Flutter socket bridge and `8443` for P2P transfers.

### 3. Flutter Client App

```bash
flutter pub get
flutter run -d chrome # or windows / android
```

---

## Docker Compose Deployment

To deploy all 3 components in isolated containers:

```bash
# Build and run multi-container mesh
docker compose up --build -d

# Check running status
docker compose ps

# Access Flutter Web HUD UI
# Open http://localhost:8080
```
