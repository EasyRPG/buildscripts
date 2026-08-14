#pragma once
#ifdef NXDK
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
    inline int _isatty(int) { return 0; }
    inline int _setmode(int, int) { return 0; }
    inline int _fileno(FILE*) { return 0; }
}
#endif 

#endif
