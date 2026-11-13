:- encoding(utf8).
/*  io_synth_examples.pl -- nested and hierarchical predicates found from input/output.
    swipl -q -g main -t 'halt(1)' io_synth_examples.pl    (writes ../results/io_synth.txt too)

    1. Structural signals of the examples.
    2. Hierarchical predicates by top-down propagation, each checked against a reference
       predicate on every input of a bounded pool.
    3. How much each reduction removes: observational equivalence and types.
    4. The genetic algorithm, for a pipeline that top-down propagation cannot split.
    5. Active learning: from one example, distinguishing queries to an oracle.
    6. From input/output to an algorithm: the synthesised program is a specification for
       fold.pl, which derives an efficient program and proves it equal.
*/
:- use_module(io_synth).
:- use_module(fold).

main :- run(Out), setup_call_cleanup(open('../results/io_synth.txt', write, S), write(S, Out), close(S)),
        write(Out), ( sub_atom(Out, _, _, _, 'FAILED') -> halt(1) ; halt(0) ).
run(Out) :- with_output_to(atom(Out), examples).

check(Name, G) :- ( catch(G, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]) ).

examples :- signals_section, hierarchy, reductions, genetic, active, to_algorithm.

% ---------------------------------------------------------------- reference predicates (oracles)
dropmin_ref([], []).
dropmin_ref([L|Ls], [R|Rs]) :- ( L == [] -> R = [] ; min_list(L, M), exclude(==(M), L, R) ), dropmin_ref(Ls, Rs).
double_ref(L, R) :- maplist([X, Y]>>( Y is 2 * X ), L, R).
inc_all_ref(L, R) :- maplist(maplist([X, Y]>>( Y is X + 1 )), L, R).
submin_ref([], []).
submin_ref(L, R) :- L = [_|_], min_list(L, M), maplist([X, Y]>>( Y is X - M ), L, R).
minmax_ref(L, Min-Max) :- min_list(L, Min), max_list(L, Max).
evens_ref(L, R) :- include([X]>>( X mod 2 =:= 0 ), L, R).
sum_sq_evens_ref(L, S) :- include([X]>>( X mod 2 =:= 0 ), L, E), foldl([X, A0, A]>>( A is A0 + X * X ), E, 0, S).

% problem(Name, Examples, Options, Oracle, Pool)
problem(dropmin, [ [[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]] ], [], dropmin_ref, nested).
problem(double, [ [1,2,3]-[2,4,6], [5]-[10], []-[] ], [], double_ref, flat).
problem(inc_all, [ [[1,2],[3]]-[[2,3],[4]], [[5]]-[[6]], []-[] ], [], inc_all_ref, nested).
problem(submin, [ [3,5,4]-[0,2,1], [7,9]-[0,2], [2]-[0] ], [], submin_ref, flat).
problem(minmax, [ [3,1,2]-(1-3), [5,9]-(5-9), [4]-(4-4) ], [], minmax_ref, flat).
problem(evens, [ [1,2,3,4]-[2,4], [5,6]-[6], [7]-[], [-2,1]-[-2] ], [], evens_ref, flat).

pool(flat, P) :- int_lists(4, -2, 3, P).
pool(nested, P) :- nested_int_lists(2, 3, 0, 3, P).

defined(Oracle, Pool0, Pool) :- include([I]>>catch(call(Oracle, I, _), _, fail), Pool0, Pool).

% ---------------------------------------------------------------- 1
signals_section :-
    format("== 1. Structural signals~n~n"),
    format("  The shapes of the examples decide which hypotheses are tried.~n~n"),
    forall(problem(Name, Exs, _, _, _), ( signals(Exs, S), numbervars(S, 0, _), format("  ~w: ~p~n", [Name, S]) )),
    problem(dropmin, DExs, _, _, _), signals(DExs, DS),
    check(dropmin_is_per_sublist, memberchk(per_sublist, DS)),
    problem(minmax, MExs, _, _, _), signals(MExs, MS),
    check(minmax_has_output_template, memberchk(output_template(_-_), MS)).

% ---------------------------------------------------------------- 2
hierarchy :-
    format("~n== 2. Hierarchical predicates by top-down propagation~n"),
    forall(problem(Name, Exs, Opts, Oracle, PoolName), solve(Name, Exs, Opts, Oracle, PoolName)).

