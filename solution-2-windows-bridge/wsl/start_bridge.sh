#!/bin/bash
set -e

# WSL-Chrome-Bridge: WSL Startup Script
# =====================================
# This script manages the connection between WSL and Windows Chrome.
# 
# Usage: ./start_bridge.sh [--verbose]

# CONFIGURATION (Override via environment variables)
WINDOWS_PYTHON_EXE="${WINDOWS_PYTHON_EXE:-python.exe}"
WINDOWS_PROXY_PATH="${WINDOWS_PROXY_PATH:-C:\\temp\\wsl_chrome_proxy.py}"
WINDOWS_CHROME_BAT="${WINDOWS_CHROME_BAT:-C:\\temp\\start_chrome.bat}"
VERBOSE="${VERBOSE:-false}"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            ;;
    esac
done

log() {
    if [ "$VERBOSE" = true ]; then
        echo "[WSL-Bridge] $1"
    fi
}

error() {
    echo "❌ $1" >&2
}

# Check dependencies
if ! command -v socat &> /dev/null; then
    error "socat is not installed. Run: sudo apt install socat"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    error "curl is not installed. Run: sudo apt install curl"
    exit 1
fi

# Get Windows Host IP
WINDOWS_IP=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)
if [ -z "$WINDOWS_IP" ]; then
    error "Could not determine Windows IP from /etc/resolv.conf"
    exit 1
fi
log "Windows IP: $WINDOWS_IP"

# Check if already connected
if curl -s --connect-timeout 2 "http://$WINDOWS_IP:9223/json/version" > /dev/null 2>&1; then
    echo "✅ Connection to Windows Proxy is active."
else
    echo "🚀 Connection offline. Launching Windows services..."
    log "Starting Python proxy..."
    powershell.exe -Command "Start-Process '$WINDOWS_PYTHON_EXE' -ArgumentList '$WINDOWS_PROXY_PATH' -WindowStyle Hidden" 2>/dev/null || true
    log "Starting Chrome..."
    powershell.exe -Command "Start-Process '$WINDOWS_CHROME_BAT' -WindowStyle Hidden" 2>/dev/null || true
    
    # Wait for services to start
    echo "⏳ Waiting for services to start..."
    for i in {1..10}; do
        if curl -s --connect-timeout 1 "http://$WINDOWS_IP:9223/json/version" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
fi

# Setup local WSL tunnel
log "Killing existing socat processes..."
pkill -f "socat.*9222" 2>/dev/null || true
sleep 0.5

log "Starting socat forwarder..."
nohup socat TCP-LISTEN:9222,fork,reuseaddr,bind=127.0.0.1 TCP:$WINDOWS_IP:9223 > /dev/null 2>&1 &

# Final verification with retry
for i in {1..5}; do
    if curl -s --connect-timeout 2 http://127.0.0.1:9222/json/version > /dev/null 2>&1; then
        echo "✅ WSL-Chrome-Bridge: Connected successfully to 127.0.0.1:9222"
        exit 0
    fi
    sleep 1
done

error "Connection failed. Ensure Windows side is running."
error "Check: python $WINDOWS_PROXY_PATH and Chrome with --remote-debugging-port=9222"
exit 1
