# Troubleshooting Guide

Common issues and their solutions for both Chrome automation approaches.

## General Issues

### `ECONNREFUSED 127.0.0.1:9222`

**Symptoms:** Tools can't connect to Chrome

**Solutions:**

#### For Solution 1 (Native Chrome):
```bash
# 1. Check if Chrome is running
curl http://127.0.0.1:9222/json/version

# 2. Check watchdog status
chrome-status

# 3. Try restarting
chrome-restart

# 4. Check logs
tail -20 /tmp/antigravity_chrome.log
```

#### For Solution 2 (Windows Bridge):
```bash
# 1. Check if socat is running
ps aux | grep socat

# 2. Check Windows proxy
curl http://$(grep nameserver /etc/resolv.conf | awk '{print $2}'):9223/json/version

# 3. Restart bridge
./wsl/start_bridge.sh --verbose

# 4. Verify Windows Chrome is running with --remote-debugging-port=9222
```

---

### Chrome Opens But Won't Connect

**Solution 1:**
```bash
# Kill all Chrome processes
pkill -f chrome

# Clear profile (if corrupted)
rm -rf ~/.gemini/antigravity-browser-profile/*

# Restart
chrome-restart
```

**Solution 2:**
```bash
# Check Windows firewall isn't blocking port 9223
# Try disabling AV temporarily to test

# Restart Python proxy on Windows
# Restart Chrome on Windows
```

---

### Multiple Chrome Instances

**Solution 1:**
```bash
# Kill all Chrome
pkill -f chrome

# Kill watchdog
pkill -f chrome_watchdog
rm /tmp/antigravity_chrome_watchdog.pid

# Start fresh
~/start_chrome_watchdog.sh
```

**Solution 2:**
```bash
# Kill socat
pkill -f socat

# Restart bridge
./wsl/start_bridge.sh
```

---

## Solution 1 Specific Issues

### Watchdog Not Starting

```bash
# Check if already running
ps aux | grep chrome_watchdog

# Check PID file
cat /tmp/antigravity_chrome_watchdog.pid

# Manual start
~/start_chrome_watchdog.sh

# Check bashrc integration
grep "Chrome Auto-start" ~/.bashrc
```

### Chrome Crashes Repeatedly

```bash
# Check system resources
free -h
df -h

# Check Chrome logs
tail -50 /tmp/antigravity_chrome.log

# Try without sandbox (already default)
# Check if GPU issues - try --disable-gpu
```

### Wrong Scaling/Window Size

Edit `~/ensure_chrome_running.sh`:
```bash
SCALE_FACTOR="________"  # Change this
--window-size=____,____  # Change this
```

Then restart:
```bash
chrome-restart
```

---

## Solution 2 Specific Issues

### Python Proxy Won't Start

**Windows side:**
```powershell
# Check if port 9223 is in use
netstat -an | findstr :9223

# Check Python is installed
python --version

# Run proxy manually to see errors
python C:\path\to\wsl_chrome_proxy.py --verbose
```

### Socat Connection Timeout

```bash
# Get Windows IP
grep nameserver /etc/resolv.conf | awk '{print $2}'

# Test connectivity
ping <WINDOWS_IP>

# Check if port 9223 is reachable
nc -zv <WINDOWS_IP> 9223
```

### Windows Chrome Not Starting

Create a proper batch file:
```batch
@echo off
"C:\Program Files\Google\Chrome\Application\chrome.exe" ^
  --remote-debugging-port=9222 ^
  --remote-allow-origins=* ^
  --user-data-dir="C:\temp\chrome-debug" ^
  --window-size=1400,900
```

Save as `C:\temp\start_chrome.bat` and update path in `wsl/start_bridge.sh`

### Firewall Still Blocking

**Windows Firewall:**
```powershell
# Add rule for Python (run as Administrator)
New-NetFirewallRule -DisplayName "WSL Chrome Bridge" -Direction Inbound -Program "C:\Path\To\python.exe" -Action Allow
```

**Antivirus:**
- Add `python.exe` to exclusions
- Add `C:\temp\wsl_chrome_proxy.py` to exclusions
- Temporarily disable to test

---

## Performance Issues

### Slow Connection/High Latency

**Solution 1:** Should be fast (native)
```bash
# Check system load
top

# Check Chrome memory
ps aux | grep chrome | awk '{print $6}' | awk '{s+=$1} END {print s/1024 "MB"}'
```

**Solution 2:** Some overhead is normal
```bash
# Check socat isn't CPU bound
top | grep socat

# Consider switching to Solution 1
```

### High Memory Usage

```bash
# Chrome is memory-hungry, this is normal
# Restart Chrome to clear
chrome-restart  # Solution 1
./wsl/start_bridge.sh  # Solution 2
```

---

## Debugging Mode

### Solution 1: Verbose Logging

```bash
# Check current logs
tail -f /tmp/antigravity_chrome.log
tail -f /tmp/antigravity_chrome_watchdog.log

# Manual Chrome start with output
pkill -f chrome
google-chrome-stable --remote-debugging-port=9222 --user-data-dir=/tmp/test
```

### Solution 2: Verbose Mode

```bash
# WSL side
./wsl/start_bridge.sh --verbose

# Windows side (in Python proxy)
python wsl_chrome_proxy.py --verbose
```

---

## Still Having Issues?

1. **Check Chrome version compatibility**
   ```bash
   google-chrome --version
   ```

2. **Test with simple curl**
   ```bash
   curl http://127.0.0.1:9222/json/version
   ```

3. **Try the other solution**
   - If Solution 1 fails → try Solution 2
   - If Solution 2 fails → try Solution 1

4. **Open an issue on GitHub** with:
   - Your WSL version (`wsl --version`)
   - Chrome version
   - Full error logs
   - Steps to reproduce

---

## Common Environment Issues

### WSL 1 vs WSL 2

Both solutions are designed for **WSL 2**. On WSL 1:
- Solution 1 should work fine
- Solution 2 may have networking issues

Check your version:
```bash
wsl -l -v
```

### Ubuntu vs Other Distros

Both solutions tested on Ubuntu 20.04+. On other distros:
- Install Chrome: Check your distro's package manager
- Install dependencies: `curl`, `socat`, `bash`

### systemd vs non-systemd

- Solution 1 works on both (uses .bashrc)
- Systemd service is optional

---

**Need more help?** Open an issue or discussion on GitHub!
