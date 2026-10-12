# deus-ex-mac

Run the original Deus Ex (2000, Game of the Year Edition, build 1112fm) as a native program on an Apple Silicon Mac.

The game does not get a new binary port. The engine is a fork of [SurrealEngine](https://github.com/dpjudas/SurrealEngine), an open-source reimplementation of Unreal Engine 1 that runs on macOS. It loads the original maps, scripts, textures and sounds of your own copy of the game. Where SurrealEngine has missing or incorrect Deus Ex behavior, [REA](https://github.com/morluto/rea) with Ghidra shows what the original Windows DLLs do, and the fork implements that behavior again.

This repository has no game data. You need your own copy of Deus Ex.

## State on 2026-10-12

Scripted tests on an M2 Max show that these parts work:

- Start screen, main menu, new game, intro.
- Conversations and infolinks: text, choices, the transfer of objects, mouth shapes.
- Enemies and allies: patrol, see and hear the player, attack, flee. Animals wander.
- Pickups, datacubes, keypads, doors, the inventory and goals screens.
- Quick save and quick load, the Save Game and Load Game screens, a load directly after the start of the program. A load after a fight gives the dead guard, its body and the things of the body back as they were.
- Travel between maps with inventory, credits and flags. A map keeps its state when you come back.
- The mission script of Liberty Island: when the statue mission is complete, the terrorists die, the UNATCO soldiers come into the map, Paul goes to the HQ and its doors open. The boat ride to mission 2 plays as a camera path, the game goes to Battery Park, and the talk with Anna Navarre starts there.
- Particle effects, lightmaps with moving and animated lights.
- Key bindings of the game, the talk line as console, cheats.
- The six settings screens. The Screen Resolution setting changes the size of the window. A new key binding from the Keyboard/Mouse Settings screen works at once and after a new start, and a key that lost its binding stays without it.
- Buttons, checkboxes, sliders and scroll bars of the interface. A list or a text moves with the thumb, the arrow buttons, the mouse wheel and the page keys.
- The keyboard in menus: the arrow keys and the Tab key move the focus, and the Enter key presses a button. A dialog keeps the keys and the mouse while it is open, and the focus goes back to the screen below when it closes.
- The mouse cursor of the interface: the arrow, the text cursor on edit fields, and the picture of an inventory item during a drag. The cursor does not show while a person speaks in a conversation, and the answer under the mouse has a highlight.
- Keys across screens: a movement key that you release while a screen is open does not stay active, and a held key runs its command one time.
- The eight player screens: inventory, health, augmentations, skills, goals, conversations, images and logs. A medkit heals, and skill points upgrade a skill.
- Computers: login with user name and password, email, bulletins, the security screen with its camera picture, doors and turrets, the ATM, and the hack of a computer.
- Lockpicks on locked doors and multitools on keypads. A key goes to the key ring, and the key ring unlocks the door of that key.
- Swimming, the breath timer and drowning. The death of the player, with the camera sequence and the return to the title screen.
- Ladders: the player climbs up with a level view and down with the view down, holds on with no key down, and gets on a ladder that starts above the floor with a jump.
- Landings: a person pushes off a player who lands on its head, a burning barrel burns, and a long fall hurts the legs.
- A fight with the pistol: the HUD counts the rounds of the clip, the guard takes damage, flees and dies, and the search of the body gives its knife and the rounds of its pistol.
- Weapons: the reload key, with the HUD that shows no numbers during the reload, and the ammo key that changes between the dart types of the mini crossbow.
- Things in the world: the player lifts a trash can and throws it, breaks a crate with a crowbar and takes what was in it.
- The start of a map: a body that the map has from the start keeps its things hidden until the player searches it, a gun turret that hangs from a ceiling stays there, and a glass plate with an attach tag has its target as base.
- Stasis: a thing or a person that the player did not see for 5 seconds, and that is far away or in a room that is not in view, stops until the player comes back. The scripts of the game are written for this rule of the original engine.
- The music: the calm, combat and conversation parts of a song, the fades between them, and the return to the place where the calm part stopped.
- The vision augmentation shows people as bright shapes.
- The animated fire textures of the game: flames, static, laser beams, fountains, lightning.
- All 88 map files of the game start with no error.

Speed: the main thread needs about 8 ms of processor time for each frame on Liberty Island, the heaviest map, and 6 to 7 ms on the two heaviest maps of Hong Kong. The mean of all maps is 1.9 ms. A display with 120 Hz shows the game at 120 frames per second on most maps.

Sound: a test tool records the sound output to a file. The recordings of the intro and of a conversation have music and speech in each second. In the recording of the conversation, 134 of 4.3 million samples are at full scale, in runs of 4 samples at most. The music changes to the combat and the conversation part of a song at the same song position as with the original sound code.

No person has checked these parts yet:

- Sound by ear. The test runs are muted or go to a file.
- Mouse look in real play. The tests send input without the mouse capture.
- Fullscreen. The tests run in a window, and no test covers the fullscreen switch.
- A full mission from start to end.

Known gaps:

- A save game has no picture. The original also makes no picture with its OpenGL renderer.
- The program uses about 15 MB more memory after each map change. The engine frees the geometry, the lightmaps and the textures of a map that it left, but it has no garbage collector for the objects of that map.
- The Effects Channels setting applies at the next start.
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

Put the folder in a place where you can write. The engine keeps its settings and the save games in the game folder. In a working copy of this project, name the folder `DeusEx` and put it at the top of the working copy. The app in `dist/` and the test tools find it there, and git ignores it. A different place is `~/Games/Deus Ex`.

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

Open `dist/Deus Ex.app`. The first start looks for the game folder in these places, in this order: a `DeusEx` or `Deus Ex` folder next to the app, the `DeusEx` folder of this working copy (the folder next to `dist`), `~/Library/Application Support/Steam/steamapps/common/Deus Ex`, `~/Games/Deus Ex`, `~/Documents/Deus Ex` and `/Applications/Deus Ex`. If the game is not there, a dialog asks for the folder. The app stores the folder in `~/Library/Application Support/DeusExMac/gamefolder.txt`. Delete that file to select a different folder. The environment variable `DEUSEX_GAME_FOLDER` selects a folder for one start.

The game folder does not need the original `DeusEx.exe`. A folder where a mod launcher replaced that file also works.

### Controls and settings

- The first start opens a window that is the largest whole multiple of 640x480 pixels that fits on your screen. The game scales its screens by whole numbers, as the original does.
- Settings, Display, Screen Resolution in the game changes the size of the window. The list has each whole multiple of 640x480 pixels that fits on your screen. The engine keeps the size for the next start.
- Settings, Display, Toggle Full-Screen Mode and the green button of the window switch between the window and fullscreen.
- The window size and the fullscreen switch are also in `System/SE-DeusEx.ini` in the game folder, section `[Engine.SurrealClient]`: `WindowedViewportX`, `WindowedViewportY` (in points) and `StartupFullscreen`.
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

The first argument is the name of the run and the second is the time in seconds of game time. The log and the pictures go to `runs/m01/`. A test run makes no sound and does not take the keyboard or the mouse.

A run repeats exactly. The game advances a fixed time for each frame with a fixed random seed, and it starts only when the window has its size, because the size of the view changes which actors the player sees. A run is also faster than real time, and it does not wait for the display after each frame (`VSYNC=1` turns that wait on).

`SCRIPT=tests/<name>.txt` gives the run an input script. Each line has a time and a command: keys, mouse clicks, console commands, pictures, commands that list actors, flags, goals, interface windows and the inventory, and commands that set a flag or send a trigger event to actors. The file `SurrealEngine/SurrealEngine/Harness.h` has the full list. `SurrealEngine/SurrealEngine/Harness.cpp` has the full list.

`APP="dist/Deus Ex.app"` runs the packaged app and its start script. `GAME=<folder>` selects a different game folder. `tools/fresh-game.sh <new folder>` makes a game folder in the state of a first start: links to the data in `DeusEx/`, copies of the ini files of the game, no saved games.

### Regression tests

```bash
tools/regress.sh
```

This runs the scripted tests and prints one line for each. Each test gets its own new game folder in the state of a first start, so the result of a test does not depend on the tests before it. The save game tests are a chain that uses one folder, because the later tests load the saved games of the earlier tests. The line has the count of script errors, the last inventory list and the total count of script calls. The totals are the same in each run of a test, so a difference shows a change of behavior.

A test can have a file `tests/<name>.expect`. Each line of that file is a pattern that the log of the test must have. The test fails when a line is missing. A line that starts with `!` is a pattern that the log must not have. The harness command `windows` writes the visible interface windows to the log, with the text of text windows, the row count of lists, the state of checkboxes and the position of scroll bars. The command `dump` writes properties of actors. With these two commands a test can check what a screen shows and what the game state is.

To run only some tests, give their names. A test of a chain also runs the tests before it in the chain:

```bash
tools/regress.sh computer-email menu-scroll
```

```bash
tests/start-script-test.sh
```

This tests the start script of the app with a fake engine and fake dialogs.

```bash
tests/window-size-test.sh
```

This checks that the Screen Resolution setting changes the window and that the next start opens with the same size.

```bash
tools/map-sweep.sh
```

This starts each map of the game for some seconds and writes the errors and the frame times of each map to `runs/map-sweep.txt`.

`tests/fire-textures.txt` uses the harness command `showtex` to draw the 40 fire textures of the game in a grid. A square that stays black shows a spark type that does not work.

### Test the sound

```bash
SCRIPT=tests/audio-intro.txt tools/audio-test.sh audio-intro 60
```

This runs the game in real time and sends the sound to `runs/audio-intro/audio.wav`, not to the speakers. Then it prints the level of each second of the file. `tests/audio-paul.txt` does the same for a conversation on Liberty Island (add `--url=01_NYC_UNATCOIsland`).

`tools/modsections.cpp` prints where each section of a music file starts. Its first lines tell how to build it.

`tools/upkgprops.py <package> <class> [text]` prints the saved properties of each object of a class in a game package. It shows what the game data has, for example which goals of the conversation file are primary goals:

```bash
python3 tools/upkgprops.py DeusEx/System/DeusExConText.u ConEventAddGoal Ambrosia
```

### Measure memory

`tests/memory.txt` goes between two maps twelve times and logs the memory of the process after each change:

```bash
FIXED_FPS=60 SCRIPT=tests/memory.txt SHOT_INTERVAL=0 tools/run-dx.sh memory 130 --url=01_NYC_UNATCOIsland
```

`tools/heap-growth.sh` runs the same test with the allocation log of macOS and prints which call stacks hold more memory after later map changes.

### Measure speed

`tests/perf-m01.txt` has `perf` commands. Each one logs the mean frame time in real time (`ms`) and the mean processor time of the main thread for a frame (`cpums`). When the display shows the test window, `ms` cannot go below the frame time of the display. Use `cpums` to compare two versions of the engine.

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
