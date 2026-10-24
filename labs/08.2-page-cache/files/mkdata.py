#!/usr/bin/python3
"""Write a file of the given size (Lab 8.2). Usage: mkdata.py PATH --mb N"""

import argparse
import os

p = argparse.ArgumentParser()
p.add_argument("path")
p.add_argument("--mb", type=int, default=300)
args = p.parse_args()
block = os.urandom(1024 * 1024)
with open(args.path, "wb") as f:
    for _ in range(args.mb):
        f.write(block)
    f.flush()
    os.fsync(f.fileno())
print(f"wrote {args.mb} MB to {args.path}")
