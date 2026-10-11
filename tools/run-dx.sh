#!/bin/bash
# Usage: run-dx.sh <run-name> <seconds> [extra SurrealEngine args...]
# Starts Deus Ex in the local SurrealEngine build with the test harness, then prints a summary.
# Environment: SCRIPT=<input script file>, SHOT_INTERVAL=<seconds, 0 = off>, SHOT_FIRST=<seconds>, LOG_HEAD=<lines>
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SECS="$2"; shift 2
R="$W/runs/$NAME"; rm -rf "$R"; mkdir -p "$R"
B="$W/SurrealEngine/build/SurrealEngine.app/Contents/MacOS/SurrealEngine"
cd "$W/DeusEx/System" || exit 2
SCRIPT_ARG=()
[ -n "$SCRIPT" ] && SCRIPT_ARG=(--script="$SCRIPT")
"$B" --nolauncher --nograb --logfile="$R/log.txt" --shots="$R" --shot-interval="${SHOT_INTERVAL:-5}" --shot-first="${SHOT_FIRST:-3}" --exit-after="$SECS" --winsize="${WINSIZE:-2048x1536}" "${SCRIPT_ARG[@]}" "$@" "$W/DeusEx" > "$R/stdout.txt" 2> "$R/stderr.txt" &
PID=$!
# AeroSpace (tiling window manager) resizes new windows. Make this one window float. This changes no configuration.
if command -v aerospace >/dev/null 2>&1; then
  ( for i in $(seq 1 40); do
      ID=$(aerospace list-windows --all --format '%{window-id}|%{app-pid}' 2>/dev/null | grep "|$PID\$" | cut -d'|' -f1 | head -1)
      if [ -n "$ID" ]; then aerospace layout --window-id "$ID" floating >/dev/null 2>&1; break; fi
      sleep 0.25
    done ) &
fi
( sleep $((SECS + 90)); kill -9 $PID 2>/dev/null ) 2>/dev/null &
WD=$!
wait $PID; RC=$?
{ kill $WD; wait $WD; } 2>/dev/null
echo "exit code: $RC"
for f in "$R"/*.bmp; do [ -f "$f" ] && sips -s format png -Z 1100 "$f" --out "${f%.bmp}.png" >/dev/null 2>&1 && rm -f "$f"; done
echo "log lines: $(wc -l < "$R/log.txt")   shots: $(ls "$R" | grep -c png)"
echo "--- FATAL / stderr (no MoltenVK noise)"
grep -a "FATAL" "$R/log.txt" "$R/stderr.txt" | cut -c1-400 | head -5
echo "--- unimplemented (unique)"
grep -a -o "Unimplemented: .*" "$R/log.txt" | sort | uniq -c | sort -rn | head -40
echo "--- other log lines (unique, no 'Accessed None' stacks)"
grep -a -v "Unimplemented\| at .* line [0-9]*:\|Accessed None\|Harness: \|<SE>: \(Vulkan\|Core.u\|Engine.u\|SHA1\|Loaded\|Audio\|Closing\|Saving\|Shutting\|Game:\)\|InputExt" "$R/log.txt" | sed 's/^\[[0-9.]*\] //' | sort | uniq -c | sort -rn | head -${LOG_HEAD:-40} | cut -c1-220
