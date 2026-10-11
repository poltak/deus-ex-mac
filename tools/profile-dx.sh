#!/bin/bash
# profile-dx.sh <run-name> <output file> [engine args...]: run the game for 60 seconds of game time with the test
# harness and take an 8 second sample of the engine process with the macOS "sample" tool. tools/selfprof.py and
# tools/callers.py read the output file.
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; OUT="$2"; shift 2
( SHOT_INTERVAL=0 "$W/tools/run-dx.sh" "$NAME" 60 "$@" > /dev/null 2>&1 & )
sleep 8
PID=$(pgrep -n -f "MacOS/SurrealEngine.*--logfile=$W/runs/$NAME/log.txt")
[ -n "$PID" ] || { echo "the engine process was not found"; exit 1; }
sample "$PID" 8 -file "$OUT" > /dev/null 2>&1
echo "sample written to $OUT"
# Wait for the run to end so that the next run does not start while this one is active
while pgrep -f "MacOS/SurrealEngine.*--logfile=$W/runs/$NAME/log.txt" > /dev/null; do sleep 1; done
