/*  generate.pl -- 200 input/output pairs for S2A2, each produced by running the code: every
    family learned from its training programs, the learned algorithms on every test and
    training program, spec to algorithm (fold.pl), lemmas, the totality, functionality and
    type checks, bounded checks, and proof/types. From the repository root:
        swipl -q -g main -t halt io_pairs/generate.pl
    writes io_pairs/pairs.jsonl and io_pairs/io_pairs.md. */
:- prolog_load_context(directory, D), assertz(user:io_dir(D)).
:- use_module(harness).
:- use_module(to_markdown).
:- use_module('../prolog/s2a2').
:- use_module('../prolog/axioms').
:- use_module('../prolog/instances').
:- use_module('../prolog/prover').
:- use_module('../prolog/types').
:- use_module('../prolog/fold', [spec_to_algorithm/5, spec_to_algorithm/6, verify/5, show/1, prove_lemma/3,
                                 discover_lemmas/4, clauses/2, bounded_equal/7]).
:- style_check(-singleton).
% experiment.pl is not a module and has its own main/0: load it into a module of its own
:- io_dir(D), atom_concat(D, '/../prolog/experiment.pl', F), exp:consult(F).
proof(P0, P1, T, R) :- exp:proof(P0, P1, T, R).

:- dynamic learned/2.
learn_family(F, Alg) :- learned(F, Alg), !.
learn_family(F, Alg) :-
    axioms(F, Ax),
    findall(pair(B, A, T), ( inst(F, train, _, Cs, T), program_from_clauses(Cs, B), apply_algorithm(Ax, B, T, A, _) ), Pairs),
    learn(Pairs, Alg), assertz(learned(F, Alg)).

optimise(F, Name) :-
    learn_family(F, Alg), inst(F, test, Name, Cs, T), program_from_clauses(Cs, P0),
    apply_algorithm(Alg, P0, T, P1, _), program_to_clauses(P1, C1),
    format("optimised program:~n"), forall(member(C, C1), portray_clause(C)),
    axioms(F, Ax), apply_algorithm(Ax, P0, T, Ref, _), preds_of(P0, Fx),
    ( same_program(P1, Ref, Fx) -> E = yes ; E = no ),
    proof(P0, P1, T, Pr),
    copy_term(Pr, Pc), numbervars(Pc, 0, _),
    format("same as the reference axioms: ~w~nproof against the original: ~p~n", [E, Pc]).

clauses_text(Cs, Text) :- with_output_to(string(Text), forall(member(C, Cs), portray_clause(C))).
train_text(F, Text) :-
    with_output_to(string(Text),
        forall(inst(F, train, N, Cs, T), ( format("% training program ~w (targets ~q)~n", [N, T]), forall(member(C, Cs), portray_clause(C)), nl ))).
test_text(F, N, Text) :- inst(F, test, N, Cs, T),
    with_output_to(string(Text), ( format("% targets ~q~n", [T]), forall(member(C, Cs), portray_clause(C)) )).

spec(append, [ app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R)) ]).
spec(app3,   [ (app3(X, Y, Z, R) :- app(X, Y, W), app(W, Z, R)) ]).
spec(nrev,   [ rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)) ]).
spec(flat,   [ flat(leaf, []), (flat(node(L, X, R), F) :- flat(L, FL), flat(R, FR), app(FL, [X|FR], F)) ]).
spec(sum,    [ sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H) ]).
spec(len,    [ len([], 0), (len([_|T], N) :- len(T, M), N is M + 1) ]).
spec(fib,    [ fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2) ]).
spec_prog(Ns, P) :- foldl([N, A0, A]>>( spec(N, Cs), clauses(Cs, P1), append(A0, P1, A) ), Ns, [], P).
spec_text(Ns, Text) :- findall(C, ( member(N, Ns), spec(N, Cs), member(C, Cs) ), All), clauses_text(All, Text).

derive(Ns, K, Mode) :-
    spec_prog(Ns, S), spec_to_algorithm(S, K, [], P0, report(St, _, Used, _, _)),
    verify(S, P0, K, Mode, verdict(total(T), functional(F), typed_answers(Ty), _, P)),
    format("strategy: ~w; lemmas found and used: ~w~nderived program:~n", [St, Used]), show(P),
    format("total: ~w, specification functional: ~w, typed answers: ~w~n", [T, F, Ty]).

