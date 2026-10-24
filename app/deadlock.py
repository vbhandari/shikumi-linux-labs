#!/usr/bin/python3
"""Two threads take two locks in opposite order and hang (Lab 14.2).

Send SIGUSR1 to dump every thread's Python stack to stderr.
"""

import faulthandler
import os
import signal
import sys
import threading
import time

faulthandler.register(signal.SIGUSR1, all_threads=True)
FIXED = "--fixed" in sys.argv

accounts = threading.Lock()
audit_log = threading.Lock()
done = [0]


def transfer():
    while True:
        with accounts:
            time.sleep(0.001)
            with audit_log:
                done[0] += 1


def report():
    first, second = ((accounts, audit_log) if FIXED
                     else (audit_log, accounts))
    while True:
        time.sleep(2)  # report every 2 seconds
        with first:
            time.sleep(0.001)
            with second:
                pass


print(f"deadlock.py pid={os.getpid()} {'(fixed)' if FIXED else ''}", flush=True)
for target in (transfer, report):
    threading.Thread(target=target, name=target.__name__, daemon=True).start()
while True:
    time.sleep(1)
    print(f"transfers={done[0]}", flush=True)  # stops growing once hung
