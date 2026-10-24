#!/usr/bin/python3
"""Write a reproducible sample access log to access.log (Lab 1.2)."""

import random
from datetime import datetime, timedelta, timezone

rng = random.Random(2026)
ips = [f"10.0.{rng.randint(0, 3)}.{rng.randint(2, 254)}" for _ in range(40)]
paths = ["/healthz"] * 6 + ["/data?name=hello.txt"] * 4 + ["/slow?ms=200", "/checksum?kb=64", "/files?n=5", "/missing"]
t = datetime(2026, 10, 23, 9, 0, tzinfo=timezone.utc)
with open("access.log", "w") as log:
    for _ in range(2000):
        t += timedelta(seconds=rng.randint(0, 3))
        path = rng.choice(paths)
        status = 404 if path == "/missing" else rng.choices([200, 500, 503], [96, 3, 1])[0]
        rt = rng.uniform(0.2, 0.25) if path.startswith("/slow") else rng.uniform(0.001, 0.05)
        ip = rng.choice(ips[:5]) if rng.random() < 0.3 else rng.choice(ips)
        log.write(f'{ip} - - [{t:%d/%b/%Y:%H:%M:%S %z}] "GET {path} HTTP/1.1" {status} {rng.randint(40, 900)} {rt:.3f}\n')
print("wrote access.log")
