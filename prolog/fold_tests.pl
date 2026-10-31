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

prog(Ns, P) :- foldl([N, A0, A]>>( p(N, Cs), clauses(Cs, P1), append(A0, P1, A) ), Ns, [], P).

def(def(rev_acc(T, A, R), [rev(T, RT), app(RT, A, R)])).

main :-
    prog([app], App), prog([app, nrev], Spec), prog([acc], Acc), def(D),
    t(fold_applies_when_local_variable_is_private,
      ( clauses([(p(X, R) :- rev(X, RT), app(RT, [a], R))], [C1]), fold_with(D, C1, _-[rev_acc(_, [a], _)]) )),
    t(fold_refused_when_local_variable_is_used_elsewhere,
      ( clauses([(p(X, R) :- rev(X, RT), app(RT, [a], R), q(RT))], [C2]), \+ fold_with(D, C2, _) )),
    t(fold_refused_when_local_variable_is_in_the_head,
      ( clauses([(p(X, RT, R) :- rev(X, RT), app(RT, [a], R))], [C3]), \+ fold_with(D, C3, _) )),
    Lm = lemma(assoc, [app(X1, Y1, W1), app(W1, Z1, R1)], [app(Y1, Z1, V1), app(X1, V1, R1)]),
    t(lemma_refused_when_intermediate_is_used_elsewhere,
      ( clauses([(p(A, B, C, R) :- app(A, B, W), app(W, C, R), q(W))], [C4]), \+ lemma_step(Lm, lr, C4, _) )),
    t(lemma_applies_otherwise,
      ( clauses([(p(A2, B2, C2b, R2) :- app(A2, B2, W2), app(W2, C2b, R2))], [C5]), lemma_step(Lm, lr, C5, _-[app(_, _, _), app(_, _, _)]) )),
    t(unfold_keeps_answers,
      ( clauses([(p(X6, Y6, R6) :- app(X6, Y6, R6))], Pc), append(Pc, App, P6), [C6] = Pc,
        unfold(App, C6, 1, Cs6), append(Cs6, App, P6b),
        bounded_equal(P6, p/3, P6b, p/3, [in(list), in(any), out], inputs([a, b], 3), equal_on(_)) )),
    t(accumulator_reverse_is_total, total(Acc, rev/2, [in(list), out])),
    t(missing_base_case_is_not_total, ( prog([no_base], NB), \+ total(NB, rev_acc/3, [in(list), in(any), out]) )),
    t(non_structural_recursion_is_not_total, ( prog([not_structural], NS), \+ total(NS, rev_acc/3, [in(list), in(any), out]) )),
    t(naive_reverse_is_functional, functional(Spec, rev/2, [in, out])),
    t(overlapping_heads_are_not_functional, ( prog([two_answers], TA), \+ functional(TA, q/2, [in, out]) )),
    t(reverse_answers_only_lists, list_slot(Spec, rev/2, 1)),
    t(append_second_argument_is_not_a_list_slot, \+ list_slot(App, app/3, 2)),
    t(wrong_accumulator_is_refuted,
      ( prog([wrong_acc], WA), bounded_equal(Spec, rev/2, WA, rev/2, [in(list), out], inputs([a, b], 3), refuted(_, _, _)) )),
    t(assoc_lemma_proved, prove_lemma(App, Lm, proved(_, _))),
    t(commutativity_not_proved, prove_lemma(App, lemma(c, [app(X7, Y7, R7)], [app(Y7, X7, R7)]), not_proved)),
    ( failed(_) -> halt(1) ; format("all fold tests passed~n"), halt(0) ).
