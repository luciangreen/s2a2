:- encoding(utf8).
/*  fold_examples.pl -- spec to algorithm with fold, eureka definitions, lemma discovery and a
    learned choice of strategy.
    swipl -q -g main -t 'halt(1)' fold_examples.pl     (writes ../results/fold.txt too)

    1. The lemma database: associativity of append proved, commutativity refuted.
    2. Six specifications, each derived from an EMPTY lemma database (lemmas are discovered),
       proved and measured: app3 (deforest), naive reverse, tree flatten, sum and length
       (accumulate, with integer arithmetic), Fibonacci on naturals (tuple).
    3. Agreement in a second mode (both arguments given).
    4. Learning which strategy to try first, leave-one-out.
*/
:- use_module(fold).

spec(append, [ app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R)) ]).
spec(app3,   [ (app3(X, Y, Z, R) :- app(X, Y, W), app(W, Z, R)) ]).
spec(nrev,   [ rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)) ]).
spec(flat,   [ flat(leaf, []), (flat(node(L, X, R), F) :- flat(L, FL), flat(R, FR), app(FL, [X|FR], F)) ]).
spec(sum,    [ sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H) ]).
spec(len,    [ len([], 0), (len([_|T], N) :- len(T, M), N is M + 1) ]).
spec(fib,    [ fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2) ]).

% example(Name, Specs, Target, Mode, BoundedSize, CostGoal(Size))
example(app3, [append, app3], app3/4, [in(list(any)), in(list(any)), in(any), out], 3).
example(rev,  [append, nrev], rev/2,  [in(list(any)), out], 7).
example(flat, [append, flat], flat/2, [in(tree(any)), out], 3).
example(sum,  [sum],          sum/2,  [in(list(int)), out], 4).
example(len,  [len],          len/2,  [in(list(any)), out], 7).
example(fib,  [fib],          fib/2,  [in(nat), out], 16).

cost_goal(app3, N, app3(L, L, [], _)) :- numlist(1, N, L).
cost_goal(rev,  N, rev(L, _)) :- numlist(1, N, L).
cost_goal(flat, N, flat(T, _)) :- left_comb(N, T).
cost_goal(sum,  N, sum(L, _)) :- numlist(1, N, L).
cost_goal(len,  N, len(L, _)) :- numlist(1, N, L).
cost_goal(fib,  N, fib(P, _)) :- peano(N, P).
sizes(fib, [10, 15, 20]) :- !.
sizes(_, [16, 64, 256]).
left_comb(0, leaf) :- !.
left_comb(N, node(T, N, leaf)) :- N1 is N - 1, left_comb(N1, T).
peano(0, 0) :- !.
peano(N, s(P)) :- N1 is N - 1, peano(N1, P).

program(Names, P) :- foldl([N, A0, A]>>( spec(N, Cs), clauses(Cs, P1), append(A0, P1, A) ), Names, [], P).

main :- run(Out), setup_call_cleanup(open('../results/fold.txt', write, S), write(S, Out), close(S)),
        write(Out), ( sub_atom(Out, _, _, _, 'FAILED') -> halt(1) ; halt(0) ).
run(Out) :- with_output_to(atom(Out), examples).

check(Name, G) :- ( catch(G, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]) ).

examples :-
    lemmas, derivations, second_mode, learning.

% ---------------------------------------------------------------- 1
lemmas :-
    program([append], App),
    format("== 1. The lemma database~n~n"),
    format("  A lemma about user predicates is admitted only once both sides deforest to the same program.~n~n"),
    A = lemma(app_assoc, [app(X, Y, W), app(W, Z, R)], [app(Y, Z, V), app(X, V, R)]),
    prove_lemma(App, A, RA),
    format("  app(X,Y,W), app(W,Z,R) <=> app(Y,Z,V), app(X,V,R): "),
    ( RA = proved(How, Prog) -> format("proved (~w); both sides become~n", [How]), show(Prog) ; format("not proved~n") ),
    check(assoc_proved, RA = proved(_, _)),
    discover_lemmas(App, [p-[app(a, b, c)]], [], Found),
    format("~n  app(X,Y,R) <=> app(Y,X,R):~n"), forall(member(Fd, Found), show_found(Fd)),
    check(commutativity_refuted, Found = [refuted(_, input(_))]),
    format("  Integer axioms (not proved here; used only where their variables are integers):~n"),
    forall(axiom(N, L, Rh, T), ( format("    ~w (~w): ", [N, T]), print_sides(L, Rh) )).
