# callers.py <sample file> <regex> [levels]: for the main thread, total inclusive samples of frames that match the regex,
# grouped by the nearest ancestor frames in the SurrealEngine binary (levels = how many ancestors to show).
import sys, re, collections
lines = open(sys.argv[1], errors='replace').read().split('\n')
pat = re.compile(sys.argv[2]); levels = int(sys.argv[3]) if len(sys.argv) > 3 else 1
start = next(i for i,l in enumerate(lines) if l.startswith('Call graph:'))
end = next(i for i,l in enumerate(lines) if l.startswith('Total number in stack'))
rows = []; thread = 0
for l in lines[start+1:end]:
    m = re.match(r'^([\s+!:|]*)(\d+) (.*?)(  \(in ([^)]*)\).*)?$', l)
    if not m: continue
    if m.group(3).startswith('Thread_'):
        thread += 1
        if thread > 1: break
    rows.append((len(m.group(1)), int(m.group(2)), m.group(3), m.group(5) or ''))
total = rows[0][1]
agg = collections.Counter(); stack = []
skip_until = None
for d, n, name, lib in rows:
    while stack and stack[-1][0] >= d: stack.pop()
    if skip_until is not None and d > skip_until:
        stack.append((d, name, lib)); continue
    skip_until = None
    if pat.search(name):
        anc = [s[1] for s in reversed(stack) if s[2] == 'SurrealEngine' and not pat.search(s[1])][:levels]
        agg[' <- '.join(a[:70] for a in anc)] += n
        skip_until = d
    stack.append((d, name, lib))
tot = sum(agg.values())
print(f"total {tot} samples = {tot*100/total:.1f}% of the thread")
for k, v in agg.most_common(25):
    print(f"{v*100/total:5.1f}%  {k}")
