:- encoding(utf8).
/*  io_synth_examples.pl -- nested and hierarchical predicates found from input/output, each
    proved equal to a reference program.
    swipl -q -g main -t 'halt(1)' io_synth_examples.pl    (writes ../results/io_synth.txt too)

    1. Structural signals of the examples.
    2. Hierarchical predicates by top-down propagation, each proved equal to its reference
       program (io_synth_refs.pl) for every input of the declared types (io_proof.pl), and
       run against it on a pool of inputs.
    3. How much each reduction removes: observational equivalence and types.
    4. The genetic algorithm, for a pipeline that top-down propagation cannot split.
    5. Active learning: from one example, distinguishing queries to an oracle.
    6. From input/output to an algorithm: the program found is proved equal to its reference;
       fold.pl derives an efficient program from it and proves the two equal.
    7. The prover refuses programs that are not equal.
*/
:- use_module(io_synth).
:- use_module(io_proof).
:- use_module(io_synth_refs).
:- use_module(fold).

main :- run(Out), setup_call_cleanup(open('../results/io_synth.txt', write, S), write(S, Out), close(S)),
        write(Out), ( sub_atom(Out, _, _, _, 'FAILED') -> halt(1) ; halt(0) ).
run(Out) :- with_output_to(atom(Out), examples).

check(Name, G) :- ( catch(G, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]) ).

examples :- signals_section, hierarchy, reductions, genetic, active, to_algorithm, refusals.

% problem(Name, Examples, Options, Pool): Name also names the reference ref_Name
problem(dropmin_each, [ [[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]] ], [], nested).
problem(double, [ [1,2,3]-[2,4,6], [5]-[10], []-[] ], [], flat).
problem(inc_all, [ [[1,2],[3]]-[[2,3],[4]], [[5]]-[[6]], []-[] ], [], nested).
problem(submin, [ [3,5,4]-[0,2,1], [7,9]-[0,2], [2]-[0] ], [], flat).
problem(minmax, [ [3,1,2]-(1-3), [5,9]-(5-9), [4]-(4-4) ], [], flat).
problem(evens, [ [1,2,3,4]-[2,4], [5,6]-[6], [7]-[], [-2,1]-[-2] ], [], flat).

pool(flat, P) :- int_lists(4, -2, 3, P).
pool(nested, P) :- nested_int_lists(2, 3, 0, 3, P).

ref_name(Name, RN) :- atom_concat(ref_, Name, RN).
ref_oracle(Name, In, Out) :- ref(Name, _, R), ref_name(Name, RN), run_program(R, RN, In, Out).

% prove_and_run(+Program, +Name, +PoolName, -Proof, -Run)
prove_and_run(P, Name, PoolName, Proof, Run) :-
    ref(Name, Types, R), ref_name(Name, RN),
    format("  reference program:~n"), show_program(R),
    prove_equal(P, Name, R, RN, Types, Proof),
    format("  proof that ~w/2 = ~w/2:~n", [Name, RN]), show_proof(Proof),
    pool(PoolName, Pool), agrees_prog(P, Name, R, RN, Pool, Run),
    format("  both run on every input of the pool: ~w~n", [Run]).

% ---------------------------------------------------------------- 1
signals_section :-
    format("== 1. Structural signals~n~n"),
    format("  The shapes of the examples decide which hypotheses are tried.~n~n"),
    forall(problem(Name, Exs, _, _), ( signals(Exs, S), numbervars(S, 0, _), format("  ~w: ~p~n", [Name, S]) )),
    problem(dropmin_each, DExs, _, _), signals(DExs, DS),
    check(dropmin_is_per_sublist, memberchk(per_sublist, DS)),
    problem(minmax, MExs, _, _), signals(MExs, MS),
    check(minmax_has_output_template, memberchk(output_template(_-_), MS)).

% ---------------------------------------------------------------- 2
hierarchy :-
    format("~n== 2. Hierarchical predicates by top-down propagation, with proofs~n"),
    forall(problem(Name, Exs, Opts, PoolName), solve(Name, Exs, Opts, PoolName)).

solve(Name, Exs, Opts, PoolName) :-
    format("~n--- ~w~n  examples:~n", [Name]),
    forall(member(I-O, Exs), format("    ~q -> ~q~n", [I, O])),
    (   synth(Name, Exs, [ga(false)|Opts], P, report(Tree, _, Stats))
    ->  format("  hypothesis tree:~n"), show_tree(Tree),
        format("  program:~n"), show_program(P),
        Stats = stats(candidates(C), pruned_equivalent(Pr), type_rejected(TR)),
        format("  candidates built: ~w; dropped as observationally equivalent: ~w; arguments refused by type: ~w~n", [C, Pr, TR]),
        prove_and_run(P, Name, PoolName, Proof, Run),
        check(Name, ( Proof = proved(_), Run = equal_on(_) ))
    ;   format("  no program~n"), check(Name, fail) ).

