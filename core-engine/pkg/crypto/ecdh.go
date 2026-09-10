package crypto

import (
	"crypto/ecdh"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
)

// GenerateECDHKeyPair generates a P-256 private and public key pair
func GenerateECDHKeyPair() (*ecdh.PrivateKey, *ecdh.PublicKey, error) {
	curve := ecdh.P256()
	privKey, err := curve.GenerateKey(rand.Reader)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to generate ECDH key: %w", err)
	}
	return privKey, privKey.PublicKey(), nil
}

// ComputeSharedSecret derives a 32-byte shared AES key from private key & peer public key
func ComputeSharedSecret(priv *ecdh.PrivateKey, peerPubBytes []byte) ([]byte, error) {
	curve := ecdh.P256()
	peerPub, err := curve.NewPublicKey(peerPubBytes)
	if err != nil {
		return nil, fmt.Errorf("invalid peer public key: %w", err)
	}

	secret, err := priv.ECDH(peerPub)
	if err != nil {
		return nil, fmt.Errorf("ECDH key agreement failed: %w", err)
	}

	// Hash shared secret with SHA-256 to obtain a uniform 32-byte AES-256 key
	hash := sha256.Sum256(secret)
	return hash[:], nil
}

// ComputeFileSHA256 computes the SHA-256 checksum of an entire file
func ComputeFileSHA256(filePath string) (string, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}

	return hex.EncodeToString(h.Sum(nil)), nil
}

// ComputeChunkSHA256 computes 32-byte SHA-256 array of a chunk byte array
func ComputeChunkSHA256(data []byte) [32]byte {
	return sha256.Sum256(data)
}
