#!/bin/bash
# window-size-test.sh: the Screen Resolution setting must change the window, and the engine must keep the size for
# the next start. The test uses a new game folder in the state of a first start (tools/fresh-game.sh).
W="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$("$W/tools/fresh-game.sh" "$W/runs/window-size-game")" || exit 2
export GAME
FAILED=0
check() {
  local text="$1" log="$2"
  if grep -a -q "$text" "$log"; then echo "ok: $text"; else echo "FAILED: no \"$text\" in $log"; FAILED=1; fi
}
# The harness option --winsize puts its own size back each second, so these runs must not use it
WINSIZE=none SCRIPT="$W/tests/window-size.txt" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" window-size 8 > "$W/runs/window-size.out" 2>&1
LOG="$W/runs/window-size/log.txt"
check "exec result: 640x480 1280x960" "$LOG"
check "\[4.00\].*exec result: 640x480$" "$LOG"
check "\[6.00\].*exec result: 1280x960$" "$LOG"
WINSIZE=none SCRIPT="$W/tests/window-size-next.txt" SHOT_INTERVAL=0 "$W/tools/run-dx.sh" window-size-next 4 > "$W/runs/window-size-next.out" 2>&1
check "\[2.00\].*exec result: 1280x960$" "$W/runs/window-size-next/log.txt"
[ "$FAILED" = 0 ] && echo "window size test passed"
exit $FAILED
