/*  calc_check.pl -- checks every worked calculation quoted in the report.
    swipl calc_check.pl        (prints OK or BAD for each, and exits 1 if any is BAD) */
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

:- initialization(main, main).

:- dynamic bad/0.
ok(Goal, Msg) :- ( catch(Goal, _, fail) -> format("OK  ~w~n", [Msg]) ; format("BAD ~w~n", [Msg]), assertz(bad) ).

step(S, Th, Y) :- ( S >= Th -> Y = 1 ; Y = 0 ).
sig(X, Y) :- Y is 1 / (1 + exp(-X)).
logit(Y, Z) :- Z is log(Y / (1 - Y)).

% transitive closure of a set of edges (pairs X-Y)
closure(Es, C) :- sort(Es, S0), closure_(S0, C).
closure_(C0, C) :-
    findall(X-Z, ( member(X-Y, C0), member(Y-Z, C0) ), New), append(C0, New, A), sort(A, C1),
    ( C1 == C0 -> C = C0 ; closure_(C1, C) ).
subset_of([], []).
subset_of([X|Xs], [X|Ys]) :- subset_of(Xs, Ys).
subset_of([_|Xs], Ys) :- subset_of(Xs, Ys).

% recurrence t(0) = B, t(I) = t(I-1) + S over a domain of indices (stops at the first gap)
rec(B, S, Dom, T) :- ( memberchk(0, Dom) -> rec_(1, S, Dom, [0-B], T) ; T = [] ).
rec_(I, S, Dom, [J-V|Acc], T) :- memberchk(I, Dom), J =:= I - 1, !, V1 is V + S,
    I1 is I + 1, rec_(I1, S, Dom, [I-V1, J-V|Acc], T).
rec_(_, _, _, Acc, T) :- reverse(Acc, T).
closed(B, S, Dom, T) :- findall(I-V, ( member(I, Dom), V is B + S * I ), T).
inverse(V, B, S, I) :- D is V - B, D mod S =:= 0, I is D // S, I >= 0.

