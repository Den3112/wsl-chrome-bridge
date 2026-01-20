#!/bin/bash

# Configuration
PROJECT_NAME="${ANTIGRAVITY_PROJECT_NAME:-Slovor MP}"
CHROME_CLASS="google-chrome"

# Wait for Chrome window to appear
while true; do
    # Find the window IDs for Google Chrome
    # We use 'search --onlyvisible' to find the actual visible window
    WIDS=$(xdotool search --onlyvisible --class "$CHROME_CLASS" 2>/dev/null)
    
    for wid in $WIDS; do
        # Get current title
        CURRENT_TITLE=$(xdotool getwindowname $wid 2>/dev/null)
        
        # If the title is NOT exactly our project name, force it
        # This fights Chrome's attempt to show "Page Title - Google Chrome"
        if [ "$CURRENT_TITLE" != "$PROJECT_NAME" ]; then
            xdotool setwindowname $wid "$PROJECT_NAME"
        fi
    done
    
    # Check if Chrome is still running locally to avoid infinite orphan loop
    if ! pgrep -f "chrome" > /dev/null; then
        exit 0
    fi
    
    # Low latency polling to react instantly to tab changes
    sleep 0.5
done
