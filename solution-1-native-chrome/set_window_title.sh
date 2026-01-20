#!/bin/bash
REGISTRY_FILE="/tmp/ag_chrome_registry.json"
export DISPLAY=:0

log() {
    echo "[$(date +'%H:%M:%S')] $1"
}

# Python one-liner to parse JSON and output "pid project_name" lines
PARSE_CMD="
import json, sys
try:
    with open('$REGISTRY_FILE') as f:
        data = json.load(f)
        for name, info in data.items():
            print(f\"{info['pid']} {name}\")
except: pass
"

log "Starting multi-project title helper..."

while true; do
    if [ -f "$REGISTRY_FILE" ]; then
        # Get list of "PID PROJECT_NAME"
        python3 -c "$PARSE_CMD" | while read -r pid project_name; do
            if [ -z "$pid" ] || [ "$pid" = "0" ]; then continue; fi
            
            # Search for windows belonging to this PID
            # We search for children too because Chrome spawns processes
            # Ideally xdotool search --pid matches the specific window
            WIDS=$(xdotool search --pid "$pid" 2>/dev/null)
            
            for wid in $WIDS; do
                current_title=$(xdotool getwindowname "$wid" 2>/dev/null)
                if [ -n "$current_title" ] && [ "$current_title" != "$project_name" ]; then
                    xdotool set_window --name "$project_name" "$wid"
                    # log "Creating title '$project_name' for PID $pid (WID $wid)"
                fi
            done
        done
    fi
    sleep 1
done