prog(reach, [(reach(X,Y) :- edge(X,Y)), (reach(X1,Y1) :- edge(X1,Z1), reach(Z1,Y1))]).
prog(family, [(person(A) :- parent(A,_)), (person(B) :- parent(_,B)),
              (sib(S,T) :- person(S), parent(P,S), parent(P,T), S \= T),
              (adult(X) :- person(X), age(X,G), G >= 18)]).
prog(numbers, [(pos(N) :- num(N), N > 0), (val(I,V) :- pos(I), V is 1+2*I)]).
prog(physics, [(force(O,F) :- mass(O,M), acc(O,A), F is M*A)]).
prog(physics_bad, [(force(O,F) :- mass(O,M), acc(O,A), F is M+A)]).
tp(N, P) :- prog(N, Cs), program_from_clauses(Cs, P).
ptext(N, T) :- prog(N, Cs), clauses_text(Cs, T).

optimise_train(F, Name) :-
    learn_family(F, Alg), inst(F, train, Name, Cs, T), program_from_clauses(Cs, P0),
    apply_algorithm(Alg, P0, T, P1, _), program_to_clauses(P1, C1),
    format("optimised program:~n"), forall(member(C, C1), portray_clause(C)),
    axioms(F, Ax), apply_algorithm(Ax, P0, T, Ref, _), preds_of(P0, Fx),
    ( same_program(P1, Ref, Fx) -> E = yes ; E = no ), format("same as the reference axioms: ~w~n", [E]).
train_one_text(F, N, Text) :- inst(F, train, N, Cs, T),
    with_output_to(string(Text), ( format("% targets ~q~n", [T]), forall(member(C, Cs), portray_clause(C)) )).

spec(prod,   [ prod([], 1), (prod([H|T], P) :- prod(T, P1), P is P1 * H) ]).
spec(size,   [ size(leaf, 0), (size(node(L, _, R), N) :- size(L, A), size(R, B), N is A + B + 1) ]).
spec(app4,   [ (app4(A, B, C, D, R) :- app(A, B, X), app(X, C, Y), app(Y, D, R)) ]).
spec(lenapp, [ len([], 0), (len([_|T], N) :- len(T, M), N is M + 1), (lenapp(X, Y, N) :- app(X, Y, Z), len(Z, N)) ]).
spec(revapp, [ rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)), (revapp(X, Y, R) :- rev(X, Z), app(Z, Y, R)) ]).
spec(dbl,    [ dbl([], []), (dbl([H|T], [D|R]) :- D is 2 * H, dbl(T, R)) ]).
spec(sumdbl, [ dbl([], []), (dbl([H|T], [D|R]) :- D is 2 * H, dbl(T, R)), sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H), (sumdbl(L, S) :- dbl(L, D), sum(D, S)) ]).
spec(nodes,  [ nodes(leaf, []), (nodes(node(L, X, R), N) :- nodes(L, NL), nodes(R, NR), app(NL, [X|NR], N)) ]).

derive_with(Ns, K, Mode, Order) :-
    spec_prog(Ns, S),
    (   spec_to_algorithm(S, K, [], Order, P0, report(St, _, Used, Att, _))
    ->  format("strategy: ~w (attempt ~w of ~w); lemmas found and used: ~w~n", [St, Att, Order, Used]),
        (   verify(S, P0, K, Mode, verdict(total(T), functional(F), typed_answers(Ty), _, P))
        ->  format("derived program:~n"), show(P), format("total: ~w, specification functional: ~w, typed answers: ~w~n", [T, F, Ty])
        ;   format("derived program (not verified):~n"), show(P0) )
    ;   format("no derivation with the strategies ~w~n", [Order]) ).

