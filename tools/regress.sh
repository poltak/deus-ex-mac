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
# A test can have a file tests/<test>.loadout.json. The game then starts through the developer loader with the
# selections of that file. With a file tests/<test>.loader.txt, the loader window opens and gets the commands of that file.
# A line of this script can give a run a frame rate and the input script of a different test:
#   FIXED_FPS=60 SCRIPT_NAME=npc-patrol-pause run npc-patrol-pause-60 20
# That run uses tests/npc-patrol-pause.txt. It uses tests/npc-patrol-pause-60.expect when that file is there, and
# tests/npc-patrol-pause.expect when it is not. So one script can run with more than one frame rate.
# With test names as arguments, the script runs only these tests: tools/regress.sh computer-email keys
# JOBS=<n> (default 6) runs n tests or chains at the same time. The tests of a chain still run one after the other.
# The game advances a fixed time for each frame, so the results are the same as with JOBS=1. Each line comes when
# its test ends, and the full list in the order of this script comes at the end.
W="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${GAME:-$W/DeusEx}"
JOBS="${JOBS:-6}"
RES="$W/runs/reg-results"
rm -rf "$RES"; mkdir -p "$RES"
CHAINS=0
START=$(date +%s)
# A watcher writes each change of the app in front to runs/reg-results/focus.txt. A test must never be that app.
(
  last=""
  while :; do
    front="$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null | sed -n 's/.*="\(.*\)"/\1/p')"
    if [ "$front" != "$last" ]; then echo "$(( $(date +%s) - START )) s: ${front:-none}" >> "$RES/focus.txt"; last="$front"; fi
    sleep 0.2
  done
) &
FOCUS_WATCH=$!
disown $FOCUS_WATCH
SELECTED=" $* "
selected() {
  [ "$SELECTED" = "  " ] && return 0
  case "$SELECTED" in *" $1 "*) return 0 ;; esac
  return 1
}
run_one() {
  local name="$1" secs="$2"; shift 2
  local script="${SCRIPT_NAME:-$name}" expect="$W/tests/$name.expect"
  [ -f "$expect" ] || expect="$W/tests/$script.expect"
  local loadout="" loader_script=""
  [ -f "$W/tests/$name.loadout.json" ] && loadout="$W/tests/$name.loadout.json"
  [ -f "$W/tests/$name.loader.txt" ] && loader_script="$W/tests/$name.loader.txt"
  SCRIPT="$W/tests/$script.txt" LOADOUT="$loadout" LOADER_SCRIPT="$loader_script" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" "reg-$name" "$secs" "$@" > "$W/runs/reg-$name.out" 2>&1
  local log="$W/runs/reg-$name/log.txt"
  local ended; ended=$(head -1 "$W/runs/reg-$name.out")
  local none; none=$(grep -a -c "Accessed None" "$log")
  local errors; errors=$(grep -a -c -i "script error\|FATAL\|Unknown native function" "$log")
  local perf; perf=$(grep -a "perf totals" "$log" | tail -1 | sed 's/.*perf totals //')
  local inv; inv=$(grep -a "Harness: inv count" "$log" | tail -1 | sed 's/.*Harness: inv //')
  local checks="" missing=0 total=0 pattern
  if [ -f "$expect" ]; then
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
    done < "$expect"
    checks=", checks $((total - missing)) of $total"
  fi
  echo "$name: $ended, accessed none $none, errors $errors$checks${perf:+, $perf}${inv:+, last inventory: $inv}"
  [ "$ended" = "run ended correctly" ] && [ "$errors" = 0 ] && [ "$missing" = 0 ]
}
# chain "<test> <seconds> [engine arguments]" ...: run these tests in this order in one new game folder.
# When the arguments of this script select a test of a chain, the tests before it in the chain run also.
chain() {
  local members=("$@") last=0 i
  for i in "${!members[@]}"; do
    if selected "${members[$i]%% *}"; then last=$((i + 1)); fi
  done
  [ "$last" -gt 0 ] || return 0
  # Wait for a free place. bash 3.2 of macOS has no "wait -n".
  while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 0.2; done
  CHAINS=$((CHAINS + 1))
  local out="$RES/$CHAINS"
  (
    # Each chain has a game folder of its own, because chains run at the same time
    GAME="$("$W/tools/fresh-game.sh" "$W/runs/reg-game-${members[0]%% *}" "$SRC")" || { echo "${members[0]%% *}: no game folder" > "$out.txt"; touch "$out.failed"; exit 0; }
    export GAME
    for ((i = 0; i < last; i++)); do
      # The words of a member are the arguments of run_one
      # shellcheck disable=SC2086
      line="$(run_one ${members[$i]})" || touch "$out.failed"
      echo "$line" >> "$out.txt"
      echo "$line"
    done
  ) &
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
# A mouse click skips a speech line of Paul, and the line stops. See tests/talk-skip.txt.
run talk-skip 31 --url=01_NYC_UNATCOIsland
# The player crouches through the laser beams of the statue door, and the guards come. See tests/m01-laser-alarm.txt.
run m01-laser-alarm 15 --url=01_NYC_UNATCOIsland
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
# The laser beams of the statue door and the electric arcs of the box in the basement. See tests/render-laser.txt.
run render-laser 6 --url=01_NYC_UNATCOIsland
run render-backface 5 --url=99_Endgame4
run render-mirror 6 --url=02_NYC_Hotel
run player-weapons 110 --url=01_NYC_UNATCOIsland
run player-swim 41 --url=01_NYC_UNATCOIsland
run player-moves 18 --url=01_NYC_UNATCOIsland
# The crouch next to the wide stairs and a crouch walk up the stairs, with 30 and with 120 frames per second.
run player-crouch 14 --url=01_NYC_UNATCOIsland
FIXED_FPS=120 SCRIPT_NAME=player-crouch run player-crouch-120 14 --url=01_NYC_UNATCOIsland
run player-ladder 17 --url=01_NYC_UNATCOIsland
run player-landing 16 --url=01_NYC_UNATCOIsland
# A jump onto a platform on a roof of the NSF warehouse, with 30 and with 120 frames per second.
run player-jump-ledge 6 --url=02_NYC_Warehouse
FIXED_FPS=120 SCRIPT_NAME=player-jump-ledge run player-jump-ledge-120 6 --url=02_NYC_Warehouse
run player-elevator 12 --url=03_NYC_AirfieldHeliBase
run map-start 8 --url=01_NYC_UNATCOIsland
run map-attach 3 --url=00_TrainingCombat
run actor-stasis 12 --url=01_NYC_UNATCOIsland
run player-fight 19 --url=01_NYC_UNATCOIsland
# Shots with the sniper rifle at a far and at a near guard. See tests/player-rifle.txt.
run player-rifle 13 --url=01_NYC_UNATCOIsland
run enemy-run 21 --url=01_NYC_UNATCOIsland --tracepath=Terrorist12
run npc-upright 6 --url=01_NYC_UNATCOIsland
run npc-hidden 123 --url=01_NYC_UNATCOIsland
# The pause of a guard at a patrol point, with four frame rates. See tests/npc-patrol-pause.txt.
run npc-patrol-pause 20 --url=01_NYC_UNATCOIsland
FIXED_FPS=60 SCRIPT_NAME=npc-patrol-pause run npc-patrol-pause-60 20 --url=01_NYC_UNATCOIsland
FIXED_FPS=60.06 SCRIPT_NAME=npc-patrol-pause run npc-patrol-pause-60.06 20 --url=01_NYC_UNATCOIsland
FIXED_FPS=59.94 SCRIPT_NAME=npc-patrol-pause run npc-patrol-pause-59.94 20 --url=01_NYC_UNATCOIsland
# The way of a guard between two patrol points, with two frame rates. See tests/npc-patrol-path.txt.
run npc-patrol-path 86 --url=01_NYC_UNATCOIsland --tracepath=Terrorist34
FIXED_FPS=60 SCRIPT_NAME=npc-patrol-path run npc-patrol-path-60 86 --url=01_NYC_UNATCOIsland --tracepath=Terrorist34
# The wall contacts of the player and of a guard. See tests/player-wall-hit.txt.
run player-wall-hit 9 --url=01_NYC_UNATCOIsland --tracepath=JCDentonMale0
run npc-wall-hit 9 --url=01_NYC_UNATCOIsland --tracepath=Terrorist34
# The slide of the player along a thing that it touches at an angle. See tests/player-slide.txt.
run player-slide 19 --url=01_NYC_UNATCOIsland --tracepath=JCDentonMale0
run save-fight 30 --url=01_NYC_UNATCOIsland
run save-goals 17 --url=01_NYC_UNATCOIsland
run travel-goals 30 --url=01_NYC_UNATCOIsland
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
run menu-save-name 17 --url=01_NYC_UNATCOIsland
# menu-keys-restart reads the key bindings that menu-keys saved
chain "menu-keys 18 --url=01_NYC_UNATCOIsland" "menu-keys-restart 6 --url=01_NYC_UNATCOIsland"
run computer-login-keys 13 --url=01_NYC_UNATCOHQ
run computer-security 22 --url=01_NYC_UNATCOIsland
run computer-atm 16 --url=01_NYC_UNATCOIsland
run computer-hack 16 --url=01_NYC_UNATCOIsland
run loader-loadout 6
run loader-window 6
run loader-main-menu 6
# A controller: the game, the menus, the inventory screen, the key binding screen and a conversation
run pad-moves 22 --url=01_NYC_UNATCOIsland
FIXED_FPS=120 SCRIPT_NAME=pad-moves run pad-moves-120 22 --url=01_NYC_UNATCOIsland
run pad-items 21 --url=01_NYC_UNATCOIsland
run pad-menu 12 --tracekeys
run pad-inventory 17 --url=01_NYC_UNATCOIsland
run pad-bind 18 --url=01_NYC_UNATCOIsland
run pad-talk 82 --url=01_NYC_UNATCOIsland
wait
kill $FOCUS_WATCH 2>/dev/null
FAILED=0
echo "--- all results in the order of the suite"
for ((i = 1; i <= CHAINS; i++)); do
  cat "$RES/$i.txt"
  [ -f "$RES/$i.failed" ] && FAILED=1
done
if grep -q "SurrealEngine" "$RES/focus.txt"; then
  echo "--- a test engine was the app in front. Changes of the app in front:"
  cat "$RES/focus.txt"
fi
echo "--- $(cat "$RES"/[0-9]*.txt | wc -l | tr -d ' ') runs in $(( $(date +%s) - START )) seconds with JOBS=$JOBS, $(ls "$RES" | grep -c failed) chains with a failure"
exit $FAILED
