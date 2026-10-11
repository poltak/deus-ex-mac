# selfprof.py <sample file> [thread index]: self time per function for one thread of a macOS "sample" report
import sys, re, collections
lines = open(sys.argv[1], errors='replace').read().split('\n')
which = int(sys.argv[2]) if len(sys.argv) > 2 else 1
start = next(i for i,l in enumerate(lines) if l.startswith('Call graph:'))
end = next(i for i,l in enumerate(lines) if l.startswith('Total number in stack'))
rows = []
thread = 0
for l in lines[start+1:end]:
    m = re.match(r'^([\s+!:|]*)(\d+) (.*?)(  \(in ([^)]*)\).*)?$', l)
    if not m: continue
    if m.group(3).startswith('Thread_'):
        thread += 1
        if thread > which: break
    if thread == which:
        rows.append((len(m.group(1)), int(m.group(2)), m.group(3), m.group(5) or ''))
total = rows[0][1]
self_ = collections.Counter()
for i, (d, n, name, lib) in enumerate(rows):
    child = 0
    for j in range(i+1, len(rows)):
        if rows[j][0] <= d: break
        if rows[j][0] == d + 2: child += rows[j][1]
    s = n - child
    if s > 0: self_[(name, lib)] += s
print("thread samples:", total)
for (name, lib), s in self_.most_common(45):
    print(f"{s*100/total:5.1f}%  {name[:100]}  [{lib}]")
