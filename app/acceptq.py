#!/usr/bin/python3
"""Listen with a small backlog and never call accept() (Lab 10.2)."""

import argparse
import socket
import time

p = argparse.ArgumentParser()
p.add_argument("--backlog", type=int, default=8)
p.add_argument("--port", type=int, default=8300)
args = p.parse_args()

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", args.port))
srv.listen(args.backlog)
print(f"acceptq listening on 127.0.0.1:{args.port} backlog={args.backlog}, never accepting", flush=True)
while True:
    time.sleep(3600)
