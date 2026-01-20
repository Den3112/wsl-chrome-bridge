# Solution 1: Native Chrome + Watchdog

> **Recommended for pure WSL development** — Chrome runs natively in Linux with automatic monitoring

## 🎯 Overview

This solution runs Google Chrome directly in WSL 2 (Linux) with a robust watchdog system that automatically monitors and restarts Chrome if needed. Perfect for Antigravity, Playwright, Puppeteer, and other browser automation tools.

## ✨ Features

- ✅ **Native Performance:** Chrome runs directly in Linux (no proxy overhead)
- ✅ **On-Demand Start:** Chrome starts automatically when you need it
- ✅ **Passive Watchdog:** Monitors state without annoying auto-restarts
- ✅ **4K Ready:** Pre-configured with 150% scaling for 4K displays
- ✅ **Optimized Window:** Fixed 1400x900 size for consistent screenshots
- ✅ **Zero Windows Dependencies:** Pure WSL solution

## 📋 Prerequisites

- WSL 2 (Ubuntu 20.04+ or Debian-based distro)
- Google Chrome for Linux installed in WSL
- `curl` and `bash` (usually pre-installed)

## 🚀 Quick Installation

```bash
chmod +x setup.sh
./setup.sh
```

That's it! The watchdog will start automatically when you open a new terminal.

## 📁 What Gets Installed

```
~/ensure_chrome_running.sh    # Smart Chrome launcher
~/chrome_watchdog.sh          # Background monitor (passive)
~/start_chrome_watchdog.sh    # Watchdog launcher
~/chrome-ctl                  # Management utility
~/chrome_shim                 # On-demand launcher
~/.bashrc                     # Auto-start integration
```

## 🎮 Usage

### Automatic Mode (Recommended)
Just use your tools normally!
```javascript
// Playwright
const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
```
Chrome will start automatically when the tool tries to connect!

### Manual Control

```bash
# Check status
chrome-status

# Start Chrome manually
chrome-ctl start

# Stop Chrome
chrome-ctl stop
```

## 🔧 Configuration

### Change Scaling Factor
Edit `ensure_chrome_running.sh`:
```bash
SCALE_FACTOR="1.5"  # 150% for 4K, 1.0 for 1080p
```

### Change Window Size
Edit `ensure_chrome_running.sh`:
```bash
--window-size=1400,900  # Width x Height
```

## 📊 How It Works

1. **Watchdog**: Runs in background, checks if Chrome is alive.
2. **On-Demand**: When you run a test, `chrome_shim` or `ensure_chrome_running.sh` starts Chrome.
3. **Passive Mode**: If you close Chrome manually, it stays closed (no annoyance).

## 📋 Logs

```bash
tail -f /tmp/antigravity_chrome.log
```
