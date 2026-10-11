#!/usr/bin/env python3
"""peread.py <dll> <f|d|i|w> <address>...: read float, double, int32 or UTF-16 string values from a PE file at virtual addresses."""
import struct, sys

def main():
    data = open(sys.argv[1], "rb").read()
    kind = sys.argv[2]
    pe = struct.unpack_from("<I", data, 0x3c)[0]
    nsec = struct.unpack_from("<H", data, pe + 6)[0]
    opt = pe + 24
    base = struct.unpack_from("<I", data, opt + 28)[0]
    secoff = opt + struct.unpack_from("<H", data, pe + 20)[0]
    def read(va, n):
        rva = va - base
        for i in range(nsec):
            s = secoff + i * 40
            vsize, vaddr, rsize, roff = struct.unpack_from("<IIII", data, s + 8)
            if vaddr <= rva < vaddr + max(vsize, rsize):
                return data[roff + rva - vaddr: roff + rva - vaddr + n]
        return b""
    for arg in sys.argv[3:]:
        va = int(arg, 16)
        if kind == "f":
            print(arg, struct.unpack("<f", read(va, 4))[0])
        elif kind == "d":
            print(arg, struct.unpack("<d", read(va, 8))[0])
        elif kind == "i":
            print(arg, struct.unpack("<i", read(va, 4))[0])
        else:
            print(arg, read(va, 400).decode("utf-16-le", "replace").split("\0")[0])

main()
