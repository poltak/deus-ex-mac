#!/bin/bash
# loader.sh [engine arguments]: open the developer loader with the engine build of this working copy.
# The loader window selects a map, a start point, the weapons and the values of the player. Its Start button starts
# the game there, with no menu and no intro. The window keeps the selections for the next time.
# GAME=<game folder>: the game folder to play in. The default is DeusEx/ of this working copy.
# The loader removes the map states of the current game (Save/Current of the game folder), as a new game does.
# The saved games stay as they are.
W="$(cd "$(dirname "$0")/.." && pwd)"
B="$W/SurrealEngine/build/SurrealEngine.app/Contents/MacOS/SurrealEngine"
GAME="${GAME:-$W/DeusEx}"
[ -x "$B" ] || { echo "Build the engine first: ninja -C SurrealEngine/build SurrealEngine"; exit 1; }
[ -f "$GAME/System/DeusEx.u" ] || { echo "No game folder at $GAME. Put your Deus Ex folder there, or set GAME=<game folder>."; exit 1; }
exec "$B" --direct --loader "$@" "$GAME"
