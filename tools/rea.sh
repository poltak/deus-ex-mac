#!/bin/bash
# rea.sh: use REA with Ghidra on the omarchy box for one original DLL.
#   rea.sh start <session> <Dll-name>     e.g. rea.sh start ext Extension   (opens ~/src/dx-re/bin/Extension.dll)
#   rea.sh search <session> <regex>       list procedures whose name matches
#   rea.sh pc <session> <proc> [out-name] decompile; follows export thunks; saves to re-out/<session>/<out-name>.c
#   rea.sh asm <session> <proc> [out-name] disassemble; saves to re-out/<session>/<out-name>.asm
#   rea.sh stop <session>
# Raw decompiler output goes to re-out/, which git ignores.
W="$(cd "$(dirname "$0")/.." && pwd)"
OMX="$W/tools/omx.sh"
cmd="$1"; ses="$2"; shift 2
case "$cmd" in
  start)
    "$OMX" ". ~/src/dx-re/env.sh; cd ~/src/dx-re; if [ -S $ses.sock ]; then echo 'session exists'; else (setsid nohup python3 tools/reamcp.py serve \$HOME/src/dx-re/$ses.sock > $ses.daemon.log 2>&1 < /dev/null &); sleep 4; fi; tools/q.sh $ses open_binary '{\"path\":\"'\$HOME'/src/dx-re/bin/$1.dll\",\"provider_id\":\"ghidra\"}' | cut -c1-200" ;;
  search)
    "$OMX" "cd ~/src/dx-re; tools/q.sh $ses search_procedures '{\"pattern\":\"$1\",\"mode\":\"regex\"}' | python3 -c 'import json,sys
for r in json.load(sys.stdin)[\"normalized_result\"]: print(r[\"address\"], r[\"value\"])'" ;;
  pc|asm)
    name="${2:-$(echo "$1" | tr -c 'A-Za-z0-9_\n' '_')}"; mkdir -p "$W/re-out/$ses"
    if [ "$cmd" = pc ]; then
      "$OMX" "cd ~/src/dx-re; T=\$(python3 tools/asm.py $ses '$1' 2>/dev/null | head -1 | sed -n 's/^; thunk -> //p'); tools/pc.sh $ses \"\${T:-$1}\"" > "$W/re-out/$ses/$name.c"
      echo "re-out/$ses/$name.c ($(wc -l < "$W/re-out/$ses/$name.c") lines)"
    else
      "$OMX" "cd ~/src/dx-re; python3 tools/asm.py $ses '$1'" > "$W/re-out/$ses/$name.asm"
      echo "re-out/$ses/$name.asm ($(wc -l < "$W/re-out/$ses/$name.asm") lines)"
    fi ;;
  stop)
    "$OMX" "cd ~/src/dx-re; python3 tools/reamcp.py quit \$HOME/src/dx-re/$ses.sock; sleep 1; ls *.sock 2>/dev/null" ;;
  *) echo "unknown command"; exit 2 ;;
esac
