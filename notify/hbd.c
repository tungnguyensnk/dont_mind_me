// hbd — heartbeat daemon. A wakeup timer that survives deep sleep.
//
// The notification fix must nudge Google Play Services to reconnect its FCM socket on a
// schedule, even while the phone is suspended overnight. A shell `sleep` loop can't: its
// timer (CLOCK_MONOTONIC) pauses during suspend, so no heartbeat fires until the device
// wakes on its own. This uses a CLOCK_BOOTTIME_ALARM timerfd, which keeps counting through
// suspend and WAKES the device when it fires (needs CAP_WAKE_ALARM — we run as root), then
// runs the given command (the shell `beat`: re-add GMS to the no-freeze list + reconnect).
//
// usage: hbd <seconds> <cmd> [args...]

#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/timerfd.h>
#include <sys/wait.h>

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: hbd <seconds> <cmd> [args...]\n"); return 2; }
    long sec = atol(argv[1]);
    if (sec < 30) sec = 600;

    // prefer the suspend-surviving, device-waking clock; degrade gracefully if unavailable
    int tfd = timerfd_create(CLOCK_BOOTTIME_ALARM, TFD_CLOEXEC);
    if (tfd < 0) tfd = timerfd_create(CLOCK_BOOTTIME, TFD_CLOEXEC);
    if (tfd < 0) tfd = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC);
    if (tfd < 0) { perror("timerfd_create"); return 1; }

    struct itimerspec its;
    its.it_value.tv_sec = sec;    its.it_value.tv_nsec = 0;
    its.it_interval.tv_sec = sec; its.it_interval.tv_nsec = 0;
    if (timerfd_settime(tfd, 0, &its, NULL) < 0) { perror("timerfd_settime"); return 1; }

    for (;;) {
        uint64_t expirations;
        ssize_t n = read(tfd, &expirations, sizeof expirations);
        if (n != (ssize_t) sizeof expirations) {
            if (errno == EINTR) continue;
            break;
        }
        pid_t pid = fork();
        if (pid == 0) { execvp(argv[2], &argv[2]); _exit(127); }
        if (pid > 0) waitpid(pid, NULL, 0);
    }
    return 1;
}
