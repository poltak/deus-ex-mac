#!/bin/bash
# pc.sh <socket-name> <procedure> : print decompiled pseudocode of one procedure
$HOME/src/dx-re/tools/q.sh "$1" procedure_pseudo_code "{\"procedure\":\"$2\"}" | python3 -c "
import json,sys
t=sys.stdin.read()
try:
    d=json.loads(t)
    r=d.get(\"normalized_result\") or d.get(\"raw_result\") or d
    print(r if isinstance(r,str) else json.dumps(r,indent=1)[:20000])
except Exception: print(t[:20000])
"
