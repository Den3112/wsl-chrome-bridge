# WSL-Chrome-Bridge 🚀

A robust solution to connect WSL 2 applications (Puppeteer, Playwright, Browser-based Agents) to a Google Chrome instance running on Windows, even when blocked by strict local Firewalls or Antiviruses (like Bitdefender, Kaspersky, etc.).

## 📖 The Problem
In WSL 2, connecting to the Windows host's Chrome DevTools Protocol (CDP) port (default `9222`) often fails with `ECONNREFUSED` or `Timeout`. 
This happens because:
1. **Networking Mode:** WSL 2 uses NAT (default on most installations), meaning `localhost` in WSL is not `localhost` on Windows.
2. **Security Software:** Strict security software (Firewalls/AVs) often blocks inbound cross-network traffic to Chrome, even if you add Windows Firewall rules.

## ✨ The Solution
This bridge uses a dual-proxy approach:
- **Windows-side Python Proxy:** Acts as a trusted local process on Windows that tunnels traffic to Chrome.
- **WSL-side Socat Forwarder:** Maps `127.0.0.1:9222` inside WSL to the Windows host proxy.
- **Chrome Shim:** A wrapper script that tricks tools into thinking they are launching a local Linux browser.

---

## 🛠 Installation & Setup

### 1. Windows Preparation
1. Install [Python](https://www.python.org/downloads/).
2. Copy `windows/wsl_chrome_proxy.py` to a known location (e.g., `C:\tools\`).
3. Ensure you have a way to launch Chrome with these flags:
   `--remote-debugging-port=9222 --remote-allow-origins=* --user-data-dir="C:\temp\chrome-debug"`
   *(We recommend creating a `.bat` file for this)*.

### 2. WSL Setup
1. Clone this repository into your WSL environment.
2. Run the automated setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   This will create a `google-chrome` command in WSL that automatically triggers the bridge.

---

## 🚀 How to Use
Simply run any tool that expects Chrome or use the shim directly:
```bash
# This will ensure the bridge is active and "launch" the connection
google-chrome --version
```
Or run the bridge script manually:
```bash
./wsl/start_bridge.sh
```

Now, any tool connecting to `http://127.0.0.1:9222` (like Puppeteer or Playwright) will work perfectly!

---

## 🛡️ Security & Transparency
This project is open-source and designed with transparency in mind. It does **not** collect data, phone home, or execute arbitrary code.

### 🔍 What each component does:
- **Python Proxy (`wsl_chrome_proxy.py`)**: A simple TCP forwarder. It only moves data between your local ports (`9223` -> `9222`). It does not log traffic or touch the internet.
- **Socat Forwarder**: A standard Linux networking tool used to bridge ports between WSL and Windows.
- **Chrome Shim**: A simple bash script that checks for the `--version` flag or triggers the bridge script. **No hidden logic.**

**Why it's safe:** 
- **No compiled binaries** — everything is plain-text script that you can read and audit yourself.
- **No Administrator/Root privileges required** for daily use (except for the one-time `setup.sh` to create a symlink in `/usr/bin/`).

---

## 🔍 Troubleshooting
- **Connection Refused:** Ensure the Python proxy is running on Windows and listening on port `9223`.
- **Hang on Startup:** Check if Windows Firewall or your Antivirus is blocking `python.exe`.
- **Path Errors:** Open `wsl/start_bridge.sh` and ensure the `WINDOWS_PROXY_PATH` matches your Windows file location.

## 📄 License
MIT
