package bridge

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"sync"

	"secure-p2p-engine/pkg/transfer"
)

type BridgeCommand struct {
	Command       string `json:"command"` // SEND | RECEIVE | PAUSE | RESUME | CANCEL
	TransferID    string `json:"transferId"`
	PeerIP        string `json:"peerIp"`
	PeerPort      int    `json:"peerPort"`
	FilePath      string `json:"filePath"`
	FileSize      int64  `json:"fileSize"`
	FileHash      string `json:"fileHash"`
	ChunkSize     int    `json:"chunkSize"`
	PeerPublicKey string `json:"peerPublicKey"`
}

type BridgeProgressUpdate struct {
	TransferID       string  `json:"transferId"`
	CurrentChunk     uint64  `json:"currentChunk"`
	TotalChunks      uint64  `json:"totalChunks"`
	BytesTransferred int64   `json:"bytesTransferred"`
	TotalBytes       int64   `json:"totalBytes"`
	SpeedBytesPerSec float64 `json:"speedBytesPerSec"`
	RetryCount       uint32  `json:"retryCount"`
	State            string  `json:"state"`
}

type BridgeServer struct {
	Port     int
	listener net.Listener
	mu       sync.Mutex
	sessions map[string]*transfer.TransferSession
}

func NewBridgeServer(port int) *BridgeServer {
	return &BridgeServer{
		Port:     port,
		sessions: make(map[string]*transfer.TransferSession),
	}
}

func (b *BridgeServer) Start() error {
	addr := fmt.Sprintf("127.0.0.1:%d", b.Port)
	l, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("failed to start bridge listener on %s: %w", addr, err)
	}
	b.listener = l
	log.Printf("[Go Bridge] Socket Server listening for Flutter client on %s", addr)

	for {
		conn, err := l.Accept()
		if err != nil {
			break
		}
		go b.handleClient(conn)
	}

	return nil
}

func (b *BridgeServer) handleClient(conn net.Conn) {
	defer conn.Close()
	scanner := bufio.NewScanner(conn)

	for scanner.Scan() {
		line := scanner.Bytes()
		var cmd BridgeCommand
		if err := json.Unmarshal(line, &cmd); err != nil {
			log.Printf("[Go Bridge] Command JSON parse error: %v", err)
			continue
		}

		log.Printf("[Go Bridge] Command received: %s for TransferID: %s", cmd.Command, cmd.TransferID)
		b.processCommand(cmd, conn)
	}
}

func (b *BridgeServer) processCommand(cmd BridgeCommand, conn net.Conn) {
	b.mu.Lock()
	sess, exists := b.sessions[cmd.TransferID]
	b.mu.Unlock()

	switch cmd.Command {
	case "SEND":
		if !exists {
			chunkSize := cmd.ChunkSize
			if chunkSize == 0 {
				chunkSize = 65536
			}
			sess = transfer.NewTransferSession(cmd.TransferID, cmd.FilePath, cmd.FileSize, chunkSize, true)
			b.mu.Lock()
			b.sessions[cmd.TransferID] = sess
			b.mu.Unlock()
		}

		// Emit progress updates back to Flutter client
		b.sendProgressUpdate(conn, sess)

	case "RECEIVE":
		if !exists {
			chunkSize := cmd.ChunkSize
			if chunkSize == 0 {
				chunkSize = 65536
			}
			sess = transfer.NewTransferSession(cmd.TransferID, cmd.FilePath, cmd.FileSize, chunkSize, false)
			b.mu.Lock()
			b.sessions[cmd.TransferID] = sess
			b.mu.Unlock()
		}

		b.sendProgressUpdate(conn, sess)

	case "PAUSE":
		if exists {
			sess.Pause()
			b.sendProgressUpdate(conn, sess)
		}

	case "RESUME":
		if exists {
			sess.Resume()
			b.sendProgressUpdate(conn, sess)
		}

	case "CANCEL":
		if exists {
			sess.Cancel()
			b.sendProgressUpdate(conn, sess)
		}
	}
}

func (b *BridgeServer) sendProgressUpdate(conn net.Conn, sess *transfer.TransferSession) {
	update := BridgeProgressUpdate{
		TransferID:       sess.ID,
		CurrentChunk:     sess.CurrentChunk,
		TotalChunks:      sess.TotalChunks,
		BytesTransferred: sess.BytesTransferred,
		TotalBytes:       sess.FileSize,
		SpeedBytesPerSec: sess.SpeedBytesPerSec,
		RetryCount:       sess.RetryCount,
		State:            string(sess.State),
	}

	data, _ := json.Marshal(update)
	conn.Write(append(data, '\n'))
}

func (b *BridgeServer) Stop() {
	if b.listener != nil {
		b.listener.Close()
	}
}
