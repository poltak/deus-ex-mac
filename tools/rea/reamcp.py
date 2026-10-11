#!/usr/bin/env python3
"""Small daemon: keeps one REA MCP server (and its Ghidra session) alive and serves
JSON requests over a unix socket, so repeated queries do not import the DLL again.
  reamcp.py serve <socket>            start daemon (foreground)
  reamcp.py call <socket> <tool> <json-args>   call one MCP tool, print result JSON
  reamcp.py tools <socket>            list MCP tools
"""
import json, os, socket, subprocess, sys, threading

def serve(sock_path):
    env = dict(os.environ)
    proc = subprocess.Popen(["node", os.path.expanduser("~/src/rea/scripts/rea.mjs"), "mcp"],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=open(sock_path + ".stderr", "w"), env=env)
    lock = threading.Lock()
    nextid = [0]
    def rpc(method, params=None, notify=False):
        with lock:
            msg = {"jsonrpc": "2.0", "method": method}
            if params is not None: msg["params"] = params
            if not notify:
                nextid[0] += 1; msg["id"] = nextid[0]
            proc.stdin.write((json.dumps(msg) + "\n").encode()); proc.stdin.flush()
            if notify: return None
            while True:
                line = proc.stdout.readline()
                if not line: return {"error": "server closed"}
                try: resp = json.loads(line)
                except Exception: continue
                if resp.get("id") == msg["id"]: return resp
    rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "dx-re", "version": "0"}})
    rpc("notifications/initialized", {}, notify=True)
    if os.path.exists(sock_path): os.unlink(sock_path)
    srv = socket.socket(socket.AF_UNIX); srv.bind(sock_path); srv.listen(4)
    while True:
        conn, _ = srv.accept()
        data = b""
        while not data.endswith(b"\n"):
            chunk = conn.recv(65536)
            if not chunk: break
            data += chunk
        try:
            req = json.loads(data)
            if req.get("op") == "quit":
                conn.sendall(b"{}\n"); conn.close(); proc.terminate(); os.unlink(sock_path); return
            resp = rpc(req["method"], req.get("params"))
        except Exception as e:
            resp = {"error": repr(e)}
        conn.sendall((json.dumps(resp) + "\n").encode()); conn.close()

def client(sock_path, req):
    c = socket.socket(socket.AF_UNIX); c.connect(sock_path)
    c.sendall((json.dumps(req) + "\n").encode())
    data = b""
    while True:
        chunk = c.recv(1 << 20)
        if not chunk: break
        data += chunk
    return json.loads(data)

if __name__ == "__main__":
    cmd, sock = sys.argv[1], sys.argv[2]
    if cmd == "serve": serve(sock)
    elif cmd == "tools":
        r = client(sock, {"method": "tools/list"})
        for t in r["result"]["tools"]: print(t["name"], "-", (t.get("description") or "")[:110].replace("\n", " "))
    elif cmd == "schema":
        r = client(sock, {"method": "tools/list"})
        for t in r["result"]["tools"]:
            if t["name"] == sys.argv[3]: print(json.dumps(t["inputSchema"], indent=1)[:6000])
    elif cmd == "call":
        r = client(sock, {"method": "tools/call", "params": {"name": sys.argv[3], "arguments": json.loads(sys.argv[4]) if len(sys.argv) > 4 else {}}})
        print(json.dumps(r))
    elif cmd == "quit": print(client(sock, {"op": "quit"}))
