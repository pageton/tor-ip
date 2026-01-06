# Tor IP Changer

A simple tool to manage a Tor instance and cycle its IP address (circuit) on
demand. Built with Go and Nix.

## Prerequisites

- [Nix](https://nixos.org/download.html) (with
  [Flakes](https://nixos.wiki/wiki/Flakes) enabled)

## Quick Start

Enter the development shell to automatically set up the environment, start Tor,
and compile the tool:

```bash
nix develop
```

This will:

1. Download dependencies (Go, Tor, etc.).
2. Set up a local Tor data directory (`.tor/`).
3. Configure and start a Tor instance (Control Port: `9053`, Socks Port:
   `9052`).
4. Build the `tor-ip` Go binary.
5. Generate helper scripts in `.bin/`.

## Helper Commands

Once inside `nix develop`, the following commands are available:

| Command       | Description                                |
| :------------ | :----------------------------------------- |
| `tor-start`   | Start the Tor daemon.                      |
| `tor-stop`    | Stop the Tor daemon.                       |
| `tor-restart` | Restart the Tor daemon.                    |
| `tor-log`     | View Tor logs (follows output).            |
| `change`      | **Change Tor IP** (Sends `NEWNYM` signal). |
| `tip`         | Show current Tor exit IP.                  |
| `tmyip`       | Show local IP alongside Tor IP.            |

## Manual Usage (`tor-ip`)

The `tor-ip` binary can also be used directly:

```bash
./tor-ip [flags]
```

### Flags

- `-p <port>`: Tor control port (default: `9053`).
- `-addr <address>`: Tor control address (e.g., `127.0.0.1:9051`).
- `-s`: Show current Tor IP only (no change).
- `-l`: Show local IP alongside Tor IP (use with `-s`).
- `-w <seconds>`: Wait specified seconds before changing IP.

## Troubleshooting

- **"failed to connect to Tor control port"**: Ensure Tor is running
  (`tor-start`) and listening on port 9053.
- **Authentication failed**: The setup uses cookie authentication. Ensure the
  `control_auth_cookie` is accessible in `.tor/`.
