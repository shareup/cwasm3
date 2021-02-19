//
//  m3_bind.c
//
//  Created by Steven Massey on 4/29/19.
//  Copyright © 2019 Steven Massey. All rights reserved.
//

#include "m3_exec.h"
#include "m3_env.h"
#include "m3_exception.h"
#include "m3_info.h"


u8  ConvertTypeCharToTypeId (char i_code)
{
    switch (i_code) {
    case 'v': return c_m3Type_none;
    case 'i': return c_m3Type_i32;
    case 'I': return c_m3Type_i64;
    case 'f': return c_m3Type_f32;
    case 'F': return c_m3Type_f64;
    case '*': return c_m3Type_i32;
    }
    return c_m3Type_unknown;
}


M3Result  SignatureToFuncType  (IM3FuncType * o_functionType, ccstr_t i_signature)
{
    M3Result result = m3Err_none;

    IM3FuncType funcType = NULL;
_try {
    if (not o_functionType)
        _throw ("null function type");

    if (not i_signature)
        _throw ("null function signature");

    cstr_t sig = i_signature;

    int maxNumArgs = strlen (i_signature) - 2; // "()"
    _throwif (m3Err_malformedFunctionSignature, maxNumArgs < 0);
    _throwif ("insane argument count", maxNumArgs > d_m3MaxSaneFunctionArgCount);

_   (AllocFuncType (& funcType, maxNumArgs));

    bool parsingArgs = false;
    while (* sig)
    {
        char typeChar = * sig++;

        if (typeChar == '(')
        {
            parsingArgs = true;
            continue;
        }
        else if ( typeChar == ' ')
            continue;
        else if (typeChar == ')')
            break;

        u8 type = ConvertTypeCharToTypeId (typeChar);

        _throwif ("unknown argument type char", c_m3Type_unknown == type);

        if (type == c_m3Type_none)
            continue;

        if (not parsingArgs)
        {
            _throwif ("malformed function signature; too many return types", funcType->numRets >= 1);

            d_FuncRetType(funcType, funcType->numRets++) = type;
        }
        else
        {
            _throwif (m3Err_malformedFunctionSignature, funcType->numArgs >= maxNumArgs);  // forgot trailing ')' ?

            d_FuncArgType(funcType, funcType->numArgs++) = type;
        }
    }

} _catch:

    if (result)
        m3Free (funcType);  // nulls funcType

    * o_functionType = funcType;

    return result;
}


static
M3Result  ValidateSignature  (IM3Function i_function, ccstr_t i_linkingSignature)
{
    M3Result result = m3Err_none;

    IM3FuncType ftype = NULL;
_   (SignatureToFuncType (& ftype, i_linkingSignature));

    if (not AreFuncTypesEqual (ftype, i_function->funcType))
    {
        m3log (module, "expected: %s", SPrintFuncTypeSignature (ftype));
        m3log (module, "   found: %s", SPrintFuncTypeSignature (i_function->funcType));

        _throw ("function signature mismatch");
    }

    _catch:

    m3Free (ftype);

    return result;
}


M3Result  LinkRawFunction  (IM3Module io_module,  IM3Function io_function, ccstr_t signature,  const void * i_function, const void * i_userdata)
{
    M3Result result = m3Err_none;                                                 d_m3Assert (io_module->runtime);

_try {
_   (ValidateSignature (io_function, signature));

    IM3CodePage page = AcquireCodePageWithCapacity (io_module->runtime, 4);

    if (page)
    {
        io_function->compiled = GetPagePC (page);
        io_function->module = io_module;

        EmitWord (page, op_CallRawFunction);
        EmitWord (page, i_function);
        EmitWord (page, io_function);
        EmitWord (page, i_userdata);

        ReleaseCodePage (io_module->runtime, page);
    }
    else _throw(m3Err_mallocFailedCodePage);

} _catch:
    return result;
}

M3Result  FindAndLinkFunction      (IM3Module       io_module,
                                    ccstr_t         i_moduleName,
                                    ccstr_t         i_functionName,
                                    ccstr_t         i_signature,
                                    voidptr_t       i_function,
                                    voidptr_t       i_userdata)
{
    M3Result result = m3Err_functionLookupFailed;

    bool wildcardModule = (strcmp (i_moduleName, "*") == 0);

    for (u32 i = 0; i < io_module->numFunctions; ++i)
    {
        IM3Function f = & io_module->functions [i];

        if (f->import.moduleUtf8 and f->import.fieldUtf8)
        {
            if (strcmp (f->import.fieldUtf8, i_functionName) == 0 and
               (wildcardModule or strcmp (f->import.moduleUtf8, i_moduleName) == 0))
            {
                result = LinkRawFunction (io_module, f, i_signature, i_function, i_userdata);
                if (result) return result;
            }
        }
    }

    return result;
}

M3Result  m3_LinkRawFunctionEx  (IM3Module            io_module,
                                const char * const    i_moduleName,
                                const char * const    i_functionName,
                                const char * const    i_signature,
                                M3RawCall             i_function,
                                const void *          i_userdata)
{
    return FindAndLinkFunction (io_module, i_moduleName, i_functionName, i_signature, (voidptr_t)i_function, i_userdata);
}

M3Result  m3_LinkRawFunction  (IM3Module            io_module,
                              const char * const    i_moduleName,
                              const char * const    i_functionName,
                              const char * const    i_signature,
                              M3RawCall             i_function)
{
    return FindAndLinkFunction (io_module, i_moduleName, i_functionName, i_signature, (voidptr_t)i_function, NULL);
}

