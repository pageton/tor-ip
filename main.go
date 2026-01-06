package main

import (
	"flag"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"time"

	"github.com/wybiral/torgo"
)

const (
	defaultControlPort = 9053
	defaultSocksPort   = 9052
)

func getCurrentIP() string {
	cmd := exec.Command("curl", "-s", "--socks5", fmt.Sprintf("127.0.0.1:%d", defaultSocksPort), "https://api.ipify.org")
	output, err := cmd.Output()
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(output))
}

func changeIP(controlAddr string) error {
	// Create Tor controller (already connects)
	c, err := torgo.NewController(controlAddr)
	if err != nil {
		return fmt.Errorf("failed to connect to Tor control port: %w", err)
	}

	// Try cookie authentication first
	if err := c.AuthenticateCookie(); err != nil {
		// Fall back to no authentication
		if err := c.AuthenticateNone(); err != nil {
			return fmt.Errorf("authentication failed: %w", err)
		}
	}

	// Send NEWNYM signal to change IP
	if err := c.Signal("NEWNYM"); err != nil {
		return fmt.Errorf("failed to send NEWNYM signal: %w", err)
	}

	return nil
}

func getLocalIP() string {
	cmd := exec.Command("curl", "-s", "https://api.ipify.org")
	output, err := cmd.Output()
	if err != nil {
		return "Unknown"
	}
	return strings.TrimSpace(string(output))
}

func main() {
	port := flag.Int("p", defaultControlPort, "Tor control port")
	controlAddr := flag.String("addr", "", "Tor control address (e.g., 127.0.0.1:9051)")
	showOnly := flag.Bool("s", false, "Show current IP only (don't change)")
	showLocal := flag.Bool("l", false, "Show local IP alongside Tor IP")
	wait := flag.Int("w", 0, "Wait seconds before changing (Tor recommends ~10s between changes)")

	flag.Parse()

	addr := *controlAddr
	if addr == "" {
		addr = fmt.Sprintf("127.0.0.1:%d", *port)
	}

	// Show IP only mode
	if *showOnly {
		torIP := getCurrentIP()
		fmt.Printf("Tor exit IP: %s\n", torIP)
		if *showLocal {
			localIP := getLocalIP()
			fmt.Printf("Local IP:   %s\n", localIP)
		}
		return
	}

	if *wait > 0 {
		fmt.Printf("Waiting %d seconds before changing IP...\n", *wait)
		time.Sleep(time.Duration(*wait) * time.Second)
	}

	// Show old IP
	oldIP := getCurrentIP()
	fmt.Printf("Old IP: %s\n", oldIP)

	fmt.Println("Sending NEWNYM signal to Tor...")

	if err := changeIP(addr); err != nil {
		log.Fatalf("Error: %v", err)
	}

	fmt.Println("✓ NEWNYM signal sent successfully")

	// Give Tor time to build new circuit
	time.Sleep(2 * time.Second)

	// Show new IP
	newIP := getCurrentIP()
	fmt.Printf("New IP: %s\n", newIP)
}
