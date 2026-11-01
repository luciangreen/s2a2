# S2A2: 200 input/output pairs

Each pair is a query to S2A2: an optimisation family learned from its two training programs, the learned algorithm applied to every unseen test program and to its own training programs (checked against the reference axioms and proved against the original), spec to algorithm with fold and eureka definitions, lemma proofs and discovery, the totality, functionality and answer-type checks, bounded checks, and proof/types. Every output was produced by running this repository's code with `io_pairs/generate.pl`; nothing was written by hand.

| Category | Pairs |
|---|---|
| `s2a2/learn` | 13 |
| `s2a2/apply` | 44 |
| `s2a2/apply-training` | 26 |
| `fold/spec-to-algorithm` | 32 |
| `fold/lemmas` | 10 |
| `fold/checks` | 20 |
| `fold/bounded` | 5 |
| `types/proof-types` | 50 |

## 1. dup_clause: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program reach_last (targets [reach/2])
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).

% training program ancestor_last (targets [ancestor/2])
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).

?- learn_family(dup_clause, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_clause when [duplicate_of_another_clause]
```

## 2. dup_literal: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program reach_last (targets [reach/2])
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B),
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

% training program ancestor_last (targets [ancestor/2])
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B),
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).

?- learn_family(dup_literal, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_lit when [repeats_another_literal]
```

## 3. subsumed_clause: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program reach_last (targets [reach/2])
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B),
    edge(B, A).

% training program ancestor_last (targets [ancestor/2])
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B),
    parent(B, A).

?- learn_family(subsumed_clause, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_clause when [subsumed_by_other_clause]
```

## 4. implied_clause: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program reach_last (targets [reach/2])
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, C),
    edge(C, B).

% training program ancestor_last (targets [ancestor/2])
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, C),
    parent(C, B).

?- learn_family(implied_clause, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_clause when [implied_by_the_other_clauses]
```

## 5. dup_then_subsumed: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program reach_last (targets [reach/2])
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, B),
    edge(B, A).

% training program ancestor_last (targets [ancestor/2])
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, B),
    parent(B, A).

?- learn_family(dup_then_subsumed, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_clause when [duplicate_of_another_clause]
2. del_clause when [subsumed_by_other_clause]
```

## 6. pid: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program path (targets [path/2])
edge(a, b).
edge(b, c).
edge(c, d).
path(A, B) :-
    edge(A, B).
path(A, B) :-
    path(A, C),
    edge(C, B).
path(A, B) :-
    path(A, B).

% training program anc (targets [anc/2])
par(p, q).
par(q, r).
par(r, s).
anc(A, B) :-
    par(A, B).
anc(A, B) :-
    anc(A, C),
    par(C, B).
anc(A, B) :-
    anc(A, B).

?- learn_family(pid, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_clause when [calls_itself_unchanged]
2. replace A([B,C]) :- A([B,D]), E([D,C]) by A([B,C]) :- E([B,D]), A([D,C])
```

## 7. loop2: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program colour (targets [col/1])
colour(red).
colour(blue).
q(A) :-
    colour(A).
col(A) :-
    q(A).

% training program size (targets [big/1])
size(s1).
size(s2).
size(s3).
s(A) :-
    size(A).
big(A) :-
    s(A).

?- learn_family(loop2, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. unfold when []
```

## 8. starlog: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program chain3 (targets [r/2])
f(a, b).
f(b, c).
g(b, x).
g(c, y).
h(x, ok).
h(y, ok).
t1(A, B) :-
    f(A, B).
t2(A, B) :-
    t1(A, C),
    g(C, B).
r(A, B) :-
    t2(A, C),
    h(C, B).

% training program chain3b (targets [s/2])
a(p, q).
a(q, s).
b(q, u).
b(s, v).
c(u, done).
u1(A, B) :-
    a(A, B).
u2(A, B) :-
    u1(A, C),
    b(C, B).
s(A, B) :-
    u2(A, C),
    c(C, B).

?- learn_family(starlog, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. unfold when []
2. del_clause when [defines_unused_non_target]
```

## 9. plop: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program report (targets [report/2])
sub(a, s1).
sub(b, s2).
sub(c, s3).
fin(s1, v1).
fin(s2, v2).
fin(s3, v3).
good(v1).
good(v3).
lab(v1, red).
lab(v2, green).
lab(v3, blue).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
report(A, B) :-
    row1(A, _),
    row2(A, B).

% training program summary (targets [summary/2])
step(a, m1).
step(b, m2).
next(m1, n1).
next(m2, n2).
ok(n1).
tag(n1, t1).
tag(n2, t2).
calc(A, B) :-
    step(A, C),
    next(C, B).
chk(A, B) :-
    calc(A, B),
    ok(B).
lbl(A, B) :-
    calc(A, C),
    tag(C, B).
summary(A, B) :-
    chk(A, _),
    lbl(A, B).

?- learn_family(plop, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. unfold when [caller_is_a_target]
2. merge when [functional_in_first_argument]
```

## 10. algebraplop: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program base1_step2 (targets [val/2,at/2])
pos(0).
pos(1).
pos(2).
pos(3).
pos(4).
val(0, 1).
val(A, B) :-
    pos(A),
    A>0,
    C is A-1,
    val(C, D),
    B is D+2.
at(A, B) :-
    val(B, A).

% training program base0_step3 (targets [seq/2,where/2])
idx(0).
idx(1).
idx(2).
idx(3).
seq(0, 0).
seq(A, B) :-
    idx(A),
    A>0,
    C is A-1,
    seq(C, D),
    B is D+3.
where(A, B) :-
    seq(B, A).

?- learn_family(algebraplop, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. closed_form when [affine_recurrence]
2. invert_formula when []
```

## 11. detlog: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program sign (targets [cls/2])
num(-2).
num(-1).
num(0).
num(1).
num(2).
pos(A) :-
    num(A),
    A>0.
cls(A, pos) :-
    pos(A).
cls(A, nonpos) :-
    num(A),
    \+ pos(A).

% training program size (targets [label/2])
val(1).
val(2).
val(3).
val(4).
val(5).
big(A) :-
    val(A),
    A>=3.
label(A, big) :-
    big(A).
label(A, small) :-
    val(A),
    \+ big(A).

?- learn_family(detlog, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. complement_guard when []
```

## 12. piglog2: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program two_groups (targets [ok/1])
src(s1).
src(s2).
wcheck(s1, w1).
wcheck(s2, w2).
wgood(w1).
nccheck(s1, n1).
nccheck(s2, n1).
ngood(n1).
ok(A) :-
    src(A),
    wcheck(A, B),
    wgood(B),
    nccheck(A, C),
    ngood(C).

% training program two_groups_b (targets [run/1])
job(j1).
job(j2).
cpu(j1, c1).
fast(c1).
mem(j1, m1).
mem(j2, m2).
big(m1).
run(A) :-
    job(A),
    cpu(A, B),
    fast(B),
    mem(A, C),
    big(C).

?- learn_family(piglog2, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. extract when []
```

## 13. proof_types: learn the optimisation algorithm from two training programs

*Category:* `s2a2/learn`

**Input**

```prolog
% training program family (targets [grandparent/2,adult/1])
parent(ann, bob).
parent(bob, cy).
age(ann, 70).
age(eve, 30).
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
grandparent(A, B) :-
    person(A),
    parent(A, C),
    parent(C, B).
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

% training program graph (targets [two_step/2,heavy/1])
link(a, b).
link(b, c).
weight(c, 9).
weight(d, 7).
node(A) :-
    link(A, _).
node(A) :-
    link(_, A).
two_step(A, B) :-
    node(B),
    link(A, C),
    link(C, B).
heavy(A) :-
    node(A),
    weight(A, B),
    B>5.

?- learn_family(proof_types, _Algorithm), show_algorithm(_Algorithm).
```

**Output**

```text
1. del_lit when [type_implied_by_related_variable]
```

## 14. dup_clause: the learned algorithm on the unseen program grandparent_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [grandparent/2]
parent(ann, bob).
parent(bob, cy).
parent(ann, dee).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).

?- optimise(dup_clause, grandparent_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, dee).
parent(bob, cy).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((grandparent(A,B):-[parent(A,C),parent(C,B)]))]))
```

## 15. dup_clause: the learned algorithm on the unseen program sibling_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sibling/2]
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.

?- optimise(dup_clause, sibling_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((sibling(A,B):-[parent(C,A),parent(C,B),A\=B]))]))
```

## 16. dup_clause: the learned algorithm on the unseen program compound_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [q/1,r/2]
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
r(A, B) :-
    a(A, B).

?- optimise(dup_clause, compound_last).
```

**Output**

```text
optimised program:
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((r(A,B):-[a(A,B)]))]))
```

## 17. dup_clause: the learned algorithm on the unseen program path3_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, B).

?- optimise(dup_clause, path3_last).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((path(A,B):-[link(A,B)]))]))
```

## 18. dup_clause: the learned algorithm on the unseen program path3_first

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
path(A, B) :-
    link(A, B).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).

?- optimise(dup_clause, path3_first).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((path(A,B):-[link(A,B)]))]))
```

## 19. dup_literal: the learned algorithm on the unseen program grandparent_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [grandparent/2]
parent(ann, bob).
parent(bob, cy).
parent(ann, dee).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B),
    parent(A, C).

?- optimise(dup_literal, grandparent_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, dee).
parent(bob, cy).
parent(dee, eli).
grandparent(A, B) :-
    parent(C, B),
    parent(A, C).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_literal((grandparent(A,B):-[parent(A,C),parent(C,B),parent(A,C)]))]))
```

## 20. dup_literal: the learned algorithm on the unseen program sibling_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sibling/2]
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B,
    parent(C, A).

