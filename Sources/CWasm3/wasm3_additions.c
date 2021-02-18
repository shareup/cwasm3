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
    if (o_size) { *o_size = 0; }
    M3Result result = m3Err_none;

    if (i_function->compiled)
    {
        IM3Module module = i_function->module;

        IM3Runtime runtime = module->runtime;
        runtime->argc = i_argc;
        runtime->argv = i_argv;
        if (i_function->numNames == 1 and i_function->names[0] and strcmp (i_function->names[0], "_start") == 0) // WASI
            i_argc = 0;

        IM3FuncType ftype = i_function->funcType;
        m3log (runtime, "calling %s", SPrintFuncTypeSignature (ftype));

        if (i_argc != ftype->numArgs)
            _throw (m3Err_argumentCountMismatch);

        // args are always 64-bit aligned
        u64 * stack = (u64 *) runtime->stack;

        // The format is currently not user-friendly by default,
        // as this is used in spec tests
        for (u32 i = 0; i < ftype->numArgs; ++i)
        {
            u64 * s = & stack [i];
            ccstr_t str = i_argv[i];

            switch (ftype->types[ftype->numRets + i]) {
            case c_m3Type_i32:
            case c_m3Type_f32:  *(u32*)(s) = (u32)strtoul(str, NULL, 10);  break;
            case c_m3Type_i64:
            case c_m3Type_f64:  *(u64*)(s) = strtoull(str, NULL, 10); break;
            default: _throw("unknown argument type");
            }
        }

        m3StackCheckInit();
        _ ((M3Result) Call (i_function->compiled, (m3stack_t) stack, runtime->memory.mallocated, d_m3OpDefaultArgs));

        switch (GetSingleRetType(ftype)) {
            case c_m3Type_none:
                if (o_size) { *o_size = 0; }
                break;
            case c_m3Type_i32:
                if (o_size && o_ret) {
                    *o_size = sizeof(u32);
                    *(u32 *)o_ret = *(u32 *)stack;
                }
                break;
            case c_m3Type_f32:  {
                if (o_size && o_ret) {
                    *o_size = sizeof(f32);
                    *(f32 *)o_ret = * (f32 *)(stack);;
                }
                break;
            }
            case c_m3Type_i64:
            case c_m3Type_f64:
                if (o_size && o_ret) {
                    *o_size = sizeof(u64);
                    *(u64 *)o_ret = *(u64 *)stack;
                }
                break;
            default: _throw("unknown return type");
        }
    }
    else _throw (m3Err_missingCompiledCode);

_catch: {
    return result;
}
}
