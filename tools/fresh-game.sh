#!/bin/bash
# fresh-game.sh <new folder> [game folder]: make a game folder for tests that is in the state of a first start.
# The new folder has links to the data of the game folder (default DeusEx/), copies of the ini files of the game,
# no ini files of the engine and no saved games. A test that uses it does not depend on the runs before, and it
# does not change the game folder. The script deletes <new folder> first if it is there.
W="$(cd "$(dirname "$0")/.." && pwd)"
NEW="$1"; SRC="${2:-$W/DeusEx}"
[ -n "$NEW" ] || { echo "usage: fresh-game.sh <new folder> [game folder]" >&2; exit 2; }
[ -d "$SRC/System" ] || { echo "no game folder at $SRC" >&2; exit 2; }
# Delete only a folder that this script made before
if [ -e "$NEW" ]; then
  [ -f "$NEW/.fresh-game" ] || { echo "$NEW is there and this script did not make it" >&2; exit 2; }
  rm -rf "$NEW"
fi
mkdir -p "$NEW/System" "$NEW/Save"
touch "$NEW/.fresh-game"
SRC="$(cd "$SRC" && pwd)"
for d in "$SRC"/*; do
  n="$(basename "$d")"
  case "$n" in
    System|Save|_src) ;;
    *) ln -s "$d" "$NEW/$n" ;;
  esac
done
for f in "$SRC/System"/*; do
  n="$(basename "$f")"
  case "$n" in
    SE-*) ;;
    *.ini|*.INI) cp "$f" "$NEW/System/$n" ;;
    *) ln -s "$f" "$NEW/System/$n" ;;
  esac
done
echo "$NEW"
