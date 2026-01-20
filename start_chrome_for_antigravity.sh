#!/bin/bash

# =============================================================================
# Antigravity Chrome Launcher (On-Demand)
# =============================================================================

CHROME_BIN="/usr/bin/google-chrome-stable"
PORT="${CHROME_PORT:-9222}"
USER_DATA_DIR="/home/creator/.gemini/antigravity-browser-profile"

# Scale factor for High DPI screens (default 1.5 for 4K)
SCALE_FACTOR="${1:-1.5}"

echo "🛑 Stopping existing Chrome processes on port $PORT..."
pkill -f "chrome.*$PORT" 2>/dev/null || true
sleep 2

echo "📁 Preparing user profile..."
mkdir -p "$USER_DATA_DIR"

echo "🚀 Starting Chrome on port $PORT (Scale: ${SCALE_FACTOR}x)..."

nohup "$CHROME_BIN" \
  --remote-debugging-port=$PORT \
  --user-data-dir="$USER_DATA_DIR" \
  --remote-allow-origins=* \
  --no-sandbox \
  --disable-dev-shm-usage \
  --force-device-scale-factor=$SCALE_FACTOR \
  --window-size=1400,900 \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-sync \
  > /tmp/antigravity_chrome.log 2>&1 &

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
