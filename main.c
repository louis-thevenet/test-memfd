#define _GNU_SOURCE
#include <unistd.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <errno.h>

int main() {
    #ifndef __NR_memfd_secret
    printf("Doing stuff without memfd");
    #else
    printf("Doing stuff with memfd");
    long ret = syscall(__NR_memfd_secret, 0);
    #endif

    return 0;
}

