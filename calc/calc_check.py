"""Checks every worked calculation quoted in the report."""
import itertools, math
ok = lambda c, m: print(("OK  " if c else "BAD ") + m)

# 1 AND / OR units (step mode, w = 1)
step = lambda s, th: int(s >= th)
th = 1 * (2 - 0.5)                         # grandparent: p = 2 positive inputs
ok(th == 1.5 and step(2, th) == 1 and step(1, th) == 0, "AND unit p=2: threshold 1.5, fires on 2, not on 1")
th = 1 * (1 - 0.5)                         # flies: p = 1, q = 1
ok(step(1 - 0, th) == 1 and step(1 - 1, th) == 0, "flies unit: bird=1 penguin=0 -> fires; penguin=1 -> silent")
ok(step(1, 0.5) == 1 and step(0, 0.5) == 0, "OR output: threshold 0.5")

# 2 non-unique inversion: graphs on 3 nodes whose closure is complete
nodes = "abc"; E = [(x, y) for x in nodes for y in nodes if x != y]
def closure(es):
    c = set(es)
    while True:
        n = c | {(x, z) for (x, y) in c for (y2, z) in c if y == y2}
        if n == c: return c
        c = n
full = closure(E) | {(x, x) for x in nodes}
sols = [s for k in range(7) for s in itertools.combinations(E, k) if closure(s) == full]
sizes = sorted({len(s) for s in sols})
mins = [s for s in sols if len(s) == 3]
ok(len(mins) == 2 and max(sizes) == 6, f"3-node cycle: {len(sols)} inputs give the full closure, sizes {sizes}, {len(mins)} smallest, 1 largest")
ok(closure([("a","b"),("b","c")]) == closure([("a","b"),("b","c"),("a","c")]), "lost shortcut: edge(a,c) does not change the closure of a->b->c")

# 3 exhaustive proof sizes
ok(2**8 == 256 and 2**7 == 128 and 2**6 == 64 and 2**16 == 65536, "2^8=256, 2^7=128, 2^6=64, 2^16=65,536 inputs")

# 4 AlgebraPLOp closed form and inverse
def rec(b, s, dom):
    t = {}
    if 0 in dom: t[0] = b
    i = 1
    while i in dom and i - 1 in t: t[i] = t[i-1] + s; i += 1
    return t
cf = lambda b, s, dom: {i: b + s*i for i in dom}
ok(rec(3, 5, range(4)) == cf(3, 5, range(4)) == {0:3, 1:8, 2:13, 3:18}, "t(I) = 3 + 5I matches the recurrence on 0..3")
ok(rec(3, 5, [0,1,3]) == {0:3, 1:8} and cf(3, 5, [0,1,3])[3] == 18, "gap at 2: recurrence stops at t(1)=8, closed form still gives t(3)=18")
inv = lambda v, b, s: (v - b)//s if (v - b) % s == 0 and (v - b)//s >= 0 else None
ok(inv(18, 3, 5) == 3 and inv(17, 3, 5) is None and inv(4, 10, -2) == 3, "inverse I=(V-b)/s with divisibility guard; decreasing w: from(4,3)")

# 5 softmax log-ratio (exact last layer)
p = [0.7, 0.2, 0.1]
ok(abs(math.log(p[0]/p[2]) - 1.9459) < 1e-4 and abs(math.log(p[1]/p[2]) - 0.6931) < 1e-4, "softmax: z1-z3 = ln 7 = 1.9459, z2-z3 = ln 2 = 0.6931")
logit = lambda y: math.log(y/(1-y))
ok(abs((logit(0.5) + 1)/2 - 0.5) < 1e-12, "sigmoid(2x-1)=0.5 -> 2x-1 = logit(0.5) = 0 -> x = 0.5")
sig = lambda x: 1/(1+math.exp(-x))
l, h = 0.4, 0.6
ok(sig(2*l-1) < 0.5 < sig(2*h-1), f"interval: x in [0.4,0.6] -> y in [{sig(2*l-1):.4f},{sig(2*h-1):.4f}], contains 0.5 so the box is kept")

# 6 unicode capacity of S2GN symbols
pts = 0x10FFFF - 0x100 + 1; sur = 0xDFFF - 0xD800 + 1
ev = sum(1 for c in range(0x100, 0x110000, 2) if not 0xD800 <= c <= 0xDFFF)
od = sum(1 for c in range(0x101, 0x110000, 2) if not 0xD800 <= c <= 0xDFFF)
ok(pts == 1113856 and sur == 2048 and ev == od == 555904 and 26 + ev + od == 1111834,
   f"symbols: {pts:,} points from U+0100, minus {sur:,} surrogates = {ev+od:,}; {ev:,} even + {od:,} odd + 26 = {26+ev+od:,}")

# 7 MNN speed-up ratio
ok(round(230873/82315, 2) == 2.80, "starlog nodes 230,873 -> 82,315 = 2.80x fewer")

# 8 logistic unit
w = {"bias": -1.0, "op=unfold": 2.0, "caller_is_a_target": 1.5}
z = sum(w.values()); ok(abs(1/(1+math.exp(-z)) - 0.9241) < 1e-4, "score = sigmoid(-1 + 2 + 1.5) = sigmoid(2.5) = 0.9241")