?- optimise(dup_literal, sibling_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, B),
    A\=B,
    parent(C, A).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_literal((sibling(A,B):-[parent(C,A),parent(C,B),A\=B,parent(C,A)]))]))
```

## 21. dup_literal: the learned algorithm on the unseen program compound_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [q/1,r/2]
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, B),
    b(A, _),
    a(A, B).
r(A, B) :-
    a(A, B).

?- optimise(dup_literal, compound_last).
```

**Output**

```text
optimised program:
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    b(A, _),
    a(A, _).
r(A, B) :-
    a(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_literal((q(A):-[a(A,B),b(A,C),a(A,B)]))]))
```

## 22. dup_literal: the learned algorithm on the unseen program path3_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, B),
    link(A, B).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).

?- optimise(dup_literal, path3_last).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_literal((node(A):-[link(A,B),link(A,B)]))]))
```

## 23. subsumed_clause: the learned algorithm on the unseen program grandparent_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [grandparent/2]
parent(ann, bob).
parent(bob, cy).
parent(ann, dee).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B),
    parent(B, A).

?- optimise(subsumed_clause, grandparent_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, dee).
parent(bob, cy).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([subsumed((grandparent(A,B):-[parent(A,C),parent(C,B),parent(B,A)]),by((grandparent(D,E):-[parent(D,F),parent(F,E)])))]))
```

## 24. subsumed_clause: the learned algorithm on the unseen program sibling_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sibling/2]
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B,
    parent(B, A).

?- optimise(subsumed_clause, sibling_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
same as the reference axioms: yes
proof against the original: proved(syntactic([subsumed((sibling(A,B):-[parent(C,A),parent(C,B),A\=B,parent(B,A)]),by((sibling(D,E):-[parent(F,D),parent(F,E),D\=E])))]))
```

## 25. subsumed_clause: the learned algorithm on the unseen program compound_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [q/1,r/2]
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
r(A, B) :-
    a(A, B),
    a(B, A).

?- optimise(subsumed_clause, compound_last).
```

**Output**

```text
optimised program:
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([subsumed((r(A,B):-[a(A,B),a(B,A)]),by((r(C,D):-[a(C,D)])))]))
```

## 26. subsumed_clause: the learned algorithm on the unseen program path3_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, B),
    link(B, A).

?- optimise(subsumed_clause, path3_last).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([subsumed((path(A,B):-[link(A,B),link(B,A)]),by((path(C,D):-[link(C,D)])))]))
```

## 27. implied_clause: the learned algorithm on the unseen program path3_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, C),
    link(C, B).

?- optimise(implied_clause, path3_last).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(16))
```

## 28. dup_then_subsumed: the learned algorithm on the unseen program grandparent_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [grandparent/2]
parent(ann, bob).
parent(bob, cy).
parent(ann, dee).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B),
    parent(B, A).

?- optimise(dup_then_subsumed, grandparent_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, dee).
parent(bob, cy).
parent(dee, eli).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((grandparent(A,B):-[parent(A,C),parent(C,B)])),subsumed((grandparent(D,E):-[parent(D,F),parent(F,E),parent(E,D)]),by((grandparent(A,B):-[parent(A,C),parent(C,B)])))]))
```

## 29. dup_then_subsumed: the learned algorithm on the unseen program sibling_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sibling/2]
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B,
    parent(B, A).

?- optimise(dup_then_subsumed, sibling_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
sibling(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((sibling(A,B):-[parent(C,A),parent(C,B),A\=B])),subsumed((sibling(D,E):-[parent(F,D),parent(F,E),D\=E,parent(E,D)]),by((sibling(A,B):-[parent(C,A),parent(C,B),A\=B])))]))
```

## 30. dup_then_subsumed: the learned algorithm on the unseen program compound_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [q/1,r/2]
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
r(A, B) :-
    a(A, B).
r(A, B) :-
    a(A, B),
    a(B, A).

?- optimise(dup_then_subsumed, compound_last).
```

**Output**

```text
optimised program:
a(c1, d1).
a(c2, d2).
b(c1, e1).
b(c3, e3).
q(A) :-
    a(A, _),
    b(A, _).
r(A, B) :-
    a(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((r(A,B):-[a(A,B)])),subsumed((r(C,D):-[a(C,D),a(D,C)]),by((r(A,B):-[a(A,B)])))]))
```

## 31. dup_then_subsumed: the learned algorithm on the unseen program path3_last

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, B),
    link(B, A).

?- optimise(dup_then_subsumed, path3_last).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((path(A,B):-[link(A,B)])),subsumed((path(C,D):-[link(C,D),link(D,C)]),by((path(A,B):-[link(A,B)])))]))
```

## 32. dup_then_subsumed: the learned algorithm on the unseen program path3_first

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,path/2]
link(a, b).
link(b, c).
link(c, a).
link(c, d).
path(A, B) :-
    link(A, B).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
path(A, B) :-
    link(A, C),
    path(C, B).

?- optimise(dup_then_subsumed, path3_first).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
link(c, a).
link(c, d).
node(A) :-
    link(A, _).
path(A, B) :-
    link(A, B).
path(A, B) :-
    link(A, C),
    path(C, B).
same as the reference axioms: yes
proof against the original: proved(syntactic([dup_clause((path(A,B):-[link(A,B)])),dup_clause((path(C,D):-[link(C,E),path(E,D)]))]))
```

## 33. pid: the learned algorithm on the unseen program no_loop_clause

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [reach/2]
link(a, b).
link(b, c).
reach(A, B) :-
    link(A, B).
reach(A, B) :-
    reach(A, C),
    link(C, B).

?- optimise(pid, no_loop_clause).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
reach(A, B) :-
    link(A, B).
reach(A, B) :-
    link(A, C),
    reach(C, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(4))
```

## 34. pid: the learned algorithm on the unseen program extra_rule

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [node/1,conn/2]
arc(a, b).
arc(b, c).
arc(c, a).
node(A) :-
    arc(A, _).
conn(A, B) :-
    arc(A, B).
conn(A, B) :-
    conn(A, C),
    arc(C, B).
conn(A, B) :-
    conn(A, B).

?- optimise(pid, extra_rule).
```

**Output**

```text
optimised program:
arc(a, b).
arc(b, c).
arc(c, a).
node(A) :-
    arc(A, _).
conn(A, B) :-
    arc(A, B).
