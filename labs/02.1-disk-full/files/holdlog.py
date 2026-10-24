#!/usr/bin/python3
"""Append to a log file until the disk is full, then keep it open (Lab 2.1)."""

import os
import sys
import time

path = sys.argv[1]
log = open(path, "ab", buffering=0)
chunk = b"x" * (1024 * 1024)
written = 0
try:
    while True:
        log.write(chunk)
        written += 1
except OSError as e:
    print(f"stopped after {written} MB: {e}", flush=True)
print(f"pid={os.getpid()} is holding {path} open; Ctrl-C to exit", flush=True)
while True:
    time.sleep(3600)
