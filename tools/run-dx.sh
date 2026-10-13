#!/bin/bash
# Usage: run-dx.sh <run-name> <seconds> [extra SurrealEngine args...]
# Starts Deus Ex in the local SurrealEngine build with the test harness, then prints a summary.
# The game advances 1/FIXED_FPS seconds per frame (default 30) with a fixed random seed, so a run repeats exactly
# and runs faster than real time. <seconds> and the script times are game time.
# A test run makes no sound and shows no window. Set MUTE=0 to hear it and VISIBLE=1 to see it.
# Environment: MUTE=0, FIXED_FPS=<n>, SEED=<n>, WINSIZE=<W>x<H> (or "none": keep the size that the engine selects), VISIBLE=1 (show the window behind the windows of the active app, default is a hidden window), FOREGROUND=1 (show the window in front), SCRIPT=<input script file>, SHOT_INTERVAL=<seconds, 0 = off>, SHOT_FIRST=<seconds>, LOG_HEAD=<lines>
# STATS=0: do not show the frame rate and object counts on the screen. WATCHDOG=<seconds>: time limit for a run that hangs.
# VSYNC=1: wait for the display after each frame, as a normal start does.
# GAME=<game folder>: use this folder for the settings and the saved games of the run. Without it, the run gets a new
# game folder in the state of a first start (runs/<run-name>/game, see tools/fresh-game.sh). The run reads the game data
# from DeusEx/ and writes nothing into it, so the tests do not change the settings and the saved games of the player.
# LOADOUT=<file>: start through the developer loader with the selections of this JSON file (--loadout).
# LOADER_SCRIPT=<file>: open the loader window and use it with the commands of this file (--loader --loader-script).
# APP=<path of a packaged "Deus Ex.app">: test the packaged app and its start script, not the engine build.
# APP_HOME=<folder> (with APP): give the app this folder as home folder, and do not tell it where the game is. The start
# script of the app must then find the game folder as it does for a player (tests/app-start-test.sh).
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SECS="$2"; shift 2
R="$W/runs/$NAME"; rm -rf "$R"; mkdir -p "$R"
B="$W/SurrealEngine/build/SurrealEngine.app/Contents/MacOS/SurrealEngine"
if [ -z "$GAME" ] && [ -z "$APP_HOME" ]; then GAME="$("$W/tools/fresh-game.sh" "$R/game")" || exit 2; fi
SCRIPT_ARG=()
# The engine starts in a different folder, so give it the full path of the input script.
case "$SCRIPT" in
  "") ;;
  /*) SCRIPT_ARG=(--script="$SCRIPT") ;;
  *) SCRIPT_ARG=(--script="$PWD/$SCRIPT") ;;
esac
# The developer loader (DevLoader.h of the engine fork). The engine needs full paths here also.
LOADER_ARG=()
case "$LOADOUT" in
  "") ;;
  /*) LOADER_ARG+=(--loadout="$LOADOUT") ;;
  *) LOADER_ARG+=(--loadout="$PWD/$LOADOUT") ;;
esac
case "$LOADER_SCRIPT" in
  "") ;;
  /*) LOADER_ARG+=(--loader --loader-script="$LOADER_SCRIPT") ;;
  *) LOADER_ARG+=(--loader --loader-script="$PWD/$LOADER_SCRIPT") ;;
esac
MUTE_ARG=(--mute)
[ "$MUTE" = 0 ] && MUTE_ARG=()
STATS_ARG=(--stats)
[ "$STATS" = 0 ] && STATS_ARG=()
# A visible window waits for the display after each frame, and a hidden one does not. Without that wait a frame time
# is only the work of the engine, and a run is faster.
VSYNC_ARG=(--novsync)
[ "$VSYNC" = 1 ] && VSYNC_ARG=()
# The engine does not start the game before the file $R/window-ready is there. See the window manager step below.
WINSIZE_ARG=(--winsize="${WINSIZE:-1280x960}" --wait-file="$R/window-ready")
[ "$WINSIZE" = none ] && WINSIZE_ARG=()
ARGS=(--nograb "${MUTE_ARG[@]}" "${STATS_ARG[@]}" "${VSYNC_ARG[@]}" --logfile="$R/log.txt" --shots="$R" --shot-interval="${SHOT_INTERVAL:-5}" --shot-first="${SHOT_FIRST:-3}" --exit-after="$SECS" "${WINSIZE_ARG[@]}" --fixed-fps="${FIXED_FPS:-30}" --seed="${SEED:-1}" "${SCRIPT_ARG[@]}" "${LOADER_ARG[@]}" "$@")
# ENGINE_ENV="NAME=value NAME2=value2": environment variables for the engine process
ENV_ARG=()
for pair in $ENGINE_ENV; do ENV_ARG+=("$pair"); done
# The engine starts as a child of this script, not through LaunchServices (the "open" command). A program that
# LaunchServices starts is responsible for its own file access. macOS then asks the person at the computer for
# permission when the program opens a file in the Documents, Desktop or Downloads folder, and it asks again for each
# new build, because a new build has a new signature. A child of this script uses the permission of the program that
# runs the script, so a test opens no permission dialog.
# SURREAL_NO_ACTIVATE keeps the engine from making itself the active app, so a test does not take the keyboard focus.
# SURREAL_HIDDEN_WINDOW hides the windows of the engine from the person at the computer: a window is fully
# transparent, the mouse goes through it, the engine has no icon in the Dock, and a window manager does not take the
# window. The engine draws into the window as usual, so the pictures and the results of a test are the same.
# VISIBLE=1 shows the window behind the windows of the active app. FOREGROUND=1 shows it in front.
HIDDEN=""
if [ -z "$FOREGROUND" ]; then
  ENV_ARG+=("SURREAL_NO_ACTIVATE=1")
  if [ "$VISIBLE" != 1 ]; then HIDDEN=1; ENV_ARG+=("SURREAL_HIDDEN_WINDOW=1"); fi
fi
if [ -n "$APP" ]; then
  # The program of the app is its start script. It adds --direct and the game folder. An error opens the error window
  # of the engine, as it does for a player.
  if [ -n "$APP_HOME" ]; then ENV_ARG+=("HOME=$APP_HOME"); else ENV_ARG+=("DEUSEX_GAME_FOLDER=$GAME"); fi
  EXE="$APP/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")"
  env "${ENV_ARG[@]}" "$EXE" "${ARGS[@]}" > "$R/stdout.txt" 2> "$R/stderr.txt" &
  WAITER=$!
else
  env "${ENV_ARG[@]}" "$B" --nolauncher "${ARGS[@]}" "$GAME" > "$R/stdout.txt" 2> "$R/stderr.txt" &
  WAITER=$!
fi
PID=""
for i in $(seq 1 40); do
  PID=$(pgrep -n -f "MacOS/SurrealEngine.*--logfile=$R/log.txt")
  [ -n "$PID" ] && break
  sleep 0.25
done
# AeroSpace (tiling window manager) resizes new windows. Make this one window float. This changes no configuration.
# The size of the window changes what the game does, so the engine waits for the file window-ready before it starts
# the game. Then each run of a test gives the same result.
# AeroSpace does not take the small window of an app that is not the active app (a run in the background), so the
# wait for the window is short. With FOREGROUND=1, and with the large window of WINSIZE=none, it takes the window, and
# the wait is longer.
# AeroSpace does not take a hidden window, so a hidden run does not wait for it.
AERO_TRIES=8
if [ -n "$FOREGROUND" ] || [ "$WINSIZE" = none ]; then AERO_TRIES=40; fi
if [ -n "$HIDDEN" ]; then
  touch "$R/window-ready"
elif [ -n "$PID" ] && command -v aerospace >/dev/null 2>&1 && aerospace list-windows --all >/dev/null 2>&1; then
  ( for i in $(seq 1 $AERO_TRIES); do
      ID=$(aerospace list-windows --all --format '%{window-id}|%{app-pid}' 2>/dev/null | grep "|$PID\$" | cut -d'|' -f1 | head -1)
      if [ -n "$ID" ]; then aerospace layout --window-id "$ID" floating >/dev/null 2>&1; break; fi
      sleep 0.25
    done
    touch "$R/window-ready" ) &
else
  touch "$R/window-ready"
fi
# A run that hangs gets a kill signal after the game time plus WATCHDOG seconds (default 120) of real time
# The sleep is a child of the watchdog. The trap stops it with the watchdog, or it would hold the output of this
# script open until its time is over.
( trap 'kill $SP 2>/dev/null; exit 0' TERM; sleep $((SECS + ${WATCHDOG:-120})) & SP=$!; wait $SP; [ -n "$PID" ] && kill -9 $PID 2>/dev/null ) 2>/dev/null &
WD=$!
wait $WAITER; RC=$?
{ kill $WD; wait $WD; } 2>/dev/null
# A run that ended correctly logs "Shutting down"
if grep -a -q "Shutting down" "$R/log.txt" 2>/dev/null; then
  echo "run ended correctly"
else
  echo "RUN DID NOT END CORRECTLY (crash, fatal error or watchdog)"
  IPS=$(ls -t "$HOME/Library/Logs/DiagnosticReports"/SurrealEngine-*.ips 2>/dev/null | head -1)
  if [ -n "$IPS" ] && [ "$IPS" -nt "$R/stdout.txt" ]; then
    python3 -I - "$IPS" <<'PYEOF'
import json, sys
hdr, body = open(sys.argv[1]).read().split("\n", 1)
d = json.loads(body)
print("crash:", d.get("exception", {}).get("type"), d.get("exception", {}).get("subtype", ""))
t = [t for t in d["threads"] if t.get("triggered")][0]
for f in t["frames"][:14]:
    print("   ", f.get("symbol", "?")[:110], f.get("sourceFile", ""), f.get("sourceLine", ""))
PYEOF
  fi
fi
for f in "$R"/*.bmp; do [ -f "$f" ] && sips -s format png -Z 1100 "$f" --out "${f%.bmp}.png" >/dev/null 2>&1 && rm -f "$f"; done
echo "log lines: $(wc -l < "$R/log.txt")   shots: $(ls "$R" | grep -c png)"
echo "--- FATAL / stderr (no MoltenVK noise)"
grep -a "FATAL" "$R/log.txt" "$R/stderr.txt" | cut -c1-400 | head -5
echo "--- unimplemented (unique)"
grep -a -o "Unimplemented: .*" "$R/log.txt" | sort | uniq -c | sort -rn | head -40
echo "--- other log lines (unique, no 'Accessed None' stacks)"
grep -a -v "Unimplemented\| at .* line [0-9]*:\|Accessed None\|Harness: \|<SE>: \(Vulkan\|Core.u\|Engine.u\|SHA1\|Loaded\|Audio\|Closing\|Saving\|Shutting\|Game:\)\|InputExt" "$R/log.txt" | sed 's/^\[[0-9.]*\] //' | sort | uniq -c | sort -rn | head -${LOG_HEAD:-40} | cut -c1-220
