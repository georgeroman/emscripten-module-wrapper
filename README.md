## Running new versions of Rust on Truebit

This is a wrapper for being able to compile and run newer versions of Rust for Truebit.
You can find additional info on how this works at the end of this file.

## Installation instructions

Begin by `cd` in your Rust project directory.

Make sure your project compiles with Rust version `1.40.0` (this is the version I've used):
```
rustup install 1.40.0
rustup default 1.40.0
rustup target add wasm32-unknown-emscripten
```

Install Emscripten (versions `1.38.33` (needed in `emscripten-module-wrapper`) and `1.39.8` (needed for transpiling the Rust code to WebAssembly)):
```
# One directory above your Rust project directory
git clone https://github.com/emscripten-core/emsdk
cd emsdk
./emsdk install 1.38.33
./emsdk install 1.39.8

# To activate and make available any of these Emscripten versions run the following (only activate one version per terminal session):
./emsdk activate $VERSION
source ./emsdk_env.sh
```

Clone and build TrueBit's WebAssembly interpreter:
```
# One directory above your Rust project directory
git clone --single-branch --branch v2 https://github.com/TrueBitFoundation/ocaml-offchain.git
cd ocaml-offchain/interpreter
# Install dependencies
make
```

Clone and run a modified version of `emscripten-module-wrapper`:
```
# One directory above your Rust project directory
git clone https://github.com/georgeroman/emscripten-module-wrapper.git
cd emscripten-module-wrapper
npm install
# Optional (make sure Emsscripten 1.38.33 is activated)
./fs-script.sh
```

## Building and testing

You should place the files `build/build-rust-task.sh` and `build/run-truebit-task.sh` at the root of your Rust project and modify them to fit your needs.
Run `build-rust-task.sh` (make sure Emscripten `1.39.8` is activated when doing this) to get your code compiled and have the resulting WASM modified so that it is compatible with Truebit.

## How it works

When transpiling from Rust to WASM via Emscripten version `1.38.33`, the resulting WASM file has two types of imports:
`env` imports, which make use of functions provided directly by Emscripten and `wasi_snapshot_preview` imports,
which make use of WASI functions that are to be provided by a runtime that supports WASI.
Unfortunately, since TrueBit's WASM interpreter is an old fork of the reference WASM interpreter, it doesn't support WASI.
So, in order to have the code running on TrueBit, it was needed to provide implementations of the functions imported from `wasi_snapshot_preview1`.
Rather than have a new module created under the name of `wasi_snapshot_preview1` and make it available at runtime, I decided to manually change the WASM file
(by using the `wasm2wat` and `wat2wasm` utilities) so that the required functions are imported from `env` (rather than `wasi_snapshot_preview1`)
while at the same time provide implementations in `filesystem.c` (which is where you can make functions available at runtime via `env`) for those functions.

In our case, the functions imported from `wasi_snapshot_preview1` were: `fd_environ_get`, `fd_environ_sizes_get`, `fd_fdstat_get`, `fd_write`, `fd_close`.
Out of these, only `fd_close` needed an actual implementation, while the other ones were provided with dummy implementations.

The implementations of these functions can be found here (also check `fs-script.sh` to see how they are exported):
https://github.com/georgeroman/emscripten-module-wrapper/blob/v2/filesystem.c

Due to a runtime error in TrueBit's WASM interpreter when running the code, `emscripten_memcpy_big` also needed to be exported from `filesystem.c` (via `fs-script.sh`).

Check `fs-script.sh` here:
https://github.com/georgeroman/emscripten-module-wrapper/blob/v2/fs-script.sh

The prototypes of WASI functions can be found here: https://github.com/WebAssembly/wasi-libc/blob/master/libc-bottom-half/headers/public/wasi/api.h.
