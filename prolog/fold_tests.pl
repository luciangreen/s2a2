:- encoding(utf8).
/*  fold_tests.pl -- the side conditions that keep fold.pl sound.
    swipl -q -g main -t 'halt(1)' fold_tests.pl      (exits 1 if any test fails) */
:- use_module(fold).

:- dynamic failed/1.
t(Name, Goal) :- ( catch(Goal, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]), assertz(failed(Name)) ).

p(app, [app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R))]).
p(nrev, [rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R))]).
p(acc, [rev([], []), (rev([H|T], R) :- rev_acc(T, [H], R)), rev_acc([], A, A), (rev_acc([H|T], A, R) :- rev_acc(T, [H|A], R))]).
p(no_base, [(rev_acc([H|T], A, R) :- rev_acc(T, [H|A], R))]).
p(not_structural, [rev_acc([], A, A), (rev_acc([H|T], A, R) :- rev_acc([H|T], A, R))]).
p(wrong_acc, [rev([], []), (rev([H|T], R) :- rev_acc(T, [H], R)), rev_acc([], A, A), (rev_acc([H|T], A, R) :- rev_acc(T, [H], R))]).
p(two_answers, [q([], a), q([], b)]).
p(tree_missing_node, [size(leaf, 0)]).
p(tree_size, [size(leaf, 0), (size(node(L, _, R), N) :- size(L, A), size(R, B), N is A + B + 1)]).
p(nat_missing, [f(0, 0), (f(s(s(N)), M) :- f(N, M))]).
p(nat_even, [f(0, 0), f(s(0), 1), (f(s(s(N)), M) :- f(N, M))]).
p(with_test, [(g([], 0)), (g([H|T], N) :- H > 0, g(T, N))]).
p(sum_non_tail, [sum([], 0), (sum([H|T], S) :- sum(T, S1), S is S1 + H)]).
p(fib, [fib(0, 0), fib(s(0), 1), (fib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2)]).

prog(Ns, P) :- foldl([N, A0, A]>>( p(N, Cs), clauses(Cs, P1), append(A0, P1, A) ), Ns, [], P).

def(def(rev_acc(T, A, R), [rev(T, RT), app(RT, A, R)])).
lm(lemma(app_assoc, [app(X1, Y1, W1), app(W1, Z1, R1)], [app(Y1, Z1, V1), app(X1, V1, R1)])).

