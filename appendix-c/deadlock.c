/* C2: two threads take two mutexes in opposite order (handout Appendix C2).
 * Debug the hang: sudo gdb -p $(pgrep deadlock) -batch -ex 'thread apply all bt'
 * Build with -g so the backtrace shows file and line. */
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static pthread_mutex_t accounts = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t audit_log = PTHREAD_MUTEX_INITIALIZER;
static volatile unsigned long transfers;

static void *transfer(void *arg) {
    (void)arg;
    for (;;) {
        pthread_mutex_lock(&accounts);
        usleep(1000);
        pthread_mutex_lock(&audit_log);
        transfers++;
        pthread_mutex_unlock(&audit_log);
        pthread_mutex_unlock(&accounts);
    }
    return NULL;
}

static void *report(void *arg) {
    (void)arg;
    for (;;) {
        pthread_mutex_lock(&audit_log);     /* bug: opposite order to transfer() */
        usleep(1000);
        pthread_mutex_lock(&accounts);
        pthread_mutex_unlock(&accounts);
        pthread_mutex_unlock(&audit_log);
    }
    return NULL;
}

int main(void) {
    pthread_t a, b;
    printf("deadlock pid=%d\n", getpid());
    pthread_create(&a, NULL, transfer, NULL);
    pthread_create(&b, NULL, report, NULL);
    for (;;) {
        sleep(1);
        /* Usually stays at transfers=0: both threads start
         * together and deadlock almost at once. */
        printf("transfers=%lu\n", transfers);
        fflush(stdout);
    }
}
