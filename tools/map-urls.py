# map-urls.py <Maps folder> [map name]: the travel addresses (map#tag) that the map exits of the game use.
# With no map name: one line for each map with all addresses that lead to it.
# With a map name: the first address that leads to that map, or the map name alone if no exit leads to it.
import collections, os, re, sys

folder = sys.argv[1]
maps = sorted(f[:-3] for f in os.listdir(folder) if f.endswith('.dx'))
lower = {m.lower(): m for m in maps}
dest = collections.defaultdict(set)
for m in maps:
    data = open(os.path.join(folder, m + '.dx'), 'rb').read()
    for found in re.finditer(rb'([0-9A-Za-z_]{4,40})#([A-Za-z0-9_]{1,40})', data):
        name = found.group(1).decode().lower()
        if name in lower:
            dest[lower[name]].add(lower[name] + '#' + found.group(2).decode())

if len(sys.argv) > 2:
    name = lower.get(sys.argv[2].lower(), sys.argv[2])
    print(sorted(dest[name])[0] if dest[name] else name)
else:
    for m in maps:
        print(m, ' '.join(sorted(dest[m])))
