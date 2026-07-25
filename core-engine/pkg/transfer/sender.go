package transfer

import (
	"fmt"
	"io"
	"net"
	"os"
	"time"

	"secure-p2p-engine/pkg/crypto"
	"secure-p2p-engine/pkg/protocol"
)

type ProgressCallback func(s *TransferSession)

// RunSender initiates P2P file sending over a TCP connection
func RunSender(conn net.Conn, session *TransferSession, aesKey []byte, onProgress ProgressCallback) error {
	defer conn.Close()

	file, err := os.Open(session.FilePath)
	if err != nil {
		session.State = StateFailed
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer file.Close()

	session.State = StateTransferring
	buffer := make([]byte, session.ChunkSize)

	for chunkIdx := uint64(0); chunkIdx < session.TotalChunks; chunkIdx++ {
		// Handle pause & cancel
		for session.IsPaused() {
			time.Sleep(100 * time.Millisecond)
			if session.IsCanceled() {
				break
			}
		}

		if session.IsCanceled() {
			session.State = StateCancelled
			return fmt.Errorf("transfer canceled by user")
		}

		n, err := file.Read(buffer)
		if err != nil && err != io.EOF {
			session.State = StateFailed
			return fmt.Errorf("error reading file chunk: %w", err)
		}

		if n == 0 {
			break
		}

		plaintextChunk := buffer[:n]
		checksum := crypto.ComputeChunkSHA256(plaintextChunk)

		// Encrypt chunk with AES-256-GCM
		encryptedData, err := crypto.EncryptChunk(plaintextChunk, aesKey)
		if err != nil {
			session.State = StateFailed
			return fmt.Errorf("encryption error: %w", err)
		}

		// Prepare packet header
		header := protocol.PacketHeader{
			Version:      protocol.ProtocolVersion,
			Type:         protocol.TypeDATA,
			Flags:        0,
			ChunkNumber:  chunkIdx,
			TotalChunks:  session.TotalChunks,
			ChunkSize:    uint32(len(encryptedData)),
			Checksum:     checksum,
		}

		// Retry loop for ACKs
		ackReceived := false
		maxRetries := 3

		for retry := 0; retry < maxRetries; retry++ {
			// Write header + encrypted payload
			if _, err := conn.Write(header.Encode()); err != nil {
				session.RetryCount++
				continue
			}

			if _, err := conn.Write(encryptedData); err != nil {
				session.RetryCount++
				continue
			}

			// Read ACK
			conn.SetReadDeadline(time.Now().Add(5 * time.Second))
			ackHeader, err := protocol.DecodeHeader(conn)
			conn.SetReadDeadline(time.Time{})

			if err == nil && ackHeader.Type == protocol.TypeACK && ackHeader.ChunkNumber == chunkIdx {
				ackReceived = true
				break
			}

			session.RetryCount++
		}

		if !ackReceived {
			session.State = StateFailed
			return fmt.Errorf("ACK timeout for chunk %d after retries", chunkIdx)
		}

		session.UpdateProgress(1, int64(n))
		if onProgress != nil {
			onProgress(session)
		}
	}

	session.State = StateCompleted
	session.EndTime = time.Now()
	if onProgress != nil {
		onProgress(session)
	}

	return nil
}