conn(A, B) :-
    arc(A, C),
    conn(C, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 35. pid: the learned algorithm on the unseen program loop_clause_first

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [trip/2]
road(a, b).
road(b, c).
road(c, d).
trip(A, B) :-
    trip(A, B).
trip(A, B) :-
    road(A, B).
trip(A, B) :-
    trip(A, C),
    road(C, B).

?- optimise(pid, loop_clause_first).
```

**Output**

```text
optimised program:
road(a, b).
road(b, c).
road(c, d).
trip(A, B) :-
    road(A, B).
trip(A, B) :-
    road(A, C),
    trip(C, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 36. loop2: the learned algorithm on the unseen program arity2

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [conn/2]
edge(a, b).
edge(b, c).
e(A, B) :-
    edge(A, B).
conn(A, B) :-
    e(A, B).

?- optimise(loop2, arity2).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
e(A, B) :-
    edge(A, B).
conn(A, B) :-
    edge(A, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(4))
```

## 37. loop2: the learned algorithm on the unseen program extra_goal

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [col/1]
colour(red).
colour(blue).
bright(red).
q(A) :-
    colour(A).
col(A) :-
    q(A),
    bright(A).

?- optimise(loop2, extra_goal).
```

**Output**

```text
optimised program:
bright(red).
colour(blue).
colour(red).
q(A) :-
    colour(A).
col(A) :-
    colour(A),
    bright(A).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 38. loop2: the learned algorithm on the unseen program two_callers

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [col/1,paint/1]
colour(red).
colour(blue).
q(A) :-
    colour(A).
col(A) :-
    q(A).
paint(A) :-
    q(A).

?- optimise(loop2, two_callers).
```

**Output**

```text
optimised program:
colour(blue).
colour(red).
q(A) :-
    colour(A).
col(A) :-
    colour(A).
paint(A) :-
    colour(A).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(4))
```

## 39. starlog: the learned algorithm on the unseen program chain2

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [r/2]
f(a, b).
f(b, c).
g(b, x).
g(c, y).
t1(A, B) :-
    f(A, B).
r(A, B) :-
    t1(A, C),
    g(C, B).

?- optimise(starlog, chain2).
```

**Output**

```text
optimised program:
f(a, b).
f(b, c).
g(b, x).
g(c, y).
r(A, B) :-
    f(A, C),
    g(C, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(16))
```

## 40. starlog: the learned algorithm on the unseen program chain4

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [r/2]
f(a, b).
g(b, c).
h(c, d).
k(d, e).
t1(A, B) :-
    f(A, B).
t2(A, B) :-
    t1(A, C),
    g(C, B).
t3(A, B) :-
    t2(A, C),
    h(C, B).
r(A, B) :-
    t3(A, C),
    k(C, B).

?- optimise(starlog, chain4).
```

**Output**

```text
optimised program:
f(a, b).
g(b, c).
h(c, d).
k(d, e).
r(A, B) :-
    f(A, C),
    g(C, D),
    h(D, E),
    k(E, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(16))
```

## 41. starlog: the learned algorithm on the unseen program unary_end

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [ok/1]
f(a, b).
g(b, x).
good(x).
t1(A, B) :-
    f(A, B).
t2(A, B) :-
    t1(A, C),
    g(C, B).
ok(A) :-
    t2(A, B),
    good(B).

?- optimise(starlog, unary_end).
```

**Output**

```text
optimised program:
good(x).
f(a, b).
g(b, x).
ok(A) :-
    f(A, B),
    g(B, C),
    good(C).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 42. plop: the learned algorithm on the unseen program extra_goal

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [report/2]
sub(a, s1).
sub(b, s2).
fin(s1, v1).
fin(s2, v2).
good(v1).
lab(v1, red).
lab(v2, green).
shown(red).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
report(A, B) :-
    row1(A, _),
    row2(A, B),
    shown(B).

?- optimise(plop, extra_goal).
```

**Output**

```text
optimised program:
good(v1).
shown(red).
fin(s1, v1).
fin(s2, v2).
lab(v1, red).
lab(v2, green).
sub(a, s1).
sub(b, s2).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
report(A, B) :-
    sub(A, C),
    fin(C, D),
    good(D),
    lab(D, B),
    shown(B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(256))
```

## 43. plop: the learned algorithm on the unseen program three_rows

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [report/3]
sub(a, s1).
sub(b, s2).
fin(s1, v1).
fin(s2, v2).
good(v1).
lab(v1, red).
lab(v2, green).
size(v1, big).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
row3(A, B) :-
    exp(A, C),
    size(C, B).
report(A, B, C) :-
    row1(A, _),
    row2(A, B),
    row3(A, C).

?- optimise(plop, three_rows).
```

**Output**

```text
optimised program:
good(v1).
fin(s1, v1).
fin(s2, v2).
lab(v1, red).
lab(v2, green).
size(v1, big).
sub(a, s1).
sub(b, s2).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
row3(A, B) :-
    exp(A, C),
    size(C, B).
report(A, B, C) :-
    sub(A, D),
    fin(D, E),
    good(E),
    lab(E, B),
    size(E, C).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(256))
```

## 44. plop: the learned algorithm on the unseen program renamed

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [out/2]
get(k1, j1).
get(k2, j2).
conv(j1, w1).
conv(j2, w2).
valid(w2).
name(w1, one).
name(w2, two).
val(A, B) :-
    get(A, C),
    conv(C, B).
good(A, B) :-
    val(A, B),
    valid(B).
named(A, B) :-
    val(A, C),
    name(C, B).
out(A, B) :-
    good(A, _),
    named(A, B).

?- optimise(plop, renamed).
```

**Output**

```text
optimised program:
valid(w2).
conv(j1, w1).
conv(j2, w2).
get(k1, j1).
get(k2, j2).
name(w1, one).
name(w2, two).
val(A, B) :-
    get(A, C),
    conv(C, B).
good(A, B) :-
    val(A, B),
    valid(B).
named(A, B) :-
    val(A, C),
    name(C, B).
out(A, B) :-
    get(A, C),
    conv(C, D),
    valid(D),
    name(D, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(128))
```

## 45. algebraplop: the learned algorithm on the unseen program base3_step5

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [t/2,inv/2]
n(0).
n(1).
n(2).
n(3).
t(0, 3).
t(A, B) :-
    n(A),
    A>0,
    C is A-1,
    t(C, D),
    B is D+5.
inv(A, B) :-
    t(B, A).

?- optimise(algebraplop, base3_step5).
```

**Output**

```text
optimised program:
n(0).
n(1).
n(2).
n(3).
inv(A, B) :-
    between(3, 18, A),
    (A-3)mod 5=:=0,
    B is (A-3)//5,
    n(B).
t(A, B) :-
    n(A),
    B is 3+5*A.
same as the reference axioms: yes
proof against the original: proved_if_types_fixed(all_subsets_of_the_other_facts(1),refuted(input([t(0,3),n(0),n(1),n(3)]),only_in_original([inv(3,0),inv(8,1),t(0,3),t(1,8)]),only_in_result([inv(3,0),inv(8,1),inv(18,3),t(0,3),t(1,8),t(3,18)])))
```

## 46. algebraplop: the learned algorithm on the unseen program base2_step1_longer

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [u/2,back/2]
k(0).
k(1).
k(2).
k(3).
k(4).
k(5).
k(6).
u(0, 2).
u(A, B) :-
    k(A),
    A>0,
    C is A-1,
    u(C, D),
    B is D+1.
back(A, B) :-
    u(B, A).

?- optimise(algebraplop, base2_step1_longer).
```

**Output**

```text
optimised program:
k(0).
k(1).
k(2).
k(3).
k(4).
k(5).
k(6).
back(A, B) :-
    between(2, 8, A),
    (A-2)mod 1=:=0,
    B is (A-2)//1,
    k(B).
u(A, B) :-
    k(A),
    B is 2+1*A.
same as the reference axioms: yes
proof against the original: proved_if_types_fixed(all_subsets_of_the_other_facts(1),refuted(input([u(0,2),k(0),k(1),k(2),k(3),k(4),k(6)]),only_in_original([back(2,0),back(3,1),back(4,2),back(5,3),back(6,4),u(0,2),u(1,3),u(2,4),u(3,5),u(4,6)]),only_in_result([back(2,0),back(3,1),back(4,2),back(5,3),back(6,4),back(8,6),u(0,2),u(1,3),u(2,4),u(3,5),u(4,6),u(6,8)])))
```

## 47. algebraplop: the learned algorithm on the unseen program decreasing

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [w/2,from/2]
d(0).
d(1).
d(2).
d(3).
w(0, 10).
w(A, B) :-
    d(A),
    A>0,
    C is A-1,
    w(C, D),
    B is D-2.
from(A, B) :-
    w(B, A).

?- optimise(algebraplop, decreasing).
```

**Output**

```text
optimised program:
d(0).
d(1).
d(2).
d(3).
from(A, B) :-
    between(4, 10, A),
    (A-10)mod-2=:=0,
    B is (A-10)// -2,
    d(B).
w(A, B) :-
    d(A),
    B is 10+ -2*A.
same as the reference axioms: yes
proof against the original: proved_if_types_fixed(all_subsets_of_the_other_facts(1),refuted(input([w(0,10),d(0),d(1),d(3)]),only_in_original([from(8,1),from(10,0),w(0,10),w(1,8)]),only_in_result([from(4,3),from(8,1),from(10,0),w(0,10),w(1,8),w(3,4)])))
```

## 48. detlog: the learned algorithm on the unseen program less_than

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sign/2]
num(-2).
num(0).
num(3).
neg(A) :-
    num(A),
    A<0.
sign(A, n) :-
    neg(A).
sign(A, nn) :-
    num(A),
    \+ neg(A).

?- optimise(detlog, less_than).
```

**Output**

```text
optimised program:
num(-2).
num(0).
num(3).
neg(A) :-
    num(A),
    A<0.
sign(A, n) :-
    neg(A).
sign(A, nn) :-
    num(A),
    A>=0.
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 49. detlog: the learned algorithm on the unseen program at_most

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [grade/2]
score(10).
score(50).
score(90).
low(A) :-
    score(A),
    A=<50.
grade(A, fail) :-
    low(A).
grade(A, pass) :-
    score(A),
    \+ low(A).

?- optimise(detlog, at_most).
```

**Output**

```text
optimised program:
score(10).
score(50).
score(90).
low(A) :-
    score(A),
    A=<50.
grade(A, fail) :-
    low(A).
grade(A, pass) :-
    score(A),
    A>50.
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 50. detlog: the learned algorithm on the unseen program extra_goal

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [kind/2]
num(1).
num(5).
even(2).
num(2).
small(A) :-
    num(A),
    A<3.
kind(A, small) :-
    small(A).
kind(A, large) :-
    num(A),
    \+ small(A),
    A>0.

?- optimise(detlog, extra_goal).
```

**Output**

```text
optimised program:
even(2).
num(1).
num(2).
num(5).
small(A) :-
    num(A),
    A<3.
kind(A, small) :-
    small(A).
kind(A, large) :-
    num(A),
    A>=3,
    A>0.
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(16))
```

## 51. piglog2: the learned algorithm on the unseen program three_groups

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [ok/1]
src(s1).
a(s1, x1).
b(x1).
c(s1, y1).
d(y1).
e(s1, z1).
f(z1).
ok(A) :-
    src(A),
    a(A, B),
    b(B),
    c(A, C),
    d(C),
    e(A, D),
    f(D).

?- optimise(piglog2, three_groups).
```

**Output**

```text
optimised program:
b(x1).
d(y1).
f(z1).
src(s1).
a(s1, x1).
c(s1, y1).
e(s1, z1).
ok(A) :-
    src(A),
    inv_1(A),
    inv_2(A),
    inv_3(A).
inv_1(A) :-
    a(A, B),
    b(B).
inv_2(A) :-
    c(A, B),
    d(B).
inv_3(A) :-
    e(A, B),
    f(B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(128))
```

## 52. piglog2: the learned algorithm on the unseen program group_of_three

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [ok/1]
src(s1).
a(s1, x1).
b(x1, x2).
g(x2).
c(s1, y1).
d(y1).
ok(A) :-
    src(A),
    a(A, B),
    b(B, C),
    g(C),
    c(A, D),
    d(D).

?- optimise(piglog2, group_of_three).
```

**Output**

```text
optimised program:
d(y1).
g(x2).
src(s1).
a(s1, x1).
b(x1, x2).
c(s1, y1).
ok(A) :-
    src(A),
    inv_1(A),
    inv_2(A).
inv_1(A) :-
    a(A, B),
    b(B, C),
    g(C).
inv_2(A) :-
    c(A, B),
    d(B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(64))
```

## 53. piglog2: the learned algorithm on the unseen program two_head_vars

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [pair/2]
p(s1).
q(t1).
a(s1, x1).
b(x1).
c(t1, y1).
d(y1).
pair(A, B) :-
    p(A),
    q(B),
    a(A, C),
    b(C),
    c(B, D),
    d(D).

?- optimise(piglog2, two_head_vars).
```

