#!/usr/bin/python3
"""Allocate and touch memory in steps until stopped or killed (Lab 8.3)."""

import argparse
import time

p = argparse.ArgumentParser()
p.add_argument("--step-mb", type=int, default=10)
p.add_argument("--max-mb", type=int, default=4096)
p.add_argument("--delay", type=float, default=0.2)
args = p.parse_args()

held = []
while len(held) * args.step_mb < args.max_mb:
    held.append(bytearray(args.step_mb * 1024 * 1024))  # zero-filled, so touched
    print(f"allocated {len(held) * args.step_mb} MB", flush=True)
    time.sleep(args.delay)
print("reached --max-mb; holding", flush=True)
time.sleep(3600)
