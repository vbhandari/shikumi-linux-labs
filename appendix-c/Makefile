CC ?= gcc
CFLAGS ?= -O1 -g -Wall -Wextra
LDFLAGS_THREADS = -pthread

all: epoll_echo deadlock

epoll_echo: epoll_echo.c
	$(CC) $(CFLAGS) -o $@ $<

deadlock: deadlock.c
	$(CC) $(CFLAGS) $(LDFLAGS_THREADS) -o $@ $<

clean:
	rm -f epoll_echo deadlock

.PHONY: all clean
