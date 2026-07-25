package transfer

import (
	"sync"
	"sync/atomic"
	"time"
)

type SessionState string

const (
	StatePending      SessionState = "pending"
	StateConnecting   SessionState = "connecting"
	StateTransferring SessionState = "transferring"
	StatePaused       SessionState = "paused"
	StateCompleted    SessionState = "completed"
	StateFailed       SessionState = "failed"
	StateCancelled    SessionState = "cancelled"
)

// TransferSession maintains active state, speed, and thread-safe cancellation/pause signals
type TransferSession struct {
	ID               string
	PeerIP           string
	PeerPort         int
	FilePath         string
	FileName         string
	FileSize         int64
	FileHash         string
	ChunkSize        int
	IsSending        bool
	State            SessionState
	CurrentChunk     uint64
	TotalChunks      uint64
	BytesTransferred int64
	SpeedBytesPerSec float64
	RetryCount       uint32

	StartTime time.Time
	EndTime   time.Time

	mu        sync.Mutex
	isPaused  atomic.Bool
	isCanceled atomic.Bool
}

func NewTransferSession(id string, filePath string, fileSize int64, chunkSize int, isSending bool) *TransferSession {
	totalChunks := uint64((fileSize + int64(chunkSize) - 1) / int64(chunkSize))
	if totalChunks == 0 {
		totalChunks = 1
	}

	return &TransferSession{
		ID:               id,
		FilePath:         filePath,
		FileSize:         fileSize,
		ChunkSize:        chunkSize,
		IsSending:        isSending,
		State:            StatePending,
		TotalChunks:      totalChunks,
		StartTime:        time.Now(),
	}
}

func (s *TransferSession) Pause() {
	s.isPaused.Store(true)
	s.mu.Lock()
	s.State = StatePaused
	s.mu.Unlock()
}

func (s *TransferSession) Resume() {
	s.isPaused.Store(false)
	s.mu.Lock()
	s.State = StateTransferring
	s.mu.Unlock()
}

func (s *TransferSession) Cancel() {
	s.isCanceled.Store(true)
	s.mu.Lock()
	s.State = StateCancelled
	s.mu.Unlock()
}

func (s *TransferSession) IsPaused() bool {
	return s.isPaused.Load()
}

func (s *TransferSession) IsCanceled() bool {
	return s.isCanceled.Load()
}

func (s *TransferSession) UpdateProgress(chunksDelivered uint64, bytesAdded int64) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.CurrentChunk += chunksDelivered
	s.BytesTransferred += bytesAdded

	elapsed := time.Since(s.StartTime).Seconds()
	if elapsed > 0 {
		s.SpeedBytesPerSec = float64(s.BytesTransferred) / elapsed
	}
}
