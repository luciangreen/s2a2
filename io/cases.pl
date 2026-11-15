% The predicates whose inputs and outputs are recorded in io/ios.txt (see io/ios_engine.pl):
% S2A2's real io_synth, io_proof, prover, the axioms of each family, learn/apply, and fold.
:- ios_engine:load_repo('prolog/io_synth').
:- ios_engine:load_repo('prolog/io_proof').
:- ios_engine:load_repo('prolog/prover').
:- ios_engine:load_repo('prolog/s2a2').
:- ios_engine:load_repo('prolog/axioms').
:- ios_engine:load_repo('prolog/instances').
:- ios_engine:load_repo('prolog/fold').

io_title('S2A2').

:- discontiguous io_input/3, io_run/3.

io_cases([synth, signals, prove_equal, equivalent, apply_axioms, learn_apply, derive]).

% Clauses as text: variables named in order.
clause_text(T0, Text) :-
    copy_term(T0, T), numbervars(T, 0, _),
    format(string(Text), "~W", [T, [quoted(true), numbervars(true), portray(false), spacing(next_argument)]]).
lines_of(Goal, Lines) :-
    with_output_to(string(S), Goal),
    split_string(S, "\n", " ", Ls0), exclude(==(""), Ls0, Lines).

% Lists of whole numbers, the same for each K and Salt.
lists(K, Salt, Ls) :-
    findall(L, ( between(1, 4, I), S is Salt * 7 + I, num(K, S, 0, 4, N), length(L, N),
                 foldl([X, J0, J]>>(S2 is S * 11 + J0, num(K, S2, -3, 9, X), J is J0 + 1), L, 0, _) ), Ls0),
    sort(Ls0, Ls).

kind_out(double, L, R) :- maplist([X, Y]>>(Y is 2 * X), L, R).
kind_out(add_k, L, R) :- maplist([X, Y]>>(Y is X + 3), L, R).
kind_out(evens, L, R) :- include([X]>>(0 is X mod 2), L, R).
kind_out(positives, L, R) :- include([X]>>(X > 0), L, R).
kind_out(reversed, L, R) :- reverse(L, R).
kind_out(sum, L, S) :- sum_list(L, S).
kind_out(len, L, N) :- length(L, N).
kind_out(maximum, L, M) :- ( L = [] -> M = none ; max_list(L, M) ).
kind_out(sorted, L, R) :- msort(L, R).
kind_out(dedup, L, R) :- sort(L, R).

examples(K, Salt, Kind, Exs) :-
    pick(K, Salt, [double, add_k, evens, positives, reversed, sum, len, maximum, sorted, dedup], Kind),
    lists(K, Salt, Ls),
    findall(L-O, ( member(L, Ls), kind_out(Kind, L, O) ), Exs).

% ---- io_synth: a program from input/output examples ----
io_input(synth, K, [Kind, Examples]) :- examples(K, 1, Kind, Examples).
% the hypothesis, the program, and the program run on new inputs
io_run(synth, [Kind, Exs], [hypothesis(H1), program(Lines), runs_on(Ins, Outs)]) :-
    io_synth:synth(Kind, Exs, [ga(false)], P, report(Tree, _, _)),
    ( Tree = node(_, H0, _) -> H = H0 ; H = Tree ), copy_term(H, H1), numbervars(H1, 0, _),
    lines_of(io_synth:show_program(P), Lines),
    Ins = [[1, 2, 3, 4, 5, 6], [-4, 0, 7]],
    findall(O, ( member(I, Ins), ( catch(io_synth:run_program(P, Kind, I, O0), _, fail) -> O = O0 ; O = none ) ), Outs).

% ---- io_synth: the structural signals of examples ----
io_input(signals, K, [Kind, Examples]) :- examples(K, 2, Kind, Examples).
io_run(signals, [_, Exs], Signals) :- io_synth:signals(Exs, Signals).

% ---- io_proof: two list programs equal on every input of their types ----
map_prog(Name, Expr, X, Y, [P0, (P1 :- Y is Expr, P2)]) :-
    P0 =.. [Name, [], []], P1 =.. [Name, [X|Xs], [Y|Ys]], P2 =.. [Name, Xs, Ys].
filter_prog(Name, Test, X, [P0, (P1 :- (Test -> R = [X|R1] ; R = R1), P2)]) :-
    P0 =.. [Name, [], []], P1 =.. [Name, [X|Xs], R], P2 =.. [Name, Xs, R1].
pair_progs(map, N, A, B) :-
    map_prog(d, 2 * X, X, _, A),
    pick(N, 3, [x_plus_x, two_x_plus_k, three_x, x_times_2], Form),
    ( Form == x_plus_x -> map_prog(e, Z + Z, Z, _, B)
    ; Form == two_x_plus_k -> num(N, 4, 1, 3, Kk), map_prog(e, 2 * Z + Kk, Z, _, B)
    ; Form == three_x -> map_prog(e, 3 * Z, Z, _, B)
    ; map_prog(e, Z * 2, Z, _, B) ).
