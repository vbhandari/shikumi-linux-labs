# Appendix C: C examples

Optional reading for the handout's Appendix C. These are not labs, and nothing in `labs/` depends on them.

| File | Handout | Shows |
|---|---|---|
| [`epoll_echo.c`](epoll_echo.c) | C1, from E07.2 | The readiness loop asyncio runs for you: `epoll_wait`, non-blocking `accept4`, `read`, `write` |
| [`deadlock.c`](deadlock.c) | C2, from Lab 14.2 | The lock-order inversion from `deadlock.py`, debugged with `gdb` |

Paste one block at a time. First build both and try the epoll server (from `~/shikumi-linux-labs/appendix-c`):

```bash
sudo apt install -y build-essential gdb
make
./epoll_echo &
sudo true           # strace needs sudo to attach on Ubuntu
sudo strace -f -e trace=epoll_wait,accept4,read,write \
  -p $! &           # attach before the test connection
sleep 1
printf 'hello\n' | nc -q1 127.0.0.1 9000
sudo pkill -x strace; kill %1
```

`build-essential` brings `gcc`, `make` and the C library headers (`libc6-dev`). `gcc` alone may leave the headers out, and then `make` stops at `arpa/inet.h: No such file or directory`.

Then run the deadlock. Both threads start at once, so it usually hangs straight away and prints `transfers=0` every second (`deadlock.py` in Lab 14.2 counts for about two seconds first):

```bash
./deadlock
```

In a second terminal, while it hangs:

```bash
sudo gdb -p "$(pgrep -x deadlock)" -batch \
  -ex 'thread apply all bt'
```

Back in the first terminal, press Ctrl-C to stop `./deadlock`, then:

```bash
make clean
```

`gdb -p` attaches with ptrace, which Ubuntu limits to your own child processes (`kernel.yama.ptrace_scope = 1`), so it needs `sudo`. One thread waits in `pthread_mutex_lock` called from `transfer`, the other from `report`. Without the C library's debug symbols, the frames below `pthread_mutex_lock` show as `??`.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
