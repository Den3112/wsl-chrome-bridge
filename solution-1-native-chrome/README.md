# Solution 1: Native Chrome + Smart Proxy (Recommended)

> **Recommended for pure WSL development** — Chrome runs natively in Linux with intelligent socket activation.

## 🎯 Overview

This solution runs Google Chrome directly in WSL 2 (Linux) using a **Smart Python Proxy**. Unlike old "watchdog" scripts that wasted resources or failed to connect, this proxy listens on the debugger port (9222) and launches Chrome **instantly on demand**.

## ✨ Features

- ✅ **Native Performance:** Chrome runs directly in Linux.
- ✅ **Socket Activation:** Launch Chrome by simply connecting to port 9222.
- ✅ **Smart Filtering:** Ignores IDE metadata queries (no random popups!).
- ✅ **Resource Efficient:** Uses <15MB RAM when idle (Python script only).
- ✅ **Race Condition Proof:** Built-in locks prevent multiple browser instances.
- ✅ **Zero Windows Dependencies:** Pure WSL solution.

## 📋 Prerequisites

- WSL 2 (Ubuntu 20.04+ or Debian-based distro)
- Google Chrome for Linux installed in WSL
- `python3` (pre-installed on most distros)

## 🚀 Quick Installation

```bash
chmod +x setup.sh
./setup.sh
```

That's it! The proxy will start automatically when you open a new terminal.

## 📁 What Gets Installed

```
~/smart_chrome_proxy.py       # The active proxy listener (port 9222)
~/start_chrome_for_antigravity.sh # Helper script with correct Chrome flags
~/chrome-ctl                  # Management utility
~/.bashrc                     # Auto-start integration
```

## 🎮 Usage

### Automatic Mode (Recommended)
Just use your tools normally!
```javascript
// Playwright
const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
```
The proxy will intercept the connection and launch Chrome instantly.

### Manual Control

```bash
# Check status
chrome-status

# Start Proxy manually (if stopped)
chrome-ctl start

# Stop everything (Proxy + Chrome)
chrome-ctl stop

# View logs
chrome-ctl logs
```

## 🔧 Configuration

### Change Scaling Factor
Edit `start_chrome_for_antigravity.sh`:
```bash
SCALE_FACTOR="${1:-1.5}"  # 1.5 for 4K (default), 1.0 for 1080p
```

### Change Window Size
Edit `start_chrome_for_antigravity.sh`:
```bash
--window-size=1400,900
```

## 📊 How It Works

1. **Proxy (9222)**: A Python script listens on `0.0.0.0:9222`.
2. **On-Demand**: When a client connects, the proxy checks if Chrome is running on internal port `9223`.
3. **Launch**: If not, it executes `start_chrome_for_antigravity.sh` and waits for `9223` to open.
4. **Peeking**: The proxy "peeks" at the request. If it's just a metadata query (e.g. from an IDE plugin), it sends a mock response instead of launching Chrome.

## 📋 Logs

```bash
chrome-ctl logs
```
