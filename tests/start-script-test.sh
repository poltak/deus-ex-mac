#!/bin/bash
# Test of packaging/DeusEx.sh, the start script of the app. It uses a temporary home folder, a fake engine and a
# fake osascript, so it opens no dialog and starts no game.
# Usage: tests/start-script-test.sh
W="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/dx-start-test.XXXXXX")"
trap 'chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT

mkdir -p "$T/app" "$T/bin" "$T/home"
cp "$W/packaging/DeusEx.sh" "$T/app/DeusEx"
# The fake engine writes its arguments, one for each line
printf '#!/bin/bash\nprintf "%%s\\n" "$@" > "%s/engine-args.txt"\n' "$T" > "$T/app/SurrealEngine"
# The fake osascript records the call. For a folder dialog it prints $FAKE_CHOICE, or fails if that is empty.
cat > "$T/bin/osascript" <<'EOS'
#!/bin/bash
echo "$2" >> "$FAKE_LOG"
case "$2" in
  *"choose folder"*) [ -n "$FAKE_CHOICE" ] || exit 1; printf '%s\n' "$FAKE_CHOICE" ;;
esac
EOS
chmod +x "$T/app/DeusEx" "$T/app/SurrealEngine" "$T/bin/osascript"

make_game() { mkdir -p "$1/System" "$1/Maps"; : > "$1/System/DeusEx.u"; }

FAILED=0
# run <name> <expected exit code> <expected game folder or ""> <expected dialogs: none|choose|alert|choose+alert>
run() {
  local name="$1" want_rc="$2" want_game="$3" want_dialogs="$4"; shift 4
  rm -f "$T/engine-args.txt" "$T/osascript.log"
  env -i PATH="$T/bin:/usr/bin:/bin" HOME="$T/home" FAKE_LOG="$T/osascript.log" "$@" "$T/app/DeusEx" --mute
  local rc=$? game="" dialogs="none"
  [ -f "$T/engine-args.txt" ] && game="$(tail -1 "$T/engine-args.txt")"
  if [ -f "$T/osascript.log" ]; then
    dialogs=""
    grep -q "choose folder" "$T/osascript.log" && dialogs="choose"
    grep -q "display alert" "$T/osascript.log" && dialogs="${dialogs:+$dialogs+}alert"
  fi
  local ok=1
  [ "$rc" = "$want_rc" ] || ok=0
  [ "$game" = "$want_game" ] || ok=0
  [ "$dialogs" = "$want_dialogs" ] || ok=0
  if [ -n "$want_game" ] && [ "$(head -2 "$T/engine-args.txt" | tr '\n' ' ')" != "--direct --mute " ]; then ok=0; fi
  if [ "$ok" = 1 ]; then echo "ok    $name"; else echo "FAIL  $name: exit $rc (want $want_rc), game '$game' (want '$want_game'), dialogs $dialogs (want $want_dialogs)"; FAILED=1; fi
}
stored() { cat "$T/home/Library/Application Support/DeusExMac/gamefolder.txt" 2>/dev/null; }
check_stored() { if [ "$(stored)" = "$2" ]; then echo "ok    $1"; else echo "FAIL  $1: stored '$(stored)' (want '$2')"; FAILED=1; fi; }

make_game "$T/games/env game"
make_game "$T/games/picked"
make_game "$T/games/other"
mkdir -p "$T/games/not a game"

run "the environment variable selects the folder" 0 "$T/games/env game" none DEUSEX_GAME_FOLDER="$T/games/env game"
check_stored "the environment variable does not change the stored folder" ""
run "a cancelled dialog stops with no error" 0 "" choose
run "a folder that is not a game shows an alert" 1 "" choose+alert FAKE_CHOICE="$T/games/not a game/"
check_stored "a bad folder is not stored" ""
run "the dialog selects the folder" 0 "$T/games/picked" choose FAKE_CHOICE="$T/games/picked/"
check_stored "the selected folder is stored" "$T/games/picked"
run "the stored folder starts with no dialog" 0 "$T/games/picked" none
rm -rf "$T/games/picked"
run "a stored folder that is gone opens the dialog again" 0 "$T/games/other" choose FAKE_CHOICE="$T/games/other/System/"
check_stored "the System folder selects its parent folder" "$T/games/other"
rm -rf "$T/home/Library"
make_game "$T/home/Library/Application Support/Steam/steamapps/common/Deus Ex"
run "a Steam folder is found with no dialog" 0 "$T/home/Library/Application Support/Steam/steamapps/common/Deus Ex" none
check_stored "the found folder is stored" "$T/home/Library/Application Support/Steam/steamapps/common/Deus Ex"
chmod a-w "$T/home/Library/Application Support/Steam/steamapps/common/Deus Ex/System"
run "a read-only game folder shows an alert" 1 "" alert

[ "$FAILED" = 0 ] && echo "all start script tests passed"
exit $FAILED
