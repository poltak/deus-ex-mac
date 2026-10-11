# deus-ex-mac

Work to run the original Deus Ex (2000, build 1112fm) as a native macOS program on Apple Silicon.

The game does not get a new binary port. The engine is [SurrealEngine](https://github.com/dpjudas/SurrealEngine), an open-source reimplementation of Unreal Engine 1 that supports macOS. It loads the original maps, scripts, textures and sounds. Where SurrealEngine has missing or incorrect Deus Ex behavior, [REA](https://github.com/morluto/rea) with Ghidra shows what the original Windows DLLs do, and the fork implements that behavior again.

## Rules

- SurrealEngine does not accept AI-written code. All changes stay in the `deus-ex-mac` branch of the `SurrealEngine` submodule. Do not open a pull request upstream with them.
- Game data comes from your own copy of Deus Ex. The `DeusEx/` folder is in `.gitignore`. Do not commit it.
- Do not commit raw decompiler output of the original DLLs. Commit only your own code and notes.

## Layout

- `SurrealEngine/` is the engine fork (git submodule, branch `deus-ex-mac`).
- `DeusEx/` is your game data: the `System`, `Maps`, `Textures`, `Sounds`, `Music`, `Help` and `Save` folders.
- `tools/run-dx.sh` starts a map for a set time and prints a summary of the log.
- `tools/rea/` has the scripts that keep one REA session with Ghidra open and call it.
- `tools/native_gap.py` compares the native functions that the DLLs export with the ones the engine registers.
- `analysis/exports/` has the export table of each original DLL.
- `runs/` receives the log and screenshots of each test run.

## Game data

SurrealEngine identifies the game by the SHA1 of `System/DeusEx.exe`. Use the original executable. In a Steam install that has Kentie's launcher, the original is `System/DeusEx-vanilla.exe`. Copy it to `DeusEx.exe` in your `DeusEx/System` folder. A `Save` folder must exist.

## Build

```bash
cd SurrealEngine
cmake -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -B build
ninja -C build SurrealEngine
```

## Run a test

```bash
tools/run-dx.sh m01 60 --url=01_NYC_UNATCOIsland
```

The first argument is the run name, the second is the time in seconds. The log and screenshots go to `runs/m01/`.
