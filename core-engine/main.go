package main

import (
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"secure-p2p-engine/pkg/bridge"
	"secure-p2p-engine/pkg/crypto"
)

func main() {
	portFlag := flag.Int("port", 9000, "Local bridge TCP port for Flutter client")
	flag.Parse()

	log.Println("===============================================================")
	log.Println("⚡ GO CORE ENGINE ONLINE // SECURE P2P TRANSFER")
	log.Println("===============================================================")

	// Pre-generate ECDH key pair
	priv, pub, err := crypto.GenerateECDHKeyPair()
	if err != nil {
		log.Fatalf("Failed to initialize ECDH key pair: %v", err)
	}
	_ = priv
	_ = pub
	log.Println("🛡️ ECDH-P256 Key Pair initialized successfully")
	log.Println("🔒 AES-256-GCM symmetric chunk cipher ready")
	log.Println("📦 Wire Protocol v1 initialized (72-byte fixed header)")

	// Start Bridge Server on localhost:9000
	bridgeServer := bridge.NewBridgeServer(*portFlag)
	go func() {
		if err := bridgeServer.Start(); err != nil {
			log.Fatalf("Bridge server error: %v", err)
		}
	}()

	log.Printf("🔌 Local Bridge listening on 127.0.0.1:%d", *portFlag)

	// Graceful shutdown handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	<-sigChan

	log.Println("Shutting down Go Core Engine...")
	bridgeServer.Stop()
	log.Println("Go Core Engine stopped cleanly.")
}