pair_progs(filter, N, A, B) :-
    num(N, 5, 0, 4, Kk), K1 is Kk + 1,
    filter_prog(d, X > Kk, X, A),
    pick(N, 6, [ge_next, gt_same, ge_same, lt_neg], Form),
    ( Form == ge_next -> filter_prog(e, Z >= K1, Z, B)
    ; Form == gt_same -> filter_prog(e, Z > Kk, Z, B)
    ; Form == ge_same -> filter_prog(e, Z >= Kk, Z, B)
    ; filter_prog(e, \+ Z =< Kk, Z, B) ).
io_input(prove_equal, K, [Shape, K]) :- pick(K, 7, [map, filter], Shape).
% the two programs and io_proof's verdict, proved(Steps) or not_proved
io_run(prove_equal, [Shape, N], [first(A1), second(B1), Result]) :-
    pair_progs(Shape, N, A, B),
    maplist(clause_text, A, A1), maplist(clause_text, B, B1),
    io_proof:prove_equal(A, d, B, e, [list(int), any], Result0),
    ( Result0 = proved(Steps) -> length(Steps, NS), Result = proved(steps(NS)) ; Result = Result0 ).

% ---- prover: same answers for every input ----
io_input(equivalent, K, [Change, Edges]) :-
    pick(K, 8, [dup_clause, dup_literal, subsumed, flipped, extra_base, none], Change),
    pick_n(K, 9, 4, [a-b, b-c, c-a, a-c, b-a], Es0), sort(Es0, Edges).
reach_prog(Facts, [(reach(X, Y) :- edge(X, Y)), (reach(X1, Y1) :- edge(X1, Z1), reach(Z1, Y1))|Facts]).
changed(dup_clause, P, [(reach(X, Y) :- edge(X, Y))|P]).
changed(dup_literal, [(reach(X, Y) :- edge(X, Y))|R], [(reach(X, Y) :- edge(X, Y), edge(X, Y))|R]).
changed(subsumed, P, [(reach(X, Y) :- edge(X, Y), edge(Y, _))|P]).
changed(flipped, [(reach(X, Y) :- edge(X, Y))|R], [(reach(X, Y) :- edge(Y, X))|R]).
changed(extra_base, P, [(reach(X, X) :- edge(X, _))|P]).
changed(none, P, P).
% the prover on the reach program and a changed copy: syntactic, exhaustive or refuted
io_run(equivalent, [Change, Edges], Result) :-
    reach_prog([], A), changed(Change, A, B),
    findall(C, member(_-C, Edges), Cs0), findall(C, member(C-_, Edges), Cs1), append(Cs0, Cs1, Cs2), sort(Cs2, Consts),
    prover:equivalent(B, A, [reach/2], edb([edge/2], Consts), Result0),
    copy_term(Result0, Result), numbervars(Result, 0, _).

% ---- the axioms of each family applied to its test programs ----
test_instance_(K, F, Name, Cs, T) :-
    findall(i(F0, N0, C0, T0), instances:inst(F0, test, N0, C0, T0), All),
    length(All, L), I is (K * 7) mod L, nth0(I, All, i(F, Name, Cs, T)).
io_input(apply_axioms, K, [Family, Name]) :- test_instance_(K, Family, Name, _, _).
% S2A2's reference algorithm for the family on a program it has not seen: the steps, the
% optimised program and the prover's verdict on its targets
io_run(apply_axioms, [Family, Name], [steps(NS), optimised(Lines), proof(Proof)]) :-
    once(instances:inst(Family, test, Name, Cs, T)),
    axioms:axioms(Family, Ax),
    s2a2:program_from_clauses(Cs, P0),
    s2a2:apply_algorithm(Ax, P0, T, P1, Trace),
    ( is_list(Trace) -> length(Trace, NS) ; NS = Trace ),
    s2a2:program_to_clauses(P1, Cs1), maplist(clause_text, Cs1, Lines),
    (   catch(call_with_time_limit(5, prover:equivalent(Cs, Cs1, T, edb([], []), R0)), _, fail)
    ->  ( R0 = proved(How) -> functor(How, Kind, _), Proof = proved(Kind) ; Proof = refuted )
    ;   Proof = not_checked
    ).