solve(Name, Exs, Opts, Oracle, PoolName) :-
    format("~n--- ~w~n  examples:~n", [Name]),
    forall(member(I-O, Exs), format("    ~q -> ~q~n", [I, O])),
    (   synth(Name, Exs, [ga(false)|Opts], P, report(Tree, _, Stats))
    ->  format("  hypothesis tree:~n"), show_tree(Tree),
        format("  program:~n"), show_program(P),
        Stats = stats(candidates(C), pruned_equivalent(Pr), type_rejected(TR)),
        format("  candidates built: ~w; dropped as observationally equivalent: ~w; arguments refused by type: ~w~n", [C, Pr, TR]),
        pool(PoolName, Pool0), defined(Oracle, Pool0, Pool),
        agrees(P, Name, Oracle, Pool, A),
        format("  against the reference on every input of the pool: ~w~n", [A]),
        check(Name, A = equal_on(_))
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
    format("  Top-down propagation: dropmin is solved as three small searches (the map, its~n"),
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
        pool(flat, Pool), agrees(P, sum_sq_evens, sum_sq_evens_ref, Pool, A),
        format("  against the reference on every input of the pool: ~w~n", [A]),
        check(ga_pipeline, A = equal_on(_))
    ;   check(ga_pipeline, fail) ),
    findall(G-L, ( between(1, 20, Seed), ga_synth(g, Exs, [seed(Seed)], _, ga_report(G, Gn)), length(Gn, L) ), GLs),
    pairs_keys_values(GLs, Gs, Ls), length(GLs, NS), min_list(Gs, GMin), max_list(Gs, GMax), max_list(Ls, LMax),
    format("  seeds 1 to 20: ~w found a pipeline, in ~w to ~w generations, at most ~w genes after shortening~n",
           [NS, GMin, GMax, LMax]),
    check(ga_every_seed, ( NS =:= 20, LMax =:= 3 )).

% ---------------------------------------------------------------- 5
active :-
    format("~n== 5. Active learning with an oracle~n~n"),
    format("  From the single example [[1,3,5],[5,3,2]] -> [[3,5],[5,3]], several programs fit~n"),
    format("  (keep x > 2, keep x =\\= min, ...). The loop asks the oracle about the input on which~n"),
    format("  the candidates disagree most, then checks the survivor on the whole pool.~n"),
    pool(nested, Pool),
    (   active_synth(dropmin, dropmin_ref, Pool, [initial([[[1,3,5],[5,3,2]]])], P, active(R, examples(N), Trace, Final))
    ->  forall(member(T, Trace), format("    query: ~q~n", [T])),
        format("  rounds: ~w; examples used: ~w; final check: ~w~n  program:~n", [R, N, Final]), show_program(P),
        check(active_dropmin, ( Final = equal_on(_), N =< 3 ))
    ;   check(active_dropmin, fail) ).

% ---------------------------------------------------------------- 6
to_algorithm :-
    format("~n== 6. From input/output to an algorithm~n~n"),
    format("  With the library aggregate left out, the synthesised program is a plain recursive~n"),
    format("  specification. fold.pl turns it into an accumulator program and proves them equal.~n"),
    forall(algo(Name, Exs, Ex, Mode, Size), algorithm(Name, Exs, Ex, Mode, Size)).

algo(sum, [ [1,2,3]-6, [4]-4, []-0, [2,5]-7 ], [sum], [in(list(int)), out], 4).
algo(len, [ [1,2,3]-3, [4]-1, []-0, [5,6]-2 ], [len], [in(list(any)), out], 7).
algo(rev, [ [1,2,3]-[3,2,1], [4]-[4], []-[], [2,5]-[5,2] ], [rev], [in(list(any)), out], 7).

algorithm(Name, Exs, Ex, Mode, Size) :-
    format("~n--- ~w~n", [Name]),
    (   synth(Name, Exs, [exclude(Ex), ga(false)], P, _), to_fold_spec(P, Name, SpecCs), clauses(SpecCs, S)
    ->  format("  specification found from ~w examples:~n", [Exs]), show(S),
        (   spec_to_algorithm(S, Name/2, [], P0, report(St, _, Used, _, _))
        ->  verify(S, P0, Name/2, Mode, verdict(total(T), functional(F), typed_answers(Ty), _, PF)),
            format("  derived by ~w (lemmas ~w):~n", [St, Used]), show(PF),
            format("  total: ~w; specification functional: ~w; typed answers: ~w~n", [T, F, Ty]),
            (   Ty == no
            ->  format("  (the specification also adds floats, where the integer axiom does not hold~n"),
                format("  exactly, so equality is stated for integer lists, as in results/fold.txt)~n")
            ;   true ),
            bounded_equal(S, Name/2, PF, Name/2, Mode, Size, B),
            format("  bounded check: ~w~n", [B]),
            check(Name, ( T == yes, F == yes, B = equal_on(_) ))
        ;   format("  no derivation~n"), check(Name, fail) )
    ;   format("  no specification~n"), check(Name, fail) ).
