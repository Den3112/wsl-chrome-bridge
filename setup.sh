#!/bin/bash

# WSL-Chrome-Bridge: Setup Script
# Automatically configures the 'google-chrome' shim in WSL.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIM_SRC="$REPO_DIR/wsl/google_chrome_shim"
SHIM_DEST="/usr/bin/google-chrome"

echo "🔧 Setting up WSL-Chrome-Bridge..."

if [ ! -f "$SHIM_SRC" ]; then
    echo "❌ Error: google_chrome_shim not found at $SHIM_SRC"
    exit 1
fi

# Backup existing chrome if it's not our shim
if [ -f "$SHIM_DEST" ] && [ ! -L "$SHIM_DEST" ]; then
    echo "📦 Backing up existing /usr/bin/google-chrome to /usr/bin/google-chrome.bak"
    sudo mv "$SHIM_DEST" "$SHIM_DEST.bak"
fi

# Create symlink
echo "🔗 Creating symlink: $SHIM_DEST -> $SHIM_SRC"
sudo ln -sf "$SHIM_SRC" "$SHIM_DEST"
sudo chmod +x "$SHIM_DEST"

echo "✅ Setup complete! You can now run 'google-chrome --version' to test."
