# deus-ex-mac

Run the original Deus Ex (2000, Game of the Year Edition, build 1112fm) as a native program on an Apple Silicon Mac.

The game does not get a new binary port. The engine is a fork of [SurrealEngine](https://github.com/dpjudas/SurrealEngine), an open-source reimplementation of Unreal Engine 1 that runs on macOS. It loads the original maps, scripts, textures and sounds of your own copy of the game. Where SurrealEngine has missing or incorrect Deus Ex behavior, [REA](https://github.com/morluto/rea) with Ghidra shows what the original Windows DLLs do, and the fork implements that behavior again.

This repository has no game data. You need your own copy of Deus Ex.

## State on 2026-10-11

Scripted tests on an M2 Max show that these parts work:

- Start screen, main menu, new game, intro.
- Conversations and infolinks: text, choices, the transfer of objects, mouth shapes.
- Enemies and allies: patrol, see and hear the player, attack, flee. Animals wander.
- Pickups, datacubes, keypads, doors, the inventory and goals screens.
- Quick save and quick load, the Save Game and Load Game screens, a load directly after the start of the program.
- Travel between maps with inventory, credits and flags. A map keeps its state when you come back.
- Particle effects, lightmaps with moving and animated lights.
- Key bindings of the game, the talk line as console, cheats.

Speed: Liberty Island, the heaviest map in the tests, takes 10 ms for each frame (about 97 frames per second).

No person has checked these parts yet:

- Sound. All test runs are muted.
- Mouse look in real play. The tests send input without the mouse capture.
- Fullscreen. The tests run in a window.
- A full mission from start to end.

Known gaps:

- A save game has no picture (`RootWindow.GenerateSnapshot`).
- `Actor.StopSound` and `Actor.SetInstantSpeechVolume` do nothing.
- The program uses about 22 MB more memory after each map load, because the engine does not free a map that it left.
- Multiplayer is not tested.

## Play

### What you need

- A Mac with Apple Silicon and macOS 15 or later.
- The Xcode command line tools, CMake and Ninja to build the app (`brew install cmake ninja`).
- The files of Deus Ex: the `System`, `Maps`, `Textures`, `Sounds` and `Music` folders.

### Get the game files

The game folder is the folder that has `System` and `Maps` in it. There are three usual ways to get it. Only the first one was used in this project.

1. Copy the folder from a computer where the game is installed. On Windows and Linux, Steam keeps it in `steamapps/common/Deus Ex`.
2. Download the Windows files with SteamCMD (not tested here). App 6910 is the Game of the Year Edition:

   ```bash
   steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$HOME/Games/Deus Ex" +login YOUR_STEAM_NAME +app_update 6910 validate +quit
   ```

3. Extract the GOG offline installer with `innoextract` (not tested here).

Put the folder in a place where you can write, for example `~/Games/Deus Ex`. The engine keeps its settings and the save games in the game folder.

### Build the app

The engine fork is the `SurrealEngine` folder of this working copy.

```bash
cmake -S SurrealEngine -B SurrealEngine/build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

```bash
ninja -C SurrealEngine/build SurrealEngine
```

```bash
tools/make-app.sh
```

The result is `dist/Deus Ex.app`. It has the engine and its libraries in it, and no game data.

### Start the game

Open `dist/Deus Ex.app`. The first start looks for the game in `~/Library/Application Support/Steam/steamapps/common/Deus Ex`, `~/Games/Deus Ex`, `~/Documents/Deus Ex` and `/Applications/Deus Ex`. If the game is not there, a dialog asks for the folder. The app stores the folder in `~/Library/Application Support/DeusExMac/gamefolder.txt`. Delete that file to select a different folder. The environment variable `DEUSEX_GAME_FOLDER` selects a folder for one start.

The game folder does not need the original `DeusEx.exe`. A folder where a mod launcher replaced that file also works.

### Controls and settings

- The first start opens a window that is the largest whole multiple of 640x480 pixels that fits on your screen. The game scales its screens by whole numbers, as the original does.
- The window size and the fullscreen switch are in `System/SE-DeusEx.ini` in the game folder, section `[Engine.SurrealClient]`: `WindowedViewportX`, `WindowedViewportY` (in points) and `StartupFullscreen`.
- The key bindings are the ones of the game. Change them in the game under Settings, Keyboard/Mouse. The engine saves them in `System/SE-User.ini`.
- The engine does not change `DeusEx.ini` and `User.ini` of the game. It keeps its own copies with the prefix `SE-`.
- T opens the talk line, which is also the console. To turn the cheats on, press T, delete `Say`, and type `set DeusExPlayer bCheatsEnabled True`.
- The console command `timedemo 1` shows the frame rate.

### Game files with mods

The engine uses `System/DeusEx.u` of the game folder, so the folder must have the original script packages.

GMDX installs its conversation files over the original ones. A game folder with GMDX in it runs, and the first infolink then tries to give an object that only GMDX has. The log shows `Could not spawn class: null` for it. The original game does the same with these files.

## Develop

### Layout

- `SurrealEngine/` is the engine fork (git submodule, branch `deus-ex-mac`).
- `DeusEx/` is your game data for tests. Git ignores it.
- `packaging/` has the start script and the `Info.plist` of the app.
- `tests/` has input scripts for the test harness of the fork.
- `tools/` has the scripts to run tests, to measure speed and to read the original DLLs.
- `analysis/exports/` has the export table of each original DLL.
- `runs/` gets the log and the pictures of each test run. Git ignores it.
- `re-out/` gets the raw decompiler output. Git ignores it.

### Run a test

```bash
tools/run-dx.sh m01 60 --url=01_NYC_UNATCOIsland
```

The first argument is the name of the run and the second is the time in seconds of game time. The log and the pictures go to `runs/m01/`. The game advances a fixed time for each frame with a fixed random seed, so a run repeats exactly and is faster than real time. A test run makes no sound and does not take the keyboard or the mouse.

`SCRIPT=tests/<name>.txt` gives the run an input script. Each line has a time and a command: keys, mouse clicks, console commands, pictures, and commands that list actors, flags and the inventory. `SurrealEngine/SurrealEngine/Harness.cpp` has the full list.

`APP="dist/Deus Ex.app"` runs the packaged app and its start script. `GAME=<folder>` selects a different game folder.

### Regression tests

```bash
tools/regress.sh
```

This runs the scripted tests and prints one line for each. The line has the count of script errors, the last inventory list and the total count of script calls. The totals are the same in each run of a test, so a difference shows a change of behavior.

```bash
tests/start-script-test.sh
```

This tests the start script of the app with a fake engine and fake dialogs.

```bash
tools/map-sweep.sh
```

This starts each map of the game for some seconds and writes the errors and the frame time of each map to `runs/map-sweep.txt`.

### Measure speed

`tests/perf-m01.txt` has `perf` commands, which log the mean frame time in real time:

```bash
FIXED_FPS=60 SCRIPT=tests/perf-m01.txt SHOT_INTERVAL=0 tools/run-dx.sh perf 26 --url=01_NYC_UNATCOIsland
```

`tools/profile-dx.sh <run name> <output file> [engine arguments]` takes a sample of the engine with the macOS `sample` tool. `tools/selfprof.py <file>` prints the time of each function, and `tools/callers.py <file> <regex>` prints which engine functions call the functions that match.

### Read the original DLLs

`tools/rea.sh` keeps one REA session with Ghidra open for each DLL:

```bash
tools/rea.sh start con ConSys
```

```bash
tools/rea.sh search con BindEvents
```

```bash
tools/rea.sh pc con 0x1000fec0 CV_BindEvents
```

The decompiler drops x87 float math and stack arguments. For a formula, read the assembly (`tools/rea.sh asm`) and the constants (`tools/rea/peread.py <dll> f|d|i|w <address>`). Stop a session with `tools/rea.sh stop <session>`.

## Rules

- SurrealEngine does not accept AI-written code. All changes stay in the `deus-ex-mac` branch of the `SurrealEngine` submodule. Do not open a pull request upstream with them.
- The commits of the fork are only in this working copy. The URL of the submodule is the upstream repository, which does not have them. To give the project to other people, push the `deus-ex-mac` branch to a repository of your own and put its URL in `.gitmodules`.
- Game data comes from your own copy of Deus Ex. Do not commit it.
- Do not commit raw decompiler output of the original DLLs. Commit only your own code and notes.
