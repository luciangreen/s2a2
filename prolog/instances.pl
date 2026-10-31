/*  instances.pl -- original (unoptimised) programs for each optimisation family.

    inst(Family, Split, Name, Clauses, Targets): Split is train (two per family, the
    only ones the learner sees) or test (programs of other shapes, lengths, names,
    arities and clause positions). The reference optimised program for every
    instance is computed by axioms.pl, never written here. */
:- module(instances, [inst/5, families/1]).
:- discontiguous inst/5.

families([dup_clause, dup_literal, subsumed_clause, implied_clause, dup_then_subsumed,
          pid, loop2, starlog, plop, algebraplop, detlog, piglog2]).

% ---------------------------------------------------------------- bases for the redundancy families
base(reach, [edge(a,b), edge(b,c), edge(c,d), edge(b,e)],
     [(reach(X,Y) :- edge(X,Y)), (reach(X1,Y1) :- edge(X1,Z1), reach(Z1,Y1))], [reach/2], edge, true).
base(ancestor, [parent(ann,bob), parent(bob,cy), parent(cy,dee), parent(bob,eli)],
     [(ancestor(X,Y) :- parent(X,Y)), (ancestor(X1,Y1) :- parent(X1,Z1), ancestor(Z1,Y1))], [ancestor/2], parent, true).
base(grandparent, [parent(ann,bob), parent(bob,cy), parent(ann,dee), parent(dee,eli)],
     [(grandparent(X,Y) :- parent(X,Z), parent(Z,Y))], [grandparent/2], parent, false).
base(sibling, [parent(ann,bob), parent(ann,cy), parent(bob,dee)],
     [(sibling(X,Y) :- parent(P,X), parent(P,Y), X \= Y)], [sibling/2], parent, false).
% compound-argument shape: a(C,D), b(C,E)
base(compound, [a(c1,d1), a(c2,d2), b(c1,e1), b(c3,e3)],
     [(q(C) :- a(C,D), b(C,_E)), (r(C,D) :- a(C,D))], [q/1, r/2], a, false).
% a longer program: three rules, one unrelated
base(path3, [link(a,b), link(b,c), link(c,a), link(c,d)],
     [(node(X) :- link(X,_)), (path(X1,Y1) :- link(X1,Y1)), (path(X2,Y2) :- link(X2,Z2), path(Z2,Y2))],
     [node/1, path/2], link, true).

redundancy_family(dup_clause). redundancy_family(dup_literal). redundancy_family(subsumed_clause).
redundancy_family(implied_clause). redundancy_family(dup_then_subsumed).

inst(F, Split, Name, Clauses, Targets) :-
    redundancy_family(F),
    member(Split-B-Pos, [train-reach-last, train-ancestor-last,
                         test-grandparent-last, test-sibling-last, test-compound-last,
                         test-path3-last, test-path3-first]),
    base(B, Facts, Rules, Targets, Edb, Rec),
    ( F == implied_clause -> Rec == true ; true ),
    ( Pos == first, F \== dup_clause, F \== dup_then_subsumed -> fail ; true ),
    inflate(F, Rules, Edb, Pos, Rules1),
    atomic_list_concat([B, Pos], '_', Name),
    append(Facts, Rules1, Clauses).

% the redundancy that each family removes
inflate(dup_clause, Rules, _, Pos, Out) :- dup_target(Rules, R), copy_term(R, R1), place(Pos, Rules, R1, Out).
inflate(dup_literal, [(H :- B)|Rs], _, _, [(H :- B1)|Rs]) :- B = (G, _), !, B1 = (B, G).
inflate(dup_literal, [(H :- G)|Rs], _, _, [(H :- (G, G))|Rs]).
inflate(subsumed_clause, Rules, Edb, Pos, Out) :-
    dup_target(Rules, R), copy_term(R, (H :- B)), H =.. [_, X|Rest], ( Rest = [Y|_] -> true ; Y = X ),
    Extra =.. [Edb, Y, X], place(Pos, Rules, (H :- (B, Extra)), Out).
