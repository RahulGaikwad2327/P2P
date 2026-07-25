package transfer

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"os"
	"time"

	"secure-p2p-engine/pkg/crypto"
	"secure-p2p-engine/pkg/protocol"
)

// RunReceiver receives encrypted P2P chunks, verifies integrity, decrypts, and writes to target file
func RunReceiver(conn net.Conn, session *TransferSession, aesKey []byte, targetPath string, onProgress ProgressCallback) error {
	defer conn.Close()

	file, err := os.Create(targetPath)
	if err != nil {
		session.State = StateFailed
		return fmt.Errorf("failed to create target file: %w", err)
	}
	defer file.Close()

	session.State = StateTransferring

	for {
		if session.IsCanceled() {
			session.State = StateCancelled
			return fmt.Errorf("transfer canceled by user")
		}

		// Read packet header
		header, err := protocol.DecodeHeader(conn)
		if err != nil {
			if err == io.EOF {
				break // End of stream
			}
			session.State = StateFailed
			return fmt.Errorf("failed to decode binary header: %w", err)
		}

		if header.Type == protocol.TypeFIN {
			break // Transfer complete signal
		}

		// Read encrypted payload
		payloadBuf := make([]byte, header.ChunkSize)
		if _, err := io.ReadFull(conn, payloadBuf); err != nil {
			session.State = StateFailed
			return fmt.Errorf("failed to read payload chunk: %w", err)
		}

		// Decrypt payload with AES-256-GCM
		plaintextChunk, err := crypto.DecryptChunk(payloadBuf, aesKey)
		if err != nil {
			session.State = StateFailed
			return fmt.Errorf("decryption error: %w", err)
		}

		// Verify chunk SHA-256 checksum
		computedChecksum := crypto.ComputeChunkSHA256(plaintextChunk)
		if !bytes.Equal(computedChecksum[:], header.Checksum[:]) {
			session.State = StateFailed
			return fmt.Errorf("checksum mismatch on chunk %d", header.ChunkNumber)
		}

		// Write to file
		if _, err := file.Write(plaintextChunk); err != nil {
			session.State = StateFailed
			return fmt.Errorf("file write error: %w", err)
		}

		// Send ACK header back to sender
		ackHeader := protocol.PacketHeader{
			Version:     protocol.ProtocolVersion,
			Type:        protocol.TypeACK,
			Flags:       0,
			ChunkNumber: header.ChunkNumber,
			TotalChunks: header.TotalChunks,
			ChunkSize:   0,
		}

		if _, err := conn.Write(ackHeader.Encode()); err != nil {
			session.State = StateFailed
			return fmt.Errorf("failed to send ACK: %w", err)
		}

		session.UpdateProgress(1, int64(len(plaintextChunk)))
		if onProgress != nil {
			onProgress(session)
		}

		if session.CurrentChunk >= session.TotalChunks {
			break
		}
	}

	session.State = StateCompleted
	session.EndTime = time.Now()
	if onProgress != nil {
		onProgress(session)
	}

	return nil
}