main :-
    prog([app], App), prog([app, nrev], Spec), prog([acc], Acc), def(D), lm(Lm),
    % fold and lemma side conditions
    t(fold_applies_when_local_variable_is_private,
      ( clauses([(p(X, R) :- rev(X, RT), app(RT, [a], R))], [C1]), fold_with(D, C1, _-[rev_acc(_, [a], _)]) )),
    t(fold_refused_when_local_variable_is_used_elsewhere,
      ( clauses([(p(X, R) :- rev(X, RT), app(RT, [a], R), q(RT))], [C2]), \+ fold_with(D, C2, _) )),
    t(fold_refused_when_local_variable_is_in_the_head,
      ( clauses([(p(X, RT, R) :- rev(X, RT), app(RT, [a], R))], [C3]), \+ fold_with(D, C3, _) )),
    t(lemma_refused_when_intermediate_is_used_elsewhere,
      ( clauses([(p(A, B, C, R) :- app(A, B, W), app(W, C, R), q(W))], [C4]), \+ lemma_step(Lm, lr, C4, _) )),
    t(lemma_applies_otherwise,
      ( clauses([(p(A2, B2, C2b, R2) :- app(A2, B2, W2), app(W2, C2b, R2))], [C5]), lemma_step(Lm, lr, C5, _-[app(_, _, _), app(_, _, _)]) )),
    t(integer_axiom_applies_to_is_chains,
      ( axiom(plus_assoc, L, R0, T), clauses([(p(X8, Y8, Z8, S8) :- S18 is X8 + Y8, S8 is S18 + Z8)], [C8]),
        lemma_step(axiom(plus_assoc, L, R0, T), lr, C8, _-[_ is Y8 + Z8, S8 is X8 + _]) )),
    t(merge_unifies_calls_with_the_same_input,
      ( clauses([(p(N9, A9, B9) :- f(N9, A9), f(N9, B9))], [C9]), merge_step(C9, H9-[f(_, _)], merge), arg(2, H9, X9), arg(3, H9, Y9), X9 == Y9 )),
    t(unfold_keeps_answers,
      ( clauses([(p(X6, Y6, R6) :- app(X6, Y6, R6))], Pc), append(Pc, App, P6), [C6] = Pc,
        unfold(App, C6, 1, Cs6), append(Cs6, App, P6b),
        bounded_equal(P6, p/3, P6b, p/3, [in(list(any)), in(any), out], 3, equal_on(_)) )),
    % totality
    t(accumulator_reverse_is_total, total(Acc, rev/2, [in(list(any)), out])),
    t(missing_base_case_is_not_total, ( prog([no_base], NB), \+ total(NB, rev_acc/3, [in(list(any)), in(any), out]) )),
    t(non_structural_recursion_is_not_total, ( prog([not_structural], NS), \+ total(NS, rev_acc/3, [in(list(any)), in(any), out]) )),
    t(tree_without_node_case_is_not_total, ( prog([tree_missing_node], TM), \+ total(TM, size/2, [in(tree(any)), out]) )),
    t(tree_size_is_total_with_integer_arithmetic, ( prog([tree_size], TS), total(TS, size/2, [in(tree(any)), out]) )),
    t(nested_nat_patterns_must_cover_s0, ( prog([nat_missing], NM), \+ total(NM, f/2, [in(nat), out]) )),
    t(nested_nat_patterns_cover, ( prog([nat_even], NE), total(NE, f/2, [in(nat), out]) )),
    t(a_test_in_the_body_is_not_total, ( prog([with_test], WT), \+ total(WT, g/2, [in(list(int)), out]) )),
    t(total_orders_bodies_for_the_mode,
      ( clauses([s([], 0), (s([H7|T7], S7) :- s(T7, S7, H7)), s([], Sa, Sa), (s([Hb|Tb], Sb, Ab) :- s(Tb, Sb, Eb), Eb is Hb + Ab)], SP),
        total(SP, s/2, [in(list(int)), out], SP1), member(s([_|_], _, _)-[(_ is _), s(_, _, _)], SP1) )),
    % functionality and answer types
    t(naive_reverse_is_functional, functional(Spec, rev/2, [in, out])),
    t(overlapping_heads_are_not_functional, ( prog([two_answers], TA), \+ functional(TA, q/2, [in, out]) )),
    t(reverse_answers_only_lists, slot_type(Spec, rev/2, 1, list(any))),
    t(append_second_argument_is_not_a_list_slot, \+ slot_type(App, app/3, 2, list(any))),
    t(fibonacci_answers_only_naturals_and_integers, ( prog([fib], F), slot_type(F, fib/2, 1, nat), slot_type(F, fib/2, 2, int) )),
    % bounded check, lemmas, discovery
    t(wrong_accumulator_is_refuted,
      ( prog([wrong_acc], WA), bounded_equal(Spec, rev/2, WA, rev/2, [in(list(any)), out], 3, refuted(_, _, _)) )),
    t(assoc_lemma_proved, prove_lemma(App, Lm, proved(_, _))),
    t(commutativity_not_proved, prove_lemma(App, lemma(c, [app(X7, Y7, R7)], [app(Y7, X7, R7)]), not_proved)),
    t(discovery_proves_assoc_and_refutes_comm,
      ( clauses([(p([H0|T0], A0, R0) :- rev(T0, E0), app(E0, [H0], F0), app(F0, A0, R0))], St),
        discover_lemmas(Spec, St, [], Found),
        memberchk(proved(lemma(app_assoc, _, _)), Found), memberchk(refuted(lemma(app_comm, _, _), _), Found) )),
    % strategies
    t(reverse_needs_a_lemma, \+ spec_to_algorithm(Spec, rev/2, [], [accumulate], _, report(_, _, _, _, []))),
    t(non_tail_accumulator_is_not_accepted,
      ( prog([sum_non_tail], SN), spec_to_algorithm(SN, sum/2, [], P, _),
        member(sum_acc([_|_], Out, _)-B, P), \+ ( member(X is _, B), X == Out ) )),
    t(tuple_strategy_gives_linear_fibonacci,
      ( prog([fib], F2), spec_to_algorithm(F2, fib/2, [], [tuple], PF, _),
        member(fib_tup(s(_), _, _)-BF, PF), aggregate_all(count, ( member(G, BF), functor(G, fib_tup, 3) ), 1) )),
    t(learner_separates_strategies,
      ( learn_strategies([[conjunctive]-[deforest], [result_used_after_call]-[accumulate],
                          [calls_on_related_arguments, result_used_after_call]-[tuple]], Rules),
        choose_order(Rules, [calls_on_related_arguments, result_used_after_call], [tuple|_]),
        choose_order(Rules, [result_used_after_call], [accumulate|_]) )),
    ( failed(_) -> halt(1) ; format("all fold tests passed~n"), halt(0) ).
