#!/bin/bash
# rea.sh: use REA with Ghidra on this Mac for one original DLL.
#   rea.sh start <session> <Dll-name>      e.g. rea.sh start eng Engine   (opens DeusEx/System/Engine.dll)
#   rea.sh search <session> <regex>        list procedures whose name matches
#   rea.sh pc <session> <proc> [out-name]  decompile; follows export thunks; saves to re-out/<session>/<out-name>.c
#   rea.sh asm <session> <proc> [out-name] disassemble; saves to re-out/<session>/<out-name>.asm
#   rea.sh q <session> <reaq command...>   any other reaq.py command (callers, callees, name, strings, bytes, raw)
#   rea.sh stop <session>
# Raw decompiler output goes to re-out/, which git ignores.
# Paths: REA_HOME (default ~/Documents/github/rea), GHIDRA_INSTALL_DIR (default ~/tools/ghidra_12.1.4_PUBLIC), JAVA_HOME.
W="$(cd "$(dirname "$0")/.." && pwd)"
export REA_HOME="${REA_HOME:-$HOME/Documents/github/rea}"
export GHIDRA_INSTALL_DIR="${GHIDRA_INSTALL_DIR:-$HOME/tools/ghidra_12.1.4_PUBLIC}"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"
export REA_ANALYSIS_PROVIDER=ghidra
export REA_GHIDRA_STARTUP_TIMEOUT_MS=1800000
SOCKDIR="$HOME/tools/rea-sessions"   # a short path: unix socket paths have a 104 character limit on macOS
mkdir -p "$SOCKDIR"
cmd="$1"; ses="$2"; shift 2
SOCK="$SOCKDIR/$ses.sock"
Q=(python3 "$W/tools/rea/reaq.py" "$SOCK")
case "$cmd" in
  start)
    if [ ! -S "$SOCK" ]; then
      nohup python3 "$W/tools/rea/reamcp.py" serve "$SOCK" > "$SOCKDIR/$ses.log" 2>&1 < /dev/null &
      for i in $(seq 1 40); do [ -S "$SOCK" ] && break; sleep 0.25; done
    fi
    "${Q[@]}" open "$W/DeusEx/System/$1.dll" ;;
  search) "${Q[@]}" search "$1" ;;
  pc|asm)
    name="${2:-$(echo "$1" | tr -c 'A-Za-z0-9_\n' '_')}"; mkdir -p "$W/re-out/$ses"
    ext=c; [ "$cmd" = asm ] && ext=asm
    "${Q[@]}" "$cmd" "$1" > "$W/re-out/$ses/$name.$ext"
    echo "re-out/$ses/$name.$ext ($(wc -l < "$W/re-out/$ses/$name.$ext" | tr -d ' ') lines)" ;;
  q) "${Q[@]}" "$@" ;;
  stop) python3 "$W/tools/rea/reamcp.py" quit "$SOCK" ;;
  *) echo "unknown command"; exit 2 ;;
esac
