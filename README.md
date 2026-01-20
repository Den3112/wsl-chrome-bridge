# Antigravity WSL Chrome Manager 🚀

**A robust, self-healing browser orchestration system for WSL 2.**

This repository provides solutions to seamlessly integrate Google Chrome running in WSL 2 with agentic frameworks like **Antigravity**. It solves common issues such as:

*   **Project Isolation:** Launches a separate, independent Chrome instance for every project.
*   **Dynamic Identity:** Automatically sets window titles to match your project name.
*   **CDP Routing:** Smart proxy routes WebSocket traffic to the correct instance.
*   **Resource Management:** Clean, optimized, and self-managed.

## 📦 Solutions

### [Solution 1: Native Chrome (Recommended)](solution-1-native-chrome/README.md)
**Best for:** Standard WSL setups (home use, personal devices)
*   ✅ Runs Chrome natively in Linux
*   ✅ **Auto-starts** only when needed
*   ✅ **Smart Proxy** (Socket Activation) manages launching
*   ✅ Zero Windows dependencies
*   ✅ Fastest performance

### [Solution 2: Windows Bridge](solution-2-windows-bridge/README.md)
**Best for:** Corporate environments with strict firewalls/AVs
*   ✅ Bypasses strict firewalls (Bitdefender, Kaspersky, etc.)
*   ✅ Runs Chrome on Windows (proxy to WSL)
*   ✅ Uses Python proxy to evade detection
*   ⚠️ Slightly slower than native

## 🛠️ Smart Proxy Tools
Now integrated into **[Solution 1](solution-1-native-chrome/)**.
*   `smart_chrome_proxy.py`: Python socket activation proxy.
*   `chrome-ctl`: Management utility.


## 🚀 Quick Start

### Option 1: Native Chrome (Try this first!)

```bash
cd solution-1-native-chrome
./setup.sh
```

### Option 2: Windows Bridge (If Option 1 fails)

```bash
cd solution-2-windows-bridge
./setup.sh
```

## 📚 Documentation

*   [**FAQ**](FAQ.md) - Common questions
*   [**Troubleshooting**](TROUBLESHOOTING.md) - Fix common issues
*   [**Contributing**](CONTRIBUTING.md) - How to help
*   [**Security**](SECURITY.md) - Safety information

## 🧪 Verified Compatible With

*   Google Chrome Stable
*   WSL 2 (Ubuntu 20.04 - 24.04)
*   Antigravity Agent
*   Playwright
*   Puppeteer

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
