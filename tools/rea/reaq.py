#!/usr/bin/env python3
"""Client for one REA session (see reamcp.py).
  reaq.py <socket> open <path>           open a binary with the Ghidra provider
  reaq.py <socket> search <regex>        list procedures whose name matches
  reaq.py <socket> pc <proc>             decompile a procedure (follows a one-instruction JMP thunk)
  reaq.py <socket> asm <proc>            disassemble a procedure (follows a thunk)
  reaq.py <socket> callers <proc>        list direct callers
  reaq.py <socket> callees <proc>        list direct callees
  reaq.py <socket> name <address>        name at an address
  reaq.py <socket> strings <regex>       search strings
  reaq.py <socket> bytes <address> <n>   read bytes
  reaq.py <socket> raw <tool> <json>     call any MCP tool
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reamcp

def call(sock, tool, args):
    r = reamcp.client(sock, {"method": "tools/call", "params": {"name": tool, "arguments": args}})
    if "error" in r:
        raise SystemExit("ERROR " + json.dumps(r["error"])[:2000])
    text = "".join(c.get("text", "") for c in r["result"].get("content", []) if c.get("type") == "text")
    try:
        d = json.loads(text)
    except Exception:
        return text
    if isinstance(d, dict) and ("normalized_result" in d or "raw_result" in d):
        return d.get("normalized_result") if d.get("normalized_result") is not None else d.get("raw_result")
    return d

def text_of(r):
    return r if isinstance(r, str) else json.dumps(r, indent=1)

def follow_thunk(sock, proc):
    t = text_of(call(sock, "procedure_assembly", {"procedure": proc}))
    m = re.fullmatch(r"\s*(?:0x[0-9a-f]+:?\s*)?JMP\s+(0x[0-9a-f]+)\s*", t.strip(), re.I)
    return (m.group(1), None) if m else (proc, t)

def main():
    sock, cmd, args = sys.argv[1], sys.argv[2], sys.argv[3:]
    if cmd == "open":
        print(text_of(call(sock, "open_binary", {"path": args[0], "provider_id": "ghidra"}))[:300])
    elif cmd == "search":
        for r in call(sock, "search_procedures", {"pattern": args[0], "mode": "regex"}): print(r["address"], r["value"])
    elif cmd == "strings":
        for r in call(sock, "search_strings", {"pattern": args[0], "mode": "regex"}): print(r["address"], json.dumps(r["value"]))
    elif cmd == "pc":
        target, _ = follow_thunk(sock, args[0])
        if target != args[0]: print("/* thunk %s -> %s */" % (args[0], target))
        print(text_of(call(sock, "procedure_pseudo_code", {"procedure": target})))
    elif cmd == "asm":
        target, t = follow_thunk(sock, args[0])
        if t is None:
            print("; thunk %s -> %s" % (args[0], target)); t = text_of(call(sock, "procedure_assembly", {"procedure": target}))
        print(t)
    elif cmd in ("callers", "callees"):
        target, _ = follow_thunk(sock, args[0])
        for a in call(sock, "procedure_" + cmd, {"procedure": target}):
            try: n = text_of(call(sock, "address_name", {"address": a}))
            except SystemExit: n = "?"
            print(a, n)
    elif cmd == "name":
        print(text_of(call(sock, "address_name", {"address": args[0]})))
    elif cmd == "bytes":
        print(text_of(call(sock, "read_bytes", {"address": args[0], "length": int(args[1])})))
    elif cmd == "raw":
        print(text_of(call(sock, args[0], json.loads(args[1]) if len(args) > 1 else {})))
    else:
        raise SystemExit("unknown command")

if __name__ == "__main__":
    main()
