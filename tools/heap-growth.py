# heap-growth.py <snapshot 1> <snapshot 2>: compare two "malloc_history <pid> -allBySize" reports and print the
# call stacks whose live memory grew most. A stack is shown by its engine functions that are nearest to the allocation.
import collections, re, sys

SKIP = ('malloc', 'operator new', '_malloc', 'calloc', 'realloc', 'thread_start', '_pthread', 'start', 'main',
        'GameApp::main', 'Engine::Run', 'std::', 'void* std::', 'void std::', '_aligned_alloc')

def load(path):
    out = collections.Counter()
    for line in open(path, errors='replace'):
        m = re.match(r'^(\d+) calls? for (\d+) bytes: (.*)$', line)
        if not m:
            continue
        frames = []
        for f in m.group(3).split('|'):
            f = re.sub(r'^\s*0x[0-9a-f]+ \([^)]*\) ', '', f.strip())
            f = re.sub(r'\(.*?\)', '()', f)
            f = re.sub(r'\s+\S+\.(cpp|h|mm):\d+$', '', f)
            frames.append(f)
        keep = [f for f in frames if f and not f.startswith(SKIP)]
        out[' < '.join(keep[-5:][::-1])] += int(m.group(2))
    return out

a, b = load(sys.argv[1]), load(sys.argv[2])
rows = sorted(((b[k] - a.get(k, 0), k) for k in b), reverse=True)
total = sum(b.values()) - sum(a.values())
print(f"live memory grew by {total / 1048576:.1f} MB between the snapshots")
for delta, key in rows[:30]:
    if delta <= 0:
        break
    print(f"{delta / 1048576:7.2f} MB  {key[:260]}")
