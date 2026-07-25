package protocol

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
)

const (
	ProtocolVersion byte = 0x01
	HeaderSize      int  = 72
)

// Packet Types
const (
	TypeSYN   byte = 0x01
	TypeACK   byte = 0x02
	TypeDATA  byte = 0x03
	TypeFIN   byte = 0x04
	TypePAUSE byte = 0x05
)

// PacketHeader represents the 72-byte fixed binary wire protocol header
type PacketHeader struct {
	Version      byte     // 1 byte
	Type         byte     // 1 byte (SYN/ACK/DATA/FIN/PAUSE)
	Flags        uint16   // 2 bytes
	TransferID   [16]byte // 16 bytes (UUID)
	ChunkNumber  uint64   // 8 bytes
	TotalChunks  uint64   // 8 bytes
	ChunkSize    uint32   // 4 bytes (payload size)
	Checksum     [32]byte // 32 bytes (SHA-256 of plaintext)
}

// Encode serializes the header into a 72-byte buffer
func (h *PacketHeader) Encode() []byte {
	buf := make([]byte, HeaderSize)
	buf[0] = h.Version
	buf[1] = h.Type
	binary.BigEndian.PutUint16(buf[2:4], h.Flags)
	copy(buf[4:20], h.TransferID[:])
	binary.BigEndian.PutUint64(buf[20:28], h.ChunkNumber)
	binary.BigEndian.PutUint64(buf[28:36], h.TotalChunks)
	binary.BigEndian.PutUint32(buf[36:40], h.ChunkSize)
	copy(buf[40:72], h.Checksum[:])
	return buf
}

// DecodeHeader deserializes 72 bytes from a reader into a PacketHeader
func DecodeHeader(r io.Reader) (*PacketHeader, error) {
	buf := make([]byte, HeaderSize)
	if _, err := io.ReadFull(r, buf); err != nil {
		return nil, fmt.Errorf("failed to read packet header: %w", err)
	}

	if buf[0] != ProtocolVersion {
		return nil, errors.New("unsupported wire protocol version")
	}

	h := &PacketHeader{
		Version:     buf[0],
		Type:        buf[1],
		Flags:       binary.BigEndian.Uint16(buf[2:4]),
		ChunkNumber: binary.BigEndian.Uint64(buf[20:28]),
		TotalChunks: binary.BigEndian.Uint64(buf[28:36]),
		ChunkSize:   binary.BigEndian.Uint32(buf[36:40]),
	}

	copy(h.TransferID[:], buf[4:20])
	copy(h.Checksum[:], buf[40:72])

	return h, nil
}
