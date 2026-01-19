import socket
import threading
import sys

"""
WSL-Chrome-Bridge: Windows Proxy
This script listens on all interfaces (0.0.0.0:9223) and forwards
traffic to the local Chrome instance (127.0.0.1:9222).
"""

def pipe(source, dest):
    try:
        source.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        dest.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        while True:
            data = source.recv(65536)
            if not data:
                break
            dest.sendall(data)
    except:
        pass
    finally:
        try: source.close()
        except: pass
        try: dest.close()
        except: pass

def handle_client(client_socket):
    remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        remote.connect(('127.0.0.1', 9222))
        t1 = threading.Thread(target=pipe, args=(client_socket, remote))
        t2 = threading.Thread(target=pipe, args=(remote, client_socket))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
    except Exception as e:
        client_socket.close()

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('0.0.0.0', 9223))
        server.listen(10)
        print("WSL-Chrome-Bridge Proxy: Listening on 9223 -> 9222")
        while True:
            client, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(client,))
            t.daemon = True
            t.start()
    except Exception as e:
        print(f"Server error: {e}")
    finally:
        server.close()

if __name__ == '__main__':
    main()
