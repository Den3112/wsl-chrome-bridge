# Configuration
PROJECT_NAME_FILE="/tmp/ag_project_name"
DEFAULT_PROJECT_NAME="${ANTIGRAVITY_PROJECT_NAME:-Antigravity Browser}"
CHROME_CLASS="google-chrome"
export DISPLAY=:0

# Wait for Chrome window to appear
while true; do
    # Read project name dynamically from temp file (updated by proxy)
    if [ -f "$PROJECT_NAME_FILE" ]; then
        PROJECT_NAME=$(cat "$PROJECT_NAME_FILE")
    else
        PROJECT_NAME="$DEFAULT_PROJECT_NAME"
    fi

    # Find the window IDs for Google Chrome
    # Removed --onlyvisible to be more robust
    WIDS=$(xdotool search --class "$CHROME_CLASS" 2>/dev/null)
    
    for wid in $WIDS; do
        # Get current title
        CURRENT_TITLE=$(xdotool getwindowname $wid 2>/dev/null)
        
        # If the title is valid and NOT exactly our project name, force it
        if [ -n "$CURRENT_TITLE" ] && [ "$CURRENT_TITLE" != "$PROJECT_NAME" ]; then
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

