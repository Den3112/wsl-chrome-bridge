#!/bin/bash

# =============================================================================
# Chrome for Antigravity - IMPROVED VERSION (non-intrusive)
# =============================================================================
# Chrome starts ONLY on first request,
# Does NOT auto-restart if manually closed by user

CHROME_BIN="/usr/bin/google-chrome-stable"
PORT=9222
USER_DATA_DIR="/home/creator/.gemini/antigravity-browser-profile"
SCALE_FACTOR="${1:-1.5}"
LOG_FILE="/tmp/antigravity_chrome.log"
LOCK_FILE="/tmp/chrome_auto_start.lock"

# Function to check if Chrome is running
check_chrome() {
    if curl -s --connect-timeout 2 "http://127.0.0.1:$PORT/json/version" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to start Chrome
start_chrome() {
    echo "🚀 Starting Chrome on port $PORT (scale ${SCALE_FACTOR}x)..." | tee -a "$LOG_FILE"
    
    mkdir -p "$USER_DATA_DIR"
    
    # Create lock file to mark that Chrome was started
    touch "$LOCK_FILE"
    
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
      >> "$LOG_FILE" 2>&1 &
    
    sleep 3
}

# Main logic
if check_chrome; then
    echo "✅ Chrome is already running on port $PORT"
    exit 0
else
    echo "⚠️  Chrome not found, starting..."
    
    # Stop any hanging processes
    pkill -f "chrome.*$PORT" 2>/dev/null || true
    sleep 2
    
    # Start Chrome
    start_chrome
    
    # Verify startup
    if check_chrome; then
        echo "✅ SUCCESS! Chrome started successfully"
        echo "🪟 Window: 1400x900 (scale ${SCALE_FACTOR}x)"
        echo "🔌 Port: $PORT"
        exit 0
    else
        echo "❌ Chrome startup failed:"
        tail -10 "$LOG_FILE"
        exit 1
    fi
fi
