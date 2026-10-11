#!/usr/bin/env python3
"""wstr.py <socket> <address>... : print the UTF-16 string at each address of the open binary"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reaq
sock = sys.argv[1]
for addr in sys.argv[2:]:
    r = reaq.call(sock, "read_bytes", {"address": addr, "length": 160})
    b = bytes.fromhex(r["bytes_hex"])
    s = b.decode("utf-16-le", errors="replace")
    print(addr, json.dumps(s.split("\x00")[0]))
