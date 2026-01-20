#!/bin/bash

# =============================================================================
# Start Antigravity Chrome Watchdog (if not already running)
# =============================================================================

WATCHDOG_SCRIPT="/home/creator/chrome_watchdog.sh"
PID_FILE="/tmp/antigravity_chrome_watchdog.pid"

# Check if watchdog is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        # Watchdog is already running
        exit 0
    fi
fi

# Start watchdog in background
nohup bash "$WATCHDOG_SCRIPT" > /dev/null 2>&1 &
NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"

echo "✅ Chrome Watchdog started (PID: $NEW_PID)"
