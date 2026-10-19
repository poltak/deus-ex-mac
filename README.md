# deus-ex-mac

Run the original Deus Ex (2000, Game of the Year Edition, build 1112fm) as a native program on an Apple Silicon Mac.

The game does not get a new binary port. The engine is a fork of [SurrealEngine](https://github.com/dpjudas/SurrealEngine), an open-source reimplementation of Unreal Engine 1 that runs on macOS. It loads the original maps, scripts, textures and sounds of your own copy of the game. Where SurrealEngine has missing or incorrect Deus Ex behavior, [REA](https://github.com/morluto/rea) with Ghidra shows what the original Windows DLLs do, and the fork implements that behavior again.

The fork is at [poltak/SurrealEngine](https://github.com/poltak/SurrealEngine), and it is the `SurrealEngine` submodule of this repository. Claude Opus 5.5, an AI model of Anthropic, wrote the changes of the fork and the tools and tests of this repository.

This repository has no game data. You need your own copy of Deus Ex.

## State on 2026-10-19

Scripted tests on an M2 Max show that these parts work:

- Start screen, main menu, new game, intro.
- Conversations and infolinks: text, choices, the transfer of objects, mouth shapes.
- Enemies and allies: patrol, see and hear the player, attack, flee. Animals wander, and so do persons and robots that have the order to wander. A guard on patrol takes the same way at each frame rate. A guard that comes after the player with the "run and fire" move has its full speed. A guard with a pistol goes to a place from which the player is in the range of its weapon, and it fires from there. A person that walks stays upright when its target is above or below it. A person that the player did not see for 5 seconds, and that is more than 600 units away, does not look for enemies other than the player. So guards and robots do not fight in places that the player cannot see.
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
- Contacts of the player: the player slides along a person, a door, a wall and a thing that it cannot push when it touches them at an angle, also on stairs. It pushes a light thing when it walks against the middle of it, and it slides past the thing when it touches its side.
- The start of a map: a body that the map has from the start keeps its things hidden until the player searches it, a gun turret that hangs from a ceiling stays there, and a glass plate with an attach tag has its target as base.
- Stasis: a thing or a person that the player did not see for 5 seconds, and that is far away or in a room that is not in view, stops until the player comes back. The scripts of the game are written for this rule of the original engine. The engine counts a thing as seen when a part of its rectangle on the screen is free of the level geometry in front of it, as the original renderer does.
- The music: the calm, combat and conversation parts of a song, the fades between them, and the return to the place where the calm part stopped.
- The vision augmentation shows people as bright shapes.
- The animated fire textures of the game: flames, static, laser beams, fountains, lightning.
- Walls from behind: the engine does not draw a wall that the camera sees from behind, and such a wall hides nothing, as in the original. A cutscene camera that is outside a room shows the room. An example is the dance club ending, where the camera moves up through the ceiling and shows the dancers from above.
- Mirrors: a mirror shows the player and the room in front of it, and it shows nothing of the room behind its wall. The tests use the two bathroom mirrors of the 'Ton hotel.
- All 88 map files of the game start with no error.
- Developer loader: a window that selects a map, a start point, the weapons and the values of the player, and starts the game there. See "Developer loader" below.
- A controller: the sticks move and aim, with the same turn speed at 30 and at 120 frames per second. The buttons give the actions of the game, and LB gives a second layer with the augmentations. The D-pad and A work the menus and the answers of a conversation, the right stick moves the mouse cursor on the inventory screen, and the Keyboard/Mouse Settings screen binds a controller button. See "Controller" below.

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

A test on 2026-10-13 found that a guard on patrol took a different way at a different frame rate. The second guard of the first dock went from one patrol point to the next on a south way with 30 frames per second, and on a north way, which takes 1.7 seconds longer, with 60 and with 120. The engine sent a person in a straight line to a navigation point that was far away, and its test for that straight line gave a different result when the person stood 0.08 units away. Now the engine has the path search of the original (`findPathToward`, `findPathTo` and `breadthPathFrom` of `Engine.dll`). A person that stands on a navigation point takes the next point on the shortest way along the reach specs of the map, so its way does not change with the frame rate. The guard makes the same path searches with 30, 60 and 120 frames per second.

The engine has the reach tests of the original also (`actorReachable`, `pointReachable`, `walkReachable`, and the tests for a person that flies, swims or jumps). A reach test tells if a person can go to a place in a straight line. As in the original, the test goes through other persons and through objects such as crates, and a person as the goal counts as reached from some distance. A person that stands on a navigation point and asks for a second point gets the answer from the reach specs.

The same work found an older fault, and it is fixed. A person looks for a new place with a direction test of the engine (`AIDirectionReachable`). The test moves the person in one direction and gives the last place in a range of distances. Before the fix it never found a place. So a guard in a fight found no firing place and ran from navigation point to navigation point until it stood next to the player, and a robot or a person with the order to wander did not move. Now a guard with a pistol stops where the player is in the range of its weapon and fires from there, it strafes, and it runs to the player when it changes to its knife. The medical robot of the UNATCO HQ moves around its room.

The wall contacts of a pawn now follow the original also (`processHitWall` of `Engine.dll`). The original has a filter between a wall contact and the script event `HitWall`. A contact with a person gives no event, and a pawn with no acceleration gets no event. A wall counts for a pawn only when it faces against the way of the pawn to its destination. A pawn that has no `HitWall` function in its state gets no event for such a wall, and its move ends. An actor that falls onto a floor and does not bounce gets the event `Landed` only. Before, the engine called the event `HitWall` for each contact.

The move of the player after a contact now follows the original also (`APawn::stepUp` of `Engine.dll`). A test on 2026-10-13 found two faults there:

- A player that walked at an angle into an actor stopped dead. The actor can be a person, a door or a thing that the player cannot push, such as the police boat of the first dock. The engine had no rule for a contact of the player with an actor.
- A player that walked up stairs at an angle into the side wall stopped in front of the next step. The engine did the slide along the wall after the move down from the height of a step, and the next step was in the way there.

The original moves the pawn up by the height of a step, makes the rest of the move and the slide there, and then moves the pawn down. This rule is the same for the level and for an actor. Now the player slides along each of these things, also on stairs.

The rule for a thing that the player can push changed also. The player pushes the thing when the contact is not more than 26 degrees away from head-on, as in the original. At a larger angle the player slides past the thing and gives it a short push. Before, the test for head-on used the length of the move, so the player pushed the thing at almost each angle and did not slide past it.

A person played all of Liberty Island on 2026-10-18 and found seven faults. All seven are fixed:

- The crouch failed on many floors, and the camera then went below the floor. The crouch script makes the collision cylinder of the player smaller and moves the player down with `Move` until the feet touch the floor. The original `Move` (`ULevel::MoveActor` of `Engine.dll`) gives true when the actor moved some part of the distance. This engine gave true only for the full distance, and on many floors the collision code gives such a move a fraction a little below 1. Then the script made the player full height again, with the feet 27 units down in the floor. The walk physics then lifted the player at each step and the script put the player down again, and the eye height script moved the camera down by the same distance in each frame. Before the fix, the camera of a test went 192 units below the feet of the player at the first step of the wide stairs.
- The sniper rifle hurt nobody. Its shot is a line test of 48000 units. The line test of the engine looked for actors only when the line was shorter than 100 cells of the actor grid (25600 units) on each axis, so the shot could hit only level geometry. Now the line test looks at the cells along the line in parts of one cell. The pistol and the crossbow have shorter lines, so they worked before.
- The guards did not come to a laser alarm. This was a result of the crouch fault: the place of the alarm is under the feet of the person who breaks the beam, so it was under the floor, and the guards found no way to it. Now the guards near the laser door of the statue come to the door. As in the original, a guard hears the alarm only when the player saw it in the last 5 seconds or when it is less than 1200 units from the player, and when it is not in stasis.
- The dark background of the pause menu covered only a 4:3 part in the middle of a wide screen. The root window of the interface is a 4:3 box in this engine, and the menu draws its background texture on the root window. Now the background of the root window covers the full screen, as the root window of the original does.
- A speech line that the player skipped with the mouse played to its end, together with the next line. The script of a conversation plays a line through the person who speaks and stops it with `player.StopSound`. The original `StopSound` uses only the sound id, and this engine also wanted the actor of the request to be the actor of the sound. A new harness command `sounds` lists the sounds that play.
- The weapon of the player went into a wall near the camera. The original clears the depth buffer before the `RenderOverlays` event, in which the weapon is drawn (`URender::DrawWorld` of `Render.dll`). This engine did not.
- The electric arcs of the box in the basement of Liberty Island did not show, and the laser beams of the statue door did not show either. A beam is drawn by a `LaserIterator` (native code of `DeusEx.dll`), which puts the `LaserProxy` mesh at each 16-unit segment of the beam. An electric arc moves each segment by a random amount. The engine did not have this iterator. All segments of a beam use one light list, so a view of the five laser beams costs about 0.4 ms of processor time for each frame.

No person has reported on these parts yet:

- Sound by ear. The test runs are muted or go to a file.
- Mouse look in real play. The tests send input without the mouse capture.
- Fullscreen and the free mouse on the menus. The tests run in a hidden window that never has the keyboard focus, so no test covers the menu bar, the fullscreen switch or the mouse of macOS.
- A real controller. The tests use a test controller of the harness, and the speeds of the sticks need a person to tune them.
- A full mission from start to end.

Known gaps:

- A save game has no picture. The original also makes no picture with its OpenGL renderer.
- A saved game from a build before the second play of 2026-10-12 does not have the goals, the notes and the keys of the player in it. The engine loads such a saved game without them and writes a line to the log.
- A text field with more than one line, such as a note, has no moves of the insertion point by row, and its insertion mark has the height of the field.
- The program uses about 15 MB more memory after each map change. The engine frees the geometry, the lightmaps and the textures of a map that it left, but it has no garbage collector for the objects of that map.
- A mirror does not show a second mirror. When mirrors with different planes are in view at the same time, the engine makes one mirror picture, with the plane of one of them, for all of them. The original makes a picture for each mirror, and it shows a mirror in a mirror.
- The second guard of the first dock of Liberty Island walks against the side of a container on its first way after the start of the map, and it pushes against it for 12 seconds. Then it goes back one navigation point and passes. The rules of the original for these steps are in the engine: a person stops less than 16 units before a navigation point, the reach spec of that place is for a radius of 21 units on the exact line between its two points, the guard has a radius of 20, and a wall contact does not end the move of a person. With these rules the straight way of the guard goes into the container by up to 3 units. So the original guard does the same in all probability, but no test with the original program confirmed it.
- The reach tests and the direction test use the collision code of this engine for their test steps. A place that is very narrow can give a different answer than in the original.
- Only the player has the move of the original after a contact. A person, an animal or a robot that walks still has the older code. It slides after the move down from the height of a step, so the next step of stairs can stop it when it slides along a wall or an actor, as it stopped the player. It reports a wall contact to its script for a vertical wall only, and the original reports a contact also for a slope that stops the pawn.
- For a pawn that flies or swims, the original tries a step up before it reports a contact with a vertical wall, and this engine does not.
- The controller has no on-screen keyboard. The login of a computer needs the keyboard for the user name and the password.
- The HUD and the help texts show keyboard keys, for example F3 next to an augmentation icon.
- A small push of the left stick does not walk. The player gets to the full speed later, but at each position of the stick. L3 changes between walk and run.
- The controller has no rumble, and the engine reads a controller only on macOS.
- The speed with which the player pushes a thing changes with the frame rate. With a trash can it is about 100 units in a second with 30 frames per second, 50 with 60 and 83 with 120. The rule of the original takes a part of the velocity of the player in each frame with a contact. So the original has this property in all probability, but no test with the original program confirmed it.
- The Effects Channels setting applies at the next start.
- The setting UI/Menu Background has the values "Render 3D", "Snapshot" and "Black". Only the default "Render 3D", which makes the game view darker, is tested. The engine has no draw code for the raw background of the root window (`SetRawBackground`), so "Snapshot" shows no snapshot.
- An electric arc can show one extra segment for one frame at a place of the arc of the frame before. The renderer also draws the proxy mesh of a beam as a normal actor, at the random segment where the iterator left it. The original renderer in all probability does the same, but no test with the original program confirmed it.
- Multiplayer is not tested.

## Play

### What you need

- A Mac with Apple Silicon and macOS 15 or later. Intel Macs are not supported. All tests ran on one machine, an M2 Max with macOS 15.
- Your own copy of Deus Ex, Game of the Year Edition (version 1112fm), from Steam or GOG. Both stores sell only the Windows version, and the app plays the files of that version. You do not need Windows or Wine.
- The app from the [releases page](https://github.com/poltak/deus-ex-mac/releases). You do not need build tools. To build the app yourself, see [Build the app](#build-the-app).

You do these steps one time:

1. Download the app.
2. Get the game files.
3. Open the app for the first time.

### Step 1: download the app

1. Open the [latest release](https://github.com/poltak/deus-ex-mac/releases/latest) and download `DeusEx-mac-<version>.zip`.
2. Open the zip, if your browser did not open it. Safari opens a zip after the download.
3. Move `Deus Ex.app` into your Applications folder. Do this before you open the app for the first time.

The app has no game files in it. It has the engine and its libraries, and it is approximately 30 MB.

### Step 2: get the game files

The app needs the game folder of the Windows version. This folder is approximately 750 MB, and it has these folders in it:

```
System    (with DeusEx.u in it)
Maps
Textures
Sounds
Music
```

Put the game folder at `~/Games/Deus Ex`. This is the folder `Deus Ex` in the folder `Games` of your home folder. The app finds it there and does not ask you for it. The app can also use a different place, and then it asks you to select the folder at the first start. Do not use a place where you cannot write, because the game keeps its settings and saved games in the game folder.

Use one of these ways to get the game folder. This project used only way B for its tests. Way A uses the same download as way B. Way C is not tested here.

#### Way A: Steam on this Mac

The Mac version of Steam does not install Deus Ex, because Steam has no Mac version of the game. But the console of Steam can download the Windows files of a game that you own.

1. Open Steam and log in with the account that owns Deus Ex.
2. Open the Terminal app, and type this command. It opens the console of Steam.

   ```bash
   open steam://open/console
   ```

3. In the console of Steam, type this command and press Enter. App 6910 is Deus Ex: Game of the Year Edition, and depot 6911 is its game files.

   ```
   download_depot 6910 6911
   ```

   The console shows no progress. When the download is complete, it shows `Depot download complete` and the folder of the download.
4. Move the downloaded folder to `~/Games/Deus Ex` with these Terminal commands:

   ```bash
   mkdir -p ~/Games
   ```

   ```bash
   mv ~/Library/Application\ Support/Steam/steamapps/content/app_6910/depot_6911 ~/Games/Deus\ Ex
   ```

If you do not move the folder, the app also finds it at its download place.

#### Way B: copy the folder from a Windows or Linux computer

On a Windows or Linux computer where Steam installed Deus Ex, the game folder is `steamapps/common/Deus Ex` in the Steam folder. On Windows, this is usually `C:\Program Files (x86)\Steam\steamapps\common\Deus Ex`. Copy the full folder to `~/Games/Deus Ex` on your Mac.

#### Way C: the GOG installer

GOG sells only the Windows version. The installer is an `.exe` file, and the program `innoextract` can unpack it on a Mac.

1. On the GOG website, open your games library, select Deus Ex GOTY Edition, and download the offline backup installer for Windows (`setup_deus_ex_goty_<version>.exe`).
2. Install Homebrew from [brew.sh](https://brew.sh), if you do not have it. Then install innoextract:

   ```bash
   brew install innoextract
   ```

3. Unpack the installer to `~/Games/Deus Ex`:

   ```bash
   innoextract --gog -d ~/Games/Deus\ Ex ~/Downloads/setup_deus_ex_goty_*.exe
   ```

4. Look for the `System` folder. If it is in a folder `app` in `~/Games/Deus Ex`, then `~/Games/Deus Ex/app` is the game folder. Select that folder when the app asks for the game folder.

#### Check the game folder

This Terminal command shows the file `DeusEx.u` if the game folder is in the correct place:

```bash
ls ~/Games/Deus\ Ex/System/DeusEx.u
```

The game folder does not need the original `DeusEx.exe`. A folder where a mod launcher replaced that file also works. See [Game files with mods](#game-files-with-mods).

### Step 3: open the app for the first time

The app has no signature from an Apple developer account, so macOS stops it at the first start. You must let it open one time:

1. Open `Deus Ex.app` in your Applications folder. macOS shows a message that it cannot verify the app. Click Done. Do not click Move to Trash.
2. Open the Apple menu, then System Settings, then Privacy & Security.
3. Go down to the Security part. It shows a message that "Deus Ex" was blocked. Click Open Anyway, and type your password.
4. macOS asks one more time. Click Open Anyway.

You can also use one Terminal command for this. It removes the download mark from the app, and then macOS does not stop it:

```bash
xattr -dr com.apple.quarantine /Applications/Deus\ Ex.app
```

You must do this again after you install a new version of the app.

The app then looks for the game folder. If it does not find one, a dialog asks you to select it. Select the folder that has `System` and `Maps` in it. The app stores your selection in `~/Library/Application Support/DeusExMac/gamefolder.txt`. Delete that file to select a different folder.

The app looks in these places, in this order:

1. The folder in the environment variable `DEUSEX_GAME_FOLDER`. This is for one start.
2. The folder from the last start.
3. A `DeusEx` or `Deus Ex` folder next to the app.
4. The `DeusEx` folder at the top of a working copy of this repository. A developer can put the game folder there, and git ignores it.
5. `~/Games/Deus Ex`, `~/Documents/Deus Ex`, `/Applications/Deus Ex`, the Steam folder `~/Library/Application Support/Steam/steamapps/common/Deus Ex` and the download folder of way A.

When the game folder is in your Documents, Desktop or Downloads folder, macOS asks at the first start if the app can open files there. It asks again after each new version of the app. A game folder in `~/Games` does not cause this question.

### A new version

Download the new zip and put the new `Deus Ex.app` in your Applications folder in place of the old one. Then do step 3 again. Your settings and saved games stay, because they are in the game folder.

### Controls and settings

- The first start opens a window that is the largest whole multiple of 640x480 pixels that fits on your screen. The game scales its screens by whole numbers, as the original does.
- Settings, Display, Screen Resolution in the game changes the size of the window. The list has each whole multiple of 640x480 pixels that fits on your screen. The engine keeps the size for the next start.
- To switch between the window and fullscreen, use one of these:
  - View, Enter Full Screen in the menu bar, or Control-Command-F, or Fn-F.
  - Settings, Display, Toggle Full-Screen Mode in the game.
  - The green button of the window.
- In the game, the window holds the mouse for the view. While a menu, a screen of the game or a conversation is open, the mouse is free, and the cursor of the game follows it. Then you can move the mouse to the title bar, the green button or the menu bar, also in fullscreen. Press Escape for the main menu.
- The window lets go of the mouse when you switch to a different app.
- Command-Q and the red button stop the game and save the settings. Command-H hides the game and Command-M minimizes the window.
- The engine keeps the window size and the fullscreen state for the next start. They are also in `System/SE-DeusEx.ini` in the game folder, section `[Engine.SurrealClient]`: `WindowedViewportX`, `WindowedViewportY` (in points) and `StartupFullscreen`.
- The key bindings are the ones of the game. Change them in the game under Settings, Keyboard/Mouse. The engine saves them in `System/SE-User.ini`.
- The engine does not change `DeusEx.ini` and `User.ini` of the game. It keeps its own copies with the prefix `SE-`.
- T opens the talk line, which is also the console. To turn the cheats on, press T, delete `Say`, and type `set DeusExPlayer bCheatsEnabled True`.
- The console command `timedemo 1` shows the frame rate.

### Controller

The engine reads a controller through the Game Controller framework of macOS. That framework supports Xbox, PlayStation and Switch Pro controllers. Connect the controller in System Settings, Bluetooth, before or during play. The controller works while the game window is the active window. The tests use a test controller, and no person has played with a real controller yet.

In the game:

| Control | Action |
|---|---|
| Left stick | Move |
| Right stick | Turn and look up and down |
| RT | Fire, or use the item in the hand |
| LT | Use the thing in front of you: open, pick up, talk |
| A | Jump |
| B | Crouch |
| X | Reload |
| Y | Change the ammo |
| RB | Scope on and off |
| L3 | Walk or run |
| R3 | Light (F12) |
| D-pad left and right | The item before or after the item in the hand on the belt |
| D-pad up | Goals and notes |
| D-pad down | Put the item in the hand away |
| Back (View, Share, Minus) | Inventory |
| Start (Menu, Options, Plus) | Main menu |

Hold LB for the second layer:

| Control | Action |
|---|---|
| LB + D-pad up, right, down, left | Augmentations F3, F4, F5, F6 |
| LB + Y, B, A, X | Augmentations F7, F8, F9, F10 |
| LB + RB | Augmentation F11 |
| LB + LT, LB + RT | Lean left, lean right |
| LB + L3 | Drop the item in the hand |
| LB + R3 | Laser sight on and off |
| LB + Start | Quick save |
| LB + Back | Quick load |

The HUD shows the F key of each augmentation next to its icon.

On a screen of the game, for example a menu, the inventory, a conversation, a computer or a keypad:

| Control | Action |
|---|---|
| D-pad, left stick | Arrow keys: move the focus, select an answer |
| A | Enter |
| B, Back, Start | Escape |
| X | Backspace. On the inventory screen it drops the selected item. |
| Y | Delete |
| Right stick | Move the mouse cursor |
| RT, LT | Left and right mouse button. Hold RT to drag an item. |
| LB, RB | Mouse wheel up and down |

To bind a button in the game, open Settings, Keyboard/Mouse, select the function, press A and then the button. While the screen waits for the button, Start stops the wait.

The bindings are in `System/SE-User.ini` of the game folder, section `[Extension.InputExt]`. The engine writes this file when the game stops, so change it while the game does not run. The names of the controls are those of the joystick keys of the original engine:

- `Joy1` to `Joy4` are A, B, X and Y. `Joy5` is LB, `Joy6` RB, `Joy7` Back, `Joy8` Start, `Joy9` L3, `Joy10` R3, `Joy11` LT and `Joy12` RT.
- `JoyPovUp`, `JoyPovDown`, `JoyPovLeft` and `JoyPovRight` are the D-pad.
- `JoyX` and `JoyY` are the left stick, `JoyU` and `JoyV` the right stick. The `Speed` of `JoyU` and `JoyV` (280 and 200) sets the speed of the turn and of the look up and down. A negative `Speed` for `JoyV` turns the vertical look the other way.
- A name with `Layer` in front, for example `LayerJoy1`, is the binding while LB is down. A button with no `Layer` binding does its usual action while LB is down.

The section `[SurrealEngine.Gamepad]` has three settings:

- `DeadZone=0.15`: the part of the way of a stick, from the middle, that has no effect.
- `LookCurve=2.0`: a larger number makes small movements of the right stick slower, for exact aim. 1.0 is a straight line.
- `CursorSpeed=480`: the speed of the mouse cursor on a screen, in interface units per second. The screen is 640 units wide.

The engine writes these bindings and settings one time, at the first start of this version. They take the place of the joystick bindings of the original game, which are for a joystick of the year 2000. The original Windows game reads such a joystick only when `UseJoystick` is on in `DeusEx.ini`, and its menus need the mouse.

### Developer loader

The developer loader starts the game in a map that you select, with the weapons and the player values that you select. It shows no menu and no intro.

To open the loader, hold the Option key while the app starts. You can also start the app with the `--loader` option:

```bash
open "/Applications/Deus Ex.app" --args --loader
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
- `packaging/` has the start script, the `Info.plist`, the license list and the release text of the app.
- `.github/workflows/release.yml` builds the app and makes a draft release for a version tag.
- `tests/` has input scripts for the test harness of the fork.
- `tools/` has the scripts to run tests, to open the developer loader, to measure speed and to read the original DLLs.
- `analysis/exports/` has the export table of each original DLL.
- `runs/` gets the log and the pictures of each test run. Git ignores it.
- `re-out/` gets the raw decompiler output. Git ignores it.

### Build the app

You need the Xcode command line tools, CMake and Ninja (`brew install cmake ninja`).

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

The result is `dist/Deus Ex.app`. It has the engine, its libraries and the license texts in it (`Contents/Resources/Licenses`), and no game data. It plays from the `DeusEx` folder of the working copy, if that folder has the game. macOS does not stop an app that you built on your Mac, so step 3 of [Play](#play) is not necessary for it.

### Make a release

The workflow `.github/workflows/release.yml` builds the app on an Apple Silicon Mac of GitHub. GitHub has no game data, so the workflow runs only `tests/start-script-test.sh`. Do these steps:

1. Run the regression tests on a Mac with the game (`tools/regress.sh`).
2. Push a tag with the version:

   ```bash
   git tag v0.1.0
   ```

   ```bash
   git push origin v0.1.0
   ```

3. The workflow makes a draft release with `DeusEx-mac-<version>.zip`, its SHA-256 checksum and the text of `packaging/release-notes.md`. Download the zip, and start the app from it on a Mac with the game.
4. Publish the draft on the releases page of GitHub.

The Run workflow button of the workflow on GitHub builds the zip with no release. The zip is then an artifact of the workflow run.

### Run a test

```bash
tools/run-dx.sh m01 60 --url=01_NYC_UNATCOIsland
```

The first argument is the name of the run and the second is the time in seconds of game time. The log and the pictures go to `runs/m01/`. A test run makes no sound, shows no window and does not take the keyboard or the mouse.

The engine of a test starts as a child process of the test script, with a hidden window: the window is fully transparent, the mouse goes through it, the engine has no icon in the Dock, and a window manager such as AeroSpace does not take the window. The engine draws into the window as usual, so the pictures and the results of a test are the same. `VISIBLE=1` shows the window behind the windows of the active app, and `FOREGROUND=1` shows it in front. A test does not use the `open` command: macOS gives a program that `open` starts its own permissions, and it then asks the person at the computer for the Documents folder after each new build.

A run repeats exactly. The game advances a fixed time for each frame with a fixed random seed, and it starts only when the window has its size, because the size of the view changes which actors the player sees. A run is also faster than real time, and it does not wait for the display after each frame (`VSYNC=1` turns that wait on).

`SCRIPT=tests/<name>.txt` gives the run an input script. Each line has a time and a command: keys, mouse clicks, console commands, pictures, commands that list actors, flags, goals, interface windows and the inventory, and commands that set a flag or send a trigger event to actors. The file `SurrealEngine/SurrealEngine/Harness.h` has the full list. The `key` command gives a key to the engine. The `pad` command gives the input of a test controller: a button, a stick position or a trigger position. A run with a script does not read the real controller. The `oskey` command sends a key with its macOS key code through the window, as the real keyboard does, so a test with it also covers the key table of the macOS window code.

The engine option `--tracepath=<name>` writes log lines for the person with that name. A `path` line for each path search has the place of the person, the goal, the navigation point that the person stands on (`on`) or the nearest point that it can go to (`from`), and the next point of the way (`next`). A `reach` line for each reach test of the script has the goal and the answer. A `direction` line for each direction test has the direction, the range of distances and the place that the test found. A `hitwall` line for a wall contact has the actor of the wall, the normal of the wall, and the result of the filter before the script event. The same `hitwall` line comes one time in a second at most. `tests/npc-patrol-path.txt`, `tests/enemy-run.txt`, `tests/player-wall-hit.txt` and `tests/npc-wall-hit.txt` use the option.

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

This runs the scripted tests and prints one line for each. Each test gets its own new game folder in the state of a first start, so the result of a test does not depend on the tests before it. Six tests run at the same time (`JOBS=6`, the default). Each one has its own game folder and its own hidden window, and the game advances a fixed time for each frame, so the results are the same as with `JOBS=1`, which runs one test after the other. A line comes when its test ends, and at the end the full list comes again in the order of the script. The save game tests are a chain that uses one folder, because the later tests load the saved games of the earlier tests. The line has the count of script errors, the last inventory list and the total count of script calls. The totals are the same in each run of a test, so a difference shows a change of behavior.

A test can have a file `tests/<name>.expect`. Each line of that file is a pattern that the log of the test must have. The test fails when a line is missing. A line that starts with `!` is a pattern that the log must not have. The harness command `windows` writes the visible interface windows to the log, with the text of text windows, the row count of lists, the state of checkboxes and the position of scroll bars. The command `dump` writes properties of actors. With these two commands a test can check what a screen shows and what the game state is. The command `visible` writes how many level surfaces and actors the last frame showed, so a test can also check the picture of the level.

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
