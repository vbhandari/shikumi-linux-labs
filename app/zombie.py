#!/usr/bin/python3
"""Create a zombie child, then reap it when you press Enter (Lab 3.2)."""

import os
import time

pid = os.fork()
if pid == 0:
    os._exit(7)          # child exits immediately
time.sleep(0.2)
print(f"parent={os.getpid()} child={pid}; try: ps -o pid,stat,cmd -p {pid}", flush=True)
input("child is a zombie (state Z); press Enter to reap it ")
_, status = os.waitpid(pid, 0)
print(f"reaped child {pid}, exit code {os.waitstatus_to_exitcode(status)}")
