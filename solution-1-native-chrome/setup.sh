#!/bin/bash
set -e

# ==============================================================================
# WSL Antigravity Chrome Solutions - Solution 1: Native Chrome (Smart Proxy)
# Automated Setup Script
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 WSL Antigravity Chrome - Solution 1: Native Chrome (Active Proxy)"
echo "===================================================================="
echo ""

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null && ! command -v google-chrome-stable &> /dev/null; then
    echo "⚠️  Google Chrome not found in WSL."
    echo ""
    echo "📦 Install Chrome for Linux:"
    echo "   wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    echo "   sudo apt install ./google-chrome-stable_current_amd64.deb"
    echo ""
    read -p "Do you want to install Chrome now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd /tmp
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
        echo "✅ Chrome installed!"
    else
        echo "❌ Chrome is required. Please install it manually."
        exit 1
    fi
fi

echo "📦 Installing scripts to home directory..."

# Copy scripts
cp "$SCRIPT_DIR/smart_chrome_proxy.py" ~/smart_chrome_proxy.py
cp "$SCRIPT_DIR/start_chrome_for_antigravity.sh" ~/start_chrome_for_antigravity.sh
cp "$SCRIPT_DIR/chrome-ctl" ~/chrome-ctl

# Make executable
chmod +x ~/start_chrome_for_antigravity.sh
chmod +x ~/chrome-ctl

echo "✅ Scripts installed to ~/"
echo ""

# Check if .bashrc already has the auto-start section
if grep -q "Antigravity Smart Proxy" ~/.bashrc; then
    echo "✅ .bashrc already configured"
else
    echo "📝 Adding proxy to ~/.bashrc..."
    cat >> ~/.bashrc << 'EOF'

# =============================================================================
# Antigravity Smart Proxy Auto-start
# =============================================================================
# Automatically starts the Smart Socket Proxy
if [ -f "$HOME/smart_chrome_proxy.py" ]; then
    # Start proxy in background if not running
    if ! pgrep -f "smart_chrome_proxy.py" > /dev/null; then
        nohup python3 "$HOME/smart_chrome_proxy.py" > /tmp/smart_proxy.log 2>&1 &
    fi
fi

# Antigravity Chrome management aliases
alias chrome-status='~/chrome-ctl status'
alias chrome-restart='~/chrome-ctl restart'
alias chrome-logs='~/chrome-ctl logs'
EOF
    echo "✅ .bashrc updated"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 What was installed:"
echo "   ~/smart_chrome_proxy.py       - The Active Socket Proxy (listens on 9222)"
echo "   ~/start_chrome_for_antigravity.sh - Chrome launcher helper"
echo "   ~/chrome-ctl                  - Management utility"
echo "   ~/.bashrc                     - Auto-start integration"
echo ""
echo "🚀 Next steps:"
echo "   1. Restart your terminal (or run: source ~/.bashrc)"
echo "   2. The Proxy will start automatically."
echo "   3. When Antigravity/Playwright connects to port 9222, Chrome will launch instantly."
echo ""
echo "ℹ️  Smart Behavior:"
echo "   • Zero RAM usage when idle (Python script only)"
echo "   • Chrome runs ONLY when you need it"
echo "   • No more 'ECONNREFUSED' errors"
echo ""
echo "🧪 Test now:"
echo "   source ~/.bashrc"
echo "   chrome-status"
echo ""