**Output**

```text
optimised program:
b(x1).
d(y1).
p(s1).
q(t1).
a(s1, x1).
c(t1, y1).
pair(A, B) :-
    p(A),
    q(B),
    inv_1(A),
    inv_2(B).
inv_1(A) :-
    a(A, B),
    b(B).
inv_2(A) :-
    c(A, B),
    d(B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(64))
```

## 54. proof_types: the learned algorithm on the unseen program sibling_two_guards

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [sib/2]
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    person(B),
    parent(C, A),
    parent(C, B),
    A\=B.

?- optimise(proof_types, sibling_two_guards).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(ann, cy).
parent(bob, dee).
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    parent(C, A),
    parent(C, B),
    A\=B.
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 55. proof_types: the learned algorithm on the unseen program renamed_with_kept_guard

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [manages/2,pay/2]
works(al, d1).
works(bo, d2).
boss(cy, d1).
salary(al, 5).
salary(zed, 3).
employee(A) :-
    works(A, _).
manages(A, B) :-
    employee(B),
    works(B, C),
    boss(A, C).
pay(A, B) :-
    employee(A),
    salary(A, B).

?- optimise(proof_types, renamed_with_kept_guard).
```

**Output**

```text
optimised program:
boss(cy, d1).
salary(al, 5).
salary(zed, 3).
works(al, d1).
works(bo, d2).
employee(A) :-
    works(A, _).
manages(A, B) :-
    works(B, C),
    boss(A, C).
pay(A, B) :-
    employee(A),
    salary(A, B).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(32))
```

## 56. proof_types: the learned algorithm on the unseen program chain_through_recursion

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [start/1,reach/2]
edge(a, b).
edge(b, c).
edge(c, a).
node(A) :-
    edge(A, _).
node(A) :-
    edge(_, A).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
start(A) :-
    node(A),
    reach(A, _).

?- optimise(proof_types, chain_through_recursion).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(c, a).
node(A) :-
    edge(A, _).
node(A) :-
    edge(_, A).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
start(A) :-
    reach(A, _).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(8))
```

## 57. proof_types: the learned algorithm on the unseen program guard_implied_by_guard

*Category:* `s2a2/apply`

**Input**

```prolog
% targets [elder/1]
parent(ann, bob).
parent(bob, cy).
person(A) :-
    parent(A, _).
human(A) :-
    person(A).
elder(A) :-
    human(A),
    person(A),
    parent(A, B),
    parent(B, _).

?- optimise(proof_types, guard_implied_by_guard).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
person(A) :-
    parent(A, _).
human(A) :-
    person(A).
elder(A) :-
    parent(A, B),
    parent(B, _).
same as the reference axioms: yes
proof against the original: proved(all_subsets_of_the_facts(4))
```

## 58. dup_clause: the learned algorithm on its own training program reach_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [reach/2]
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).

?- optimise_train(dup_clause, reach_last).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(b, e).
edge(c, d).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).
same as the reference axioms: yes
```

## 59. dup_clause: the learned algorithm on its own training program ancestor_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ancestor/2]
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).

?- optimise_train(dup_clause, ancestor_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
parent(bob, eli).
parent(cy, dee).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).
same as the reference axioms: yes
```

## 60. dup_literal: the learned algorithm on its own training program reach_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [reach/2]
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B),
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- optimise_train(dup_literal, reach_last).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(b, e).
edge(c, d).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
same as the reference axioms: yes
```

## 61. dup_literal: the learned algorithm on its own training program ancestor_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ancestor/2]
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B),
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).

?- optimise_train(dup_literal, ancestor_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
parent(bob, eli).
parent(cy, dee).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
same as the reference axioms: yes
```

## 62. subsumed_clause: the learned algorithm on its own training program reach_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [reach/2]
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B),
    edge(B, A).

?- optimise_train(subsumed_clause, reach_last).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(b, e).
edge(c, d).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
same as the reference axioms: yes
```

## 63. subsumed_clause: the learned algorithm on its own training program ancestor_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ancestor/2]
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B),
    parent(B, A).

?- optimise_train(subsumed_clause, ancestor_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
parent(bob, eli).
parent(cy, dee).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
same as the reference axioms: yes
```

## 64. implied_clause: the learned algorithm on its own training program reach_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [reach/2]
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, C),
    edge(C, B).

?- optimise_train(implied_clause, reach_last).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(b, e).
edge(c, d).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
same as the reference axioms: yes
```

## 65. implied_clause: the learned algorithm on its own training program ancestor_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ancestor/2]
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, C),
    parent(C, B).

?- optimise_train(implied_clause, ancestor_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
parent(bob, eli).
parent(cy, dee).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
same as the reference axioms: yes
```

## 66. dup_then_subsumed: the learned algorithm on its own training program reach_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [reach/2]
edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, B),
    edge(B, A).

?- optimise_train(dup_then_subsumed, reach_last).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(b, e).
edge(c, d).
reach(A, B) :-
    edge(A, C),
    reach(C, B).
reach(A, B) :-
    edge(A, B).
same as the reference axioms: yes
```

## 67. dup_then_subsumed: the learned algorithm on its own training program ancestor_last

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ancestor/2]
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
parent(bob, eli).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).
ancestor(A, B) :-
    parent(A, B),
    parent(B, A).

?- optimise_train(dup_then_subsumed, ancestor_last).
```

**Output**

```text
optimised program:
parent(ann, bob).
parent(bob, cy).
parent(bob, eli).
parent(cy, dee).
ancestor(A, B) :-
    parent(A, C),
    ancestor(C, B).
ancestor(A, B) :-
    parent(A, B).
same as the reference axioms: yes
```

## 68. pid: the learned algorithm on its own training program path

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [path/2]
edge(a, b).
edge(b, c).
edge(c, d).
path(A, B) :-
    edge(A, B).
path(A, B) :-
    path(A, C),
    edge(C, B).
path(A, B) :-
    path(A, B).

?- optimise_train(pid, path).
```

**Output**

```text
optimised program:
edge(a, b).
edge(b, c).
edge(c, d).
path(A, B) :-
    edge(A, B).
path(A, B) :-
    edge(A, C),
    path(C, B).
same as the reference axioms: yes
```

## 69. pid: the learned algorithm on its own training program anc

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [anc/2]
par(p, q).
par(q, r).
par(r, s).
anc(A, B) :-
    par(A, B).
anc(A, B) :-
    anc(A, C),
    par(C, B).
anc(A, B) :-
    anc(A, B).

?- optimise_train(pid, anc).
```

**Output**

```text
optimised program:
par(p, q).
par(q, r).
par(r, s).
anc(A, B) :-
    par(A, B).
anc(A, B) :-
    par(A, C),
    anc(C, B).
same as the reference axioms: yes
```

## 70. loop2: the learned algorithm on its own training program colour

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [col/1]
colour(red).
colour(blue).
q(A) :-
    colour(A).
col(A) :-
    q(A).

?- optimise_train(loop2, colour).
```

**Output**

```text
optimised program:
colour(blue).
colour(red).
q(A) :-
    colour(A).
col(A) :-
    colour(A).
same as the reference axioms: yes
```

## 71. loop2: the learned algorithm on its own training program size

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [big/1]
size(s1).
size(s2).
size(s3).
s(A) :-
    size(A).
big(A) :-
    s(A).

?- optimise_train(loop2, size).
```

**Output**

```text
optimised program:
size(s1).
size(s2).
size(s3).
s(A) :-
    size(A).
big(A) :-
    size(A).
same as the reference axioms: yes
```

## 72. starlog: the learned algorithm on its own training program chain3

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [r/2]
f(a, b).
f(b, c).
g(b, x).
g(c, y).
h(x, ok).
h(y, ok).
t1(A, B) :-
    f(A, B).
t2(A, B) :-
    t1(A, C),
    g(C, B).
r(A, B) :-
    t2(A, C),
    h(C, B).

?- optimise_train(starlog, chain3).
```

**Output**

```text
optimised program:
f(a, b).
f(b, c).
g(b, x).
g(c, y).
h(x, ok).
h(y, ok).
r(A, B) :-
    f(A, C),
    g(C, D),
    h(D, B).
same as the reference axioms: yes
```

## 73. starlog: the learned algorithm on its own training program chain3b

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [s/2]
a(p, q).
a(q, s).
b(q, u).
b(s, v).
c(u, done).
u1(A, B) :-
    a(A, B).
u2(A, B) :-
    u1(A, C),
    b(C, B).
s(A, B) :-
    u2(A, C),
    c(C, B).

?- optimise_train(starlog, chain3b).
```

**Output**

```text
optimised program:
a(p, q).
a(q, s).
b(q, u).
b(s, v).
c(u, done).
s(A, B) :-
    a(A, C),
    b(C, D),
    c(D, B).
same as the reference axioms: yes
```

## 74. plop: the learned algorithm on its own training program report

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [report/2]
sub(a, s1).
sub(b, s2).
sub(c, s3).
fin(s1, v1).
fin(s2, v2).
fin(s3, v3).
good(v1).
good(v3).
lab(v1, red).
lab(v2, green).
lab(v3, blue).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
report(A, B) :-
    row1(A, _),
    row2(A, B).

?- optimise_train(plop, report).
```

**Output**

```text
optimised program:
good(v1).
good(v3).
fin(s1, v1).
fin(s2, v2).
fin(s3, v3).
lab(v1, red).
lab(v2, green).
lab(v3, blue).
sub(a, s1).
sub(b, s2).
sub(c, s3).
exp(A, B) :-
    sub(A, C),
    fin(C, B).
row1(A, B) :-
    exp(A, B),
    good(B).
row2(A, B) :-
    exp(A, C),
    lab(C, B).