% ---------------------------------------------------------------- 3
reductions :-
    format("~n== 3. What the reductions remove~n~n"),
    format("  Expressions over one input list, up to size 4, run on two example inputs:~n"),
    enumeration_stats([x-list(int)], [[x=[1,3,5]], [x=[5,3,2]]], [max_size(4)], enum(with_pruning(NW, CW), without_pruning(NO, CO))),
    format("    without observational equivalence: ~w expressions kept (~w built)~n", [NO, CO]),
    format("    with observational equivalence:    ~w expressions kept (~w built)~n", [NW, CW]),
    check(pruning_keeps_fewer, NW < NO),
    format("  Fold combiners over r (int) and x (int), up to size 5, on 25 probe pairs:~n"),
    numlist(0, 4, Ns), findall([r=R, x=X], ( member(R, Ns), member(X, Ns) ), Envs),
    enumeration_stats([r-int, x-int], Envs, [max_size(5)], enum(with_pruning(FW, FCW), without_pruning(FO, FCO))),
    format("    without observational equivalence: ~w expressions kept (~w built)~n", [FO, FCO]),
    format("    with observational equivalence:    ~w expressions kept (~w built)~n", [FW, FCW]),
    check(pruning_keeps_fewer_combiners, FW < FO),
    format("  Top-down propagation: dropmin_each is solved as three small searches (the map, its~n"),
    format("  element filter, the filter's test) instead of one search over whole programs.~n").

