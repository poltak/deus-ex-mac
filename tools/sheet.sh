#!/bin/bash
# sheet.sh <run-name> [columns] [names...] : make runs/<run-name>/sheet.png, a labeled contact sheet of the run screenshots
W="$(cd "$(dirname "$0")/.." && pwd)"
R="$W/runs/$1"; COLS="${2:-3}"; shift 2 2>/dev/null
cd "$R" || exit 2
if [ $# -gt 0 ]; then FILES=(); for n in "$@"; do FILES+=("$n.png"); done; else FILES=($(ls -tr *.png | grep -v '^sheet')); fi
montage "${FILES[@]}" -tile "${COLS}x" -geometry 640x480+4+4 -background '#202020' -fill white -label '%t' -pointsize 18 sheet.png 2>/dev/null
echo "$R/sheet.png"
