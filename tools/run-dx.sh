#!/bin/bash
# Usage: run-dx.sh <run-name> <seconds> [extra SurrealEngine args...]
# Starts Deus Ex in the local SurrealEngine build with the test harness, then prints a summary.
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SECS="$2"; shift 2
R="$W/runs/$NAME"; rm -rf "$R"; mkdir -p "$R"
B="$W/SurrealEngine/build/SurrealEngine.app/Contents/MacOS/SurrealEngine"
cd "$W/DeusEx/System" || exit 2
"$B" --nolauncher --nograb --logfile="$R/log.txt" --shots="$R" --shot-interval="${SHOT_INTERVAL:-5}" --shot-first="${SHOT_FIRST:-3}" --exit-after="$SECS" "$@" "$W/DeusEx" > "$R/stdout.txt" 2> "$R/stderr.txt" &
PID=$!
( sleep $((SECS + 90)); kill -9 $PID 2>/dev/null ) &
WD=$!
wait $PID; RC=$?
kill $WD 2>/dev/null
echo "exit code: $RC"
for f in "$R"/shot*.bmp; do [ -f "$f" ] && sips -s format png -Z 1100 "$f" --out "${f%.bmp}.png" >/dev/null 2>&1 && rm -f "$f"; done
echo "log lines: $(wc -l < "$R/log.txt")   shots: $(ls "$R" | grep -c png)"
echo "--- FATAL / stderr (no MoltenVK noise)"
grep -a "FATAL" "$R/log.txt" "$R/stderr.txt" | cut -c1-400 | head -5
echo "--- unimplemented (unique)"
grep -a -o "Unimplemented: .*" "$R/log.txt" | sort | uniq -c | sort -rn | head -40
echo "--- other log lines (unique, no 'Accessed None' stacks)"
grep -a -v "Unimplemented\| at .* line [0-9]*:\|Accessed None\|Harness: wrote" "$R/log.txt" | sed 's/^\[[0-9.]*\] //' | sort | uniq -c | sort -rn | head -${LOG_HEAD:-40} | cut -c1-220
