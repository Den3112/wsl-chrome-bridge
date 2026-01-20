# WSL Antigravity Chrome Solutions 🚀

Two powerful solutions to run Google Chrome in WSL 2, specifically optimized for **Antigravity**, **Playwright**, and **Puppeteer**.

Choose the one that fits your environment!

## 📦 Solutions

### [Solution 1: Native Chrome (Recommended)](solution-1-native-chrome/README.md)
**Best for:** Standard WSL setups (home use, personal devices)
*   ✅ Runs Chrome natively in Linux
*   ✅ **Auto-starts** only when needed
*   ✅ **Passive Watchdog** monitors connectivity
*   ✅ Zero Windows dependencies
*   ✅ Fastest performance

### [Solution 2: Windows Bridge](solution-2-windows-bridge/README.md)
**Best for:** Corporate environments with strict firewalls/AVs
*   ✅ Bypasses strict firewalls (Bitdefender, Kaspersky, etc.)
*   ✅ Runs Chrome on Windows (proxy to WSL)
*   ✅ Uses Python proxy to evade detection
*   ⚠️ Slightly slower than native

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
