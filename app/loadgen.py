#!/usr/bin/python3
"""Concurrent HTTP GET load generator with timeouts, retries and latency percentiles."""

import argparse
import asyncio
import collections
import time
from urllib.parse import urlsplit


async def get(url, timeout):
    u = urlsplit(url)
    path = (u.path or "/") + (f"?{u.query}" if u.query else "")
    reader, writer = await asyncio.wait_for(
        asyncio.open_connection(u.hostname, u.port or 80), timeout)
    try:
        writer.write(f"GET {path} HTTP/1.1\r\nHost: {u.hostname}\r\n"
                     "Connection: close\r\n\r\n".encode())
        await writer.drain()
        data = await asyncio.wait_for(reader.read(), timeout)
    finally:
        writer.close()
    status = int(data.split(b" ", 2)[1]) if data.startswith(b"HTTP/") else 0
    body = data.split(b"\r\n\r\n", 1)[-1]
    return status, body


async def worker(url, count, timeout, retries, stats):
    for _ in range(count):
        for attempt in range(retries + 1):
            start = time.perf_counter()
            try:
                status, body = await get(url, timeout)
                stats["latency"].append(time.perf_counter() - start)
                stats["status"][status] += 1
                pid = body.split(b'"pid": ', 1)[-1].split(b"}")[0].strip()
                stats["pid"][pid.decode() or "-"] += 1
                break
            except (OSError, asyncio.TimeoutError) as e:
                stats["errors"][type(e).__name__] += 1
                if attempt < retries:
                    stats["retries"] += 1


def percentile(values, p):
    values = sorted(values)
    return values[min(len(values) - 1, int(len(values) * p / 100))] if values else 0.0


async def run(args):
    stats = {"latency": [], "status": collections.Counter(), "pid": collections.Counter(),
             "errors": collections.Counter(), "retries": 0}
    per_worker = max(1, args.n // args.c)
    start = time.perf_counter()
    await asyncio.gather(*(worker(args.url, per_worker, args.timeout, args.retries, stats)
                           for _ in range(args.c)))
    elapsed = time.perf_counter() - start
    lat = stats["latency"]
    print(f"requests={len(lat)} elapsed={elapsed:.2f}s rps={len(lat) / elapsed:.0f}")
    print("latency_ms " + " ".join(f"p{p}={percentile(lat, p) * 1000:.1f}" for p in (50, 90, 99)))
    print(f"status={dict(stats['status'])} errors={dict(stats['errors'])} retries={stats['retries']}")
    if args.by_pid:
        print(f"by_pid={dict(stats['pid'])}")


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("url")
    p.add_argument("-c", type=int, default=10, help="concurrent connections")
    p.add_argument("-n", type=int, default=200, help="total requests")
    p.add_argument("--timeout", type=float, default=5.0)
    p.add_argument("--retries", type=int, default=0)
    p.add_argument("--by-pid", action="store_true", help="count responses per server PID")
    asyncio.run(run(p.parse_args(argv)))


if __name__ == "__main__":
    main()
