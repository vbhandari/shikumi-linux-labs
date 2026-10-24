#!/usr/bin/python3
"""Map a file and touch it page by page, so RSS grows while VSZ stays flat (Lab 8.1)."""

import argparse
import mmap
import os
import time


def status(field):
    with open("/proc/self/status") as f:
        for line in f:
            if line.startswith(field + ":"):
                return line.split(":", 1)[1].strip()
    return "?"


p = argparse.ArgumentParser()
p.add_argument("path")
p.add_argument("--mb", type=int, default=500)
p.add_argument("--step-mb", type=int, default=50)
p.add_argument("--batch", action="store_true", help="no prompts and no pauses")
args = p.parse_args()


def pause(prompt):
    if not args.batch:
        input(prompt)


size = args.mb * 1024 * 1024
with open(args.path, "a+b") as f:
    f.truncate(size)
    m = mmap.mmap(f.fileno(), size)
print(f"pid={os.getpid()} mapped {args.mb} MB; watch: grep -E 'VmSize|VmRSS' /proc/{os.getpid()}/status", flush=True)
print(f"before: VmSize={status('VmSize')} VmRSS={status('VmRSS')}", flush=True)
pause("press Enter to start touching pages ")
step = args.step_mb * 1024 * 1024
for offset in range(0, size, mmap.PAGESIZE):
    m[offset]  # read one byte per page
    if offset and offset % step == 0:
        print(f"touched {offset // (1024 * 1024)} MB", flush=True)
        if not args.batch:
            time.sleep(1)
print(f"after:  VmSize={status('VmSize')} VmRSS={status('VmRSS')}", flush=True)
pause("all pages touched; press Enter to exit ")
