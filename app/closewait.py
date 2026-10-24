#!/usr/bin/python3
"""A buggy server: it answers, but never closes accepted sockets (Lab 10.1)."""

import socket
import sys

FIXED = "--fixed" in sys.argv
held = []

srv = socket.create_server(("127.0.0.1", 8200))
print("closewait listening on 127.0.0.1:8200", "(fixed)" if FIXED else "(buggy)", flush=True)
while True:
    conn, _ = srv.accept()
    conn.recv(1024)
    conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nok\n")
    if FIXED:
        conn.close()
    else:
        held.append(conn)   # bug: the client closes, we never do
