#!/bin/bash

# WSL-Chrome-Bridge: WSL Startup Script
# This script manages the connection between WSL and Windows Chrome.

# CONFIGURATION (Defaults for typical installations)
# You can override these via environment variables or edit them here.
WINDOWS_PYTHON_EXE="${WINDOWS_PYTHON_EXE:-python.exe}"
WINDOWS_PROXY_PATH="${WINDOWS_PROXY_PATH:-C:\\temp\\wsl_chrome_proxy.py}"
WINDOWS_CHROME_BAT="${WINDOWS_CHROME_BAT:-C:\\temp\\start_chrome.bat}"

# 1. Get Windows Host IP
WINDOWS_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# 2. Check if already connected
if curl -s --connect-timeout 1 "http://$WINDOWS_IP:9223/json/version" > /dev/null; then
    echo "✅ Connection to Windows Proxy is active."
else
    echo "🚀 Connection offline. Launching Windows services..."
    # Attempt to launch Windows processes via PowerShell
    powershell.exe -Command "Start-Process '$WINDOWS_PYTHON_EXE' -ArgumentList '$WINDOWS_PROXY_PATH' -WindowStyle Hidden"
    powershell.exe -Command "Start-Process '$WINDOWS_CHROME_BAT' -WindowStyle Hidden"
    sleep 3
fi

# 3. Setup local WSL tunnel
pkill -f "socat.*9222"
nohup socat TCP-LISTEN:9222,fork,reuseaddr,bind=127.0.0.1 TCP:$WINDOWS_IP:9223 > /dev/null 2>&1 &

# 4. Final verification
if curl -s --connect-timeout 2 http://127.0.0.1:9222/json/version > /dev/null; then
    echo "✅ WSL-Chrome-Bridge: Connected successfully to 127.0.0.1:9222"
else
    echo "❌ Connect failed. Ensure Windows side is running and paths in this script are correct."
    exit 1
fi
