# Go Core Engine

Encrypted P2P file transfer core engine for the **Secure Cross-Platform Decentralized File Sharing System**.

## Features

- **TLS 1.3 & AES-256-GCM Encryption**: All chunk data payloads encrypted with 256-bit AES key derived via ECDH-P256 key agreement.
- **72-Byte Fixed Binary Wire Protocol**: Custom binary wire header (`SYN`, `ACK`, `DATA`, `FIN`, `PAUSE`) with 64-bit chunk indexing and SHA-256 integrity verification.
- **Local Bridge Server (`127.0.0.1:9000`)**: Listens for JSON commands from the Flutter client (`SEND`, `RECEIVE`, `PAUSE`, `RESUME`, `CANCEL`) and streams progress updates back per chunk ACK.
- **Resumable Transfers**: Thread-safe state tracking supporting pause and resume controls.

## Tech Stack

- **Go** 1.21+
- `crypto/tls` (TLS 1.3)
- `crypto/aes` & `crypto/cipher` (AES-256-GCM)
- `crypto/ecdh` (ECDH-P256)
- `crypto/sha256` (SHA-256 integrity)
- `encoding/binary` (Binary wire protocol)

## Quick Start

### Build Binary

```bash
cd core-engine
go build -o p2p-engine main.go
```

### Run Engine

```bash
./p2p-engine -port=9000
```

The engine will initialize its ECDH key pair and open a local TCP bridge listener on `127.0.0.1:9000` for the Flutter frontend.
