#define MB_ERR_INVALID_CHARS 0x00000008
#define CP_UTF8 65001
#define CP_UTF7 65000

static inline int WideCharToMultiByte(unsigned int cp, unsigned long flags,
    const wchar_t *wstr, int wlen, char *mbstr, int mblen, const char *def, int *used)
{ (void)cp;(void)flags;(void)wstr;(void)wlen;(void)mbstr;(void)mblen;(void)def;(void)used; return 0; }

static inline int MultiByteToWideChar(unsigned int cp, unsigned long flags,
    const char *mbstr, int mblen, wchar_t *wstr, int wlen)
{ (void)cp;(void)flags;(void)mbstr;(void)mblen;(void)wstr;(void)wlen; return 0; }