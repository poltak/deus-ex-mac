import struct, sys
# upkgprops.py <package> <class name> [text filter]: print the tagged properties of each export of that class
data = open(sys.argv[1], 'rb').read()
def cidx(pos):
    b = data[pos]; pos += 1
    neg = b & 0x80; val = b & 0x3f
    if b & 0x40:
        shift = 6
        while True:
            b = data[pos]; pos += 1
            val |= (b & 0x7f) << shift; shift += 7
            if not (b & 0x80): break
    return (-val if neg else val), pos
sig, ver, lic, flags, ncount, noff, ecount, eoff, icount, ioff = struct.unpack_from('<IHHIIIIIII', data, 0)
names = []; pos = noff
for i in range(ncount):
    if ver >= 64:
        ln, pos = cidx(pos); s = data[pos:pos + ln - 1].decode('latin1'); pos += ln
    else:
        end = data.index(b'\0', pos); s = data[pos:end].decode('latin1'); pos = end + 1
    pos += 4; names.append(s)
imports = []; pos = ioff
for i in range(icount):
    cp, pos = cidx(pos); cn, pos = cidx(pos); pkg = struct.unpack_from('<i', data, pos)[0]; pos += 4; on, pos = cidx(pos)
    imports.append(names[on])
exports = []; pos = eoff
for i in range(ecount):
    cls, pos = cidx(pos); sup, pos = cidx(pos); pkg = struct.unpack_from('<i', data, pos)[0]; pos += 4
    on, pos = cidx(pos); fl = struct.unpack_from('<I', data, pos)[0]; pos += 4
    size, pos = cidx(pos); off = 0
    if size > 0: off, pos = cidx(pos)
    exports.append((cls, names[on], fl, size, off))
def clsname(c):
    if c < 0: return imports[-c - 1]
    if c > 0: return exports[c - 1][1]
    return 'Class'
def props(off, fl):
    pos = off; out = {}
    if fl & 0x02000000:   # RF_HasStack
        node, pos = cidx(pos); st, pos = cidx(pos); pos += 8 + 4
        if node != 0: o, pos = cidx(pos)
    while True:
        n, pos = cidx(pos)
        name = names[n]
        if name == 'None': break
        info = data[pos]; pos += 1
        typ = info & 0x0f; st = (info >> 4) & 7; arr = info & 0x80
        if typ == 10: sn, pos = cidx(pos)
        if st == 0: size = 1
        elif st == 1: size = 2
        elif st == 2: size = 4
        elif st == 3: size = 12
        elif st == 4: size = 16
        elif st == 5: size = data[pos]; pos += 1
        elif st == 6: size = struct.unpack_from('<H', data, pos)[0]; pos += 2
        else: size = struct.unpack_from('<I', data, pos)[0]; pos += 4
        if typ == 3:
            out[name] = bool(arr); continue
        if arr:
            b = data[pos]
            if b < 0x80: pos += 1
            elif b < 0xc0: pos += 2
            else: pos += 4
        raw = data[pos:pos + size]; pos += size
        if typ == 6: out[name] = names[cidx(pos - size)[0]]
        elif typ in (13, 9): 
            ln, p2 = cidx(pos - size); out[name] = data[p2:p2 + max(ln - 1, 0)].decode('latin1')
        elif typ == 2: out[name] = struct.unpack('<i', raw)[0]
        elif typ == 1: out[name] = raw[0]
        else: out[name] = '<%d bytes type %d>' % (size, typ)
    return out
want = sys.argv[2]; flt = sys.argv[3] if len(sys.argv) > 3 else None
n = 0; prim = 0
for cls, name, fl, size, off in exports:
    if clsname(cls) != want or size == 0: continue
    try: p = props(off, fl)
    except Exception as e: p = {'error': str(e)}
    n += 1
    if p.get('bPrimaryGoal'): prim += 1
    if flt is None or flt in str(p):
        print(name, {k: (v[:50] if isinstance(v, str) else v) for k, v in p.items()})
print('exports of', want, n, 'with bPrimaryGoal:', prim, 'package version', ver)
