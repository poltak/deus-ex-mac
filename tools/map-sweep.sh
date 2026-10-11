#!/bin/bash
# map-sweep.sh [seconds] [map name pattern]: start each map of the game for some seconds of game time (default 8) and
# write one line for each map to runs/map-sweep.txt: did the run end correctly, the count of errors in the log, the
# mean frame time and the native functions that are not implemented.
# A picture of each map is in runs/sweep-<map>/.
# A map starts at its default start point. If the player cannot stand there, the map starts again through the first
# map exit of the game that leads to it (tools/map-urls.py). WATCHDOG=<seconds> sets the time limit for a run that hangs.
W="$(cd "$(dirname "$0")/.." && pwd)"
SECS="${1:-8}"
PATTERN="${2:-.}"
OUT="$W/runs/map-sweep.txt"
SCRIPT_FILE="$W/runs/map-sweep-script.txt"
mkdir -p "$W/runs"
printf '2.0 perf\n%s.0 shot map\n%s.5 perf\n' "$((SECS - 2))" "$((SECS - 1))" > "$SCRIPT_FILE"
: > "$OUT"
run_map() {
  local map="$1" url="$2"
  FIXED_FPS=60 SCRIPT="$SCRIPT_FILE" SHOT_INTERVAL=0 WATCHDOG="${WATCHDOG:-40}" "$W/tools/run-dx.sh" "sweep-$map" "$SECS" --url="$url" > "$W/runs/sweep-$map.out" 2>&1
}
for f in "$W/DeusEx/Maps"/*.dx; do
  map="$(basename "$f" .dx)"
  echo "$map" | grep -q -i -E "$PATTERN" || continue
  url="$map"
  run_map "$map" "$url"
  log="$W/runs/sweep-$map/log.txt"
  if grep -a -q "Failed to spawn player actor" "$log" 2>/dev/null; then
    url="$(python3 -I "$W/tools/map-urls.py" "$W/DeusEx/Maps" "$map")"
    [ "$url" != "$map" ] && run_map "$map" "$url"
  fi
  ended="$(head -1 "$W/runs/sweep-$map.out")"
  errors="$(grep -a -c -i "script error\|FATAL\|Unknown native function" "$log" 2>/dev/null)"
  none="$(grep -a -c "Accessed None" "$log" 2>/dev/null)"
  ms="$(grep -a "perf frames" "$log" 2>/dev/null | tail -1 | sed -E 's/.* ms=([0-9.]+).*/\1/')"
  unimpl="$(grep -a -o "Unimplemented: .*" "$log" 2>/dev/null | sed 's/Unimplemented: //' | sort -u | tr '\n' ' ')"
  echo "$url | $ended | errors ${errors:-?} | accessed none ${none:-?} | ${ms:-?} ms | $unimpl" | tee -a "$OUT"
done
