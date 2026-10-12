#!/bin/bash
# regress.sh: run the scripted tests that start a new game and print one line for each.
# A test passes this check when the run ends correctly and the log has no script error.
# The pictures and the logs are in runs/reg-<test>/ for a closer look.
# Each test gets a new game folder in the state of a first start (tools/fresh-game.sh). So the result of a test does
# not depend on the tests before it, and the tests put no saved games and no settings into the game folder.
# The tests of a chain use one folder, because a later test of the chain needs the saved games of the tests before it.
# The totals of script calls are the same in each run. A difference shows a change of behavior.
# A test can have a file tests/<test>.expect. Each line of it is a pattern (grep -E) that the log must have.
# A line that starts with "!" is a pattern that the log must not have.
# With test names as arguments, the script runs only these tests: tools/regress.sh computer-email keys
W="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${GAME:-$W/DeusEx}"
FAILED=0
SELECTED=" $* "
selected() {
  [ "$SELECTED" = "  " ] && return 0
  case "$SELECTED" in *" $1 "*) return 0 ;; esac
  return 1
}
run_one() {
  local name="$1" secs="$2"; shift 2
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
      case "$pattern" in
        "!"*)
          if grep -a -q -E -- "${pattern#!}" "$log"; then
            missing=$((missing + 1))
            echo "$name: the log has a line for a pattern that it must not have: ${pattern#!}"
          fi ;;
        *)
          if ! grep -a -q -E -- "$pattern" "$log"; then
            missing=$((missing + 1))
            echo "$name: the log has no line for the pattern: $pattern"
          fi ;;
      esac
    done < "$W/tests/$name.expect"
    checks=", checks $((total - missing)) of $total"
  fi
  echo "$name: $ended, accessed none $none, errors $errors$checks${perf:+, $perf}${inv:+, last inventory: $inv}"
  [ "$ended" = "run ended correctly" ] && [ "$errors" = 0 ] && [ "$missing" = 0 ] || FAILED=1
}
# chain "<test> <seconds> [engine arguments]" ...: run these tests in this order in one new game folder.
# When the arguments of this script select a test of a chain, the tests before it in the chain run also.
chain() {
  local members=("$@") last=0 i
  for i in "${!members[@]}"; do
    if selected "${members[$i]%% *}"; then last=$((i + 1)); fi
  done
  [ "$last" -gt 0 ] || return 0
  GAME="$("$W/tools/fresh-game.sh" "$W/runs/reg-game" "$SRC")" || exit 2
  export GAME
  for ((i = 0; i < last; i++)); do
    # The words of a member are the arguments of run_one
    # shellcheck disable=SC2086
    run_one ${members[$i]}
  done
}
# run <test> <seconds> [engine arguments]: run one test in a new game folder
run() { chain "$*"; }
run newgame 34
run m01-interact 40
# menu-load and load-cold load the quick save of save-load, and the list of the Load Game screen has the saved games of menu-save
chain "save-load 40" "travel 60" "menu-save 34" "menu-load 40" "load-cold 20"
run ai-wander 30
run particles 12 --url=01_NYC_UNATCOIsland
run keys 31
run input-held-key 13 --url=01_NYC_UNATCOIsland
run input-mac-keys 16 --url=01_NYC_UNATCOIsland
run console 12 --url=01_NYC_UNATCOIsland
run perf-m01 26 --url=01_NYC_UNATCOIsland
run m01-paul-choice 130 --url=01_NYC_UNATCOIsland
run m01-mission-complete 14 --url=01_NYC_UNATCOIsland
run m01-boat-to-m02 24 --url=01_NYC_UNATCOIsland
run m02-briefing 67 --url=02_NYC_BatteryPark
run menu-settings 28
run aug-vision 11 --url=01_NYC_UNATCOIsland
run persona-screens 27 --url=01_NYC_UNATCOIsland
run player-health 27
run persona-skill-upgrade 12 --url=01_NYC_UNATCOIsland
run persona-inventory 16 --url=01_NYC_UNATCOIsland
run player-medbot 11 --url=01_NYC_UNATCOHQ
run player-repairbot 11 --url=01_NYC_UNATCOHQ
run player-aug-install 16 --url=01_NYC_UNATCOHQ
run fire-textures 9 --url=01_NYC_UNATCOIsland
run player-weapons 110 --url=01_NYC_UNATCOIsland
run player-swim 41 --url=01_NYC_UNATCOIsland
run player-moves 18 --url=01_NYC_UNATCOIsland
run player-ladder 17 --url=01_NYC_UNATCOIsland
run player-landing 16 --url=01_NYC_UNATCOIsland
run player-elevator 12 --url=03_NYC_AirfieldHeliBase
run map-start 8 --url=01_NYC_UNATCOIsland
run map-attach 3 --url=00_TrainingCombat
run actor-stasis 12 --url=01_NYC_UNATCOIsland
run player-fight 19 --url=01_NYC_UNATCOIsland
run enemy-run 21 --url=01_NYC_UNATCOIsland
run save-fight 30 --url=01_NYC_UNATCOIsland
run player-reload 22 --url=01_NYC_UNATCOIsland
run player-objects 18 --url=01_NYC_UNATCOIsland
run player-keydoor 12 --url=01_NYC_UNATCOIsland
run player-lockpick 19 --url=01_NYC_UNATCOIsland
run player-multitool 16 --url=01_NYC_UNATCOIsland
run player-death 30 --url=01_NYC_UNATCOIsland
run computer-email 17 --url=01_NYC_UNATCOHQ
run menu-scroll 23
run menu-keyboard 11
run menu-dialog 12 --url=01_NYC_UNATCOIsland
# menu-keys-restart reads the key bindings that menu-keys saved
chain "menu-keys 18 --url=01_NYC_UNATCOIsland" "menu-keys-restart 6 --url=01_NYC_UNATCOIsland"
run computer-login-keys 13 --url=01_NYC_UNATCOHQ
run computer-security 22 --url=01_NYC_UNATCOIsland
run computer-atm 16 --url=01_NYC_UNATCOIsland
run computer-hack 16 --url=01_NYC_UNATCOIsland
exit $FAILED
