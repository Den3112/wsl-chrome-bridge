#!/bin/bash

# =============================================================================
# Antigravity Chrome Watchdog - NEW LOGIC (non-intrusive)
# =============================================================================
# Monitors Chrome but does NOT auto-restart it!
# Chrome only starts on-demand (when Antigravity tries to connect)

PORT=9222
CHECK_INTERVAL=30  # Check every 30 seconds (less frequent to avoid interference)
LOG_FILE="/tmp/antigravity_chrome_watchdog.log"
LOCK_FILE="/tmp/chrome_auto_start.lock"

echo "[$(date)] 🐕 Antigravity Chrome Watchdog started (passive mode)" >> "$LOG_FILE"
echo "[$(date)] ℹ️  Chrome will NOT auto-restart after being closed" >> "$LOG_FILE"

# Infinite monitoring loop
while true; do
    # Check if Chrome is responsive
    if ! curl -s --connect-timeout 2 "http://127.0.0.1:$PORT/json/version" > /dev/null 2>&1; then
        # Chrome is not responding
        
        # If lock file exists - Chrome was started and is now closed
        if [ -f "$LOCK_FILE" ]; then
            # User closed Chrome manually - do NOT restart!
            echo "[$(date)] 💤 Chrome closed manually, not restarting" >> "$LOG_FILE"
            rm "$LOCK_FILE"  # Remove lock file
        else
            # Chrome never started yet - this is normal
            # Antigravity will start it when needed
            :
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
