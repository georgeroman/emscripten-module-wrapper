#!/bin/bash

# Make sure an old version of Emscripten (e.g. 1.38.33) is activated and available before running this

# Compile to WASM
emcc -o filesystem-wasm.wasm -s EXPORTED_FUNCTIONS="['_env____syscall5', '_env____syscall140', '_env____syscall6', '_env____syscall3', '_env____syscall195', '_env____syscall146', \
'_env____syscall4', '_env____syscall41', '_env____syscall63', '_env____syscall330', '_env____syscall145', '_env____syscall333', '_env____syscall197', '_env____syscall221', \
'_env____syscall334', '_env____syscall180', '_env____syscall181', '_env____syscall295', '_env____lock', '_env____unlock', '_env__getenv', \
'_env____syscall54', '_env__pthread_mutex_lock', '_env__pthread_mutex_unlock', '_env__pthread_cond_broadcast', '_env____cxa_atexit',  '_env____cxa_allocate_exception', \
'_initSystem', '_finalizeSystem', '_callArguments', '_callReturns', '_getReturn', '_callMemory', '_env__getInternalFile', '_env_emscripten_memcpy_big', \
'_env__pthread_mutex_lock', '_env__pthread_mutex_init', '_env__pthread_mutex_destroy', \
'_env__pthread_mutexattr_init', '_env__pthread_mutexattr_settype', '_env__pthread_cond_init', \
'_env__pthread_mutexattr_destroy', '_env__pthread_condattr_init', \
'_env__pthread_getspecific', '_env__pthread_setspecific', '_env__pthread_condattr_create', '_env__pthread_condattr_setclock', '_env__pthread_condattr_destroy', '_env__pthread_key_create', \
'_env__pthread_mutex_unlock', '_env__pthread_cond_broadcast', '_env__gettimeofday', \
'_env__internalSync', '_env__internalSync2', '_env__fd_fdstat_get', '_env__fd_write', '_env__fd_close']" -s WASM=1 -s SIDE_MODULE=2 filesystem.c

# Transform to WAT in order to make necessary changes
wasm2wat filesystem-wasm.wasm -o filesystem.wat

# https://github.com/googlecodelabs/web-assembly-introduction/issues/11
sed -i 's/__memory_base/memoryBase/' filesystem.wat
sed -i 's/__table_base/tableBase/' filesystem.wat

# Transform back to WASM
wat2wasm filesystem.wat -o filesystem-wasm.wasm
