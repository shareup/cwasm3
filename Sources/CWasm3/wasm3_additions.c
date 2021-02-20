#include <stdarg.h>

#include "wasm3_additions.h"
#include "m3_exception.h"
#include "m3_env.h"

M3Result  wasm3_CallWithArgs(
    IM3Function i_function,
    uint32_t i_argc,
    const char * const * i_argv,
    size_t *o_size,
    void *o_ret
) {
    M3Result result = m3_CallArgv(i_function, i_argc, (const char **)i_argv);

    if (result) { return result; }

    IM3FuncType ftype = i_function->funcType;

    if (ftype->numRets == 0) {
        if (o_size) { *o_size = 0; }
        return result;
    }

    result = m3_GetResults(i_function, 1, (const void **)&o_ret);

    switch (d_FuncRetType(ftype, 0)) {
    case c_m3Type_i32:
        if (o_size && o_ret) { *o_size = sizeof(i32); }
        break;
    case c_m3Type_i64:
        if (o_size && o_ret) { *o_size = sizeof(i64); }
        break;
    case c_m3Type_f32:
        if (o_size) { *o_size = sizeof(f32); }
        break;
    case c_m3Type_f64:
        if (o_size && o_ret) { *o_size = sizeof(f64); }
        break;
    default: return "unknown return type";
    }

    return result;
}