% ---- learn an algorithm from pairs and apply it ----
facts(F, Xs, Fs) :- findall(T, ( member(X, Xs), T =.. [F, X] ), Fs).
wrapper_pair(Style, Top, Base, Wrap, Xs, pair(B, A, [Top/1])) :-
    facts(Base, Xs, Fs),
    H1 =.. [Top, X1], W1 =.. [Wrap, X1], H2 =.. [Wrap, X2], G2 =.. [Base, X2], H3 =.. [Top, X3], G3 =.. [Base, X3],
    append(Fs, [(H2 :- G2), (H1 :- W1)], Before),
    ( Style == keep -> append(Fs, [(H2 :- G2), (H3 :- G3)], After) ; append(Fs, [(H3 :- G3)], After) ),
    s2a2:program_from_clauses(Before, B), s2a2:program_from_clauses(After, A).
io_input(learn_apply, K, [Style, Pairs, Edges]) :-
    pick(K, 10, [keep, keep, drop], Style),
    pick_n(K, 11, 3, [red, blue, green], Cs0), sort(Cs0, Cs),
    pick_n(K, 12, 3, [s1, s2, s3], Ss0), sort(Ss0, Ss),
    num(K, 13, 1, 2, NP), Pairs0 = [col-colour-q-Cs, big-size-s-Ss], length(Pairs, NP), append(Pairs, _, Pairs0),
    pick_n(K, 14, 3, [a-b, b-c, a-c, c-a], Es0), sort(Es0, Edges).
% the learned algorithm, the program it gives for conn/2, and the prover's verdict
io_run(learn_apply, [Style, Pairs, Edges], [algorithm(Alg1), optimised(Lines), proof(Proof)]) :-
    maplist([Top-Base-Wrap-Xs, Pr]>>wrapper_pair(Style, Top, Base, Wrap, Xs, Pr), Pairs, Prs),
    s2a2:learn(Prs, Alg),
    findall(edge(U, V), member(U-V, Edges), Fs),
    append(Fs, [(e(U1, V1) :- edge(U1, V1)), (conn(U2, V2) :- e(U2, V2))], Cs),
    s2a2:program_from_clauses(Cs, P0),
    s2a2:apply_algorithm(Alg, P0, [conn/2], P1, _),
    s2a2:program_to_clauses(P1, Cs1), maplist(clause_text, Cs1, Lines),
    findall(C, ( member(U-V, Edges), member(C, [U, V]) ), Cn0), sort(Cn0, Consts),
    prover:equivalent(Cs, Cs1, [conn/2], edb([edge/2], Consts), R0),
    ( R0 = proved(How) -> Proof = proved(How) ; R0 = refuted(_, OnlyA, OnlyB) -> Proof = refuted(OnlyA, OnlyB) ; Proof = R0 ),
    copy_term(Alg, Alg1), numbervars(Alg1, 0, _).

% ---- fold: a faster program from a clear specification ----
spec(sum, sum/2, [in(list(int)), out], [], [sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H)]).
spec(len, len/2, [in(list(any)), out], [], [len([], 0), (len([_|T], N) :- len(T, N0), N is N0 + 1)]).
spec(sumsq, sumsq/2, [in(list(int)), out], [], [sumsq([], 0), (sumsq([H|T], S) :- sumsq(T, S1), S is S1 + H * H)]).
spec(rev, rev/2, [in(list(any)), out], [], [rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)),
                                           app([], L, L), (app([H1|T1], L1, [H1|R1]) :- app(T1, L1, R1))]).
spec(flat2, flat2/2, [in(list(list(any))), out], [], [flat2([], []), (flat2([L|Ls], F) :- flat2(Ls, F0), app(L, F0, F)),
                                                     app([], A, A), (app([X|Xs], B, [X|C]) :- app(Xs, B, C))]).
spec(fib, fib/2, [in(nat), out], [], [fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2)]).
io_input(derive, K, [Name, Strategies]) :-
    pick(K, 15, [sum, len, sumsq, rev, flat2, fib], Name),
    pick(K, 16, [all, all, [accumulate], [fuse], [tuple]], Strategies).
% the strategy, the program, and verify/5's verdict (total, functional, typed answers)
io_run(derive, [Name, Strategies], Result) :-
    spec(Name, Target, Mode, Lemmas, Cs), fold:clauses(Cs, Spec),
    (   ( Strategies == all -> fold:spec_to_algorithm(Spec, Target, Lemmas, Prog, report(S, _, Used, _, _))
        ; fold:spec_to_algorithm(Spec, Target, Lemmas, Strategies, Prog, report(S, _, Used, _, _)) )
    ->  lines_of(fold:show(Prog), Lines),
        fold:verify(Spec, Prog, Target, Mode, verdict(Tot, Fun, Typ, _, _)),
        copy_term(Used, U), numbervars(U, 0, _),
        Result = [strategy(S), lemmas(U), program(Lines), Tot, Fun, Typ]
    ;   Result = no_derivation
    ).
