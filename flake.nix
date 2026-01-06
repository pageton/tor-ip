{
  description = "Tor IP changer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            tor
            curl
          ];

          shellHook = ''
            # Colors
            R="\033[31m" G="\033[32m" Y="\033[33m" B="\033[34m" M="\033[35m" C="\033[36m" W="\033[37m" N="\033[0m"

            export TOR_DATA_DIR=$PWD/.tor
            export TORRC=$TOR_DATA_DIR/torrc
            export TOR_PID=$TOR_DATA_DIR/tor.pid
            export BIN_DIR=$PWD/.bin

            mkdir -p "$BIN_DIR" "$TOR_DATA_DIR"

            # Rebuild tor-ip if needed
            [[ ! -f ./tor-ip ]] || [[ ./main.go -nt ./tor-ip ]] || [[ ./go.mod -nt ./tor-ip ]] && go build -o tor-ip .

            # Create torrc (no Log directive = silent)
            cat > "$TORRC" <<EOF
            ControlPort 9053
            SocksPort 9052
            DataDirectory $TOR_DATA_DIR
            CookieAuthentication 1
            CookieAuthFile $TOR_DATA_DIR/control_auth_cookie
            PidFile $TOR_PID
            EOF

            # Create helper scripts in .bin/
            cat > "$BIN_DIR/tor-start" <<'SCR'
            #!/bin/sh
            PID="$TOR_DATA_DIR/tor.pid"
            if [ -f "$PID" ]; then
              P=$(cat "$PID" 2>/dev/null)
              [ -n "$P" ] && [ -d "/proc/$P" ] && { printf "\033[33mAlready running\033[0m\n"; exit 0; }
            fi
            setsid tor -f "$TORRC" </dev/null >/dev/null 2>&1 &
            printf "\033[32mTor Started ✓\033[0m\n"
            SCR
            chmod +x "$BIN_DIR/tor-start"

            cat > "$BIN_DIR/tor-stop" <<'SCR'
            #!/bin/sh
            PID="$TOR_DATA_DIR/tor.pid"
            if [ -f "$PID" ]; then
              P=$(cat "$PID" 2>/dev/null)
              if kill "$P" 2>/dev/null; then
                rm -f "$PID"
                printf "\033[31mTor Stopped\033[0m\n"
              else
                printf "\033[33mTor not running\033[0m\n"
              fi
            else
              printf "\033[33mTor not running\033[0m\n"
            fi
            SCR
            chmod +x "$BIN_DIR/tor-stop"

            cat > "$BIN_DIR/tor-restart" <<'SCR'
            #!/bin/sh
            "$BIN_DIR/tor-stop"; sleep 1; "$BIN_DIR/tor-start"
            SCR
            chmod +x "$BIN_DIR/tor-restart"

            cat > "$BIN_DIR/tor-log" <<'SCR'
            #!/bin/sh
            tail -f "$TOR_DATA_DIR/tor.log" 2>/dev/null || echo "No log file"
            SCR
            chmod +x "$BIN_DIR/tor-log"

            cat > "$BIN_DIR/tip" <<'SCR'
            #!/bin/sh
            curl -s --socks5 127.0.0.1:9052 https://api.ipify.org; echo
            SCR
            chmod +x "$BIN_DIR/tip"

            cat > "$BIN_DIR/tmyip" <<'SCR'
            #!/bin/sh
            ./tor-ip -s -l
            SCR
            chmod +x "$BIN_DIR/tmyip"

            cat > "$BIN_DIR/change" <<'SCR'
            #!/bin/sh
            ./tor-ip -p 9053
            SCR
            chmod +x "$BIN_DIR/change"

            export PATH="$BIN_DIR:$PATH"

            # Auto-start Tor
            "$BIN_DIR/tor-start" >/dev/null 2>&1

            echo ""
            echo -e "''${C}Tor environment configured''${N} ''${W}(Control: ''${B}9053''${W}, Socks: ''${B}9052''${W})''${N}"
            echo ""
            echo -e "''${G}Available commands:''${N}"
            echo -e "  ''${B}tor-start''${N}     ''${W}-''${N} Start Tor daemon"
            echo -e "  ''${R}tor-stop''${N}      ''${W}-''${N} Stop Tor daemon"
            echo -e "  ''${Y}tor-restart''${N}   ''${W}-''${N} Restart Tor daemon"
            echo -e "  ''${M}tor-log''${N}       ''${W}-''${N} View Tor logs (tail -f)"
            echo -e "  ''${C}tip''${N}           ''${W}-''${N} Show Tor exit IP"
            echo -e "  ''${G}tmyip''${N}         ''${W}-''${N} Show local IP"
            echo -e "  ''${B}change''${N}        ''${W}-''${N} Change Tor IP (NEWNYM)"
          '';
        };
      }
    );
}
