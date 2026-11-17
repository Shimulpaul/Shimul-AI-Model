#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$SCRIPT_DIR/_shimul_core"
INSTALL_DIR="$HOME/Library/Application Support/ShimulVoiceOS"
PLIST_PATH="$HOME/Library/LaunchAgents/com.shimul.voiceagent.plist"

pkill -f shimul_agent.py 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

cp -f "$CORE_DIR/shimul_agent.py" "$INSTALL_DIR/shimul_agent.py"
cp -f "$CORE_DIR/shimul_config.json" "$INSTALL_DIR/shimul_config.json"
cp -f "$CORE_DIR/requirements.txt" "$INSTALL_DIR/requirements.txt"

python3 -m pip install SpeechRecognition pyttsx3 --quiet || true

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.shimul.voiceagent</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(command -v python3)</string>
    <string>$INSTALL_DIR/shimul_agent.py</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict>
</plist>
EOF

launchctl load "$PLIST_PATH"
osascript -e 'display notification "Previous version cleaned. Shimul Buddy is now active!" with title "Shimul Voice OS"' 2>/dev/null || true
