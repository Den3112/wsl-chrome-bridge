#!/bin/bash
set -e
# ==============================================================================
# WSL-Chrome-Bridge: Automated Setup Script
# ==============================================================================
# PURPOSE:
#   Installs the google-chrome shim so that any tool looking for Chrome
#   will automatically use the WSL-Chrome-Bridge instead.
#
# WHAT IT DOES:
#   1. Backs up any existing /usr/bin/google-chrome binary
#   2. Creates a symlink from /usr/bin/google-chrome → wsl/google_chrome_shim
#   3. Makes the shim executable
#
# REQUIREMENTS:
#   - sudo access (for creating symlink in /usr/bin/)
#   - socat package installed (sudo apt install socat)
#
# USAGE:
#   chmod +x setup.sh
#   ./setup.sh
# ==============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit && pwd)"
SHIM_SRC="$REPO_DIR/wsl/google_chrome_shim"
SHIM_DEST="/usr/bin/google-chrome"

echo "🔧 WSL-Chrome-Bridge: Setup"
echo "==========================="

# Check if shim exists
if [ ! -f "$SHIM_SRC" ]; then
    echo "❌ Error: google_chrome_shim not found at $SHIM_SRC"
    echo "   Make sure you're running this from the repository root."
    exit 1
fi

# Check for socat
if ! command -v socat &> /dev/null; then
    echo "⚠️  Warning: socat is not installed."
    echo "   Install it with: sudo apt install socat"
fi

# Backup existing Chrome binary (if it's a real file, not a symlink)
if [ -f "$SHIM_DEST" ] && [ ! -L "$SHIM_DEST" ]; then
    echo "📦 Backing up existing /usr/bin/google-chrome → /usr/bin/google-chrome.bak"
    sudo mv "$SHIM_DEST" "$SHIM_DEST.bak"
fi

# Remove old symlink if exists
if [ -L "$SHIM_DEST" ]; then
    echo "🗑️  Removing old symlink..."
    sudo rm "$SHIM_DEST"
fi

# Create new symlink
echo "🔗 Creating symlink: $SHIM_DEST → $SHIM_SRC"
sudo ln -sf "$SHIM_SRC" "$SHIM_DEST"
sudo chmod +x "$SHIM_DEST"
chmod +x "$SHIM_SRC"
chmod +x "$REPO_DIR/wsl/start_bridge.sh"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Copy windows/wsl_chrome_proxy.py to your Windows machine"
echo "   2. Create a .bat file to launch Chrome with --remote-debugging-port=9222"
echo "   3. Update paths in wsl/start_bridge.sh if needed"
echo ""
echo "🧪 Test with: google-chrome --version"
