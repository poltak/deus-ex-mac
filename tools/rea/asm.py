#!/usr/bin/env python3
# asm.py <socket-name> <procedure> : print assembly; follows a one-instruction JMP thunk to the real body
import json, re, subprocess, sys, os
def asm(proc):
    out = subprocess.run([os.path.expanduser("~/src/dx-re/tools/q.sh"), sys.argv[1], "procedure_assembly", json.dumps({"procedure": proc})], capture_output=True, text=True).stdout
    d = json.loads(out); r = d.get("normalized_result") or d.get("raw_result")
    return r if isinstance(r, str) else json.dumps(r, indent=0)
t = asm(sys.argv[2])
m = re.fullmatch(r"\s*(?:0x[0-9a-f]+:?\s*)?JMP\s+(0x[0-9a-f]+)\s*", t.strip(), re.I)
if m:
    print("; thunk ->", m.group(1)); t = asm(m.group(1))
print(t)
