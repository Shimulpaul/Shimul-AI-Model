#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$SCRIPT_DIR/_shimul_core"
INSTALL_DIR="$HOME/.local/share/shimul-voice-os"
SERVICE_DIR="$HOME/.config/systemd/user"

pkill -f shimul_agent.py 2>/dev/null || true
systemctl --user stop shimul-agent.service 2>/dev/null || true
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

cp -f "$CORE_DIR/shimul_agent.py" "$INSTALL_DIR/shimul_agent.py"
cp -f "$CORE_DIR/shimul_config.json" "$INSTALL_DIR/shimul_config.json"
cp -f "$CORE_DIR/requirements.txt" "$INSTALL_DIR/requirements.txt"

python3 -m pip install SpeechRecognition pyttsx3 --quiet || true

mkdir -p "$SERVICE_DIR"
cat > "$SERVICE_DIR/shimul-agent.service" <<EOF
[Unit]
Description=Shimul Always-On Voice Assistant
After=network-online.target sound.target

[Service]
ExecStart=$(command -v python3) $INSTALL_DIR/shimul_agent.py
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now shimul-agent.service 2>/dev/null || nohup python3 "$INSTALL_DIR/shimul_agent.py" >/dev/null 2>&1 &
