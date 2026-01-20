import socket
import threading
import time
import subprocess
import os
import signal
import sys
import re

# Configuration
LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 9222
OBVIOUS_CHROME_PORT = 9223  # Internal port where Chrome will actually run

# Dynamically find the startup script in the same directory
CHROME_START_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'start_chrome_for_antigravity.sh')

CHECK_INTERVAL = 0.5  # Seconds to wait between health checks
TIMEOUT = 10  # Seconds to wait for Chrome to start

# Global lock to prevent race conditions during Chrome startup
startup_lock = threading.Lock()

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}")

def is_port_open(host, port):
    """Check if a TCP port is open."""
    try:
        # Increased timeout to prevent false negatives on slow systems
        with socket.create_connection((host, port), timeout=0.5):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def check_process_running():
    """Checks if the Chrome process is actually running using pgrep."""
    try:
        # Check for any chrome process with our specific port flag
        # This is more robust than just checking the socket
        cmd = f"pgrep -f 'chrome.*{OBVIOUS_CHROME_PORT}'"
        result = subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL)
        return result.returncode == 0
    except Exception:
        return False

def ensure_chrome_running():
    """Checks if Chrome is running, starts it if not."""
    # 1. Fast check: Is port open?
    if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
        # log("Port 9223 open on fast check.") # Too spammy
        return True

    # 2. Acquire lock to prevent race conditions
    with startup_lock:
        # 3. Double-check port inside lock
        if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
            log("Port 9223 open inside lock.")
            return True
        
        # 4. Check if process exists but port is closed (Zombie/Slow Start)
        if check_process_running():
            log(f"Process found but port {OBVIOUS_CHROME_PORT} closed. Waiting...")
            # Wait a bit for it to open the port
            start_time = time.time()
            while time.time() - start_time < 5: # Wait up to 5s for existing process
                if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
                    log("Chrome successfully connected after wait.")
                    return True
                time.sleep(CHECK_INTERVAL)
            
            # If still closed, assume it's stuck and kill it
            log("Existing process stuck (port never opened). Killing...")
            subprocess.run(f"pkill -f 'chrome.*{OBVIOUS_CHROME_PORT}'", shell=True)
            time.sleep(1)

        log(f"Launching Chrome on port {OBVIOUS_CHROME_PORT}...")
        
        # Set environment variable for the script
        env = os.environ.copy()
        env['CHROME_PORT'] = str(OBVIOUS_CHROME_PORT)
        
        try:
            # Launch Chrome using the helper script
            subprocess.Popen(
                ['bash', CHROME_START_SCRIPT],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=os.setpgrp # Detach from parent
            )
            
            # Wait for it to become available
            start_time = time.time()
            while time.time() - start_time < TIMEOUT:
                if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
                    log("Chrome successfully started.")
                    return True
                time.sleep(CHECK_INTERVAL)
            
            log("Timeout waiting for Chrome to start.")
            return False
        except Exception as e:
            log(f"Error launching Chrome: {e}")
            return False