print_sides(L, R) :- copy_term(L-R, L1-R1), numbervars(L1-R1, 0, _), format("~p  <=>  ~p~n", [L1, R1]).

% ---------------------------------------------------------------- 2
derivations :-
    format("~n== 2. Six specifications, each from an EMPTY lemma database~n"),
    forall(example(Name, Specs, K, Mode, Size), derivation(Name, Specs, K, Mode, Size)).

derivation(Name, Specs, K, Mode, Size) :-
    program(Specs, S),
    format("~n--- ~w~n  specification:~n", [Name]),
    clauses_of_key(S, K, SK), show(SK),
    (   spec_to_algorithm(S, K, [], P0, report(St, Trace, Used, Att, Disc))
    ->  true
    ;   format("  no derivation~n"), check(Name, fail), fail ),
    format("  strategy: ~w (attempt ~w); lemmas used: ~w~n", [St, Att, Used]),
    ( Disc == [] -> true ; format("  discovered when stuck:~n"), forall(member(D, Disc), show_found(D)) ),
    show_trace(Trace),
    verify(S, P0, K, Mode, verdict(total(T), functional(F), typed_answers(Ty), integer_arithmetic(IA), P)),
    format("  derived (bodies ordered for the mode):~n"), show(P),
    exact(St, Trace, Ex),
    format("  proof:~n"),
    (   Ex == yes
    ->  format("    unfold/fold only: least model preserved (Tamaki-Sato), so equal in every mode~n")
    ;   format("    sound: every step keeps every clause true in the specification's least model~n"),
        format("    derived program total for ~w: ~w~n", [Mode, T]),
        format("    specification functional: ~w~n", [F]),
        format("    specification answers only typed inputs: ~w~n", [Ty]),
        format("    every is/2 on integers: ~w~n", [IA]),
        (   T == yes, F == yes, Ty == yes -> format("    => same least model: equal in every mode~n")
        ;   T == yes, F == yes -> format("    => equal on every input of the declared types~n")
        ;   format("    => NOT proved~n") ) ),
    proved(Ex, T, F, Proved),
    check(proved, Proved == yes),
    bounded_equal(S, K, P, K, Mode, Size, B),
    format("    bounded check: ~w~n", [B]),
    check(bounded_equal, B = equal_on(_)),
    sizes(Name, Ns),
    format("  cost of the first answer (resolution steps / most pending goals):~n    size  specification  derived~n"),
    forall(member(N, Ns), ( cost_goal(Name, N, G), copy_term(G, G2),
                            cost(S, G, Sa, Ma), cost(P, G2, Sb, Mb),
                            format("    ~t~w~6|  ~t~w~15| / ~w~t~27|  ~w / ~w~n", [N, Sa, Ma, Sb, Mb]) )),
    last(Ns, NL), cost_goal(Name, NL, GL), copy_term(GL, GL2), cost(S, GL, SL, ML), cost(P, GL2, DL, DML),
    check(cheaper, ( DL < SL ; DML < ML )).
derivation(_, _, _, _, _).

proved(yes, _, _, yes) :- !.
proved(_, yes, yes, yes) :- !.
proved(_, _, _, no).

exact(deforest, Trace, yes) :- \+ ( member(steps(SL), Trace), member(Ss, SL), member(S-_, Ss), S \= fold(_) ), !.
exact(_, _, no).

clauses_of_key(P, K, Cs) :- findall(H-B, ( member(H-B, P), functor(H, N, A), K = N/A ), Cs).

show_found(proved(lemma(N, L, R))) :- format("    ~w proved: ", [N]), print_sides(L, R).
show_found(axiom(axiom(N, L, R, T))) :- format("    ~w (~w axiom): ", [N, T]), print_sides(L, R).
show_found(refuted(lemma(N, _, _), CE)) :- format("    ~w refuted by ~w~n", [N, CE]).
show_found(unknown(lemma(N, _, _))) :- format("    ~w unknown~n", [N]).