main :-
    % 1 AND / OR units (step mode, w = 1)
    Th1 is 1 * (2 - 0.5),
    ok(( Th1 =:= 1.5, step(2, Th1, 1), step(1, Th1, 0) ), "AND unit p=2: threshold 1.5, fires on 2, not on 1"),
    Th2 is 1 * (1 - 0.5),
    ok(( step(1 - 0, Th2, 1), step(1 - 1, Th2, 0) ), "flies unit: bird=1 penguin=0 -> fires; penguin=1 -> silent"),
    ok(( step(1, 0.5, 1), step(0, 0.5, 0) ), "OR output: threshold 0.5"),
    % 2 non-unique inversion: edge sets on 3 nodes whose closure is complete
    Ns = [a, b, c], findall(X-Y, ( member(X, Ns), member(Y, Ns), X \== Y ), E),
    findall(X-Y, ( member(X, Ns), member(Y, Ns) ), Full0), sort(Full0, Full),
    findall(S, ( subset_of(E, S), closure(S, C), C == Full ), Sols), length(Sols, NS),
    findall(L, ( member(S, Sols), length(S, L) ), Ls0), sort(Ls0, Sizes),
    include([S]>>length(S, 3), Sols, Mins), length(Mins, NM), max_list(Ls0, Max),
    format(string(M2), "3-node cycle: ~w inputs give the full closure, sizes ~w, ~w smallest, 1 largest", [NS, Sizes, NM]),
    ok(( NM =:= 2, Max =:= 6 ), M2),
    ok(( closure([a-b, b-c], C1), closure([a-b, b-c, a-c], C2), C1 == C2 ),
       "lost shortcut: edge(a,c) does not change the closure of a->b->c"),
    % 3 exhaustive proof sizes
    ok(( 2 ** 8 =:= 256, 2 ** 7 =:= 128, 2 ** 6 =:= 64, 2 ** 16 =:= 65536 ), "2^8=256, 2^7=128, 2^6=64, 2^16=65,536 inputs"),
    % 4 AlgebraPLOp closed form and inverse
    ok(( rec(3, 5, [0, 1, 2, 3], R1), closed(3, 5, [0, 1, 2, 3], C3), R1 == C3, R1 == [0-3, 1-8, 2-13, 3-18] ),
       "t(I) = 3 + 5I matches the recurrence on 0..3"),
    ok(( rec(3, 5, [0, 1, 3], R2), R2 == [0-3, 1-8], closed(3, 5, [0, 1, 3], C4), memberchk(3-18, C4) ),
       "gap at 2: recurrence stops at t(1)=8, closed form still gives t(3)=18"),
    ok(( inverse(18, 3, 5, 3), \+ inverse(17, 3, 5, _), inverse(4, 10, -2, 3) ),
       "inverse I=(V-b)/s with divisibility guard; decreasing w: from(4,3)"),
    % 5 softmax log-ratio and sigmoid inversion
    ok(( abs(log(0.7 / 0.1) - 1.9459) < 1.0e-4, abs(log(0.2 / 0.1) - 0.6931) < 1.0e-4 ),
       "softmax: z1-z3 = ln 7 = 1.9459, z2-z3 = ln 2 = 0.6931"),
    ok(( logit(0.5, Z), abs((Z + 1) / 2 - 0.5) < 1.0e-12 ), "sigmoid(2x-1)=0.5 -> 2x-1 = logit(0.5) = 0 -> x = 0.5"),
    L0 is 2 * 0.4 - 1, H0 is 2 * 0.6 - 1, sig(L0, YL), sig(H0, YH),
    format(string(M5), "interval: x in [0.4,0.6] -> y in [~4f,~4f], contains 0.5 so the box is kept", [YL, YH]),
    ok(( YL < 0.5, 0.5 < YH ), M5),
    % 6 unicode capacity of S2GN symbols
    Pts is 0x10FFFF - 0x100 + 1, Sur is 0xDFFF - 0xD800 + 1,
    aggregate_all(count, ( between(0, 556927, K), C is 0x100 + 2 * K, C =< 0x10FFFF, \+ between(0xD800, 0xDFFF, C) ), Ev),
    aggregate_all(count, ( between(0, 556927, K), C is 0x101 + 2 * K, C =< 0x10FFFF, \+ between(0xD800, 0xDFFF, C) ), Od),
    Tot is 26 + Ev + Od, EO is Ev + Od,
    format(string(M6), "symbols: ~D points from U+0100, minus ~D surrogates = ~D; ~D even + ~D odd + 26 = ~D", [Pts, Sur, EO, Ev, Od, Tot]),
    ok(( Pts =:= 1113856, Sur =:= 2048, Ev =:= 555904, Od =:= 555904, Tot =:= 1111834 ), M6),
    % 7 MNN speed-up ratio
    ok(( R7 is round(230873 / 82315 * 100) / 100, R7 =:= 2.80 ), "starlog nodes 230,873 -> 82,315 = 2.80x fewer"),
    % 8 logistic unit
    Zs is -1.0 + 2.0 + 1.5, sig(Zs, S8),
    ok(abs(S8 - 0.9241) < 1.0e-4, "score = sigmoid(-1 + 2 + 1.5) = sigmoid(2.5) = 0.9241"),
    % 9 proof/types: exhaustive check size and units of F = m*a
    ok(2 ** 9 =:= 512, "reach:2 in edge:2 checked on 2^9 = 512 inputs (edge over {a,b,c})"),
    UF0 = [kg-1, m-1, s-(-2)], append([kg-1], [m-1, s-(-2)], UF1), msort(UF1, UF), msort(UF0, UF0s),
    ok(UF == UF0s, "units: [F] = [M][A] = kg * m s^-2 = kg m s^-2"),
    ( bad -> halt(1) ; true ).