def determine_project_name(client_port):
    """
    Attempts to find the project name based on the client process connecting to the proxy.
    Strategy:
    1. Find PID using 'ss'.
    2. Inspect /proc/<PID>/cmdline for '--workspace_id'.
       Format example: ...--workspace_id, file_home_creator_wsl_chrome_bridge...
    3. Parse the ID to extract the project name.
    4. Fallback: CWD (used for manual verifying like curl).
    """
    try:
        # Find PID using ss. 
        cmd = f"ss -H -t -p src 127.0.0.1 sport = {client_port}"
        result = subprocess.check_output(cmd, shell=True).decode('utf-8')
        
        match = re.search(r'pid=(\d+)', result)
        if match:
            pid = match.group(1)
            
            # METHOD 1: CMDLINE parsing (Best for Agent)
            try:
                with open(f"/proc/{pid}/cmdline", "rb") as f:
                    cmdline_bytes = f.read()
                    # Convert nulls to spaces for easier regex
                    cmdline = cmdline_bytes.replace(b'\x00', b' ').decode('utf-8', errors='ignore')
                    
                    # Look for --workspace_id
                    # Matches "--workspace_id value"
                    ws_match = re.search(r'--workspace_id\s+([^\s]+)', cmdline)
                    if ws_match:
                        raw_id = ws_match.group(1)
                        # raw_id example: "file_home_creator_wsl_chrome_bridge"
                        
                        # Cleanup strategy:
                        # 1. Remove "file_" prefix
                        clean_name = raw_id.replace('file_', '')
                        
                        # 2. Try to remove home directory prefix if present
                        # "home_creator_"
                        user_prefix = f"home_{os.environ.get('USER', 'creator')}_"
                        if clean_name.startswith(user_prefix):
                            clean_name = clean_name[len(user_prefix):]
                        
                        # 3. Use what's left. Often it will be "wsl_chrome_bridge".
                        # Optionally replace underscores with dashes if it looks like a sanitized path
                        # But honestly, "wsl_chrome_bridge" is readable enough.
                        
                        if clean_name:
                            log(f"Detected project '{clean_name}' from PID {pid} (Workspace ID)")
                            with open("/tmp/ag_project_name", "w") as f:
                                f.write(clean_name)
                            return clean_name
            except Exception as e:
                log(f"Error parsing cmdline: {e}")

            # METHOD 2: CWD parsing (Fallback for manual testing)
            try:
                cwd = os.readlink(f"/proc/{pid}/cwd")
                project_name = os.path.basename(cwd)
                # Filter out generic Antigravity installation dirs
                if project_name and "Antigravity" not in project_name and "bin" not in project_name:
                    log(f"Detected project '{project_name}' from PID {pid} (CWD: {cwd})")
                    with open("/tmp/ag_project_name", "w") as f:
                        f.write(project_name)
                    return project_name
            except: pass
            
    except Exception as e:
        log(f"Could not determine project name: {e}")
    return None

def handle_client(client_socket):
    """Proxies data, but filters 'polite' requests to avoid waking Chrome unnecessarily."""
    try:
        # 0. Identify Client for Project Naming
        try:
            _, client_port = client_socket.getpeername()
            # Run in thread to not block handling
            threading.Thread(target=determine_project_name, args=(client_port,), daemon=True).start()
        except:
            pass

        # 1. Peek at the first bytes of the request to see what it is
        try:
            first_bytes = client_socket.recv(4096, socket.MSG_PEEK)
        except Exception:
            client_socket.close()
            return
            
        request_preview = first_bytes.decode('utf-8', errors='ignore')
        
        # 2. Check if it's a metadata query
        # We ONLY filter /json/list because that's what triggers the "Zombie" behavior (polling).
        # We MUST allow /json/version because that's how the Agent connects (gets WS URL).
        is_metadata_query = (
            "GET /json/list" in request_preview
        )
        
        # 3. Check if Chrome is already running
        chrome_alive = is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT)

        # 4. DECISION LOGIC:
        # If Chrome is DEAD and this is just a Metadata Query -> LIE (Mock response).
        if not chrome_alive and is_metadata_query:
            # Send fake response to keep the client happy without launching the browser
            response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n[]"
            client_socket.sendall(response.encode('utf-8'))
            client_socket.close()
            return

        # 5. If we are here, it's either:
        #    - Chrome is ALREADY running (so we proxy)
        #    - It's a REAL request (not just json/list), so we MUST launch
        
        # Ensure Chrome is up
        if not ensure_chrome_running():
            client_socket.close()
            return

        # Connect to the actual Chrome instance
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect(('127.0.0.1', OBVIOUS_CHROME_PORT))

        def forward(source, destination):
            try:
                while True:
                    data = source.recv(4096)
                    if not data: break
                    destination.send(data)
            except: pass
            finally:
                source.close()
                destination.close()

        # Start bidirectional forwarding
        threading.Thread(target=forward, args=(client_socket, server_socket), daemon=True).start()
        threading.Thread(target=forward, args=(server_socket, client_socket), daemon=True).start()

    except Exception as e:
        print(f"[-] Proxy error: {e}")
        client_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
    except Exception as e:
        print(f"[-] Failed to bind to {LISTEN_HOST}:{LISTEN_PORT}: {e}")
        sys.exit(1)
        
    server.listen(5)
    print(f"[*] Smart Chrome Proxy listening on {LISTEN_HOST}:{LISTEN_PORT}")
    print(f"[*] Target Chrome Port: {OBVIOUS_CHROME_PORT}")
    print(f"[*] Filtering enabled: Metadata queries won't wake Chrome")

    try:
        while True:
            client_sock, addr = server.accept()
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
    except KeyboardInterrupt:
        print("\n[*] Stopping proxy...")
    finally:
        server.close()

if __name__ == "__main__":
    main()