report(A, B) :-
    sub(A, C),
    fin(C, D),
    good(D),
    lab(D, B).
same as the reference axioms: yes
```

## 75. plop: the learned algorithm on its own training program summary

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [summary/2]
step(a, m1).
step(b, m2).
next(m1, n1).
next(m2, n2).
ok(n1).
tag(n1, t1).
tag(n2, t2).
calc(A, B) :-
    step(A, C),
    next(C, B).
chk(A, B) :-
    calc(A, B),
    ok(B).
lbl(A, B) :-
    calc(A, C),
    tag(C, B).
summary(A, B) :-
    chk(A, _),
    lbl(A, B).

?- optimise_train(plop, summary).
```

**Output**

```text
optimised program:
ok(n1).
next(m1, n1).
next(m2, n2).
step(a, m1).
step(b, m2).
tag(n1, t1).
tag(n2, t2).
calc(A, B) :-
    step(A, C),
    next(C, B).
chk(A, B) :-
    calc(A, B),
    ok(B).
lbl(A, B) :-
    calc(A, C),
    tag(C, B).
summary(A, B) :-
    step(A, C),
    next(C, D),
    ok(D),
    tag(D, B).
same as the reference axioms: yes
```

## 76. algebraplop: the learned algorithm on its own training program base1_step2

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [val/2,at/2]
pos(0).
pos(1).
pos(2).
pos(3).
pos(4).
val(0, 1).
val(A, B) :-
    pos(A),
    A>0,
    C is A-1,
    val(C, D),
    B is D+2.
at(A, B) :-
    val(B, A).

?- optimise_train(algebraplop, base1_step2).
```

**Output**

```text
optimised program:
pos(0).
pos(1).
pos(2).
pos(3).
pos(4).
at(A, B) :-
    between(1, 9, A),
    (A-1)mod 2=:=0,
    B is (A-1)//2,
    pos(B).
val(A, B) :-
    pos(A),
    B is 1+2*A.
same as the reference axioms: yes
```

## 77. algebraplop: the learned algorithm on its own training program base0_step3

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [seq/2,where/2]
idx(0).
idx(1).
idx(2).
idx(3).
seq(0, 0).
seq(A, B) :-
    idx(A),
    A>0,
    C is A-1,
    seq(C, D),
    B is D+3.
where(A, B) :-
    seq(B, A).

?- optimise_train(algebraplop, base0_step3).
```

**Output**

```text
optimised program:
idx(0).
idx(1).
idx(2).
idx(3).
where(A, B) :-
    between(0, 9, A),
    (A-0)mod 3=:=0,
    B is (A-0)//3,
    idx(B).
seq(A, B) :-
    idx(A),
    B is 3*A.
same as the reference axioms: yes
```

## 78. detlog: the learned algorithm on its own training program sign

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [cls/2]
num(-2).
num(-1).
num(0).
num(1).
num(2).
pos(A) :-
    num(A),
    A>0.
cls(A, pos) :-
    pos(A).
cls(A, nonpos) :-
    num(A),
    \+ pos(A).

?- optimise_train(detlog, sign).
```

**Output**

```text
optimised program:
num(-2).
num(-1).
num(0).
num(1).
num(2).
pos(A) :-
    num(A),
    A>0.
cls(A, pos) :-
    pos(A).
cls(A, nonpos) :-
    num(A),
    A=<0.
same as the reference axioms: yes
```

## 79. detlog: the learned algorithm on its own training program size

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [label/2]
val(1).
val(2).
val(3).
val(4).
val(5).
big(A) :-
    val(A),
    A>=3.
label(A, big) :-
    big(A).
label(A, small) :-
    val(A),
    \+ big(A).

?- optimise_train(detlog, size).
```

**Output**

```text
optimised program:
val(1).
val(2).
val(3).
val(4).
val(5).
big(A) :-
    val(A),
    A>=3.
label(A, big) :-
    big(A).
label(A, small) :-
    val(A),
    A<3.
same as the reference axioms: yes
```

## 80. piglog2: the learned algorithm on its own training program two_groups

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [ok/1]
src(s1).
src(s2).
wcheck(s1, w1).
wcheck(s2, w2).
wgood(w1).
nccheck(s1, n1).
nccheck(s2, n1).
ngood(n1).
ok(A) :-
    src(A),
    wcheck(A, B),
    wgood(B),
    nccheck(A, C),
    ngood(C).

?- optimise_train(piglog2, two_groups).
```

**Output**

```text
optimised program:
ngood(n1).
src(s1).
src(s2).
wgood(w1).
nccheck(s1, n1).
nccheck(s2, n1).
wcheck(s1, w1).
wcheck(s2, w2).
ok(A) :-
    src(A),
    inv_1(A),
    inv_2(A).
inv_1(A) :-
    wcheck(A, B),
    wgood(B).
inv_2(A) :-
    nccheck(A, B),
    ngood(B).
same as the reference axioms: yes
```

## 81. piglog2: the learned algorithm on its own training program two_groups_b

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [run/1]
job(j1).
job(j2).
cpu(j1, c1).
fast(c1).
mem(j1, m1).
mem(j2, m2).
big(m1).
run(A) :-
    job(A),
    cpu(A, B),
    fast(B),
    mem(A, C),
    big(C).

?- optimise_train(piglog2, two_groups_b).
```

**Output**

```text
optimised program:
big(m1).
fast(c1).
job(j1).
job(j2).
cpu(j1, c1).
mem(j1, m1).
mem(j2, m2).
run(A) :-
    job(A),
    inv_1(A),
    inv_2(A).
inv_1(A) :-
    cpu(A, B),
    fast(B).
inv_2(A) :-
    mem(A, B),
    big(B).
same as the reference axioms: yes
```

## 82. proof_types: the learned algorithm on its own training program family

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [grandparent/2,adult/1]
parent(ann, bob).
parent(bob, cy).
age(ann, 70).
age(eve, 30).
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
grandparent(A, B) :-
    person(A),
    parent(A, C),
    parent(C, B).
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- optimise_train(proof_types, family).
```

**Output**

```text
optimised program:
age(ann, 70).
age(eve, 30).
parent(ann, bob).
parent(bob, cy).
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
grandparent(A, B) :-
    parent(A, C),
    parent(C, B).
adult(A) :-
    person(A),
    age(A, B),
    B>=18.
same as the reference axioms: yes
```

## 83. proof_types: the learned algorithm on its own training program graph

*Category:* `s2a2/apply-training`

**Input**

```prolog
% targets [two_step/2,heavy/1]
link(a, b).
link(b, c).
weight(c, 9).
weight(d, 7).
node(A) :-
    link(A, _).
node(A) :-
    link(_, A).
two_step(A, B) :-
    node(B),
    link(A, C),
    link(C, B).
heavy(A) :-
    node(A),
    weight(A, B),
    B>5.

?- optimise_train(proof_types, graph).
```

**Output**

```text
optimised program:
link(a, b).
link(b, c).
weight(c, 9).
weight(d, 7).
node(A) :-
    link(A, _).
node(A) :-
    link(_, A).
two_step(A, B) :-
    link(A, C),
    link(C, B).
heavy(A) :-
    node(A),
    weight(A, B),
    B>5.
same as the reference axioms: yes
```

## 84. Spec to algorithm: append three lists

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
app3(A, B, C, D) :-
    app(A, B, E),
    app(E, C, D).

?- derive_with([append,app3], app3/4, [in(list(any)),in(list(any)),in(any),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest,accumulate,tuple]); lemmas found and used: []
derived program:
    app3([],A,B,C) :- app(A,B,C).
    app3([A|B],C,D,[A|E]) :- app3(B,C,D,E).
    app([],A,A).
    app([A|B],C,[A|D]) :- app(B,C,D).
total: yes, specification functional: yes, typed answers: no
```

