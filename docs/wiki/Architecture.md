# Architecture & Design

The core of Version 2.0 is the transition from a **Passive Watchdog** to an **Active Smart Proxy**.

## The "Chicken and Egg" Problem
Automation tools usually expect the browser to be "just there" on port 9222.
*   If you start Chrome manually -> It wastes RAM when idle.
*   If you don't -> The tool crashes with `Connection Refused`.
*   If you use a simple script -> It can't distinguish between a crash and a user closing the window.

## The Smart Proxy Solution
We implemented a Python-based middleware that sits on port 9222.

### 1. The Listener
The proxy opens a TCP socket on `0.0.0.0:9222`. This is where your tools connect. It consumes < 15MB RAM and practically 0% CPU.

### 2. The Lock (Mutex)
To prevent "Race Conditions" (where 5 browser tabs open at once because 5 requests came in simultaneously), we use a `threading.Lock`:

```python
with startup_lock:
    if not is_running():
        launch_chrome()
```

### 3. The Launcher
The proxy executes `start_chrome_for_antigravity.sh` with a custom environment variable `CHROME_PORT=9223`.
It then waits (polls) for port 9223 to become active.

### 4. The Pipe
Once Chrome is active, the proxy creates two threads for every connection:
1.  Client -> Proxy -> Chrome
2.  Chrome -> Proxy -> Client

This makes the proxy completely transparent. The client thinks it's talking directly to Chrome.