inflate(implied_clause, Rules, Edb, Pos, Out) :-
    member((H :- _), Rules), H =.. [P, _, _], functor(H, P, 2), \+ P == node, !,
    H2 =.. [P, X, Y], E1 =.. [Edb, X, Z], E2 =.. [Edb, Z, Y], place(Pos, Rules, (H2 :- (E1, E2)), Out).
inflate(dup_then_subsumed, Rules, Edb, Pos, Out) :-
    inflate(dup_clause, Rules, Edb, Pos, R1), inflate(subsumed_clause, Rules, Edb, Pos, R2),
    last(R2, S), append(R1, [S], Out).

% the clause to duplicate: the last non-recursive rule (so path3 duplicates a path clause)
dup_target(Rules, R) :- reverse(Rules, Rev), member(R, Rev), R = (H :- B), \+ calls_head(B, H), !.
calls_head(B, H) :- functor(H, P, N), sub_term(G, B), compound(G), functor(G, P, N), !.
place(last, Rules, R, Out) :- append(Rules, [R], Out).
place(first, Rules, R, [R|Rules]).

% ---------------------------------------------------------------- Prolog Inductive Debugger
inst(pid, train, path, [edge(a,b), edge(b,c), edge(c,d),
    (path(X,Y) :- edge(X,Y)), (path(X1,Y1) :- path(X1,Z1), edge(Z1,Y1)), (path(X2,Y2) :- path(X2,Y2))], [path/2]).
inst(pid, train, anc, [par(p,q), par(q,r), par(r,s),
    (anc(X,Y) :- par(X,Y)), (anc(X1,Y1) :- anc(X1,Z1), par(Z1,Y1)), (anc(X2,Y2) :- anc(X2,Y2))], [anc/2]).
inst(pid, test, no_loop_clause, [link(a,b), link(b,c),
    (reach(X,Y) :- link(X,Y)), (reach(X1,Y1) :- reach(X1,Z1), link(Z1,Y1))], [reach/2]).
inst(pid, test, extra_rule, [arc(a,b), arc(b,c), arc(c,a),
    (node(X) :- arc(X,_)), (conn(X1,Y1) :- arc(X1,Y1)), (conn(X2,Y2) :- conn(X2,Z2), arc(Z2,Y2)), (conn(X3,Y3) :- conn(X3,Y3))], [node/1, conn/2]).
inst(pid, test, loop_clause_first, [road(a,b), road(b,c), road(c,d),
    (trip(X3,Y3) :- trip(X3,Y3)), (trip(X,Y) :- road(X,Y)), (trip(X1,Y1) :- trip(X1,Z1), road(Z1,Y1))], [trip/2]).

% ---------------------------------------------------------------- loop2 (splice the generator)
inst(loop2, train, colour, [colour(red), colour(blue), (q(X) :- colour(X)), (col(X1) :- q(X1))], [col/1]).
inst(loop2, train, size, [size(s1), size(s2), size(s3), (s(X) :- size(X)), (big(X1) :- s(X1))], [big/1]).
inst(loop2, test, arity2, [edge(a,b), edge(b,c), (e(X,Y) :- edge(X,Y)), (conn(X1,Y1) :- e(X1,Y1))], [conn/2]).
inst(loop2, test, extra_goal, [colour(red), colour(blue), bright(red),
    (q(X) :- colour(X)), (col(X1) :- q(X1), bright(X1))], [col/1]).
inst(loop2, test, two_callers, [colour(red), colour(blue),
    (q(X) :- colour(X)), (col(X1) :- q(X1)), (paint(X2) :- q(X2))], [col/1, paint/1]).

% ---------------------------------------------------------------- Starlog (nest single-use steps)
inst(starlog, train, chain3, [f(a,b), f(b,c), g(b,x), g(c,y), h(x,ok), h(y,ok),
    (t1(X,Y) :- f(X,Y)), (t2(X1,Z1) :- t1(X1,Y1), g(Y1,Z1)), (r(X2,W2) :- t2(X2,Z2), h(Z2,W2))], [r/2]).
inst(starlog, train, chain3b, [a(p,q), a(q,s), b(q,u), b(s,v), c(u,done),
    (u1(X,Y) :- a(X,Y)), (u2(X1,Z1) :- u1(X1,Y1), b(Y1,Z1)), (s(X2,W2) :- u2(X2,Z2), c(Z2,W2))], [s/2]).
