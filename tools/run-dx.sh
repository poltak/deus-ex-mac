#!/bin/bash
# Usage: run-dx.sh <run-name> <seconds> [extra SurrealEngine args...]
# Starts Deus Ex in the local SurrealEngine build with the test harness, then prints a summary.
# The game advances 1/FIXED_FPS seconds per frame (default 30) with a fixed random seed, so a run repeats exactly
# and runs faster than real time. <seconds> and the script times are game time.
# A test run makes no sound. Set MUTE=0 to hear it.
# Environment: MUTE=0, FIXED_FPS=<n>, SEED=<n>, WINSIZE=<W>x<H> (or "none": keep the size that the engine selects), FOREGROUND=1 (start in front, default is background), SCRIPT=<input script file>, SHOT_INTERVAL=<seconds, 0 = off>, SHOT_FIRST=<seconds>, LOG_HEAD=<lines>
# STATS=0: do not show the frame rate and object counts on the screen. WATCHDOG=<seconds>: time limit for a run that hangs.
# VSYNC=1: wait for the display after each frame, as a normal start does.
# GAME=<game folder> (default DeusEx/), APP=<path of a packaged "Deus Ex.app">: test the packaged app and its start script, not the engine build.
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SECS="$2"; shift 2
R="$W/runs/$NAME"; rm -rf "$R"; mkdir -p "$R"
B="$W/SurrealEngine/build/SurrealEngine.app/Contents/MacOS/SurrealEngine"
GAME="${GAME:-$W/DeusEx}"
SCRIPT_ARG=()
# The engine starts in a different folder, so give it the full path of the input script.
case "$SCRIPT" in
  "") ;;
  /*) SCRIPT_ARG=(--script="$SCRIPT") ;;
  *) SCRIPT_ARG=(--script="$PWD/$SCRIPT") ;;
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
ARGS=(--nograb "${MUTE_ARG[@]}" "${STATS_ARG[@]}" "${VSYNC_ARG[@]}" --logfile="$R/log.txt" --shots="$R" --shot-interval="${SHOT_INTERVAL:-5}" --shot-first="${SHOT_FIRST:-3}" --exit-after="$SECS" "${WINSIZE_ARG[@]}" --fixed-fps="${FIXED_FPS:-30}" --seed="${SEED:-1}" "${SCRIPT_ARG[@]}" "$@")
# ENGINE_ENV="NAME=value NAME2=value2": environment variables for the engine process
ENV_ARG=()
for pair in $ENGINE_ENV; do ENV_ARG+=(--env "$pair"); done
if [ -n "$APP" ]; then
  # The start script of the app adds --direct and the game folder. An error opens the error window of the engine, as it does for a player.
  open -g -n -W --stdout "$R/stdout.txt" --stderr "$R/stderr.txt" --env "DEUSEX_GAME_FOLDER=$GAME" "$APP" --args "${ARGS[@]}" &
  WAITER=$!
elif [ -n "$FOREGROUND" ]; then
  "$B" --nolauncher "${ARGS[@]}" "$GAME" > "$R/stdout.txt" 2> "$R/stderr.txt" &
  WAITER=$!
else
  # -g starts the app in the background, so the test window does not take the keyboard focus from the person at the computer.
  open -g -n -W --stdout "$R/stdout.txt" --stderr "$R/stderr.txt" "${ENV_ARG[@]}" "$W/SurrealEngine/build/SurrealEngine.app" --args --nolauncher "${ARGS[@]}" "$GAME" &
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
if [ -n "$PID" ] && command -v aerospace >/dev/null 2>&1 && aerospace list-windows --all >/dev/null 2>&1; then
  ( for i in $(seq 1 40); do
      ID=$(aerospace list-windows --all --format '%{window-id}|%{app-pid}' 2>/dev/null | grep "|$PID\$" | cut -d'|' -f1 | head -1)
      if [ -n "$ID" ]; then aerospace layout --window-id "$ID" floating >/dev/null 2>&1; break; fi
      sleep 0.25
    done
    touch "$R/window-ready" ) &
else
  touch "$R/window-ready"
fi
# A run that hangs gets a kill signal after the game time plus WATCHDOG seconds (default 120) of real time
( sleep $((SECS + ${WATCHDOG:-120})); [ -n "$PID" ] && kill -9 $PID 2>/dev/null ) 2>/dev/null &
WD=$!
wait $WAITER; RC=$?
{ kill $WD; wait $WD; } 2>/dev/null
# "open" does not pass the exit code of the app on. A run that ended correctly logs "Shutting down".
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
