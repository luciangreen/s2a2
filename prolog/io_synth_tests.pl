:- encoding(utf8).
/*  io_synth_tests.pl -- the pieces of io_synth.pl.
    swipl -q -g main -t 'halt(1)' io_synth_tests.pl      (exits 1 if any test fails) */
:- use_module(io_synth).
:- use_module(io_proof).
:- use_module(io_synth_refs).

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
    % proofs (io_proof.pl)
    t(proof_arithmetic_as_polynomials,
      ( prove_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is X+X, e(Xs,Ys))], e, [list(int), any], proved(_)) )),
    t(proof_refuses_different_arithmetic,
      ( prove_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is 2*X+1, e(Xs,Ys))], e, [list(int), any], not_proved) )),
    t(proof_tests_in_normal_form,
      ( prove_equal([f([],[]), (f([X|Xs],R) :- (X > 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X >= 2 -> R=[X|R1] ; R=R1), g(Xs,R1))], g, [list(int), any], proved(_)) )),
    t(proof_refuses_different_tests,
      ( prove_equal([f([],[]), (f([X|Xs],R) :- (X > 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X >= 1 -> R=[X|R1] ; R=R1), g(Xs,R1))], g, [list(int), any], not_proved) )),
    t(proof_residues_and_flip,
      ( prove_equal([f([],[]), (f([X|Xs],R) :- (X mod 2 < 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X mod 2 =:= 1 -> R=R1 ; R=[X|R1]), g(Xs,R1))], g, [list(int), any], proved(_)) )),
    t(proof_equality_needs_integer_types,
      ( F = [f([],_,[]), (f([X|Xs],M,R) :- (X =\= M -> R=[X|R1] ; R=R1), f(Xs,M,R1))],
        G = [g([],_,[]), (g([X|Xs],M,R) :- (X == M -> R=R1 ; R=[X|R1]), g(Xs,M,R1))],
        prove_equal(F, f, G, g, [list(int), int, any], proved(_)), prove_equal(F, f, G, g, [list(any), any, any], not_proved) )),
    t(proof_induction_needs_the_tail,
      ( prove_equal([c([],0), (c([_|Xs],N) :- c(Xs,M), N is M+1)], c, [d([],0), (d([X|Xs],N) :- d([X|Xs],M), N is M+1)], d, [list(int), any], not_proved) )),
    t(proof_refuses_different_library_calls,
      ( prove_equal([(s(L, R) :- msort(L, R))], s, [(t(L, R) :- sort(L, R))], t, [list(int), any], not_proved) )),
    t(proof_of_a_synthesised_hierarchy,
      ( synth(dropmin_each, [[[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]]], [ga(false)], P, _),
        ref(dropmin_each, T, R), prove_equal(P, dropmin_each, R, ref_dropmin_each, T, proved(Steps)),
        memberchk(pair(dropmin_each/2, ref_dropmin_each/2, induction(1), none), Steps) )),
    t(proof_lemmas_reused_only_at_the_same_types,
      ( ref(evens_each, T, R), synth(evens_each, [[[1,2,4],[3,4]]-[[2,4],[4]], [[5,6,8]]-[[6,8]], [[]]-[[]], [[7,1]]-[[]], []-[]], [ga(false)], P, _),
        prove_equal(P, evens_each, R, ref_evens_each, T, proved(_)) )),
    t(proof_invariant_from_max_list,
      ( synth(dropmax, [[3,1,2]-[1,2], [7,9,8]-[7,8], [5,6,4]-[5,4]], [ga(false)], P, _),
        ref(dropmax, T, R), prove_equal(P, dropmax, R, ref_dropmax, T, proved(Steps)),
        memberchk(pair(dropmax_sel/3, del_eq/3, induction(1), upper(1, 2)), Steps) )),
    t(proof_invariant_does_not_make_lt_and_le_equal,
      ( P = [d([],[]), (d([X|Xs],R) :- max_list([X|Xs],M), s([X|Xs],M,R)), s([],_,[]), (s([Y|Ys],M2,R2) :- (Y < M2 -> R2=[Y|R3] ; R2=R3), s(Ys,M2,R3))],
        Q = [e([],[]), (e([X1|Xs1],Rq) :- max_list([X1|Xs1],Mq), t([X1|Xs1],Mq,Rq)), t([],_,[]), (t([Z|Zs],Mt,Rt) :- (Z =< Mt -> Rt=[Z|Rt1] ; Rt=Rt1), t(Zs,Mt,Rt1))],
        prove_equal(P, d, Q, e, [list(int), any], not_proved) )),
    t(proof_invariant_needs_the_right_library_fact,
      ( P = [d([],[]), (d([X|Xs],R) :- min_list([X|Xs],M), s([X|Xs],M,R)), s([],_,[]), (s([Y|Ys],M2,R2) :- (Y < M2 -> R2=[Y|R3] ; R2=R3), s(Ys,M2,R3))],
        Q = [e([],[]), (e([X1|Xs1],Rq) :- min_list([X1|Xs1],Mq), t([X1|Xs1],Mq,Rq)), t([],_,[]), (t([Z|Zs],Mt,Rt) :- (Z == Mt -> Rt=Rt1 ; Rt=[Z|Rt1]), t(Zs,Mt,Rt1))],
        prove_equal(P, d, Q, e, [list(int), any], not_proved) )),
    t(proof_invariant_must_be_kept_by_the_recursion,
      ( P = [d([],[]), (d([X|Xs],R) :- max_list([X|Xs],M), s([X|Xs],M,R)), s([],_,[]), (s([Y|Ys],M2,R2) :- (Y < M2 -> R2=[Y|R3] ; R2=R3), M3 is M2-1, s(Ys,M3,R3))],
        Q = [e([],[]), (e([X1|Xs1],Rq) :- max_list([X1|Xs1],Mq), t([X1|Xs1],Mq,Rq)), t([],_,[]), (t([Z|Zs],Mt,Rt) :- (Z == Mt -> Rt=Rt1 ; Rt=[Z|Rt1]), Mt1 is Mt-1, t(Zs,Mt1,Rt1))],
        prove_equal(P, d, Q, e, [list(int), any], not_proved) )),
    t(task_named_like_a_library_predicate_calls_the_library,
      ( synth(reverse, [[1,2,3]-[3,2,1], [4,5,6,7]-[7,6,5,4]], [], P, report(node(_, expression(_), _), _, _)),
        memberchk((reverse(_, _) :- lists:reverse(_, _)), P), run_program(P, reverse, [8,9], [9,8]) )),
    t(ga_fails_at_once_when_no_gene_takes_the_input,
      ( call_with_time_limit(30, \+ ga_synth(p, [box(red,[5,6])-[5,6], box(blue,[7,8])-[7,8]], [], _, _)) )),
    t(pools_are_shortest_first, ( int_lists(2, 0, 1, [[], [0], [1], [0,0]|_]) )),
    (   failed(_) -> format("FAILED~n"), halt(1) ; format("all io_synth tests passed~n"), halt(0) ).

run_inputs_err(P, Name, In) :- io_synth:run_inputs(P, Name, [In], [err]).
