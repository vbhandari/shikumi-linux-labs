#!/usr/bin/python3
"""shikumi-api: a small HTTP service for the Shikumi Labs Linux course.

Python standard library only. One request per connection, JSON responses.
"""

import argparse
import asyncio
import json
import os
import signal
import socket
import time
import zlib
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

HELD_FILES = []    # /files keeps these open on purpose (fd leak lab)
HELD_MEMORY = []   # /alloc keeps these allocated on purpose (memory labs)


def env(name, default):
    return os.environ.get(name, default)


def parse_args(argv=None):
    p = argparse.ArgumentParser(prog="shikumi-api")
    p.add_argument("--host", default=env("SHIKUMI_HOST", "127.0.0.1"))
    p.add_argument("--port", type=int, default=int(env("SHIKUMI_PORT", "8000")))
    p.add_argument("--backlog", type=int, default=128)
    p.add_argument("--reuseport", action="store_true")
    p.add_argument("--data-dir", default=env("SHIKUMI_DATA_DIR",
                   env("STATE_DIRECTORY", "/var/lib/shikumi")))
    p.add_argument("--cache-dir", default=env("SHIKUMI_CACHE_DIR",
                   env("CACHE_DIRECTORY", "/var/cache/shikumi")))
    p.add_argument("--cache", action="store_true",
                   default=env("SHIKUMI_CACHE", "") == "1")
    return p.parse_args(argv)


def slow_checksum(data):
    """Deliberately slow: the hot function in Lab 14.3."""
    a, b = 1, 0
    for byte in data:
        a = (a + byte) % 65521
        b = (b + a) % 65521
    return (b << 16) | a


def fast_checksum(data):
    return zlib.adler32(data)


class App:
    def __init__(self, args):
        self.args = args
        self.data_dir = Path(args.data_dir)
        self.cache_dir = Path(args.cache_dir)
        self.in_flight = 0
        self.started = time.time()

    async def route(self, path, query):
        q = {k: v[0] for k, v in parse_qs(query).items()}
        if path == "/healthz":
            return 200, {"status": "ok", "uptime_s": round(time.time() - self.started, 1)}
        if path == "/slow":
            await asyncio.sleep(int(q.get("ms", "1000")) / 1000)
            return 200, {"slept_ms": int(q.get("ms", "1000"))}
        if path == "/cpu":
            end = time.perf_counter() + int(q.get("ms", "100")) / 1000
            n = 0
            while time.perf_counter() < end:
                n += 1
            return 200, {"loops": n}
        if path == "/checksum":
            data = os.urandom(int(q.get("kb", "256")) * 1024)
            fn = fast_checksum if env("SHIKUMI_FAST_CHECKSUM", "") == "1" else slow_checksum
            return 200, {"checksum": fn(data)}
        if path == "/alloc":
            mb = int(q.get("mb", "10"))
            HELD_MEMORY.append(bytearray(mb * 1024 * 1024))
            return 200, {"held_mb": sum(len(b) for b in HELD_MEMORY) // (1024 * 1024)}
        if path == "/files":
            for _ in range(int(q.get("n", "10"))):
                HELD_FILES.append(open(os.devnull, "rb"))
            return 200, {"held_files": len(HELD_FILES)}
        if path == "/data":
            return self.read_data(q.get("name", "hello.txt"))
        return 404, {"error": "not found"}

    def read_data(self, name):
        target = (self.data_dir / name).resolve()
        if self.data_dir.resolve() not in target.parents:
            return 400, {"error": "name must stay inside the data directory"}
        try:
            body = target.read_text()
        except OSError as e:
            return 500, {"error": f"{type(e).__name__}: {e.strerror}", "path": str(target)}
        if self.args.cache:
            self.cache_dir.mkdir(parents=True, exist_ok=True)
            (self.cache_dir / f"{target.name}.cache").write_text(body)
        return 200, {"name": name, "content": body}

    async def handle(self, reader, writer):
        self.in_flight += 1
        status, payload = 400, {"error": "bad request"}
        try:
            line = await asyncio.wait_for(reader.readline(), timeout=10)
            while (await reader.readline()) not in (b"\r\n", b"\n", b""):
                pass
            parts = line.decode("latin-1").split()
            if len(parts) == 3 and parts[0] == "GET":
                url = urlsplit(parts[1])
                try:
                    status, payload = await self.route(url.path, url.query)
                except ValueError as e:
                    status, payload = 400, {"error": f"ValueError: {e}"}
                except (OSError, MemoryError) as e:
                    status, payload = 500, {"error": f"{type(e).__name__}: {e}"}
                print(f'{parts[0]} {parts[1]} {status}', flush=True)
            payload["pid"] = os.getpid()
            body = (json.dumps(payload) + "\n").encode()
            writer.write(
                f"HTTP/1.1 {status} {'OK' if status == 200 else 'Error'}\r\n"
                f"Content-Type: application/json\r\nContent-Length: {len(body)}\r\n"
                "Connection: close\r\n\r\n".encode() + body)
            await writer.drain()
        except (asyncio.TimeoutError, ConnectionError):
            pass
        finally:
            writer.close()
            self.in_flight -= 1


def make_socket(args):
    family = socket.AF_INET6 if ":" in args.host else socket.AF_INET
    sock = socket.socket(family, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    if args.reuseport:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
    sock.bind((args.host, args.port))
    sock.listen(args.backlog)
    sock.setblocking(False)
    return sock


async def serve(args, ready=None):
    app = App(args)
    server = await asyncio.start_server(app.handle, sock=make_socket(args))
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop.set)
    print(f"shikumi-api pid={os.getpid()} listening on {args.host}:{args.port}", flush=True)
    if ready:
        ready(server)
    await stop.wait()
    # Graceful shutdown: stop accepting, let in-flight requests finish (max 10 s).
    server.close()
    deadline = time.monotonic() + 10
    while app.in_flight and time.monotonic() < deadline:
        await asyncio.sleep(0.05)
    print(f"shikumi-api stopped, {app.in_flight} request(s) cut off", flush=True)


def main(argv=None):
    asyncio.run(serve(parse_args(argv)))


if __name__ == "__main__":
    main()
