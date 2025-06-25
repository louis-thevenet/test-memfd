#define _GNU_SOURCE
#include <unistd.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <errno.h>

int main() {
    long ret = syscall(__NR_memfd_secret, 0);
    if (ret == -1) {
        perror("syscall memfd_secret failed");
        return 1;
    }
    printf("memfd_secret returned: %ld\n", ret);
    return 0;
}