% ---------------------------------------------------------------- 4
genetic :-
    format("~n== 4. Genetic algorithm~n~n"),
    format("  The sum of the squares of the even elements is a filter, then a map, then an~n"),
    format("  aggregate. No top-down hypothesis splits it, so the GA searches pipelines.~n"),
    Exs = [ [1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0 ],
    forall(member(I-O, Exs), format("    ~q -> ~q~n", [I, O])),
    (   synth(sum_sq_evens, Exs, [seed(1)], P, report(Tree, _, _))
    ->  format("  hypothesis tree:~n"), show_tree(Tree),
        format("  program:~n"), show_program(P),
        prove_and_run(P, sum_sq_evens, flat, Proof, Run),
        check(ga_pipeline, ( Proof = proved(_), Run = equal_on(_) ))
    ;   check(ga_pipeline, fail) ),
    ref(sum_sq_evens, Types, R),
    findall(G-L-Pd, ( between(1, 20, Seed), ga_synth(sum_sq_evens, Exs, [seed(Seed)], PS, ga_report(G, Gn)), length(Gn, L),
                      prove_equal(PS, sum_sq_evens, R, ref_sum_sq_evens, Types, Pf), ( Pf = proved(_) -> Pd = 1 ; Pd = 0 ) ), GLs),
    findall(G, member(G-_-_, GLs), Gs), findall(L, member(_-L-_, GLs), Ls), findall(Pd, member(_-_-Pd, GLs), Pds),
    length(GLs, NS), min_list(Gs, GMin), max_list(Gs, GMax), max_list(Ls, LMax), sum_list(Pds, NP),
    format("  seeds 1 to 20: ~w found a pipeline, in ~w to ~w generations, at most ~w genes after shortening;~n", [NS, GMin, GMax, LMax]),
    NNP is NS - NP,
    format("  ~w proved equal to the reference; the other ~w square first and filter after, which is~n", [NP, NNP]),
    format("  equal only because x*x and x have the same parity, a law the prover does not use~n"),
    check(ga_every_seed, ( NS =:= 20, LMax =:= 3, NP >= 1 )).

% ---------------------------------------------------------------- 5
active :-
    format("~n== 5. Active learning with an oracle~n~n"),
    format("  From the single example [[1,3,5],[5,3,2]] -> [[3,5],[5,3]], several programs fit~n"),
    format("  (keep x > 2, keep x =\\= min, ...). The loop asks the oracle (the reference program) about~n"),
    format("  the input on which the candidates disagree most, then checks the survivor on the pool.~n"),
    pool(nested, Pool),
    (   active_synth(dropmin_each, ref_oracle(dropmin_each), Pool, [initial([[[1,3,5],[5,3,2]]])], P, active(R, examples(N), Trace, Final))
    ->  forall(member(T, Trace), format("    query: ~q~n", [T])),
        format("  rounds: ~w; examples used: ~w; final check: ~w~n  program:~n", [R, N, Final]), show_program(P),
        ref(dropmin_each, Types, Rf),
        prove_equal(P, dropmin_each, Rf, ref_dropmin_each, Types, Proof),
        format("  proof that dropmin_each/2 = ref_dropmin_each/2:~n"), show_proof(Proof),
        check(active_dropmin, ( Final = equal_on(_), N =< 3, Proof = proved(_) ))
    ;   check(active_dropmin, fail) ).

% ---------------------------------------------------------------- 6
to_algorithm :-
    format("~n== 6. From input/output to an algorithm~n~n"),
    format("  With the library aggregate left out, the program found is a plain recursive~n"),
    format("  specification. It is proved equal to its reference; fold.pl then derives an~n"),
    format("  accumulator program and proves it equal to the specification.~n"),
    forall(algo(Name, Exs, Ex, Mode, Size), algorithm(Name, Exs, Ex, Mode, Size)).

algo(sum, [ [1,2,3]-6, [4]-4, []-0, [2,5]-7 ], [sum], [in(list(int)), out], 4).
algo(len, [ [1,2,3]-3, [4]-1, []-0, [5,6]-2 ], [len], [in(list(any)), out], 7).
algo(rev, [ [1,2,3]-[3,2,1], [4]-[4], []-[], [2,5]-[5,2] ], [rev], [in(list(any)), out], 7).
algo(sumsq, [ [1,2,3]-14, [4]-16, []-0, [2,5]-29 ], [], [in(list(int)), out], 4).
algo(maxf, [ [1,3,2]-3, [4]-4, [2,5]-5, [0,1]-1, []-0 ], [maxl, msort, sort, last], [in(list(int)), out], 4).

algorithm(Name, Exs, Ex, Mode, Size) :-
    format("~n--- ~w~n", [Name]),
    (   synth(Name, Exs, [exclude(Ex), ga(false)], P, _), to_fold_spec(P, Name, SpecCs), clauses(SpecCs, S)
    ->  format("  specification found from ~w examples:~n", [Exs]), show(S),
        ref(Name, Types, R), ref_name(Name, RN),
        prove_equal(P, Name, R, RN, Types, Proof),
        format("  proof that it equals the reference ~w/2:~n", [RN]), show_proof(Proof),
        (   spec_to_algorithm(S, Name/2, [], P0, report(St, _, Used, _, _))
        ->  verify(S, P0, Name/2, Mode, verdict(total(T), functional(F), typed_answers(Ty), _, PF)),
            format("  derived by ~w (lemmas ~w):~n", [St, Used]), show(PF),
            format("  total: ~w; specification functional: ~w; typed answers: ~w~n", [T, F, Ty]),
            (   Ty == no
            ->  format("  (the specification also accepts floats, where the integer axiom does not hold~n"),
                format("  exactly, so equality is stated for integer lists, as in results/fold.txt)~n")
            ;   true ),
            bounded_equal(S, Name/2, PF, Name/2, Mode, Size, B),
            format("  bounded check: ~w~n", [B]),
            check(Name, ( Proof = proved(_), T == yes, F == yes, B = equal_on(_) ))
        ;   format("  no derivation~n"), check(Name, fail) )
    ;   format("  no specification~n"), check(Name, fail) ).

% ---------------------------------------------------------------- 7
refusals :-
    format("~n== 7. The prover refuses programs that are not equal~n~n"),
    D = [d([], []), (d([X|Xs], [Y|Ys]) :- Y is 2 * X, d(Xs, Ys))],
    E = [e([], []), (e([X1|Xs1], [Y1|Ys1]) :- Y1 is 2 * X1 + 1, e(Xs1, Ys1))],
    prove_equal(D, d, E, e, [list(int), any], R1), format("  2*X against 2*X+1:~n"), show_proof(R1),
    check(different_arithmetic_refused, R1 == not_proved),
    F = [f([], _, []), (f([A|As], M, Rf) :- ( A =\= M -> Rf = [A|Rf1] ; Rf = Rf1 ), f(As, M, Rf1))],
    G = [g([], _, []), (g([B|Bs], N, Rg) :- ( B == N -> Rg = Rg1 ; Rg = [B|Rg1] ), g(Bs, N, Rg1))],
    prove_equal(F, f, G, g, [list(int), int, any], R2), format("  =\\= against == on integers:~n"), show_proof(R2),
    check(integer_equality_proved, R2 = proved(_)),
    prove_equal(F, f, G, g, [list(any), any, any], R3), format("  =\\= against == on terms of any type:~n"), show_proof(R3),
    check(term_equality_refused, R3 == not_proved).