## 85. Spec to algorithm: naive reverse

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- derive_with([append,nrev], rev/2, [in(list(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [app_assoc]
derived program:
    rev([],[]).
    rev([A|B],C) :- rev_acc(B,[A],C).
    rev_acc([],A,A).
    rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D).
total: yes, specification functional: yes, typed answers: yes
```

## 86. Spec to algorithm: tree flatten

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- derive_with([append,flat], flat/2, [in(tree(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [app_assoc]
derived program:
    flat(leaf,[]).
    flat(node(A,B,C),D) :- flat(C,E), flat_acc(A,[B|E],D).
    flat_acc(leaf,A,A).
    flat_acc(node(A,B,C),D,E) :- flat_acc(C,D,F), flat_acc(A,[B|F],E).
total: yes, specification functional: yes, typed answers: yes
```

## 87. Spec to algorithm: sum of a list

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- derive_with([sum], sum/2, [in(list(int)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [plus_assoc]
derived program:
    sum([],0).
    sum([A|B],C) :- sum_acc(B,C,A).
    sum_acc([],A,B) :- A is 0+B.
    sum_acc([A|B],C,D) :- E is A+D, sum_acc(B,C,E).
total: yes, specification functional: yes, typed answers: no
```

## 88. Spec to algorithm: length of a list

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
len([], 0).
len([_|A], B) :-
    len(A, C),
    B is C+1.

?- derive_with([len], len/2, [in(list(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [plus_assoc]
derived program:
    len([],0).
    len([A|B],C) :- len_acc(B,C,1).
    len_acc([],A,B) :- A is 0+B.
    len_acc([A|B],C,D) :- E is 1+D, len_acc(B,C,E).
total: yes, specification functional: yes, typed answers: yes
```

## 89. Spec to algorithm: Fibonacci on naturals

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- derive_with([fib], fib/2, [in(nat),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: tuple (attempt 3 of [deforest,accumulate,tuple]); lemmas found and used: []
derived program:
    fib(0,0).
    fib(s(0),1).
    fib(s(s(A)),B) :- fib_tup(A,C,D), B is C+D.
    fib_tup(0,1,0).
    fib_tup(s(A),B,C) :- fib_tup(A,C,D), B is C+D.
total: yes, specification functional: yes, typed answers: yes
```

## 90. Spec to algorithm: product of a list

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
prod([], 1).
prod([A|B], C) :-
    prod(B, D),
    C is D*A.

?- derive_with([prod], prod/2, [in(list(int)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [times_assoc]
derived program:
    prod([],1).
    prod([A|B],C) :- prod_acc(B,C,A).
    prod_acc([],A,B) :- A is 1*B.
    prod_acc([A|B],C,D) :- E is A*D, prod_acc(B,C,E).
total: yes, specification functional: yes, typed answers: no
```

## 91. Spec to algorithm: size of a tree

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
size(leaf, 0).
size(node(A, _, B), C) :-
    size(A, D),
    size(B, E),
    C is D+E+1.

?- derive_with([size], size/2, [in(tree(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
no derivation with the strategies [deforest,accumulate,tuple]
```

## 92. Spec to algorithm: append four lists

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
app4(A, B, C, D, E) :-
    app(A, B, F),
    app(F, C, G),
    app(G, D, E).

?- derive_with([append,app4], app4/5, [in(list(any)),in(list(any)),in(list(any)),in(any),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest,accumulate,tuple]); lemmas found and used: []
derived program:
    app4([],A,B,C,D) :- app(A,B,E), app(E,C,D).
    app4([A|B],C,D,E,[A|F]) :- app4(B,C,D,E,F).
    app([],A,A).
    app([A|B],C,[A|D]) :- app(B,C,D).
total: no, specification functional: yes, typed answers: no
```

## 93. Spec to algorithm: length of an append

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
len([], 0).
len([_|A], B) :-
    len(A, C),
    B is C+1.
lenapp(A, B, C) :-
    app(A, B, D),
    len(D, C).

?- derive_with([append,lenapp], lenapp/3, [in(list(any)),in(list(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest,accumulate,tuple]); lemmas found and used: []
derived program:
    lenapp([],A,B) :- len(A,B).
    lenapp([A|B],C,D) :- lenapp(B,C,E), D is E+1.
    len([],0).
    len([A|B],C) :- len(B,D), C is D+1.
total: yes, specification functional: yes, typed answers: no
```

## 94. Spec to algorithm: reverse then append

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).
revapp(A, B, C) :-
    rev(A, D),
    app(D, B, C).

?- derive_with([append,revapp], revapp/3, [in(list(any)),in(any),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest,accumulate,tuple]); lemmas found and used: [app_assoc]
derived program:
    revapp([],A,A).
    revapp([A|B],C,D) :- revapp(B,[A|C],D).
total: yes, specification functional: yes, typed answers: yes
```

## 95. Spec to algorithm: double every element

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
dbl([], []).
dbl([A|B], [C|D]) :-
    C is 2*A,
    dbl(B, D).

?- derive_with([dbl], dbl/2, [in(list(int)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
no derivation with the strategies [deforest,accumulate,tuple]
```

## 96. Spec to algorithm: sum of the doubled list

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
dbl([], []).
dbl([A|B], [C|D]) :-
    C is 2*A,
    dbl(B, D).
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.
sumdbl(A, B) :-
    dbl(A, C),
    sum(C, B).

?- derive_with([sumdbl], sumdbl/2, [in(list(int)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest,accumulate,tuple]); lemmas found and used: []
derived program:
    sumdbl([],0).
    sumdbl([A|B],C) :- D is 2*A, sumdbl(B,E), C is E+D.
total: yes, specification functional: yes, typed answers: no
```

## 97. Spec to algorithm: nodes of a tree in order

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
nodes(leaf, []).
nodes(node(A, B, C), D) :-
    nodes(A, E),
    nodes(C, F),
    app(E, [B|F], D).

?- derive_with([append,nodes], nodes/2, [in(tree(any)),out], [deforest, accumulate, tuple]).
```

**Output**

```text
strategy: accumulate (attempt 2 of [deforest,accumulate,tuple]); lemmas found and used: [app_assoc]
derived program:
    nodes(leaf,[]).
    nodes(node(A,B,C),D) :- nodes(C,E), nodes_acc(A,[B|E],D).
    nodes_acc(leaf,A,A).
    nodes_acc(node(A,B,C),D,E) :- nodes_acc(C,D,F), nodes_acc(A,[B|F],E).
total: yes, specification functional: yes, typed answers: yes
```

## 98. Spec to algorithm: append three lists with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
app3(A, B, C, D) :-
    app(A, B, E),
    app(E, C, D).

?- derive_with([append,app3], app3/4, [in(list(any)),in(list(any)),in(any),out], [deforest]).
```

**Output**

```text
strategy: deforest (attempt 1 of [deforest]); lemmas found and used: []
derived program:
    app3([],A,B,C) :- app(A,B,C).
    app3([A|B],C,D,[A|E]) :- app3(B,C,D,E).
    app([],A,A).
    app([A|B],C,[A|D]) :- app(B,C,D).
total: yes, specification functional: yes, typed answers: no
```

## 99. Spec to algorithm: append three lists with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
app3(A, B, C, D) :-
    app(A, B, E),
    app(E, C, D).

?- derive_with([append,app3], app3/4, [in(list(any)),in(list(any)),in(any),out], [accumulate]).
```

**Output**

```text
no derivation with the strategies [accumulate]
```

## 100. Spec to algorithm: append three lists with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
app3(A, B, C, D) :-
    app(A, B, E),
    app(E, C, D).

?- derive_with([append,app3], app3/4, [in(list(any)),in(list(any)),in(any),out], [tuple]).
```

**Output**

```text
no derivation with the strategies [tuple]
```

## 101. Spec to algorithm: naive reverse with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- derive_with([append,nrev], rev/2, [in(list(any)),out], [deforest]).
```

**Output**

```text
no derivation with the strategies [deforest]
```

## 102. Spec to algorithm: naive reverse with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- derive_with([append,nrev], rev/2, [in(list(any)),out], [accumulate]).
```

**Output**

```text
strategy: accumulate (attempt 1 of [accumulate]); lemmas found and used: [app_assoc]
derived program:
    rev([],[]).
    rev([A|B],C) :- rev_acc(B,[A],C).
    rev_acc([],A,A).
    rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D).
total: yes, specification functional: yes, typed answers: yes
```

## 103. Spec to algorithm: naive reverse with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- derive_with([append,nrev], rev/2, [in(list(any)),out], [tuple]).
```

**Output**

```text
no derivation with the strategies [tuple]
```

## 104. Spec to algorithm: tree flatten with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- derive_with([append,flat], flat/2, [in(tree(any)),out], [deforest]).
```

**Output**

```text
no derivation with the strategies [deforest]
```

## 105. Spec to algorithm: tree flatten with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- derive_with([append,flat], flat/2, [in(tree(any)),out], [accumulate]).
```

**Output**

```text
strategy: accumulate (attempt 1 of [accumulate]); lemmas found and used: [app_assoc]
derived program:
    flat(leaf,[]).
    flat(node(A,B,C),D) :- flat(C,E), flat_acc(A,[B|E],D).
    flat_acc(leaf,A,A).
    flat_acc(node(A,B,C),D,E) :- flat_acc(C,D,F), flat_acc(A,[B|F],E).
total: yes, specification functional: yes, typed answers: yes
```

## 106. Spec to algorithm: tree flatten with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- derive_with([append,flat], flat/2, [in(tree(any)),out], [tuple]).
```

**Output**

```text
no derivation with the strategies [tuple]
```

## 107. Spec to algorithm: sum of a list with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- derive_with([sum], sum/2, [in(list(int)),out], [deforest]).
```

**Output**

```text
no derivation with the strategies [deforest]
```

## 108. Spec to algorithm: sum of a list with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- derive_with([sum], sum/2, [in(list(int)),out], [accumulate]).
```

**Output**

```text
strategy: accumulate (attempt 1 of [accumulate]); lemmas found and used: [plus_assoc]
derived program:
    sum([],0).
    sum([A|B],C) :- sum_acc(B,C,A).
    sum_acc([],A,B) :- A is 0+B.
    sum_acc([A|B],C,D) :- E is A+D, sum_acc(B,C,E).
total: yes, specification functional: yes, typed answers: no
```

## 109. Spec to algorithm: sum of a list with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- derive_with([sum], sum/2, [in(list(int)),out], [tuple]).
```

**Output**

```text
no derivation with the strategies [tuple]
```

## 110. Spec to algorithm: length of a list with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
len([], 0).
len([_|A], B) :-
    len(A, C),
    B is C+1.

?- derive_with([len], len/2, [in(list(any)),out], [deforest]).
```

**Output**

```text
no derivation with the strategies [deforest]
```

## 111. Spec to algorithm: length of a list with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
len([], 0).
len([_|A], B) :-
    len(A, C),
    B is C+1.

?- derive_with([len], len/2, [in(list(any)),out], [accumulate]).
```

**Output**

```text
strategy: accumulate (attempt 1 of [accumulate]); lemmas found and used: [plus_assoc]
derived program:
    len([],0).
    len([A|B],C) :- len_acc(B,C,1).
    len_acc([],A,B) :- A is 0+B.
    len_acc([A|B],C,D) :- E is 1+D, len_acc(B,C,E).
total: yes, specification functional: yes, typed answers: yes
```

## 112. Spec to algorithm: length of a list with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
len([], 0).
len([_|A], B) :-
    len(A, C),
    B is C+1.

?- derive_with([len], len/2, [in(list(any)),out], [tuple]).
```

**Output**

```text
no derivation with the strategies [tuple]
```

## 113. Spec to algorithm: Fibonacci on naturals with only the deforest strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- derive_with([fib], fib/2, [in(nat),out], [deforest]).
```

**Output**

```text
no derivation with the strategies [deforest]
```

## 114. Spec to algorithm: Fibonacci on naturals with only the accumulate strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- derive_with([fib], fib/2, [in(nat),out], [accumulate]).
```

**Output**

```text
no derivation with the strategies [accumulate]
```

## 115. Spec to algorithm: Fibonacci on naturals with only the tuple strategy

*Category:* `fold/spec-to-algorithm`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- derive_with([fib], fib/2, [in(nat),out], [tuple]).
```

**Output**

```text
strategy: tuple (attempt 1 of [tuple]); lemmas found and used: []
derived program:
    fib(0,0).
    fib(s(0),1).
    fib(s(s(A)),B) :- fib_tup(A,C,D), B is C+D.
    fib_tup(0,1,0).
    fib_tup(s(A),B,C) :- fib_tup(A,C,D), B is C+D.
total: yes, specification functional: yes, typed answers: yes
```

## 116. Lemma: associativity of append

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(X,Y,W), app(W,Z,R)], [app(Y,Z,V), app(X,V,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
proved (induction_on(1)); both sides become
    l_lhs([],A,B,C) :- app(A,B,C).
    l_lhs([A|B],C,D,[A|E]) :- l_lhs(B,C,D,E).
H = induction_on(1)
```

## 117. Lemma: associativity, mirrored

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(Y,Z,V), app(X,V,R)], [app(X,Y,W), app(W,Z,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
proved (induction_on(3)); both sides become
    l_lhs(A,B,[],C) :- app(A,B,C).
    l_lhs(A,B,[C|D],[C|E]) :- l_lhs(A,B,D,E).
H = induction_on(3)
```

## 118. Lemma: commutativity of append

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(X,Y,R)], [app(Y,X,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
not_proved
```

## 119. Lemma: append with the arguments of the second call swapped

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(X,Y,W), app(W,Z,R)], [app(X,Z,V), app(V,Y,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
not_proved
```

## 120. Lemma: appending in either grouping, four lists

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(A,B,X), app(X,C,Y), app(Y,D,R)], [app(A,B,X), app(C,D,Z), app(X,Z,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
not_proved
```

## 121. Lemma: a call equals itself

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(X,Y,R)], [app(X,Y,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
proved (induction_on(1)); both sides become
    l_lhs([],A,A).
    l_lhs([A|B],C,[A|D]) :- l_lhs(B,C,D).
H = induction_on(1)
```

## 122. Lemma: the second list dropped

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), prove_lemma(_S, lemma(l, [app(X,Y,R)], [app(X,X,R)]), _R), ( _R = proved(H, _P) -> format("proved (~w); both sides become~n", [H]), show(_P) ; writeln(_R) ).
```

**Output**

```text
not_proved
```

## 123. Lemmas conjectured from a stuck reverse step

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), clauses([(p([H|T],A,R) :- rev(T,E), app(E,[H],F), app(F,A,R))], _St), discover_lemmas(_S, _St, [], _F), forall(member(X, _F), ( functor(X, Kind, _), arg(1, X, Lm), arg(1, Lm, Name), format("~w: ~w~n", [Name, Kind]) )).
```

**Output**

```text
app_assoc: proved
app_comm: refuted
```

## 124. Lemmas conjectured from a stuck flatten step

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), clauses([(p(node(L,X,Rt),A,F) :- flat(L,FL), flat(Rt,FR), app(FL,[X|FR],G), app(G,A,F))], _St), discover_lemmas(_S, _St, [], _F), forall(member(X, _F), ( functor(X, Kind, _), arg(1, X, Lm), arg(1, Lm, Name), format("~w: ~w~n", [Name, Kind]) )).
```

**Output**

```text
app_assoc: proved
app_comm: refuted
```

## 125. Lemmas conjectured from a stuck sum step

*Category:* `fold/lemmas`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).

?- spec_prog([append], _S), clauses([(p([H|T],S,A) :- sum(T,S2), S1 is S2+H, S is S1+A)], _St), discover_lemmas(_S, _St, [], _F), forall(member(X, _F), ( functor(X, Kind, _), arg(1, X, Lm), arg(1, Lm, Name), format("~w: ~w~n", [Name, Kind]) )).
```

**Output**

```text
plus_assoc: axiom
```

## 126. Accumulator reverse answers every list

*Category:* `fold/checks`

**Input**

```prolog
rev([], []).
rev([A|B], C) :-
    rev_acc(B, [A], C).
rev_acc([], A, A).
rev_acc([A|B], C, D) :-
    rev_acc(B, [A|C], D).

?- check_total(acc,rev/2,[in(list(any)),out]).
```

**Output**

```text
total
```

## 127. A missing base case is not total

*Category:* `fold/checks`

**Input**

```prolog
rev_acc([A|B], C, D) :-
    rev_acc(B, [A|C], D).

?- check_total(nobase,rev_acc/3,[in(list(any)),in(any),out]).
```

**Output**

```text
not_total
```

## 128. Recursion on the same argument is not total

*Category:* `fold/checks`

**Input**

```prolog
rev_acc([], A, A).
rev_acc([A|B], C, D) :-
    rev_acc([A|B], C, D).

?- check_total(loop,rev_acc/3,[in(list(any)),in(any),out]).
```

**Output**

```text
not_total
```

## 129. Tree size with arithmetic is total

*Category:* `fold/checks`

**Input**

```prolog
size(leaf, 0).
size(node(A, _, B), C) :-
    size(A, D),
    size(B, E),
    C is D+E+1.

?- check_total(size,size/2,[in(tree(any)),out]).
```

**Output**

```text
total
```

## 130. A tree predicate without the node case is not total

*Category:* `fold/checks`

**Input**

```prolog
size(leaf, 0).

?- check_total(leafonly,size/2,[in(tree(any)),out]).
```

**Output**

```text
not_total
```

## 131. Nested natural-number patterns that cover

*Category:* `fold/checks`

**Input**

```prolog
f(0, 0).
f(s(0), 1).
f(s(s(A)), B) :-
    f(A, B).

?- check_total(even,f/2,[in(nat),out]).
```

**Output**

```text
total
```

## 132. Nested patterns missing s(0)

*Category:* `fold/checks`

**Input**

```prolog
f(0, 0).
f(s(s(A)), B) :-
    f(A, B).

?- check_total(evenmissing,f/2,[in(nat),out]).
```

**Output**

```text
not_total
```

## 133. A comparison in the body can fail

*Category:* `fold/checks`

**Input**

```prolog
g([], 0).
g([A|B], C) :-
    A>0,
    g(B, C).

?- check_total(test,g/2,[in(list(int)),out]).
```

**Output**

```text
not_total
```

## 134. Linear Fibonacci is total

*Category:* `fold/checks`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib_tup(A, C, D),
    B is C+D.
fib_tup(0, 1, 0).
fib_tup(s(A), B, C) :-
    fib_tup(A, C, D),
    B is C+D.

?- check_total(fibt,fib/2,[in(nat),out]).
```

**Output**

```text
total
```

## 135. Naive sum is total on integer lists

*Category:* `fold/checks`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- check_total(sum,sum/2,[in(list(int)),out]).
```

**Output**

```text
total
```

## 136. Naive reverse has at most one answer

*Category:* `fold/checks`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- check_fun(nrev,rev/2,[in,out]).
```

**Output**

```text
functional
```

## 137. Two answers for one input

*Category:* `fold/checks`

**Input**

```prolog
q([], a).
q([], b).

?- check_fun(two,q/2,[in,out]).
```

**Output**

```text
not_functional
```

## 138. Fibonacci has at most one answer

*Category:* `fold/checks`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- check_fun(fib,fib/2,[in,out]).
```

**Output**

```text
functional
```

## 139. Tree flatten has at most one answer

*Category:* `fold/checks`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- check_fun(flat,flat/2,[in,out]).
```

**Output**

```text
functional
```

## 140. Sum has at most one answer

*Category:* `fold/checks`

**Input**

```prolog
sum([], 0).
sum([A|B], C) :-
    sum(B, D),
    C is D+A.

?- check_fun(sum,sum/2,[in,out]).
```

**Output**

```text
functional
```

## 141. Reverse answers only lists

*Category:* `fold/checks`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- check_slot(nrev,rev/2,1).
```

**Output**

```text
every answer has type list(any) at argument 1
```

## 142. Append's second argument can be anything

*Category:* `fold/checks`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
rev([], []).
rev([A|B], C) :-
    rev(B, D),
    app(D, [A], C).

?- check_slot(nrev,app/3,2).
```

**Output**

```text
no type found for argument 2
```

## 143. Fibonacci's first argument is a natural

*Category:* `fold/checks`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- check_slot(fib,fib/2,1).
```

**Output**

```text
no type found for argument 1
```

## 144. Fibonacci's answer is an integer

*Category:* `fold/checks`

**Input**

```prolog
fib(0, 0).
fib(s(0), 1).
fib(s(s(A)), B) :-
    fib(s(A), C),
    fib(A, D),
    B is C+D.

?- check_slot(fib,fib/2,2).
```

**Output**

```text
every answer has type int at argument 2
```

## 145. Flatten answers only trees

*Category:* `fold/checks`

**Input**

```prolog
app([], A, A).
app([A|B], C, [A|D]) :-
    app(B, C, D).
flat(leaf, []).
flat(node(A, B, C), D) :-
    flat(A, E),
    flat(C, F),
    app(E, [B|F], D).

?- check_slot(flat,flat/2,1).
```

**Output**

```text
every answer has type tree(any) at argument 1
```

## 146. Naive and accumulator reverse on every list up to length 6

*Category:* `fold/bounded`

**Input**

```prolog
?- beq(nrev, acc, rev/2, [in(list(any)), out], 6).
```

**Output**

```text
equal_on(127)
```

## 147. Naive and linear Fibonacci up to 15

*Category:* `fold/bounded`

**Input**

```prolog
?- beq(fib, fibt, fib/2, [in(nat), out], 15).
```

**Output**

```text
equal_on(16)
```

## 148. Reverse checked with both arguments given

*Category:* `fold/bounded`

**Input**

```prolog
?- beq(nrev, acc, rev/2, [in(list(any)), in(list(any))], 3).
```

**Output**

```text
equal_on(225)
```

## 149. Sum against itself

*Category:* `fold/bounded`

**Input**

```prolog
?- beq(sum, sum, sum/2, [in(list(int)), out], 3).
```

**Output**

```text
equal_on(85)
```

## 150. Two programs that differ at s(0)

*Category:* `fold/bounded`

**Input**

```prolog
?- beq(even, evenmissing, f/2, [in(nat), out], 6).
```

**Output**

```text
refuted(input([s(0)]),first([f(s(0),1)]),second([]))
```

## 151. reach: is edge/2:1 contained in edge/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:1, edge/2:2).
```

**Output**

```text
not proved
```

## 152. reach: is edge/2:1 contained in reach/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:1, reach/2:1).
```

**Output**

```text
proved: [cover(edge/2:1,reach/2:1,reach(A,B)-[edge(A,B)])]
```

## 153. reach: is edge/2:1 contained in reach/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:1, reach/2:2).
```

**Output**

```text
not proved
```

## 154. reach: is edge/2:2 contained in edge/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:2, edge/2:1).
```

**Output**

```text
not proved
```

## 155. reach: is edge/2:2 contained in reach/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:2, reach/2:1).
```

**Output**

```text
not proved
```

## 156. reach: is edge/2:2 contained in reach/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, edge/2:2, reach/2:2).
```

**Output**

```text
proved: [cover(edge/2:2,reach/2:2,reach(A,B)-[edge(A,B)])]
```

## 157. reach: is reach/2:1 contained in edge/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, reach/2:1, edge/2:1).
```

**Output**

```text
proved: [flow(reach/2:1,edge/2:1)]
```

## 158. reach: is reach/2:1 contained in edge/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, reach/2:1, edge/2:2).
```

**Output**

```text
not proved
```

## 159. reach: is reach/2:1 contained in reach/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, reach/2:1, reach/2:2).
```

**Output**

```text
not proved
```

## 160. reach: is reach/2:2 contained in edge/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
reach(A, B) :-
    edge(A, B).
reach(A, B) :-
    edge(A, C),
    reach(C, B).

?- incl(reach, reach/2:2, edge/2:1).
```

**Output**

```text
not proved
```

## 161. family: is adult/1:1 contained in age/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, age/2:1).
```

**Output**

```text
proved: [flow(adult/1:1,age/2:1)]
```

## 162. family: is adult/1:1 contained in age/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, age/2:2).
```

**Output**

```text
not proved
```

## 163. family: is adult/1:1 contained in parent/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, parent/2:1).
```

**Output**

```text
not proved
```

## 164. family: is adult/1:1 contained in parent/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, parent/2:2).
```

**Output**

```text
not proved
```

## 165. family: is adult/1:1 contained in person/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, person/1:1).
```

**Output**

```text
proved: [flow(adult/1:1,person/1:1)]
```

## 166. family: is adult/1:1 contained in sib/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, sib/2:1).
```

**Output**

```text
not proved
```

## 167. family: is adult/1:1 contained in sib/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, adult/1:1, sib/2:2).
```

**Output**

```text
not proved
```

## 168. family: is age/2:1 contained in adult/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, adult/1:1).
```

**Output**

```text
not proved
```

## 169. family: is age/2:1 contained in age/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, age/2:2).
```

**Output**

```text
not proved
```

## 170. family: is age/2:1 contained in parent/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, parent/2:1).
```

**Output**

```text
not proved
```

## 171. family: is age/2:1 contained in parent/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, parent/2:2).
```

**Output**

```text
not proved
```

## 172. family: is age/2:1 contained in person/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, person/1:1).
```

**Output**

```text
not proved
```

## 173. family: is age/2:1 contained in sib/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, sib/2:1).
```

**Output**

```text
not proved
```

## 174. family: is age/2:1 contained in sib/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:1, sib/2:2).
```

**Output**

```text
not proved
```

## 175. family: is age/2:2 contained in adult/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, adult/1:1).
```

**Output**

```text
not proved
```

## 176. family: is age/2:2 contained in age/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, age/2:1).
```

**Output**

```text
not proved
```

## 177. family: is age/2:2 contained in parent/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, parent/2:1).
```

**Output**

```text
not proved
```

## 178. family: is age/2:2 contained in parent/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, parent/2:2).
```

**Output**

```text
not proved
```

## 179. family: is age/2:2 contained in person/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, person/1:1).
```

**Output**

```text
not proved
```

## 180. family: is age/2:2 contained in sib/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, sib/2:1).
```

**Output**

```text
not proved
```

## 181. family: is age/2:2 contained in sib/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- incl(family, age/2:2, sib/2:2).
```

**Output**

```text
not proved
```

## 182. numbers: is num/1:1 contained in pos/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, num/1:1, pos/1:1).
```

**Output**

```text
not proved
```

## 183. numbers: is num/1:1 contained in val/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, num/1:1, val/2:1).
```

**Output**

```text
not proved
```

## 184. numbers: is num/1:1 contained in val/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, num/1:1, val/2:2).
```

**Output**

```text
not proved
```

## 185. numbers: is pos/1:1 contained in num/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, pos/1:1, num/1:1).
```

**Output**

```text
proved: [flow(pos/1:1,num/1:1)]
```

## 186. numbers: is pos/1:1 contained in val/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, pos/1:1, val/2:1).
```

**Output**

```text
not proved
```

## 187. numbers: is pos/1:1 contained in val/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, pos/1:1, val/2:2).
```

**Output**

```text
not proved
```

## 188. numbers: is val/2:1 contained in num/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:1, num/1:1).
```

**Output**

```text
proved: [flow(val/2:1,num/1:1)]
```

## 189. numbers: is val/2:1 contained in pos/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:1, pos/1:1).
```

**Output**

```text
proved: [flow(val/2:1,pos/1:1)]
```

## 190. numbers: is val/2:1 contained in val/2:2?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:1, val/2:2).
```

**Output**

```text
not proved
```

## 191. numbers: is val/2:2 contained in num/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:2, num/1:1).
```

**Output**

```text
not proved
```

## 192. numbers: is val/2:2 contained in pos/1:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:2, pos/1:1).
```

**Output**

```text
not proved
```

## 193. numbers: is val/2:2 contained in val/2:1?

*Category:* `types/proof-types`

**Input**

```prolog
pos(A) :-
    num(A),
    A>0.
val(A, B) :-
    pos(A),
    B is 1+2*A.

?- incl(numbers, val/2:2, val/2:1).
```

**Output**

```text
not proved
```

## 194. family: is literal 1 of rule 3 implied by a related variable?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- tp(family, _P), ( implied_guard(_P, 3, 1, R) -> true ; R = kept ).
```

**Output**

```text
R = implied(_, by(parent/2:2), [cover(parent/2:2, person/1:1, person(A)-[parent(B, A)])])
```

## 195. family: is literal 2 of rule 3 implied by a related variable?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- tp(family, _P), ( implied_guard(_P, 3, 2, R) -> true ; R = kept ).
```

**Output**

```text
R = kept
```

## 196. family: is literal 3 of rule 3 implied by a related variable?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- tp(family, _P), ( implied_guard(_P, 3, 3, R) -> true ; R = kept ).
```

**Output**

```text
R = kept
```

## 197. family: is literal 1 of rule 4 implied by a related variable?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- tp(family, _P), ( implied_guard(_P, 4, 1, R) -> true ; R = kept ).
```

**Output**

```text
R = kept
```

## 198. family: is literal 2 of rule 4 implied by a related variable?

*Category:* `types/proof-types`

**Input**

```prolog
person(A) :-
    parent(A, _).
person(A) :-
    parent(_, A).
sib(A, B) :-
    person(A),
    parent(C, A),
    parent(C, B),
    A\=B.
adult(A) :-
    person(A),
    age(A, B),
    B>=18.

?- tp(family, _P), ( implied_guard(_P, 4, 2, R) -> true ; R = kept ).
```

**Output**

```text
R = kept
```

## 199. Units of F = m*a

*Category:* `types/proof-types`

**Input**

```prolog
force(A, B) :-
    mass(A, C),
    acc(A, D),
    B is C*D.

?- tp(physics, _P), dimensions(_P, [((mass/2):2)-[kg-1], ((acc/2):2)-[m-1, s-(-2)], ((force/2):2)-[kg-1, m-1, s-(-2)]], Result).
```

**Output**

```text
Result = ok([(force/2:2)-[kg-1, m-1, s- -2]])
```

## 200. Units of F = m+a are refuted

*Category:* `types/proof-types`

**Input**

```prolog
force(A, B) :-
    mass(A, C),
    acc(A, D),
    B is C+D.

?- tp(physics_bad, _P), dimensions(_P, [((mass/2):2)-[kg-1], ((acc/2):2)-[m-1, s-(-2)], ((force/2):2)-[kg-1, m-1, s-(-2)]], Result).
```

**Output**

```text
Result = refuted(force(A, B)-[mass(A, C), acc(A, D), B is C+D], 'sum of quantities with different units in A is B+C')
```