show_trace(Trace) :- format("  derivation:~n"), forall(member(E, Trace), show_event(E)).
show_event(eureka(accumulate, D, generalised(R, R1))) :- !,
    copy_term(D-R-R1, (H-B)-Ra-Rb), numbervars(H-B-Ra-Rb, 0, _), fold:lits_atom(B, BS),
    format("    eureka (accumulate): ~p :- ~w.~n      the consumers ~p generalised to ~p~n", [H, BS, Ra, Rb]).
show_event(eureka(tuple, D)) :- !,
    copy_term(D, H-B), numbervars(H-B, 0, _), fold:lits_atom(B, BS),
    format("    eureka (tuple): ~p :- ~w.~n", [H, BS]).
show_event(define(D)) :- !, copy_term(D, H-B), numbervars(H-B, 0, _), fold:lits_atom(B, BS),
    format("    definition: ~p :- ~w.~n", [H, BS]).
show_event(unfold(J, Cs)) :- !, format("    unfold body literal ~w, then normalise:~n", [J]), show(Cs).
show_event(steps(SL)) :- !,
    forall(member(Ss, SL), forall(member(S-C, Ss), ( format("    ~w, then normalise:~n", [S]), show([C]) ))).
show_event(fold_target(Cs)) :- !, format("    fold the specification's own clauses with the definition:~n"), show(Cs).
show_event(_).

% ---------------------------------------------------------------- 3
second_mode :-
    format("~n== 3. A second mode: both arguments given~n~n"),
    format("  Where the least models are proved equal, the programs agree in every mode. Checked here~n"),
    format("  with every pair of inputs given (+,+): both accept exactly the same pairs.~n"),
    forall(member(Name-Mode-Sz, [rev-[in(list(any)), in(list(any))]-3,
                                 flat-[in(tree(any)), in(list(any))]-2,
                                 fib-[in(nat), in(int)]-8]),
           ( example(Name, Specs, K, _, _), program(Specs, S),
             spec_to_algorithm(S, K, [], P0, _),
             example(Name, _, _, M1, _), verify(S, P0, K, M1, verdict(_, _, _, _, P)),
             bounded_equal(S, K, P, K, Mode, Sz, B),
             format("  ~w ~w: ~w~n", [Name, Mode, B]),
             check(second_mode, B = equal_on(_)) )).

% ---------------------------------------------------------------- 4
learning :-
    format("~n== 4. Learning which strategy to try first (leave one out)~n~n"),
    findall(Name-(Fs-Ok), ( example(Name, Specs, K, _, _), program(Specs, S), features(S, K, Fs),
                            findall(St, ( strategies(All), member(St, All), spec_to_algorithm(S, K, [], [St], _, _) ), Ok) ), Ex),
    forall(member(N-(Fs-Ok), Ex), format("  ~w: features ~w; succeeds with ~w~n", [N, Fs, Ok])),
    pairs_values(Ex, AllEx),
    learn_strategies(AllEx, RulesAll),
    format("~n  rules learned from all six:~n"),
    forall(member(S-R, RulesAll), format("    ~w when ~w~n", [S, R])),
    format("~n  attempts until a derivation (held-out example; learned order vs the default order):~n"),
    strategies(Default),
    foldl([N-(Fs-_), [A0, B0], [A1, B1]]>>(
              exclude([M-_]>>(M == N), Ex, Train), pairs_values(Train, TrEx),
              learn_strategies(TrEx, Rules), choose_order(Rules, Fs, Order),
              example(N, Specs, K, _, _), program(Specs, S),
              spec_to_algorithm(S, K, [], Order, _, report(_, _, _, La, _)),
              spec_to_algorithm(S, K, [], Default, _, report(_, _, _, Da, _)),
              format("    ~w: learned ~w -> ~w, default -> ~w~n", [N, Order, La, Da]),
              A1 is A0 + La, B1 is B0 + Da ), Ex, [0, 0], [LT, DT]),
    format("  total attempts: learned ~w, default ~w~n", [LT, DT]),
    check(learned_order_no_worse, LT =< DT).
