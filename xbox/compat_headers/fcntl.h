#ifndef NXDK_FCNTL_H
#define NXDK_FCNTL_H

/* Provide only minimal compatibility definitions for mpg123 */

/* File access flags (not actually used by libmpg123) */
#define O_RDONLY 0x0000
#define O_WRONLY 0x0001
#define O_RDWR   0x0002
#define O_BINARY 0x8000  /* Used by Windows; ok to stub */

/* Stub of open() so linking succeeds if something pulls it in */
__attribute__((used))
static int _open(const char *path, int flags, ...) {
    (void)path;
    (void)flags;
    return -1;
}

#endif /* NXDK_FCNTL_H */