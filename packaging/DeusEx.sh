#!/bin/bash
# Start script of "Deus Ex.app". It finds the Deus Ex game files of the player and starts the engine with them.
# The app has no game files in it. The player brings a copy of the game (Steam, GOG or a disc).
#
# The game folder is the folder that has the System and Maps folders in it.
# Order of the search:
#   1. the environment variable DEUSEX_GAME_FOLDER
#   2. the folder from the last start (~/Library/Application Support/DeusExMac/gamefolder.txt)
#   3. a "DeusEx" or "Deus Ex" folder next to the app
#   4. the DeusEx folder of a working copy of this project, where the app is in dist/ and the game folder is next to dist/
#   5. some usual places, and the folder where the console command "download_depot 6910 6911" of Steam puts the game
#   6. a folder dialog

HERE="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/Library/Application Support/DeusExMac"
CONFIG_FILE="$CONFIG_DIR/gamefolder.txt"
# The folder that has the app in it. The script is in <app>/Contents/MacOS.
APP_PARENT="$(cd "$HERE/../../.." 2>/dev/null && pwd)"
NEAR_APP=()
if [ -n "$APP_PARENT" ]; then
  NEAR_APP=("$APP_PARENT/DeusEx" "$APP_PARENT/Deus Ex")
  if [ "$(basename "$APP_PARENT")" = dist ]; then NEAR_APP+=("$(dirname "$APP_PARENT")/DeusEx"); fi
fi

is_game_folder() {
  [ -n "$1" ] && [ -f "$1/System/DeusEx.u" ] && [ -d "$1/Maps" ]
}

alert() {
  osascript -e "display alert \"$1\" message \"$2\" as critical" >/dev/null 2>&1
}

GAME=""
SAVE_CHOICE=1
if is_game_folder "$DEUSEX_GAME_FOLDER"; then
  GAME="$DEUSEX_GAME_FOLDER"
  SAVE_CHOICE=0
elif [ -f "$CONFIG_FILE" ] && is_game_folder "$(cat "$CONFIG_FILE")"; then
  GAME="$(cat "$CONFIG_FILE")"
  SAVE_CHOICE=0
else
  for candidate in \
    "${NEAR_APP[@]}" \
    "$HOME/Library/Application Support/Steam/steamapps/common/Deus Ex" \
    "$HOME/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS/steamapps/content/app_6910/depot_6911" \
    "$HOME/Games/Deus Ex" \
    "$HOME/Games/DeusEx" \
    "$HOME/Documents/Deus Ex" \
    "$HOME/Documents/DeusEx" \
    "/Applications/Deus Ex" \
    "/Applications/DeusEx"
  do
    if is_game_folder "$candidate"; then GAME="$candidate"; break; fi
  done
fi

if [ -z "$GAME" ]; then
  CHOSEN="$(osascript -e 'POSIX path of (choose folder with prompt "Select your Deus Ex folder. It is the folder that has the System and Maps folders in it.")' 2>/dev/null)" || exit 0
  CHOSEN="${CHOSEN%/}"
  # A player often selects the System folder itself
  if ! is_game_folder "$CHOSEN" && is_game_folder "$(dirname "$CHOSEN")"; then CHOSEN="$(dirname "$CHOSEN")"; fi
  if ! is_game_folder "$CHOSEN"; then
    alert "This is not a Deus Ex folder" "The folder must have the System folder (with DeusEx.u in it) and the Maps folder of the game."
    exit 1
  fi
  GAME="$CHOSEN"
fi

if [ "$SAVE_CHOICE" = 1 ]; then
  mkdir -p "$CONFIG_DIR" && printf '%s\n' "$GAME" > "$CONFIG_FILE"
fi

# The engine writes its ini files and the save games into the game folder
if [ ! -w "$GAME/System" ]; then
  alert "The Deus Ex folder is read-only" "The game keeps its settings and save games in the game folder. Copy the folder to a place where you can write, for example your Documents folder."
  exit 1
fi

exec "$HERE/SurrealEngine" --direct "$@" "$GAME"