inst(starlog, test, chain2, [f(a,b), f(b,c), g(b,x), g(c,y),
    (t1(X,Y) :- f(X,Y)), (r(X1,Z1) :- t1(X1,Y1), g(Y1,Z1))], [r/2]).
inst(starlog, test, chain4, [f(a,b), g(b,c), h(c,d), k(d,e),
    (t1(X,Y) :- f(X,Y)), (t2(X1,Z1) :- t1(X1,Y1), g(Y1,Z1)), (t3(X2,W2) :- t2(X2,Z2), h(Z2,W2)),
    (r(X3,V3) :- t3(X3,W3), k(W3,V3))], [r/2]).
inst(starlog, test, unary_end, [f(a,b), g(b,x), good(x),
    (t1(X,Y) :- f(X,Y)), (t2(X1,Z1) :- t1(X1,Y1), g(Y1,Z1)), (ok(X2) :- t2(X2,Z2), good(Z2))], [ok/1]).

% ---------------------------------------------------------------- PLOp (unfold, compute once)
inst(plop, train, report, [sub(a,s1), sub(b,s2), sub(c,s3), fin(s1,v1), fin(s2,v2), fin(s3,v3),
    good(v1), good(v3), lab(v1,red), lab(v2,green), lab(v3,blue),
    (exp(X,A) :- sub(X,S), fin(S,A)), (row1(X1,A1) :- exp(X1,A1), good(A1)),
    (row2(X2,L2) :- exp(X2,A2), lab(A2,L2)), (report(X3,L3) :- row1(X3,_), row2(X3,L3))], [report/2]).
inst(plop, train, summary, [step(a,m1), step(b,m2), next(m1,n1), next(m2,n2), ok(n1), tag(n1,t1), tag(n2,t2),
    (calc(X,A) :- step(X,S), next(S,A)), (chk(X1,A1) :- calc(X1,A1), ok(A1)),
    (lbl(X2,L2) :- calc(X2,A2), tag(A2,L2)), (summary(X3,L3) :- chk(X3,_), lbl(X3,L3))], [summary/2]).
inst(plop, test, extra_goal, [sub(a,s1), sub(b,s2), fin(s1,v1), fin(s2,v2), good(v1), lab(v1,red), lab(v2,green), shown(red),
    (exp(X,A) :- sub(X,S), fin(S,A)), (row1(X1,A1) :- exp(X1,A1), good(A1)),
    (row2(X2,L2) :- exp(X2,A2), lab(A2,L2)), (report(X3,L3) :- row1(X3,_), row2(X3,L3), shown(L3))], [report/2]).
inst(plop, test, three_rows, [sub(a,s1), sub(b,s2), fin(s1,v1), fin(s2,v2), good(v1), lab(v1,red), lab(v2,green), size(v1,big),
    (exp(X,A) :- sub(X,S), fin(S,A)), (row1(X1,A1) :- exp(X1,A1), good(A1)),
    (row2(X2,L2) :- exp(X2,A2), lab(A2,L2)), (row3(X4,Z4) :- exp(X4,A4), size(A4,Z4)),
    (report(X3,L3,Z3) :- row1(X3,_), row2(X3,L3), row3(X3,Z3))], [report/3]).
inst(plop, test, renamed, [get(k1,j1), get(k2,j2), conv(j1,w1), conv(j2,w2), valid(w2), name(w1,one), name(w2,two),
    (val(X,A) :- get(X,S), conv(S,A)), (good(X1,A1) :- val(X1,A1), valid(A1)),
    (named(X2,L2) :- val(X2,A2), name(A2,L2)), (out(X3,L3) :- good(X3,_), named(X3,L3))], [out/2]).

% ---------------------------------------------------------------- AlgebraPLOp (formula, inverse)
inst(algebraplop, train, base1_step2, [pos(0), pos(1), pos(2), pos(3), pos(4), val(0,1),
    (val(I,V) :- pos(I), I > 0, J is I - 1, val(J,W), V is W + 2), (at(V1,I1) :- val(I1,V1))], [val/2, at/2]).
