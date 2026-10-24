#!/usr/bin/python3
"""Rebind a port that has a connection in TIME_WAIT, with and without SO_REUSEADDR (Lab 10.3)."""

import socket

PORT = 8410


def listener(reuse):
    s = socket.socket()
    if reuse:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", PORT))
    return s


# One short connection where the server closes first, leaving TIME_WAIT on the server's port.
srv = listener(reuse=True)
srv.listen()
client = socket.create_connection(("127.0.0.1", PORT))
conn, _ = srv.accept()
conn.close()
client.close()
srv.close()

for reuse in (False, True):
    try:
        listener(reuse).close()
        print(f"SO_REUSEADDR={int(reuse)}: bind ok")
    except OSError as e:
        print(f"SO_REUSEADDR={int(reuse)}: {e}")
