# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Enter development shell (auto-starts Tor and builds tor-ip)
direnv reload

# Build the Go binary manually
go build -o tor-ip .

# Run tor-ip directly
./tor-ip -p 9053              # Change Tor IP (shows old/new IP)
./tor-ip -s -l                # Show both Tor exit IP and local IP
```

## Available Helper Commands

When the dev shell is loaded, these commands are available via `.bin/` scripts:

| Command | Purpose |
|---------|---------|
| `tor-start` | Start Tor daemon in background |
| `tor-stop` | Stop Tor daemon |
| `tor-restart` | Restart Tor daemon |
| `tor-log` | View Tor logs (tail -f) |
| `tip` | Show current Tor exit IP |
| `tmyip` | Show local IP (via tor-ip -s -l) |
| `change` | Change Tor IP using NEWNYM signal |

## Architecture

### Tor Configuration

- **Data directory**: `.tor/` (contains torrc, PID file, cookie auth)
- **Control port**: 9053 (for sending NEWNYM signal)
- **Socks port**: 9052 (for Tor traffic)
- **No Log directive**: torrc intentionally has no `Log` directive to prevent output leakage to terminal during shell startup

### Components

1. **main.go** (`tor-ip` binary)
   - Connects to Tor control port (9053) using `torgo` library
   - Authenticates via cookie or falls back to no auth
   - Sends NEWNYM signal to request new circuit/exit IP
   - Uses curl over socks proxy to check current exit IP via api.ipify.org

2. **flake.nix** (dev shell)
   - Auto-builds `tor-ip` only when source changes
   - Dynamically creates torrc without Log directive (silent Tor)
   - Generates helper scripts in `.bin/` directory
   - Auto-starts Tor in background using `setsid` for proper daemonization

### Key Design Decisions

- **POSIX sh for scripts**: Helper scripts use `#!/bin/sh` not `#!/bin/bash` for Nix compatibility
- **setsid for daemonization**: Tor is started with `setsid` to create new session, preventing output leakage to terminal
- **Auto-rebuild**: Go binary only rebuilds if `main.go` or `go.mod` is newer than existing binary
- **Cookie auth**: Tor uses CookieAuthentication for control port security
