#!/bin/bash
# q.sh <socket-name> <tool> <json-args> : call one REA MCP tool, print the text content
S=$HOME/src/dx-re/$1.sock; shift
python3 $HOME/src/dx-re/tools/reamcp.py call $S "$@" | python3 -c "
import json,sys
r=json.load(sys.stdin)
if \"error\" in r: print(\"ERROR\", json.dumps(r[\"error\"])[:2000]); sys.exit(1)
res=r[\"result\"]
for c in res.get(\"content\",[]):
    if c.get(\"type\")==\"text\": print(c[\"text\"])
if res.get(\"isError\"): print(\"(isError)\")
"
