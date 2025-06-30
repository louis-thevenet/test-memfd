#include <unistd.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <errno.h>

int main() {
    #ifndef __NR_memfd_secret
        printf("Doing stuff without memfd\n");
    #else
        printf("Doing stuff with memfd\n");
        long ret = syscall(__NR_memfd_secret, 0);
        if (ret == -1) {
            perror("syscall memfd_secret failed\n");
            return 1;
        } else {
        printf("syscall memfd_secret succeeded\n");
        }
    #endif

    return 0;
}

