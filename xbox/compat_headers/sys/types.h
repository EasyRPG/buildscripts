#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H

/* Minimal stub for NXDK to satisfy SDL2 */

#include <stdint.h>
#include <stddef.h>

/* Define a few common typedefs used by SDL2 and libc */
typedef int pid_t;
typedef long ssize_t;
typedef unsigned long off_t;
typedef unsigned long mode_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;

#endif /* _SYS_TYPES_H */
