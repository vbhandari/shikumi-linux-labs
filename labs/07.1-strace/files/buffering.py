#!/usr/bin/python3
"""Print a line a second. Compare: python3 buffering.py | cat  and  python3 -u buffering.py | cat"""

import time

for i in range(5):
    print(f"tick {i}")
    time.sleep(1)
