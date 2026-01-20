#!/usr/bin/env python3
import socket
import threading
import time
import subprocess
import os
import signal
import sys
import re
import json

# Configuration
LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 9222
START_PORT_RANGE = 9300
CHROME_START_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'start_chrome_for_antigravity.sh')
REGISTRY_FILE = "/tmp/ag_chrome_registry.json"

# Global lock for registry operations
registry_lock = threading.Lock()

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}")

# ... existing imports ...
import signal
import sys
import re
import json

# Configuration settings
LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 9222
START_PORT_RANGE = 9300
CHROME_START_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'start_chrome_for_antigravity.sh')
REGISTRY_FILE = "/tmp/ag_chrome_registry.json"

# ... Lock and logging ...

class ChromeRegistry:
    def __init__(self):
        self.projects = {} # { "project_name": { "port": 9300, "pid": 123 } }
        self.load()

    def load(self):
        if os.path.exists(REGISTRY_FILE):
            try:
                with open(REGISTRY_FILE, 'r') as f:
                    self.projects = json.load(f)
            except:
                self.projects = {}

    def save(self):
        try:
            with open(REGISTRY_FILE, 'w') as f:
                json.dump(self.projects, f, indent=2)
        except Exception as e:
            log(f"Error saving registry: {e}")

    def get_project(self, name):
        return self.projects.get(name)

    def register_project(self, name, port, pid):
        self.projects[name] = {"port": port, "pid": pid}
        self.save()

    def find_free_port(self):
        used_ports = {p['port'] for p in self.projects.values()}
        port = START_PORT_RANGE
        while (port in used_ports) or self.is_port_open('127.0.0.1', port):
            port += 1
        return port

    @staticmethod
    def is_port_open(host, port):
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return True
        except:
            return False

class Watchdog:
    """Monitors system health, cleans up dead processes."""
    def __init__(self):
        self.stop_event = threading.Event()
        
    def start(self):
        threading.Thread(target=self._pinger_loop, daemon=True).start()
        
    def _pinger_loop(self):
        log("🛡️  System Watchdog started.")
        while not self.stop_event.is_set():
            try:
                self._cleanup_dead_processes()
            except Exception as e:
                log(f"Watchdog error: {e}")
            time.sleep(5) 
            
    def _cleanup_dead_processes(self):
        """Checks if registered projects are actually running."""
        with registry_lock:
            registry = ChromeRegistry()
            # Iterate copy to modify original
            dirty = False
            for name, info in list(registry.projects.items()):
                pid = info.get("pid")
                port = info.get("port")
                
                # Check 1: Is process ID exists?
                pid_alive = False
                if pid and pid != 0:
                    try:
                        # sending signal 0 checks existence
                        os.kill(int(pid), 0) 
                        pid_alive = True
                    except OSError:
                        pid_alive = False
                
                # Check 2: Is port listening?
                port_open = ChromeRegistry.is_port_open('127.0.0.1', port)
                
                if not pid_alive and not port_open:
                    log(f"🧹 Cleanup: Removing dead project '{name}' (PID {pid}, Port {port})")
                    del registry.projects[name]
                    dirty = True
                elif port_open and not pid_alive:
                    # Zombie port? chrome might be running but PID changed?
                    # Or we have wrong PID.
                    # Try to find real PID from port
                    try:
                        cmd = f"fuser -n tcp {port} 2>/dev/null"
                        new_pid = subprocess.check_output(cmd, shell=True, timeout=1).decode('utf-8').strip()
                        if new_pid and new_pid != str(pid):
                            log(f"🩹 Healing: Updated PID for '{name}' from {pid} to {new_pid}")
                            registry.projects[name]['pid'] = new_pid
                            dirty = True
                    except: pass

            if dirty:
                registry.save()

# ... determine_project_name ...

# ... ensure_chrome_for_project (Ensure we pass 'timeout' to subprocess where possible if blocking) ...

# ... handle_client ...

def maintain_window_titles():
    """Background thread to keep window titles correct."""
    if "DISPLAY" not in os.environ:
        os.environ["DISPLAY"] = ":0"
        
    while True:
        try:
            with registry_lock:
                registry = ChromeRegistry()
                current_projects = list(registry.projects.items())
            
            for name, info in current_projects:
                pid = info.get("pid")
                if not pid or pid == 0: continue
                
                try:
                    # Added Timeout=1s to prevent lags if window is unresponsive
                    wids_out = subprocess.check_output(
                        ["xdotool", "search", "--pid", str(pid)], 
                        stderr=subprocess.DEVNULL,
                        timeout=1
                    ).decode('utf-8').strip()
                    
                    if wids_out:
                        for wid in wids_out.split():
                            curr_title = subprocess.check_output(
                                ["xdotool", "getwindowname", wid],
                                stderr=subprocess.DEVNULL,
                                timeout=1
                            ).decode('utf-8').strip()
                            
                            if curr_title and curr_title != name:
                                subprocess.run(
                                    ["xdotool", "set_window", "--name", name, wid],
                                    stderr=subprocess.DEVNULL,
                                    timeout=1
                                )
                except subprocess.TimeoutExpired:
                    # Window is busy/closing, skip it to avoid lag
                    continue 
                except Exception:
                    pass
                    
        except Exception as e:
            log(f"Title maintainer error: {e}")
        
        time.sleep(2.0)

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
    except Exception as e:
        log(f"Failed to bind: {e}")
        sys.exit(1)
        
    server.listen(5)
    log(f"Smart Router listening on {LISTEN_PORT}...")

    # Start Watchdog
    Watchdog().start()

    # Start Window Title Maintainer
    threading.Thread(target=maintain_window_titles, daemon=True).start()

    try:
        while True:
            client_sock, addr = server.accept()
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
    except KeyboardInterrupt:
        log("Stopping...")
    finally:
        server.close()

if __name__ == "__main__":
    main()
