#!/bin/bash
# regress.sh: run the scripted tests that start a new game and print one line for each.
# A test passes this check when the run ends correctly and the log has no script error.
# The pictures and the logs are in runs/reg-<test>/ for a closer look.
# Each run of this script uses a new game folder in the state of a first start (tools/fresh-game.sh). So the result
# does not depend on the runs before, and the tests put no saved games and no settings into the game folder.
# The totals of script calls are the same in each run. A difference shows a change of behavior.
# A test can have a file tests/<test>.expect. Each line of it is a pattern (grep -E) that the log must have.
# With test names as arguments, the script runs only these tests: tools/regress.sh computer-email keys
W="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$("$W/tools/fresh-game.sh" "$W/runs/reg-game" "${GAME:-$W/DeusEx}")" || exit 2
export GAME
FAILED=0
SELECTED=" $* "
run() {
  local name="$1" secs="$2"; shift 2
  if [ "$SELECTED" != "  " ]; then
    case "$SELECTED" in *" $name "*) ;; *) return ;; esac
  fi
  SCRIPT="$W/tests/$name.txt" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" "reg-$name" "$secs" "$@" > "$W/runs/reg-$name.out" 2>&1
  local log="$W/runs/reg-$name/log.txt"
  local ended; ended=$(head -1 "$W/runs/reg-$name.out")
  local none; none=$(grep -a -c "Accessed None" "$log")
  local errors; errors=$(grep -a -c -i "script error\|FATAL\|Unknown native function" "$log")
  local perf; perf=$(grep -a "perf totals" "$log" | tail -1 | sed 's/.*perf totals //')
  local inv; inv=$(grep -a "Harness: inv count" "$log" | tail -1 | sed 's/.*Harness: inv //')
  local checks="" missing=0 total=0 pattern
  if [ -f "$W/tests/$name.expect" ]; then
    while IFS= read -r pattern; do
      case "$pattern" in ""|"#"*) continue ;; esac
      total=$((total + 1))
      if ! grep -a -q -E -- "$pattern" "$log"; then
        missing=$((missing + 1))
        echo "$name: the log has no line for the pattern: $pattern"
      fi
    done < "$W/tests/$name.expect"
    checks=", checks $((total - missing)) of $total"
  fi
  echo "$name: $ended, accessed none $none, errors $errors$checks${perf:+, $perf}${inv:+, last inventory: $inv}"
  [ "$ended" = "run ended correctly" ] && [ "$errors" = 0 ] && [ "$missing" = 0 ] || FAILED=1
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
run keys 31
run console 12 --url=01_NYC_UNATCOIsland
run perf-m01 26 --url=01_NYC_UNATCOIsland
run m01-paul-choice 125 --url=01_NYC_UNATCOIsland
run menu-settings 28
run aug-vision 11 --url=01_NYC_UNATCOIsland
run persona-screens 27 --url=01_NYC_UNATCOIsland
run player-health 27
run fire-textures 9 --url=01_NYC_UNATCOIsland
run player-weapons 110 --url=01_NYC_UNATCOIsland
run player-swim 41 --url=01_NYC_UNATCOIsland
run player-lockpick 19 --url=01_NYC_UNATCOIsland
run player-multitool 16 --url=01_NYC_UNATCOIsland
run computer-email 17 --url=01_NYC_UNATCOHQ
run menu-scroll 23
run menu-keyboard 11
run computer-login-keys 13 --url=01_NYC_UNATCOHQ
run computer-security 22 --url=01_NYC_UNATCOIsland
run computer-atm 16 --url=01_NYC_UNATCOIsland
run computer-hack 16 --url=01_NYC_UNATCOIsland
exit $FAILED