inst(algebraplop, train, base0_step3, [idx(0), idx(1), idx(2), idx(3), seq(0,0),
    (seq(I,V) :- idx(I), I > 0, J is I - 1, seq(J,W), V is W + 3), (where(V1,I1) :- seq(I1,V1))], [seq/2, where/2]).
inst(algebraplop, test, base3_step5, [n(0), n(1), n(2), n(3), t(0,3),
    (t(I,V) :- n(I), I > 0, J is I - 1, t(J,W), V is W + 5), (inv(V1,I1) :- t(I1,V1))], [t/2, inv/2]).
inst(algebraplop, test, base2_step1_longer, [k(0), k(1), k(2), k(3), k(4), k(5), k(6), u(0,2),
    (u(I,V) :- k(I), I > 0, J is I - 1, u(J,W), V is W + 1), (back(V1,I1) :- u(I1,V1))], [u/2, back/2]).
inst(algebraplop, test, decreasing, [d(0), d(1), d(2), d(3), w(0,10),
    (w(I,V) :- d(I), I > 0, J is I - 1, w(J,W), V is W - 2), (from(V1,I1) :- w(I1,V1))], [w/2, from/2]).

% ---------------------------------------------------------------- Detlog (explicit guard)
inst(detlog, train, sign, [num(-2), num(-1), num(0), num(1), num(2),
    (pos(X) :- num(X), X > 0), (cls(X1,pos) :- pos(X1)), (cls(X2,nonpos) :- num(X2), \+ pos(X2))], [cls/2]).
inst(detlog, train, size, [val(1), val(2), val(3), val(4), val(5),
    (big(X) :- val(X), X >= 3), (label(X1,big) :- big(X1)), (label(X2,small) :- val(X2), \+ big(X2))], [label/2]).
inst(detlog, test, less_than, [num(-2), num(0), num(3),
    (neg(X) :- num(X), X < 0), (sign(X1,n) :- neg(X1)), (sign(X2,nn) :- num(X2), \+ neg(X2))], [sign/2]).
inst(detlog, test, at_most, [score(10), score(50), score(90),
    (low(X) :- score(X), X =< 50), (grade(X1,fail) :- low(X1)), (grade(X2,pass) :- score(X2), \+ low(X2))], [grade/2]).
inst(detlog, test, extra_goal, [num(1), num(5), even(2), num(2),
    (small(X) :- num(X), X < 3), (kind(X1,small) :- small(X1)), (kind(X2,large) :- num(X2), \+ small(X2), X2 > 0)], [kind/2]).

% ---------------------------------------------------------------- Piglog2 (independent groups)
inst(piglog2, train, two_groups, [src(s1), src(s2), wcheck(s1,w1), wcheck(s2,w2), wgood(w1), nccheck(s1,n1), nccheck(s2,n1), ngood(n1),
    (ok(S) :- src(S), wcheck(S,W), wgood(W), nccheck(S,N), ngood(N))], [ok/1]).
inst(piglog2, train, two_groups_b, [job(j1), job(j2), cpu(j1,c1), fast(c1), mem(j1,m1), mem(j2,m2), big(m1),
    (run(J) :- job(J), cpu(J,C), fast(C), mem(J,M), big(M))], [run/1]).
inst(piglog2, test, three_groups, [src(s1), a(s1,x1), b(x1), c(s1,y1), d(y1), e(s1,z1), f(z1),
    (ok(S) :- src(S), a(S,X), b(X), c(S,Y), d(Y), e(S,Z), f(Z))], [ok/1]).
inst(piglog2, test, group_of_three, [src(s1), a(s1,x1), b(x1,x2), g(x2), c(s1,y1), d(y1),
    (ok(S) :- src(S), a(S,X), b(X,X2), g(X2), c(S,Y), d(Y))], [ok/1]).
inst(piglog2, test, two_head_vars, [p(s1), q(t1), a(s1,x1), b(x1), c(t1,y1), d(y1),
    (pair(S,T) :- p(S), q(T), a(S,X), b(X), c(T,Y), d(Y))], [pair/2]).
