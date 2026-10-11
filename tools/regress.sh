#!/bin/bash
# regress.sh: run the scripted tests that start a new game and print one line for each.
# A test passes this check when the run ends correctly and the log has no script error.
# The pictures and the logs are in runs/reg-<test>/ for a closer look.
W="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
run() {
  local name="$1" secs="$2"; shift 2
  SCRIPT="$W/tests/$name.txt" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" "reg-$name" "$secs" "$@" > "$W/runs/reg-$name.out" 2>&1
  local log="$W/runs/reg-$name/log.txt"
  local ended; ended=$(head -1 "$W/runs/reg-$name.out")
  local none; none=$(grep -a -c "Accessed None" "$log")
  local errors; errors=$(grep -a -c -i "script error\|FATAL\|Unknown native function" "$log")
  local perf; perf=$(grep -a "perf totals" "$log" | tail -1 | sed 's/.*perf totals //')
  echo "$name: $ended, accessed none $none, errors $errors${perf:+, $perf}"
  [ "$ended" = "run ended correctly" ] && [ "$errors" = 0 ] || FAILED=1
}
run newgame 34
run m01-interact 40
run save-load 40
run travel 60
run menu-save 34
run menu-load 40
run load-cold 20
run ai-wander 30
run particles 12 --url=01_NYC_UNATCOIsland
run perf-m01 26 --url=01_NYC_UNATCOIsland
exit $FAILED
