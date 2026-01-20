#!/bin/bash

# Configuration
PROJECT_NAME="${ANTIGRAVITY_PROJECT_NAME:-Slovor MP}"
CHROME_CLASS="google-chrome"
export DISPLAY=:0

# Wait for Chrome window to appear
while true; do
    # Find the window IDs for Google Chrome
    # Removed --onlyvisible to be more robust
    WIDS=$(xdotool search --class "$CHROME_CLASS" 2>/dev/null)
    
    for wid in $WIDS; do
        # Get current title
        CURRENT_TITLE=$(xdotool getwindowname $wid 2>/dev/null)
        
        # If the title is valid and NOT exactly our project name, force it
        if [ -n "$CURRENT_TITLE" ] && [ "$CURRENT_TITLE" != "$PROJECT_NAME" ]; then
            echo "Renaming window $wid: '$CURRENT_TITLE' -> '$PROJECT_NAME'"
            xdotool set_window --name "$PROJECT_NAME" $wid
        fi
    done
    
    # Check if Chrome is still running locally
    if ! pgrep -f "chrome" > /dev/null; then
        echo "Chrome exited. Stopping helper."
        exit 0
    fi
    
    sleep 0.5
done

