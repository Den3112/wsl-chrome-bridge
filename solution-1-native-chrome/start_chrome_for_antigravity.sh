#!/bin/bash

# =============================================================================
# CHROME LAUNCHER with SINGLETON PROTECTION
# =============================================================================

# Lock file to prevent race conditions at the shell script level
LOCK_FILE="/tmp/antigravity_chrome_launch.lock"
exec 200>$LOCK_FILE
flock -n 200 || { echo "Another instance is starting Chrome. Exiting."; exit 1; }

CHROME_BIN="/usr/bin/google-chrome-stable"
# Configuration
# Default port 9223 (Internal, hidden from Agent)
PORT="${CHROME_PORT:-9223}"
USER_DATA_DIR="$HOME/.gemini/antigravity-browser-profile"

# Kill existing Chrome on this port to force a clean slate (Single Instance Policy)
# This prevents the "New Window in Old Session" behavior
pkill -f "chrome.*$PORT" 2>/dev/null

# Clean up any leftover lock files from Chrome itself if it crashed
rm -f "$USER_DATA_DIR/SingletonLock"

echo "Starting Google Chrome on port $PORT..."

# Prepare user profile directory
mkdir -p "$USER_DATA_DIR"

# Start Chrome in background
nohup "$CHROME_BIN" \
  --remote-debugging-port=$PORT \
  --user-data-dir="$USER_DATA_DIR" \
  --remote-allow-origins='*' \
  --no-sandbox \
  --disable-dev-shm-usage \
  --force-device-scale-factor=1.5 \
  --window-size=1400,900 \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-sync \
  > /dev/null 2>&1 &

# Initial short sleep to allow process to spawn
sleep 0.5

PID=$!
echo "✅ Chrome PID: $PID"
sleep 3

if curl -s "http://127.0.0.1:$PORT/json/version" > /dev/null 2>&1; then
    echo ""
    echo "✅ SUCCESS! Chrome is ready"
    echo "🪟 Window: 1400x900 (Scale: ${SCALE_FACTOR}x)"
    echo "🔌 Port: $PORT"
else
    echo "❌ Launch failed:"
    tail -10 /tmp/antigravity_chrome.log
    exit 1
fi
