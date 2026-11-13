:- encoding(utf8).
/*  io_synth_tests.pl -- the pieces of io_synth.pl.
    swipl -q -g main -t 'halt(1)' io_synth_tests.pl      (exits 1 if any test fails) */
:- use_module(io_synth).

:- dynamic failed/1.
t(Name, Goal) :- ( \+ \+ catch(Goal, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]), assertz(failed(Name)) ).

dropmin_ref([], []).
dropmin_ref([L|Ls], [R|Rs]) :- ( L == [] -> R = [] ; min_list(L, M), exclude(==(M), L, R) ), dropmin_ref(Ls, Rs).

main :-
    % anti-unification
    t(lgg_of_pairs_is_a_template, ( lgg_all([1-3, 5-9], G, Hs), G = A-B, var(A), var(B), Hs = [A-[1,5], B-[3,9]] )),
    t(lgg_keeps_shared_constants, ( lgg_all([f(a, 1), f(a, 2)], f(a, V), [V-[1, 2]]) )),
    t(lgg_reuses_a_variable_for_the_same_tuple, ( lgg_all([g(1, 1), g(2, 2)], g(X, Y), [_]), X == Y )),
    t(lgg_of_equal_terms_is_ground, ( lgg_all([h(1), h(1)], h(1), []) )),
    % signals
    t(signal_subsequence, ( signals([[1,2,3]-[1,3]], S), memberchk(subsequence, S), memberchk(drops_elements, S) )),
    t(signal_permutation, ( signals([[3,1,2]-[1,2,3]], S), memberchk(permutation, S) )),
    t(signal_per_sublist, ( signals([[[1],[2,3]]-[[1],[3]]], S), memberchk(per_sublist, S) )),
    t(no_length_signal_when_lengths_differ, ( signals([[1,2]-[1]], S), \+ memberchk(length_preserved, S) )),
    % observational equivalence and types
    t(pruning_keeps_fewer_expressions,
      ( enumeration_stats([x-list(int)], [[x=[1,2]], [x=[3]]], [max_size(3)], enum(with_pruning(W, _), without_pruning(O, _))), W < O )),
    t(pruned_bank_has_distinct_signatures,
      ( io_synth:bank([x-int], [[x=1], [x=2]], [max_size(3)], B),
        findall(S, member(e(_, _, _, S), B), Ss), sort(Ss, U), length(Ss, N), length(U, N) )),
    t(no_ill_typed_expression_is_built,
      ( io_synth:bank([x-int], [[x=1], [x=2]], [max_size(3)], B),
        \+ ( member(e(_, _, E, _), B), sub_term(T, E), nonvar(T), T = f(F, [v(x)]), memberchk(F, [sum, maxl, minl, len, rev, head]) ) )),
    t(exclude_removes_a_component,
      ( io_synth:bank([x-list(int)], [[x=[1,2]]], [max_size(2), exclude([sum])], B), \+ memberchk(e(_, _, f(sum, _), _), B) )),
    % hypotheses
    t(map_of_an_expression, ( synth(d, [[1,2]-[2,4], [3]-[6]], [ga(false)], P, _), run_program(P, d, [5,6], [10,12]) )),
    t(filter_with_plain_test, ( synth(e, [[1,2,3,4]-[2,4], [5,6]-[6]], [ga(false)], P, _), run_program(P, e, [8,9,10], [8,10]) )),
    t(filter_test_gated_by_the_whole_list,
      ( synth(m, [[2,1,4,3]-[2,4,3], [9,7,8]-[9,8], [5,6,4]-[5,6]], [ga(false)], P, report(node(m, filter(context, _), []), _, _)),
        run_program(P, m, [20,10,15,12], [20,15,12]) )),
    t(context_is_hoisted_out_of_the_recursion,
      ( synth(m, [[2,1,4,3]-[2,4,3], [9,7,8]-[9,8], [5,6,4]-[5,6]], [ga(false)], P, _),
        member((m(_, _) :- Body), P), sub_term(G, Body), nonvar(G), G = min_list(_, _) )),
    t(nested_map_invents_two_helpers,
      ( synth(n, [[[1],[2,3]]-[[2],[3,4]], [[5]]-[[6]]], [ga(false)], P, _),
        memberchk((n_el([_|_], [_|_]) :- _), P), member((n_el_el(_, _) :- _), P) )),
    t(template_splits_into_one_problem_per_hole,
      ( synth(mm, [[3,1,2]-(1-3), [5,9]-(5-9)], [ga(false)], _, report(node(mm, template(_), [_, _]), _, _)) )),
    t(foldr_recovers_naive_reverse,
      ( synth(r, [[1,2,3]-[3,2,1], [4]-[4], []-[]], [exclude([rev]), ga(false)], P, _), run_program(P, r, [a,b,c,d], [d,c,b,a]) )),
    t(fold_step_must_use_the_recursive_result,
      ( synth(l, [[1,2,3]-3, [4]-1, []-0], [exclude([len]), ga(false)], P, _), run_program(P, l, [7,7,7,7,7], 5) )),
    t(every_answer_reproduces_the_examples,
      ( Exs = [[1,2]-[2,3], [5]-[6]],
        forall(limit(5, synth_nd(s, Exs, [], P, _)), run_all(P, s, Exs, ok)) )),
    % running and checking
    t(run_all_reports_the_first_difference,
      ( run_all([q(X, Y) :- Y is X + 1], q, [1-2, 2-4], differs(2, 3, 4)) )),
    t(runaway_recursion_is_an_error_not_a_hang,
      ( run_inputs_err([(loop(X, Y) :- loop(X, Y))], loop, 1) )),
    t(agrees_finds_a_counter_example,
      ( agrees([d(L, R) :- msort(L, R)], d, [L, R]>>sort(L, R), [[1,2], [2,2]], counter_example([2,2], [2,2], [2])) )),
    % genetic algorithm
    t(ga_finds_a_pipeline,
      ( ga_synth(g, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36], [seed(1)], P, _), run_program(P, g, [4,4,5], 32) )),
    t(ga_is_reproducible_with_a_seed,
      ( Exs = [[3,1,2]-[1,2,3], [5,4]-[4,5]],
        ga_synth(h, Exs, [seed(7)], P1, R1), ga_synth(h, Exs, [seed(7)], P2, R2), P1 =@= P2, R1 =@= R2 )),
    % active learning
    t(distinguishing_query_resolves_the_context_test,
      ( nested_int_lists(2, 2, 0, 3, Pool),
        active_synth(dropmin, dropmin_ref, Pool, [initial([[[1,3,5],[5,3,2]]])], _, active(_, _, Trace, equal_on(_))),
        memberchk(distinguish(_, _), Trace) )),
    % hand-over to fold.pl
    t(fold_spec_renames_append, ( to_fold_spec([r([], []), (r([X|Xs], R) :- r(Xs, R1), append(R1, [X], R))], r, S),
                                  memberchk(app([], _, _), S), \+ ( sub_term(T, S), nonvar(T), functor(T, append, 3) ) )),
    t(fold_spec_refuses_library_calls, ( \+ to_fold_spec([(m(L, M) :- min_list(L, M))], m, _) )),
    t(pools_are_shortest_first, ( int_lists(2, 0, 1, [[], [0], [1], [0,0]|_]) )),
    (   failed(_) -> format("FAILED~n"), halt(1) ; format("all io_synth tests passed~n") ).

run_inputs_err(P, Name, In) :- io_synth:run_inputs(P, Name, [In], [err]).
