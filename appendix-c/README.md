# Appendix C: C examples

Optional reading for the handout's Appendix C. These are not labs, and nothing in `labs/` depends on them.

| File | Handout | Shows |
|---|---|---|
| [`epoll_echo.c`](epoll_echo.c) | C1, from E07.2 | The readiness loop asyncio runs for you: `epoll_wait`, non-blocking `accept4`, `read`, `write` |
| [`deadlock.c`](deadlock.c) | C2, from Lab 14.2 | The lock-order inversion from `deadlock.py`, debugged with `gdb` |

```bash
sudo apt install -y gcc make gdb
make
./epoll_echo &
sudo -v             # strace needs sudo to attach on Ubuntu
sudo strace -f -e trace=epoll_wait,accept4,read,write \
  -p $! &           # attach before the test connection
sleep 1
printf 'hello\n' | nc -q1 127.0.0.1 9000
sudo pkill -x strace; kill %1
./deadlock
# wait until transfers= stops growing, then in a second
# terminal:
sudo gdb -p "$(pgrep -x deadlock)" -batch \
  -ex 'thread apply all bt'
make clean
```

`gdb -p` attaches with ptrace, which Ubuntu limits to your own child processes (`kernel.yama.ptrace_scope = 1`), so it needs `sudo`.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
