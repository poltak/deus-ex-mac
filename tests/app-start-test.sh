#!/bin/bash
# app-start-test.sh: start the packaged app as a player does, with no setting that tells it where the game is.
# The test makes the layout of a working copy in runs/app-start-copy/: a copy of the app in dist/ and a game folder in
# the state of a first start as DeusEx/ (tools/fresh-game.sh). The start script of the app must find that game folder,
# start the game with it and store the folder. The app gets a temporary home folder, so the test does not read or
# change the stored game folder of the player. Build the app first: tools/make-app.sh
W="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="$W/dist/Deus Ex.app"
[ -d "$APP_SRC" ] || { echo "no app at $APP_SRC. Build it first: tools/make-app.sh"; exit 2; }
T="$W/runs/app-start-copy"
# Delete only a folder that this script made before
if [ -e "$T" ]; then
  [ -f "$T/.app-start-test" ] || { echo "$T is there and this script did not make it"; exit 2; }
  rm -rf "$T"
fi
mkdir -p "$T/dist" "$T/home" && touch "$T/.app-start-test" || exit 2
cp -R "$APP_SRC" "$T/dist/" || exit 2
"$W/tools/fresh-game.sh" "$T/DeusEx" > /dev/null || exit 2
FAILED=0
check() {
  if eval "$2"; then echo "ok: $1"; else echo "FAILED: $1"; FAILED=1; fi
}
APP="$T/dist/Deus Ex.app" APP_HOME="$T/home" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" app-start 5 --url=01_NYC_UNATCOIsland > "$W/runs/app-start.out" 2>&1
LOG="$W/runs/app-start/log.txt"
STORED="$T/home/Library/Application Support/DeusExMac/gamefolder.txt"
check "the run ended correctly" '[ "$(head -1 "$W/runs/app-start.out")" = "run ended correctly" ]'
check "the engine started Deus Ex" 'grep -a -q "Game: Deus Ex" "$LOG"'
check "the map started" 'grep -a -q "started mission state machine for 01_NYC_UNATCOISLAND" "$LOG"'
check "the engine used the game folder of the working copy" '[ -f "$T/DeusEx/System/SE-DeusEx.ini" ]'
check "the start script stored the game folder" '[ "$(cat "$STORED" 2>/dev/null)" = "$T/DeusEx" ]'

# Second case: a new player. The app is in a folder with no game folder near it, and the game folder is at
# ~/Games/Deus Ex with the settings file of a Steam copy that no person changed: it asks for fullscreen at the start.
# The app must find the folder, and the first start must open a window, because the fullscreen mode of the Windows
# game is not a mode of a Mac. This run does not set the window size, so the engine selects it.
mkdir -p "$T/elsewhere" "$T/home2/Games" || exit 2
cp -R "$APP_SRC" "$T/elsewhere/" || exit 2
NEWGAME="$T/home2/Games/Deus Ex"
"$W/tools/fresh-game.sh" "$NEWGAME" > /dev/null || exit 2
sed -i '' -e 's/^StartupFullscreen=.*/StartupFullscreen=True/' -e 's/^WindowedViewportX=.*/WindowedViewportX=640/' -e 's/^WindowedViewportY=.*/WindowedViewportY=480/' "$NEWGAME/System/DeusEx.ini"
APP="$T/elsewhere/Deus Ex.app" APP_HOME="$T/home2" WINSIZE=none SHOT_INTERVAL=0 "$W/tools/run-dx.sh" app-start-new 5 --url=01_NYC_UNATCOIsland > "$W/runs/app-start-new.out" 2>&1
LOG="$W/runs/app-start-new/log.txt"
STORED="$T/home2/Library/Application Support/DeusExMac/gamefolder.txt"
check "new player: the run ended correctly" '[ "$(head -1 "$W/runs/app-start-new.out")" = "run ended correctly" ]'
check "new player: the app found the game folder in ~/Games/Deus Ex and stored it" '[ "$(cat "$STORED" 2>/dev/null)" = "$NEWGAME" ]'
check "new player: the first start opened a window" 'grep -a -q "First start: window of " "$LOG"'
check "new player: the engine keeps the window mode for the next start" 'grep -q "^StartupFullscreen=False" "$NEWGAME/System/SE-DeusEx.ini"'
check "new player: the map started" 'grep -a -q "started mission state machine for 01_NYC_UNATCOISLAND" "$LOG"'
[ "$FAILED" = 0 ] && echo "app start test passed"
exit $FAILED
