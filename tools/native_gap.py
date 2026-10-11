import re, sys, glob, os, collections
root = sys.argv[1]; se = sys.argv[2]
# SurrealEngine registrations: (class, func) -> True ; also detect stubs
reg = {}
impl_unimpl = set()
for path in glob.glob(os.path.join(se, "SurrealEngine/Native/*.cpp")):
    src = open(path, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r'RegisterVMNativeFunc_\d+\("([^"]+)",\s*"([^"]+)",\s*&(\w+)::(\w+)', src):
        reg[(m.group(1).lower(), m.group(2).lower())] = (m.group(3), m.group(4), path)
    # function bodies that only log unimplemented
    for m in re.finditer(r'\n(?:[\w:<>\*&\s]+?)\s(\w+)::(\w+)\([^)]*\)\s*\{(.*?)\n\}', src, re.S):
        body = m.group(3)
        if "LogUnimplemented" in body or "Unimplemented" in body:
            impl_unimpl.add((m.group(1), m.group(2)))
tot = collections.OrderedDict()
for dll in ["Core","Engine","Extension","DeusEx","ConSys","DeusExText","IpDrv"]:
    names = [l.strip() for l in open(os.path.join(root, dll + ".txt"))]
    missing, stub, ok = [], [], []
    for n in names:
        m = re.match(r'\?exec(\w+?)@(\w+?)@@', n)
        if not m: continue
        func, cls = m.group(1), m.group(2)
        cname = cls[1:]
        key = (cname.lower(), func.lower())
        if key in reg:
            r = reg[key]
            (stub if (r[0], r[1]) in impl_unimpl else ok).append(f"{cname}.{func}")
        else:
            missing.append(f"{cname}.{func}")
    tot[dll] = (ok, stub, missing)
    print(f"{dll:11s} implemented={len(ok):4d} stub={len(stub):4d} not_registered={len(missing):4d}")
for dll in ["Extension","DeusEx","ConSys","DeusExText"]:
    ok, stub, missing = tot[dll]
    print(f"\n## {dll} stubs ({len(stub)}):"); print(", ".join(sorted(stub)))
    print(f"## {dll} not registered ({len(missing)}):"); print(", ".join(sorted(missing)))