check_total(Name, K, Mode) :- prog_t(Name, P), ( fold:total(P, K, Mode) -> R = total ; R = not_total ), format("~w~n", [R]).
check_fun(Name, K, Mode) :- prog_t(Name, P), ( fold:functional(P, K, Mode) -> R = functional ; R = not_functional ), format("~w~n", [R]).
check_slot(Name, K, I) :- prog_t(Name, P), ( fold:slot_type(P, K, I, T) -> format("every answer has type ~q at argument ~w~n", [T, I]) ; format("no type found for argument ~w~n", [I]) ).
prog_t(Name, P) :- tprog(Name, Cs), clauses(Cs, P).
tprog(acc,   [rev([], []), (rev([H|T], R) :- rev_acc(T, [H], R)), rev_acc([], A, A), (rev_acc([H|T], A, R) :- rev_acc(T, [H|A], R))]).
tprog(nrev,  [app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R)), rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R))]).
tprog(nobase, [(rev_acc([H|T], A, R) :- rev_acc(T, [H|A], R))]).
tprog(loop,  [rev_acc([], A, A), (rev_acc([H|T], A, R) :- rev_acc([H|T], A, R))]).
tprog(size,  [size(leaf, 0), (size(node(L, _, R), N) :- size(L, A), size(R, B), N is A + B + 1)]).
tprog(leafonly, [size(leaf, 0)]).
tprog(even,  [f(0, 0), f(s(0), 1), (f(s(s(N)), M) :- f(N, M))]).
tprog(evenmissing, [f(0, 0), (f(s(s(N)), M) :- f(N, M))]).
tprog(test,  [g([], 0), (g([H|T], N) :- H > 0, g(T, N))]).
tprog(two,   [q([], a), q([], b)]).
tprog(fib,   [fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2)]).
tprog(fibt,  [fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib_tup(N, F1, F2), F is F1 + F2), fib_tup(0, 1, 0), (fib_tup(s(M), F1, F2) :- fib_tup(M, F2, G), F1 is F2 + G)]).
tprog(sum,   [sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H)]).
tprog(flat,  [app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R)), flat(leaf, []), (flat(node(L, X, R), F) :- flat(L, FL), flat(R, FR), app(FL, [X|FR], F))]).

beq(A, B, K, Mode, Size) :- prog_t(A, PA), prog_t(B, PB), bounded_equal(PA, K, PB, K, Mode, Size, R), format("~q~n", [R]).

slot_pairs(Name, Pairs) :- tp(Name, P), P = prog(_, Rs),
    findall(K:I, ( member(H-_, Rs), functor(H, N, A), K = N/A, between(1, A, I) ), S0),
    findall(K:I, ( member(_-B, Rs), member(G, B), callable(G), \+ functor(G, is, 2), functor(G, N, A), atom(N), \+ memberchk(N, [>, <, >=, =<, \=, =]), K = N/A, between(1, A, I) ), S1),
    append(S0, S1, S2), sort(S2, Slots),
    findall(X-Y, ( member(X, Slots), member(Y, Slots), X \== Y ), Pairs).
incl(Name, A, B) :- tp(Name, P), ( includes(P, A, B, Pr) -> copy_term(Pr, C), numbervars(C, 0, _), format("proved: ~p~n", [C]) ; format("not proved~n") ).

