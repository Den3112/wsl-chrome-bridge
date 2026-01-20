# Smart Chrome Proxy (Socket Activation)

## Introduction
The **Smart Chrome Proxy** is a sophisticated solution designed to solve the "Chicken and Egg" problem of automating Chrome in WSL. It implements a **Socket Activation** pattern, acting as a middleware between your automation tools (Antigravity, Playwright, Puppeteer) and the Chrome browser.

## The Problem
In standard "headless" setups, you typically have to:
1.  Manually start Chrome with debugging ports open.
2.  Hope it doesn't crash.
3.  Manually restart it if you close the window.
4.  Deal with `ECONNREFUSED` errors if your script runs before Chrome is ready.

Previous solutions used a "Passive Watchdog" that monitored processes but couldn't handle incoming network requests, leading to failed connections if the browser wasn't already running.

## The Solution: Socket Activation
We replaced the passive monitor with an active Python-based proxy server (`smart_chrome_proxy.py`).

### interactions Flow
1.  **Idle State:** The Proxy listens on port `9222` (the standard Chrome DevTools Protocol port). Chrome is **NOT** running. RAM usage is minimal.
2.  **Connection Attempt:** An agent or script tries to connect to `localhost:9222`.
3.  **Interception:** The Proxy accepts the connection.
4.  **Activation:**
    *   Bin checks if Chrome is running on the internal port (`9223`).
    *   If NOT running: The Proxy launches Chrome (using `start_chrome_for_antigravity.sh`) and waits for it to initialize.
    *   **Race Condition Protection:** A `threading.Lock` ensures that even if 10 requests come in simultaneously, only **one** Chrome instance is launched.
5.  **Proxying:** Once Chrome is up on `9223`, the Proxy pipes traffic bidirectionally between the Client (9222) and Chrome (9223).

## Architecture

```mermaid
graph TD
    Client[Antigravity / Playwright] -->|Connects to :9222| Proxy[Smart Proxy (Python)]
    Proxy -->|Checks :9223| Chrome{Chrome Running?}
    Chrome -- No --> Launch[Launch Script]
    Launch -->|Starts| Browser[Chrome Instance :9223]
    Chrome -- Yes --> Browser
    Proxy <==>|Bi-directional Pipe| Browser
```

## Components

### 1. `smart_chrome_proxy.py`
The core logic. It uses standard Python libraries (`socket`, `threading`, `subprocess`) to ensure zero external dependencies.
*   **Location:** Root directory
*   **Port:** 9222 (Public) -> 9223 (Internal)

### 2. `start_chrome_for_antigravity.sh`
The launcher script. It isolates the complex flags required to run Chrome reliably in a Linux/WSL environment (GPU settings, Crashpad handlers, Sandbox disabling).
*   **Env Var:** `CHROME_PORT` (controlled by the proxy).

### 3. `chrome-ctl`
A management utility for users who prefer manual control.
*   `status`: Shows the state of both the Proxy and the underlying Chrome process.
*   `start`: Manually boots the proxy.
*   `stop`: Terminates both the proxy and any Chrome instances.

## Troubleshooting

### "Address already in use"
If the proxy fails to start, something else might be holding port 9222.
Run: `sudo netstat -tulpn | grep 9222` to find the culprit.

### Chrome starts but closes immediately
Check `/tmp/antigravity_chrome.log` for Chrome output. Common issues include missing specific libraries in WSL or invalid user data directory permissions.
