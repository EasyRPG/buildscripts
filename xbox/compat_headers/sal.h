#ifndef _NXDK_SAL_H_
#define _NXDK_SAL_H_

/* Basic SAL attribute stubs */
#define _In_
#define _Out_
#define _Inout_
#define _In_opt_
#define _Out_opt_
#define _Inout_opt_
#define _Ret_
#define _Success_(x)

/* Buffer-size annotations */
#define _In_bytecount_(x)
#define _Inout_z_cap_(x)
#define _Out_z_cap_(x)
#define _Out_cap_(x)
#define _Out_bytecap_(x)
#define _Out_z_bytecap_(x)

/* Format string annotations */
#define _Printf_format_string_
#define _Scanf_format_string_impl_

#endif