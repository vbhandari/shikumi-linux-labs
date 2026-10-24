/* C1: a minimal epoll echo server on 127.0.0.1:9000 (handout Appendix C1).
 * One thread, non-blocking sockets, level-triggered epoll.
 * Try: ./epoll_echo &  then  printf 'hello\n' | nc -q1 127.0.0.1 9000 */
#define _GNU_SOURCE
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 9000
#define MAX_EVENTS 64

static void die(const char *what) { perror(what); exit(1); }

int main(void) {
    int one = 1;
    int lfd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);
    if (lfd < 0) die("socket");
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);

    struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(PORT) };
    inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof addr) < 0) die("bind");
    if (listen(lfd, 128) < 0) die("listen");

    int ep = epoll_create1(EPOLL_CLOEXEC);
    if (ep < 0) die("epoll_create1");
    struct epoll_event ev = { .events = EPOLLIN, .data.fd = lfd };
    epoll_ctl(ep, EPOLL_CTL_ADD, lfd, &ev);
    printf("epoll_echo listening on 127.0.0.1:%d\n", PORT);
    fflush(stdout);

    struct epoll_event events[MAX_EVENTS];
    char buf[4096];
    for (;;) {
        int n = epoll_wait(ep, events, MAX_EVENTS, -1);
        for (int i = 0; i < n; i++) {
            int fd = events[i].data.fd;
            if (fd == lfd) {
                int cfd;
                while ((cfd = accept4(lfd, NULL, NULL, SOCK_NONBLOCK | SOCK_CLOEXEC)) >= 0) {
                    struct epoll_event cev = { .events = EPOLLIN, .data.fd = cfd };
                    epoll_ctl(ep, EPOLL_CTL_ADD, cfd, &cev);
                }
                continue;
            }
            ssize_t got = read(fd, buf, sizeof buf);
            if (got <= 0) {
                close(fd);          /* closing also removes it from the epoll set */
                continue;
            }
            write(fd, buf, (size_t)got);
        }
    }
}
