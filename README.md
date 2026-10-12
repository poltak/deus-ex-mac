# deus-ex-mac

Run the original Deus Ex (2000, Game of the Year Edition, build 1112fm) as a native program on an Apple Silicon Mac.

The game does not get a new binary port. The engine is a fork of [SurrealEngine](https://github.com/dpjudas/SurrealEngine), an open-source reimplementation of Unreal Engine 1 that runs on macOS. It loads the original maps, scripts, textures and sounds of your own copy of the game. Where SurrealEngine has missing or incorrect Deus Ex behavior, [REA](https://github.com/morluto/rea) with Ghidra shows what the original Windows DLLs do, and the fork implements that behavior again.

The fork is at [poltak/SurrealEngine](https://github.com/poltak/SurrealEngine), and it is the `SurrealEngine` submodule of this repository. Claude Opus 5.5, an AI model of Anthropic, wrote the changes of the fork and the tools and tests of this repository.

This repository has no game data. You need your own copy of Deus Ex.

## State on 2026-10-12

Scripted tests on an M2 Max show that these parts work:

- Start screen, main menu, new game, intro.
- Conversations and infolinks: text, choices, the transfer of objects, mouth shapes.
- Enemies and allies: patrol, see and hear the player, attack, flee. Animals wander. A guard that comes after the player with the "run and fire" move has its full speed. A person that walks stays upright when its target is above or below it. A person that the player did not see for 5 seconds, and that is more than 600 units away, does not look for enemies other than the player. So guards and robots do not fight in places that the player cannot see.
- Pickups, datacubes, keypads, doors, the inventory and goals screens.
- Quick save and quick load, the Save Game and Load Game screens, a load directly after the start of the program. A load after a fight gives the dead guard, its body and the things of the body back as they were. A saved game keeps the goals, the notes and the keys of the player.
- Travel between maps with inventory, credits, flags, goals, notes and keys. A map keeps its state when you come back.
- The mission script of Liberty Island: when the statue mission is complete, the terrorists die, the UNATCO soldiers come into the map, Paul goes to the HQ and its doors open. The boat ride to mission 2 plays as a camera path, the game goes to Battery Park, and the talk with Anna Navarre starts there.
- Particle effects, lightmaps with moving and animated lights.
- Key bindings of the game, the talk line as console, cheats.
- The six settings screens. The Screen Resolution setting changes the size of the window. A new key binding from the Keyboard/Mouse Settings screen works at once and after a new start, and a key that lost its binding stays without it.
- Buttons, checkboxes, sliders and scroll bars of the interface. A list or a text moves with the thumb, the arrow buttons, the mouse wheel and the page keys.
- The keyboard in menus: the first button of a menu has the focus when the menu opens. The arrow keys and the Tab key move the focus, and the Enter key presses a button. A dialog keeps the keys and the mouse while it is open, and the focus goes back to the screen below when it closes.
- Text fields: the name field of the Save Game screen has the focus when the screen opens, and the first typed character replaces the selected name. The Backspace and Delete keys, the arrow keys, Home and End work at the insertion point, and a click puts the insertion point at a character. A name that is longer than the field moves in the field.
- The mouse cursor of the interface: the arrow, the text cursor on edit fields, and the picture of an inventory item during a drag. The cursor does not show while a person speaks in a conversation, and the answer under the mouse has a highlight.
- Keys across screens: a movement key that you release while a screen is open does not stay active, and a held key runs its command one time.
- The keyboard of a Mac: the letters, the number row, the punctuation keys, the keypad, Shift, Ctrl, Option and Caps Lock reach the game. The number keys select the items of the belt.
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
- Stasis: a thing or a person that the player did not see for 5 seconds, and that is far away or in a room that is not in view, stops until the player comes back. The scripts of the game are written for this rule of the original engine. The engine counts a thing as seen when a part of its rectangle on the screen is free of the level geometry in front of it, as the original renderer does.
- The music: the calm, combat and conversation parts of a song, the fades between them, and the return to the place where the calm part stopped.
- The vision augmentation shows people as bright shapes.
- The animated fire textures of the game: flames, static, laser beams, fountains, lightning.
- All 88 map files of the game start with no error.
- Developer loader: a window that selects a map, a start point, the weapons and the values of the player, and starts the game there. See "Developer loader" below.

Speed: the main thread needs 6 to 7 ms of processor time for each frame on the three heaviest maps, which are Liberty Island and two maps of Hong Kong. The mean of all maps is about 2 ms. A display with 120 Hz shows the game at 120 frames per second on most maps.

Sound: a test tool records the sound output to a file. The recordings of the intro and of a conversation have music and speech in each second. In the recording of the conversation, 134 of 4.3 million samples are at full scale, in runs of 4 samples at most. The music changes to the combat and the conversation part of a song at the same song position as with the original sound code.

A person played the first part of Liberty Island on 2026-10-12. That play found two faults, and the two are fixed: the number keys did not select belt items, and a guard that ran and fired moved with its walking speed.

A second play on the same day found four more faults, and the four are fixed:

- A press of the Backspace key in the empty name field of the Save Game screen, and then a typed character, stopped the engine.
- The engine could not load a saved game of a player who had a goal, a note or a key. For the same cause, the return to a map of the same mission stopped the engine.
- Guards leaned back and looked at the sky when the person that they went to was above them.
- The guards near the first dock of Liberty Island were at a different place in each new game, and in one game the security robot of the dock killed them before the player came. The engine counted persons behind walls as seen, so hidden guards and robots fought each other, and the result changed with the frame rate. Now a hidden person counts as not seen, as in the original. The two guards of that place walk a patrol with loops of about 130 and 180 seconds, so the place where the player meets them still changes with the time. The original game does the same.

A test on the same day found one more fault, and it is fixed. The time that a guard stays at a patrol point changed with the frame rate. One guard of the first dock stayed 7.5 seconds with 30 frames per second, which is the frame rate of the tests, and 5.5 seconds with 60 and with 120. These script functions did not work as in the original:

- `Sleep` ended at the first tick after the sleep time. The original ends it at the tick that is nearest to the sleep time.
- `FinishAnim` waited one tick when there was no animation to wait for. The original then goes on in the same tick.
- `WaitForLanding` waited one tick when the person did not fall.
- `TurnTo` and `TurnToward` started the turn one tick late.

The animation step of an actor now follows the original also. A saved game now keeps the remaining time of a sleep.

At some patrol points the pause time is the same as the time at which the idle animation of the guard starts a new loop. The point of that guard is such a point, with 5.5 seconds. There the guard walks on at once when the pause ends before the new loop. When the pause ends after the start of the new loop, the guard waits 2 seconds more for the end of the animation. In real play the frame time is not exact, so the guard stays 5.5 or 7.5 seconds there. The rule of the original gives the same two results. With exactly 30, 60 or 120 frames per second the guard stays 5.5 seconds.

No person has reported on these parts yet:

- Sound by ear. The test runs are muted or go to a file.
- Mouse look in real play. The tests send input without the mouse capture.
- Fullscreen. The tests run in a window, and no test covers the fullscreen switch.
- A full mission from start to end.

Known gaps:

- A save game has no picture. The original also makes no picture with its OpenGL renderer.
- A saved game from a build before the second play of 2026-10-12 does not have the goals, the notes and the keys of the player in it. The engine loads such a saved game without them and writes a line to the log.
- A text field with more than one line, such as a note, has no moves of the insertion point by row, and its insertion mark has the height of the field.
- The program uses about 15 MB more memory after each map change. The engine frees the geometry, the lightmaps and the textures of a map that it left, but it has no garbage collector for the objects of that map.
- The engine draws a wall that the camera sees from behind. The original does not. So a camera of a cutscene that is outside a room shows a black picture, for example in some camera moves of the dance club ending.
- The Effects Channels setting applies at the next start.
- Multiplayer is not tested.

## Play

### What you need

- A Mac with Apple Silicon and macOS 15 or later. This is the only platform with tests: one machine, an M2 Max with macOS 15. Intel Macs, Windows and Linux are not tested. The app builder and the test tools are for macOS only.
- Your own copy of Deus Ex, Game of the Year Edition (version 1112fm). The Steam edition and the GOG edition have the files. This repository has no game files.
- The Xcode command line tools, CMake and Ninja to build the app (`brew install cmake ninja`). There is no ready app to download at this time.

### Step 1: get the game files

Deus Ex is a Windows game, so Steam on a Mac does not install it. You need the folder of the Windows version. It is the folder that has `System`, `Maps`, `Textures`, `Sounds` and `Music` in it.

Only the first of these ways was used in this project:

1. Copy the folder from a Windows or Linux computer where Steam installed the game. Steam keeps it in `steamapps/common/Deus Ex`.
2. Use the console of Steam on your Mac (not tested here). Open the address `steam://open/console` in a browser, and type this command in the console of Steam. App 6910 is the Game of the Year Edition and 6911 is its file depot. Steam prints the folder of the download when it is complete.

   ```
   download_depot 6910 6911
   ```

3. Download the Windows files with SteamCMD (not tested here):

   ```bash
   steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir "$HOME/Games/Deus Ex" +login YOUR_STEAM_NAME +app_update 6910 validate +quit
   ```

4. Extract the GOG offline installer with `innoextract` (not tested here).

Put the folder at `~/Games/Deus Ex`. The app finds it there with no question. A different place is also possible, and the app then asks for it. The folder must be in a place where you can write, because the engine keeps its settings and the save games in the game folder.

The tests of this project used one copy of the game: the Steam edition with the conversation files of the GMDX mod. A copy with no mod has the original files, but it was not tested here.

### Step 2: build the app

```bash
git clone --recurse-submodules https://github.com/poltak/deus-ex-mac.git
```

```bash
cd deus-ex-mac
```

The engine fork is the `SurrealEngine` folder. The first command downloads MoltenVK, the library that gives Vulkan on a Mac.

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

### Step 3: start the game

Open `dist/Deus Ex.app`.

At the first start the app looks for the game folder. If it does not find one, a dialog asks you to select it. Select the folder that has `System` and `Maps` in it. The app stores your selection in `~/Library/Application Support/DeusExMac/gamefolder.txt`. Delete that file to select a different folder.

The app looks in these places, in this order:

1. The folder in the environment variable `DEUSEX_GAME_FOLDER`. This is for one start.
2. The folder from the last start.
3. A `DeusEx` or `Deus Ex` folder next to the app.
4. The `DeusEx` folder at the top of this working copy. A developer can put the game folder there, and git ignores it.
5. `~/Library/Application Support/Steam/steamapps/common/Deus Ex`, `~/Games/Deus Ex`, `~/Documents/Deus Ex` and `/Applications/Deus Ex`.

The game folder does not need the original `DeusEx.exe`. A folder where a mod launcher replaced that file also works.

When the game folder is in your Documents, Desktop or Downloads folder, macOS asks at the first start if the app can open files there. It asks again after each new build of the app, because a new build has a new signature.

### Controls and settings

- The first start opens a window that is the largest whole multiple of 640x480 pixels that fits on your screen. The game scales its screens by whole numbers, as the original does.
- Settings, Display, Screen Resolution in the game changes the size of the window. The list has each whole multiple of 640x480 pixels that fits on your screen. The engine keeps the size for the next start.
- Settings, Display, Toggle Full-Screen Mode and the green button of the window switch between the window and fullscreen.
- The window size and the fullscreen switch are also in `System/SE-DeusEx.ini` in the game folder, section `[Engine.SurrealClient]`: `WindowedViewportX`, `WindowedViewportY` (in points) and `StartupFullscreen`.
- The key bindings are the ones of the game. Change them in the game under Settings, Keyboard/Mouse. The engine saves them in `System/SE-User.ini`.
- The engine does not change `DeusEx.ini` and `User.ini` of the game. It keeps its own copies with the prefix `SE-`.
- T opens the talk line, which is also the console. To turn the cheats on, press T, delete `Say`, and type `set DeusExPlayer bCheatsEnabled True`.
- The console command `timedemo 1` shows the frame rate.

### Developer loader

The developer loader starts the game in a map that you select, with the weapons and the player values that you select. It shows no menu and no intro.

To open the loader, hold the Option key while the app starts. You can also start the app with the `--loader` option:

```bash
open "dist/Deus Ex.app" --args --loader
```

The loader window has these controls:

- Map: the maps of your game folder with their mission. A double click on a map, or the Enter key, starts the game.
- Start point: the default start of the map, or one of the places where a map exit of the game puts the player.
- Weapons: a checkbox for each of the 24 weapons, and a list with weapon sets (No weapons, New game, Quiet, Heavy, All weapons).
- Full ammunition: each selected weapon gets all of its ammunition types, and each type is full.
- Other things: the count of medkits, bioelectric cells, lockpicks and multitools.
- Player: one level for all skills, the difficulty, the credits, all augmentations at their top level, god mode, and the cheat commands of the console.

The Start button starts the game. The loader keeps your selections in `~/.config/SurrealEngine/DeusExLoader.json` and shows them the next time. The Main menu button starts the game as it starts with no loader, and the Quit button starts no game.

The player gets the selected things one second after the map starts, by the pickup rules of the game. The game shows its pickup messages for them. A thing that has no room in the inventory lies at the feet of the player.

A start through the loader is a new game. It removes the map states of the game in progress (`Save/Current` in the game folder), and your saved games stay as they are. The story flags of the missions before the selected map are not set, so some conversations can be different from a full play.

### Game files with mods

The engine uses `System/DeusEx.u` of the game folder, so the folder must have the original script packages.

GMDX installs its conversation files over the original ones. A game folder with GMDX in it runs, and the first infolink then tries to give an object that only GMDX has. The log shows `Could not spawn class: null` for it. The original game does the same with these files.

## Develop

### Layout

- `SurrealEngine/` is the engine fork (git submodule, branch `master` of [poltak/SurrealEngine](https://github.com/poltak/SurrealEngine)).
- `DeusEx/` is the place for your game folder, or for a link to it. Git ignores it. The tests read the game data from it and write nothing into it, and the app in `dist/` plays from it.
- `packaging/` has the start script and the `Info.plist` of the app.
- `tests/` has input scripts for the test harness of the fork.
- `tools/` has the scripts to run tests, to open the developer loader, to measure speed and to read the original DLLs.
- `analysis/exports/` has the export table of each original DLL.
- `runs/` gets the log and the pictures of each test run. Git ignores it.
- `re-out/` gets the raw decompiler output. Git ignores it.

### Run a test

```bash
tools/run-dx.sh m01 60 --url=01_NYC_UNATCOIsland
```

The first argument is the name of the run and the second is the time in seconds of game time. The log and the pictures go to `runs/m01/`. A test run makes no sound and does not take the keyboard or the mouse.

The engine of a test starts as a child process of the test script, and its window opens behind the windows of the active app. A test does not use the `open` command: macOS gives a program that `open` starts its own permissions, and it then asks the person at the computer for the Documents folder after each new build.

A run repeats exactly. The game advances a fixed time for each frame with a fixed random seed, and it starts only when the window has its size, because the size of the view changes which actors the player sees. A run is also faster than real time, and it does not wait for the display after each frame (`VSYNC=1` turns that wait on).

`SCRIPT=tests/<name>.txt` gives the run an input script. Each line has a time and a command: keys, mouse clicks, console commands, pictures, commands that list actors, flags, goals, interface windows and the inventory, and commands that set a flag or send a trigger event to actors. The file `SurrealEngine/SurrealEngine/Harness.h` has the full list. The `key` command gives a key to the engine. The `oskey` command sends a key with its macOS key code through the window, as the real keyboard does, so a test with it also covers the key table of the macOS window code.

A run gets a new game folder in the state of a first start, `runs/<name>/game/`. It has links to the data in `DeusEx/`, copies of the ini files of the game and no saved games. So a run does not change your settings and your saved games in `DeusEx/`. `tools/fresh-game.sh <new folder>` makes such a folder, and `GAME=<folder>` gives a run a folder to use, for example when a second run must load the saved game of the first.

`APP="dist/Deus Ex.app"` runs the packaged app and its start script.

### Developer loader in a test

```bash
tools/loader.sh
```

This opens the loader window with the engine build of this working copy and plays in `DeusEx/`. `GAME=<game folder>` selects a different game folder.

The engine option `--loadout=<file>` starts the game with the selections of a JSON file and with no window. The file has the format of `DeusExLoader.json`. Its `Items` list can have each inventory class of the game, also a class that the window has no control for. A map of the `--url` option comes before the map of the file, so one file can serve for many maps. `LOADOUT=<file>` gives a test run that option:

```bash
LOADOUT=tests/loader-loadout.loadout.json SCRIPT=tests/loader-loadout.txt tools/run-dx.sh loadout 6
```

`LOADER_SCRIPT=<file>` opens the loader window in a test run and uses it with the commands of the file: a click at a place of the window, a key, a picture of the window, and a log line with the selections. A click goes through macOS into the window, as a click of the real mouse does. `tests/loader-window.loader.txt` is such a file.

### Regression tests

```bash
tools/regress.sh
```

This runs the scripted tests and prints one line for each. Each test gets its own new game folder in the state of a first start, so the result of a test does not depend on the tests before it. The save game tests are a chain that uses one folder, because the later tests load the saved games of the earlier tests. The line has the count of script errors, the last inventory list and the total count of script calls. The totals are the same in each run of a test, so a difference shows a change of behavior.

A test can have a file `tests/<name>.expect`. Each line of that file is a pattern that the log of the test must have. The test fails when a line is missing. A line that starts with `!` is a pattern that the log must not have. The harness command `windows` writes the visible interface windows to the log, with the text of text windows, the row count of lists, the state of checkboxes and the position of scroll bars. The command `dump` writes properties of actors. With these two commands a test can check what a screen shows and what the game state is.

A test with a file `tests/<name>.loadout.json` starts through the developer loader with the selections of that file. With a file `tests/<name>.loader.txt`, the loader window opens first and gets the commands of that file.

A test runs with 30 frames per second. A line of `tools/regress.sh` can give a run a different frame rate and the input script of a different test, so one script can run with more than one frame rate. `tests/npc-patrol-pause.txt` runs with 30, 60, 60.06 and 59.94 frames per second:

```bash
FIXED_FPS=60 SCRIPT_NAME=npc-patrol-pause run npc-patrol-pause-60 20 --url=01_NYC_UNATCOIsland
```

Such a run uses `tests/<name>.expect` when that file is there, and the `.expect` file of the script when it is not.

To run only some tests, give their names. A test of a chain also runs the tests before it in the chain:

```bash
tools/regress.sh computer-email menu-scroll
```

```bash
tests/start-script-test.sh
```

This tests the start script of the app with a fake engine and fake dialogs.

```bash
tests/app-start-test.sh
```

This starts the packaged app as a player does, with no setting that tells it where the game is. The test uses a copy of the layout of this working copy and a temporary home folder. The app must find the game folder, start the game and store the folder.
A second case is a new player: the game folder is at `~/Games/Deus Ex` of the temporary home folder, with the settings file of a Steam copy that asks for fullscreen. The app must find the folder, and the first start must open a window.

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

- The original SurrealEngine project asks that changes made with AI tools stay in a fork. All engine changes are in the fork, [poltak/SurrealEngine](https://github.com/poltak/SurrealEngine). Do not open a pull request to the original project with them.
- Game data comes from your own copy of Deus Ex. Do not commit it.
- Do not commit raw decompiler output of the original DLLs. Commit only your own code and notes.

## License

The tools, the tests and the documents of this repository have the zlib license. See [LICENSE](LICENSE).

The engine fork in `SurrealEngine/` is a changed version of SurrealEngine. It has the license of SurrealEngine, which is also the zlib license, and the licenses of the libraries that it uses. See `SurrealEngine/LICENSE.md`.

Deus Ex and its files belong to their owners. This repository has no game files.
