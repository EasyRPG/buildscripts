#ifndef _SYS_STAT_H
#define _SYS_STAT_H

#include <stdint.h>

struct stat {
    uint32_t st_mode;
    uint32_t st_size;
};

#define S_ISREG(m)  (((m) & 0170000) == 0100000)
#define S_ISDIR(m)  (((m) & 0170000) == 0040000)

#endif