main :-
    set_limit(600),
    io_dir(IO), atom_concat(IO, '/pairs.jsonl', PF), open_pairs(PF),
    families(Fs),
    forall(member(F, Fs), ( train_text(F, TT), format(string(Q), "learn_family(~w, _Algorithm), show_algorithm(_Algorithm)", [F]),
                            format(string(Ti), "~w: learn the optimisation algorithm from two training programs", [F]), pair('s2a2/learn', Ti, TT, Q) )),
    forall(inst(F, test, N, _, _), ( test_text(F, N, TT), format(string(Q), "optimise(~w, ~w)", [F, N]),
                                     format(string(Ti), "~w: the learned algorithm on the unseen program ~w", [F, N]), pair('s2a2/apply', Ti, TT, Q) )),
    forall(inst(F, train, N, _, _), ( train_one_text(F, N, TT), format(string(Q), "optimise_train(~w, ~w)", [F, N]),
                                      format(string(Ti), "~w: the learned algorithm on its own training program ~w", [F, N]), pair('s2a2/apply-training', Ti, TT, Q) )),
    D = 'fold/spec-to-algorithm',
    Specs = [ [append, app3]-(app3/4)-[in(list(any)), in(list(any)), in(any), out]-"append three lists",
              [append, nrev]-(rev/2)-[in(list(any)), out]-"naive reverse",
              [append, flat]-(flat/2)-[in(tree(any)), out]-"tree flatten",
              [sum]-(sum/2)-[in(list(int)), out]-"sum of a list",
              [len]-(len/2)-[in(list(any)), out]-"length of a list",
              [fib]-(fib/2)-[in(nat), out]-"Fibonacci on naturals",
              [prod]-(prod/2)-[in(list(int)), out]-"product of a list",
              [size]-(size/2)-[in(tree(any)), out]-"size of a tree",
              [append, app4]-(app4/5)-[in(list(any)), in(list(any)), in(list(any)), in(any), out]-"append four lists",
              [append, lenapp]-(lenapp/3)-[in(list(any)), in(list(any)), out]-"length of an append",
              [append, revapp]-(revapp/3)-[in(list(any)), in(any), out]-"reverse then append",
              [dbl]-(dbl/2)-[in(list(int)), out]-"double every element",
              [sumdbl]-(sumdbl/2)-[in(list(int)), out]-"sum of the doubled list",
              [append, nodes]-(nodes/2)-[in(tree(any)), out]-"nodes of a tree in order" ],
    forall(member(Ns-K-M-T, Specs), ( spec_text(Ns, ST), format(string(Q), "derive_with(~q, ~q, ~q, [deforest, accumulate, tuple])", [Ns, K, M]),
                                      format(string(Ti), "Spec to algorithm: ~s", [T]), pair(D, Ti, ST, Q) )),
    forall(( member(Ns-K-M-T, Specs), nth1(I, Specs, Ns-K-M-T), I =< 6, member(S, [deforest, accumulate, tuple]) ),
           ( spec_text(Ns, ST), format(string(Q), "derive_with(~q, ~q, ~q, [~w])", [Ns, K, M, S]),
             format(string(Ti), "Spec to algorithm: ~s with only the ~w strategy", [T, S]), pair(D, Ti, ST, Q) )),
    spec_text([append], AT), L = 'fold/lemmas',
    forall(member(N-Lh-Rh, [ "associativity of append"-"[app(X,Y,W), app(W,Z,R)]"-"[app(Y,Z,V), app(X,V,R)]",
                             "associativity, mirrored"-"[app(Y,Z,V), app(X,V,R)]"-"[app(X,Y,W), app(W,Z,R)]",
                             "commutativity of append"-"[app(X,Y,R)]"-"[app(Y,X,R)]",
                             "append with the arguments of the second call swapped"-"[app(X,Y,W), app(W,Z,R)]"-"[app(X,Z,V), app(V,Y,R)]",
                             "appending in either grouping, four lists"-"[app(A,B,X), app(X,C,Y), app(Y,D,R)]"-"[app(A,B,X), app(C,D,Z), app(X,Z,R)]",
                             "a call equals itself"-"[app(X,Y,R)]"-"[app(X,Y,R)]",
                             "the second list dropped"-"[app(X,Y,R)]"-"[app(X,X,R)]" ]),
           ( format(string(Q), "spec_prog([append], _S), prove_lemma(_S, lemma(l, ~s, ~s), _R), ( _R = proved(H, _P) -> format(\"proved (~~w); both sides become~~n\", [H]), show(_P) ; writeln(_R) )", [Lh, Rh]),
             format(string(Ti), "Lemma: ~s", [N]), pair(L, Ti, AT, Q) )),
    forall(member(N-B, [ "reverse step"-"[(p([H|T],A,R) :- rev(T,E), app(E,[H],F), app(F,A,R))]",
                         "flatten step"-"[(p(node(L,X,Rt),A,F) :- flat(L,FL), flat(Rt,FR), app(FL,[X|FR],G), app(G,A,F))]",
                         "sum step"-"[(p([H|T],S,A) :- sum(T,S2), S1 is S2+H, S is S1+A)]" ]),
           ( format(string(Q), "spec_prog([append], _S), clauses(~s, _St), discover_lemmas(_S, _St, [], _F), forall(member(X, _F), ( functor(X, Kind, _), arg(1, X, Lm), arg(1, Lm, Name), format(\"~~w: ~~w~~n\", [Name, Kind]) ))", [B]),
             format(string(Ti), "Lemmas conjectured from a stuck ~s", [N]), pair(L, Ti, AT, Q) )),
    C = 'fold/checks',
    forall(member(G-Ti, [ check_total(acc, rev/2, [in(list(any)), out])-"Accumulator reverse answers every list",
                          check_total(nobase, rev_acc/3, [in(list(any)), in(any), out])-"A missing base case is not total",
                          check_total(loop, rev_acc/3, [in(list(any)), in(any), out])-"Recursion on the same argument is not total",
                          check_total(size, size/2, [in(tree(any)), out])-"Tree size with arithmetic is total",
                          check_total(leafonly, size/2, [in(tree(any)), out])-"A tree predicate without the node case is not total",
                          check_total(even, f/2, [in(nat), out])-"Nested natural-number patterns that cover",
                          check_total(evenmissing, f/2, [in(nat), out])-"Nested patterns missing s(0)",
                          check_total(test, g/2, [in(list(int)), out])-"A comparison in the body can fail",
                          check_total(fibt, fib/2, [in(nat), out])-"Linear Fibonacci is total",
                          check_total(sum, sum/2, [in(list(int)), out])-"Naive sum is total on integer lists",
                          check_fun(nrev, rev/2, [in, out])-"Naive reverse has at most one answer",
                          check_fun(two, q/2, [in, out])-"Two answers for one input",
                          check_fun(fib, fib/2, [in, out])-"Fibonacci has at most one answer",
                          check_fun(flat, flat/2, [in, out])-"Tree flatten has at most one answer",
                          check_fun(sum, sum/2, [in, out])-"Sum has at most one answer",
                          check_slot(nrev, rev/2, 1)-"Reverse answers only lists",
                          check_slot(nrev, app/3, 2)-"Append's second argument can be anything",
                          check_slot(fib, fib/2, 1)-"Fibonacci's first argument is a natural",
                          check_slot(fib, fib/2, 2)-"Fibonacci's answer is an integer",
                          check_slot(flat, flat/2, 1)-"Flatten answers only trees" ]),
           ( G =.. [_, Nm|_], tprog(Nm, Cs), clauses_text(Cs, PT), format(string(Q), "~q", [G]), pair(C, Ti, PT, Q) )),
    forall(member(G-Ti, [ "beq(nrev, acc, rev/2, [in(list(any)), out], 6)"-"Naive and accumulator reverse on every list up to length 6",
                          "beq(fib, fibt, fib/2, [in(nat), out], 15)"-"Naive and linear Fibonacci up to 15",
                          "beq(nrev, acc, rev/2, [in(list(any)), in(list(any))], 3)"-"Reverse checked with both arguments given",
                          "beq(sum, sum, sum/2, [in(list(int)), out], 3)"-"Sum against itself",
                          "beq(even, evenmissing, f/2, [in(nat), out], 6)"-"Two programs that differ at s(0)" ]),
           ( pair('fold/bounded', Ti, G) )),
    TY = 'types/proof-types',
    forall(member(Nm, [reach, family, numbers]),
           ( ptext(Nm, PT), slot_pairs(Nm, Ps), length(Ps, NP), ( Nm == family -> Max = 21 ; Nm == numbers -> Max = 12 ; Max = 10 ),
             forall(( nth1(I, Ps, A-B), I =< Max ), ( format(string(Q), "incl(~w, ~q, ~q)", [Nm, A, B]),
                                                   format(string(Ti), "~w: is ~q contained in ~q?", [Nm, A, B]), pair(TY, Ti, PT, Q) )) )),
    ptext(family, FT),
    forall(member(Ri-Li, [3-1, 3-2, 3-3, 4-1, 4-2]), ( format(string(Q), "tp(family, _P), ( implied_guard(_P, ~w, ~w, R) -> true ; R = kept )", [Ri, Li]),
                                                      format(string(Ti), "family: is literal ~w of rule ~w implied by a related variable?", [Li, Ri]), pair(TY, Ti, FT, Q) )),
    ptext(physics, PT2), ptext(physics_bad, PB2),
    pair(TY, "Units of F = m*a", PT2, "tp(physics, _P), dimensions(_P, [((mass/2):2)-[kg-1], ((acc/2):2)-[m-1, s-(-2)], ((force/2):2)-[kg-1, m-1, s-(-2)]], Result)"),
    pair(TY, "Units of F = m+a are refuted", PB2, "tp(physics_bad, _P), dimensions(_P, [((mass/2):2)-[kg-1], ((acc/2):2)-[m-1, s-(-2)], ((force/2):2)-[kg-1, m-1, s-(-2)]], Result)"),
    close_pairs,
    atom_concat(IO, '/io_pairs.md', MF),
    to_markdown(PF, MF, "S2A2",
        "Each pair is a query to S2A2: an optimisation family learned from its two training programs, the learned algorithm applied to every unseen test program and to its own training programs (checked against the reference axioms and proved against the original), spec to algorithm with fold and eureka definitions, lemma proofs and discovery, the totality, functionality and answer-type checks, bounded checks, and proof/types. Every output was produced by running this repository's code with `io_pairs/generate.pl`; nothing was written by hand.").
