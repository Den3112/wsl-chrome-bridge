#!/bin/bash
set -e

# ==============================================================================
# WSL Antigravity Chrome Solutions - Solution 1: Native Chrome
# Automated Setup Script
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 WSL Antigravity Chrome - Solution 1: Native Chrome"
echo "========================================================="
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
cp "$SCRIPT_DIR/ensure_chrome_running.sh" ~/ensure_chrome_running.sh
cp "$SCRIPT_DIR/chrome_watchdog.sh" ~/chrome_watchdog.sh
cp "$SCRIPT_DIR/start_chrome_watchdog.sh" ~/start_chrome_watchdog.sh
cp "$SCRIPT_DIR/chrome-ctl" ~/chrome-ctl
cp "$SCRIPT_DIR/chrome_shim" ~/chrome_shim

# Make executable
chmod +x ~/ensure_chrome_running.sh
chmod +x ~/chrome_watchdog.sh
chmod +x ~/start_chrome_watchdog.sh
chmod +x ~/chrome-ctl
chmod +x ~/chrome_shim

echo "✅ Scripts installed to ~/"
echo ""

# Optionally install Chrome shim (so Antigravity auto-starts Chrome)
echo "🔧 Setting up Chrome auto-start on access..."
read -p "Install Chrome shim for on-demand startup? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup existing chrome if it's a real binary
    if [ -f "/usr/local/bin/google-chrome" ] && [ ! -L "/usr/local/bin/google-chrome" ]; then
        sudo mv /usr/local/bin/google-chrome /usr/local/bin/google-chrome.bak
    fi
    
    # Create symlink
    sudo mkdir -p /usr/local/bin
    sudo ln -sf ~/chrome_shim /usr/local/bin/google-chrome
    echo "✅ Chrome shim installed"
    echo "ℹ️  Chrome will now start automatically when accessed"
else
    echo "⏭️  Chrome shim skipped"
    echo "ℹ️  Start Chrome manually with: chrome-ctl start"
fi
echo ""

# Check if .bashrc already has the auto-start section
if grep -q "Antigravity Chrome Auto-start" ~/.bashrc; then
    echo "✅ .bashrc already configured"
else
    echo "📝 Adding watchdog to ~/.bashrc..."
    cat >> ~/.bashrc << 'EOF'

# =============================================================================
# Antigravity Chrome Auto-start
# =============================================================================
# Automatically starts Chrome Watchdog for Antigravity
if [ -f "$HOME/start_chrome_watchdog.sh" ]; then
    # Start watchdog in background (only one instance allowed)
    bash "$HOME/start_chrome_watchdog.sh" > /dev/null 2>&1
fi

# Antigravity Chrome management aliases
alias chrome-status='~/chrome-ctl status'
alias chrome-restart='~/chrome-ctl restart'
EOF
    echo "✅ .bashrc updated"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 What was installed:"
echo "   ~/ensure_chrome_running.sh  - Smart Chrome launcher"
echo "   ~/chrome_watchdog.sh        - Background monitor (passive)"
echo "   ~/start_chrome_watchdog.sh  - Watchdog launcher"
echo "   ~/chrome-ctl                - Management utility"
echo "   ~/chrome_shim               - On-demand Chrome starter"
echo "   ~/.bashrc                   - Watchdog integration"
echo ""
echo "🚀 Next steps:"
echo "   1. Restart your terminal (or run: source ~/.bashrc)"
echo "   2. Watchdog will start automatically (passive mode)"
echo "   3. Use Antigravity/Playwright/Puppeteer normally!"
echo ""
echo "ℹ️  Important: Chrome will NOT auto-restart if you close it manually"
echo "   This is the new improved behavior to avoid annoyance"
echo ""
echo "📚 Quick commands:"
echo "   chrome-status      - Check system status"
echo "   chrome-restart     - Restart Chrome"
echo "   ~/chrome-ctl logs  - View logs"
echo ""
echo "🧪 Test now:"
echo "   source ~/.bashrc"
echo "   chrome-status"
echo ""
