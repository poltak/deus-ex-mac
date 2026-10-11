#!/bin/bash
# audio-test.sh <run-name> <seconds> [engine args...]: run the game in real time with the sound on, but send the sound
# to a WAV file and not to the speakers. Then print the sound level of each second.
# OpenAL Soft has a "wave" driver for this. With ALSOFT_DRIVERS=wave it is the only driver, so the run makes no sound
# on this computer. The file is runs/<run-name>/audio.wav.
# Environment: SCRIPT=<input script file>, GAME=<game folder>.
W="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"; SECS="$2"; shift 2
R="$W/runs/$NAME"; rm -rf "$R"; mkdir -p "$R"
GAME="${GAME:-$W/DeusEx}"
printf '[general]\ndrivers = wave\n\n[wave]\nfile = %s\n' "$R/audio.wav" > "$R/alsoft.conf"
SCRIPT_ARG=()
[ -n "$SCRIPT" ] && SCRIPT_ARG=(--script="$SCRIPT")
open -g -n -W --stdout "$R/stdout.txt" --stderr "$R/stderr.txt" --env "ALSOFT_DRIVERS=wave" --env "ALSOFT_CONF=$R/alsoft.conf" \
  "$W/SurrealEngine/build/SurrealEngine.app" --args --nolauncher --nograb --logfile="$R/log.txt" --shots="$R" --shot-interval=0 \
  --exit-after="$SECS" --winsize=1280x960 --seed=1 "${SCRIPT_ARG[@]}" "$@" "$GAME" &
WAITER=$!
( sleep $((SECS + 60)); pkill -9 -f "MacOS/SurrealEngine.*--logfile=$R/log.txt" ) 2>/dev/null &
WD=$!
wait $WAITER
{ kill $WD; wait $WD; } 2>/dev/null
grep -a -q "Shutting down" "$R/log.txt" 2>/dev/null && echo "run ended correctly" || echo "RUN DID NOT END CORRECTLY"
for f in "$R"/*.bmp; do [ -f "$f" ] && sips -s format png -Z 1100 "$f" --out "${f%.bmp}.png" >/dev/null 2>&1 && rm -f "$f"; done
[ -f "$R/audio.wav" ] || { echo "no audio file: the wave driver did not open"; exit 1; }
python3 -I "$W/tools/wav-levels.py" "$R/audio.wav"
