#!/usr/bin/python3
"""Write data and report how long it took, with or without fsync (Lab 8.2)."""

import argparse
import os
import time

p = argparse.ArgumentParser()
p.add_argument("path")
p.add_argument("--mb", type=int, default=200)
p.add_argument("--fsync", action="store_true")
args = p.parse_args()
block = b"\0" * (1024 * 1024)
start = time.perf_counter()
with open(args.path, "wb") as f:
    for _ in range(args.mb):
        f.write(block)
    written = time.perf_counter()
    if args.fsync:
        os.fsync(f.fileno())
done = time.perf_counter()
print(f"write {written - start:.2f}s, fsync {done - written:.2f}s, total {done - start:.2f}s")
