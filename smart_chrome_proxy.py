#!/usr/bin/env python3
import socket
import threading
import time
import subprocess
import os
import signal
import sys

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

def is_port_open(host, port):
    """Check if a TCP port is open."""
    try:
        with socket.create_connection((host, port), timeout=0.5):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def ensure_chrome_running():
    """Checks if Chrome is running on the target port, starts it if not."""
    # First quick check without lock
    if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
        return True
    
    # Acquire lock to ensure only one thread starts Chrome
    with startup_lock:
        # Double-check inside lock
        if is_port_open('127.0.0.1', OBVIOUS_CHROME_PORT):
            return True
        
        print(f"[*] Chrome not running on port {OBVIOUS_CHROME_PORT}. Launching...")
        
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
                    print(f"[+] Chrome successfully started on port {OBVIOUS_CHROME_PORT}")
                    return True
                time.sleep(CHECK_INTERVAL)
                
            print("[-] Timeout waiting for Chrome to start.")
            return False
        except Exception as e:
            print(f"[-] Error launching Chrome: {e}")
            return False

def handle_client(client_socket):
    """Proxies data between the client and the actual Chrome instance."""
    try:
        # Ensure Chrome is up before connecting
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
                    if len(data) == 0:
                        break
                    destination.send(data)
            except:
                pass
            finally:
                source.close()
                destination.close()

        # Create bidirectional forwarding
        threading.Thread(target=forward, args=(client_socket, server_socket), daemon=True).start()
        threading.Thread(target=forward, args=(server_socket, client_socket), daemon=True).start()

    except Exception as e:
        print(f"[-] Proxy connection error: {e}")
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

    try:
        while True:
            client_sock, addr = server.accept()
            # Handle each connection in a separate thread to allow concurrency
            # and non-blocking Chrome startup
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
    except KeyboardInterrupt:
        print("\n[*] Stopping proxy...")
    finally:
        server.close()

if __name__ == "__main__":
    main()
