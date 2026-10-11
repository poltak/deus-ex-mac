#!/bin/bash
# heap-growth.sh [first] [second]: run tests/memory.txt with allocation stack logging, take a snapshot of the live
# allocations after the "mem" lines number <first> and <second> (default 5 and 11), and print which call stacks
# hold more memory in the second snapshot. This shows what the engine keeps for each map change.
W="$(cd "$(dirname "$0")/.." && pwd)"
A="${1:-5}"; B="${2:-11}"
OUT="$W/runs/heap-growth"; mkdir -p "$OUT"
( ENGINE_ENV="MallocStackLogging=lite" FIXED_FPS=60 SCRIPT="$W/tests/memory.txt" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" memhist 130 --url=01_NYC_UNATCOIsland > /dev/null 2>&1 & )
count() { grep -a -c 'Harness: mem resident' "$W/runs/memhist/log.txt" 2>/dev/null || echo 0; }
sleep 3
for n in "$A" "$B"; do
  while [ "$(count | tail -1)" -lt "$n" ]; do sleep 1; done
  PID=$(pgrep -n -f "MacOS/SurrealEngine.*--logfile=$W/runs/memhist/log.txt")
  malloc_history "$PID" -allBySize > "$OUT/snapshot-$n.txt" 2>&1
done
pkill -9 -f "MacOS/SurrealEngine.*runs/memhist/log.txt"
python3 -I "$W/tools/heap-growth.py" "$OUT/snapshot-$A.txt" "$OUT/snapshot-$B.txt"
