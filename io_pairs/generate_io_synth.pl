/*  generate_io_synth.pl -- 200 input/output pairs for io_synth.pl, each produced by running
    the code: structural signals, anti-unification, nested and hierarchical predicates by
    top-down propagation, the reductions, the genetic algorithm, active learning with an
    oracle, the checks, and input/output to an algorithm through fold.pl. Each program found
    is proved equal to its reference program (prolog/io_synth_refs.pl) by prolog/io_proof.pl
    for every input of the declared types, or the output says it is not proved; each is also
    run against its reference on a pool of inputs. From the repository root:
        swipl -q -g main -t halt io_pairs/generate_io_synth.pl
    writes io_pairs/io_synth_pairs.jsonl and io_pairs/io_synth_pairs.md. */
:- prolog_load_context(directory, D), assertz(user:io_dir(D)).
:- use_module(harness).
:- use_module(to_markdown).
:- use_module('../prolog/io_synth').
:- use_module('../prolog/io_proof').
:- use_module('../prolog/io_synth_refs').
:- use_module('../prolog/fold', [spec_to_algorithm/5, verify/5, show/1, clauses/2, bounded_equal/7]).
:- style_check(-singleton).

% ---------------------------------------------------------------- display helpers
pool(flat, P) :- int_lists(4, -2, 3, P).
pool(small, P) :- int_lists(3, -2, 3, P).
pool(nested, P) :- nested_int_lists(2, 2, 0, 3, P).

show_examples(Exs) :- format("examples:~n"), forall(member(I-O, Exs), format("  ~q -> ~q~n", [I, O])).

% the proof against the reference program, then the run of both on a pool of inputs
proof_and_run(P, Name, PoolName) :-
    ref(Name, Types, R), atom_concat(ref_, Name, RN),
    format("proof against the reference ~w/2:~n", [RN]),
    prove_equal(P, Name, R, RN, Types, Proof), show_proof(Proof),
    pool(PoolName, Pool), agrees_prog(P, Name, R, RN, Pool, A),
    format("both run on every input of the pool: ~w~n", [A]).

ref_oracle(Name, In, Out) :- ref(Name, _, R), atom_concat(ref_, Name, RN), run_program(R, RN, In, Out).

% show_synth(+Name, +Examples, +Options, +PoolName)
show_synth(Name, Exs, Opts, PoolName) :-
    show_examples(Exs),
    (   synth(Name, Exs, [ga(false)|Opts], P, report(Tree, _, stats(candidates(C), pruned_equivalent(Pr), type_rejected(TR))))
    ->  format("hypothesis tree:~n"), show_tree(Tree),
        format("program:~n"), show_program(P),
        format("candidates built: ~w; dropped as observationally equivalent: ~w; arguments refused by type: ~w~n", [C, Pr, TR]),
        proof_and_run(P, Name, PoolName)
    ;   format("no program found~n") ).

% show_ga(+Name, +Examples, +Seed)
show_ga(Name, Exs, Seed) :-
    show_examples(Exs),
    (   ga_synth(Name, Exs, [seed(Seed)], P, ga_report(G, Genome))
    ->  show_tree(node(Name, ga(Genome, generations(G)), [])),
        format("program:~n"), show_program(P),
        proof_and_run(P, Name, flat)
    ;   format("no pipeline within the generation limit~n") ).

% show_active(+Name, +PoolName, +Options): the oracle runs the reference program
show_active(Name, PoolName, Opts) :-
    pool(PoolName, Pool), length(Pool, NP),
    format("pool: ~w inputs; the oracle runs the reference program~n", [NP]),
    (   active_synth(Name, ref_oracle(Name), Pool, [ga(false)|Opts], P, active(R, examples(N), Trace, Final))
    ->  forall(member(T, Trace), format("query: ~q~n", [T])),
        format("rounds: ~w; examples used: ~w; final check: ~w~nprogram:~n", [R, N, Final]),
        show_program(P),
        ref(Name, Types, Rf), atom_concat(ref_, Name, RN),
        format("proof against the reference ~w/2:~n", [RN]),
        prove_equal(P, Name, Rf, RN, Types, Proof), show_proof(Proof)
    ;   format("no program within the round limit~n") ).

show_signals(Exs) :- signals(Exs, S), numbervars(S, 0, _), forall(member(X, S), format("~p~n", [X])).

show_lgg(Ts) :-
    lgg_all(Ts, G, Hs), copy_term(G-Hs, G1-H1), numbervars(G1-H1, 0, _),
    format("template: ~p~n", [G1]), forall(member(V-Vs, H1), format("  hole ~p takes ~q~n", [V, Vs])).

show_stats(Vars, Envs, Size) :-
    enumeration_stats(Vars, Envs, [max_size(Size)], enum(with_pruning(NW, CW), without_pruning(NO, CO))),
    format("without observational equivalence: ~w expressions kept (~w built)~n", [NO, CO]),
    format("with observational equivalence:    ~w expressions kept (~w built)~n", [NW, CW]).

show_equal(P1, N1, P2, N2, Types) :- prove_equal(P1, N1, P2, N2, Types, R), show_proof(R).
show_run_all(Cs, Name, Exs) :- run_all(Cs, Name, Exs, R), format("~q~n", [R]).
show_fold_spec(Cs, Name) :- ( to_fold_spec(Cs, Name, S) -> format("specification for fold.pl:~n"), show_program(S) ; format("not a fold.pl specification: it calls a library predicate~n") ).

% show_to_algorithm(+Name, +Examples, +Exclude, +Mode, +Size)
show_to_algorithm(Name, Exs, Ex, Mode, Size) :-
    show_examples(Exs),
    (   synth(Name, Exs, [exclude(Ex), ga(false)], P, _)
    ->  ref(Name, Types, R), atom_concat(ref_, Name, RN),
        format("program found:~n"), show_program(P),
        format("proof against the reference ~w/2:~n", [RN]),
        prove_equal(P, Name, R, RN, Types, Proof), show_proof(Proof),
        (   to_fold_spec(P, Name, SpecCs), clauses(SpecCs, S)
        ->  (   spec_to_algorithm(S, Name/2, [], P0, report(St, _, Used, _, _))
            ->  verify(S, P0, Name/2, Mode, verdict(total(T), functional(F), typed_answers(Ty), _, PF)),
                format("fold.pl derives, by ~w (lemmas ~w):~n", [St, Used]), show(PF),
                format("total: ~w; specification functional: ~w; typed answers: ~w~n", [T, F, Ty]),
                (   T == yes, F == yes
                ->  format("so the derived program equals the specification on every input of the declared types~n")
                ;   format("so equality with the specification is not proved~n") ),
                bounded_equal(S, Name/2, PF, Name/2, Mode, Size, B), format("bounded check: ~w~n", [B])
            ;   format("no derivation: fold.pl's strategies do not apply to this specification~n") )
        ;   format("not a fold.pl specification: it calls a library predicate~n") )
    ;   format("no program found~n") ).

% ---------------------------------------------------------------- problems
% hier(Name, Examples, Options, Reference, Pool, Title)
hier(inc, [[1,2,3]-[2,3,4], [5]-[6], []-[]], [], [L, R]>>maplist([X, Y]>>(Y is X + 1), L, R), flat, "add one to each element").
hier(dec, [[1,2,3]-[0,1,2], [5]-[4], []-[]], [], [L, R]>>maplist([X, Y]>>(Y is X - 1), L, R), flat, "subtract one from each element").
hier(double, [[1,2,3]-[2,4,6], [5]-[10], []-[]], [], [L, R]>>maplist([X, Y]>>(Y is 2 * X), L, R), flat, "double each element").
hier(square, [[1,2,3]-[1,4,9], [-2]-[4], []-[]], [], [L, R]>>maplist([X, Y]>>(Y is X * X), L, R), flat, "square each element").
hier(negate, [[1,-2,3]-[-1,2,-3], [0]-[0]], [], [L, R]>>maplist([X, Y]>>(Y is -X), L, R), flat, "negate each element").
hier(absolute, [[1,-2,3]-[1,2,3], [-5]-[5]], [], [L, R]>>maplist([X, Y]>>(Y is abs(X)), L, R), flat, "absolute value of each element").
hier(halve, [[4,5,6]-[2,2,3], [9]-[4], [1]-[0]], [], [L, R]>>maplist([X, Y]>>(Y is X // 2), L, R), flat, "halve each element (integer division)").
hier(parity, [[4,5,6]-[0,1,0], [7]-[1], [-3]-[1]], [], [L, R]>>maplist([X, Y]>>(Y is X mod 2), L, R), flat, "parity of each element").
hier(triple, [[1,2,3]-[3,6,9], [5]-[15], []-[]], [], [L, R]>>maplist([X, Y]>>(Y is 3 * X), L, R), flat, "triple each element").
hier(sq_plus_one, [[1,2,3]-[2,5,10], [0]-[1]], [], [L, R]>>maplist([X, Y]>>(Y is X * X + 1), L, R), flat, "square plus one for each element").
hier(odd_number, [[1,2,3]-[3,5,7], [0]-[1]], [], [L, R]>>maplist([X, Y]>>(Y is 2 * X + 1), L, R), flat, "2x + 1 for each element").
hier(sq_minus, [[1,2,3]-[0,2,6], [4]-[12], [0]-[0]], [], [L, R]>>maplist([X, Y]>>(Y is X * X - X), L, R), flat, "x*x - x for each element").
hier(inc_all, [[[1,2],[3]]-[[2,3],[4]], [[5]]-[[6]], []-[]], [], [L, R]>>maplist(maplist([X, Y]>>(Y is X + 1)), L, R), nested, "add one to every element of a list of lists (map inside map)").
hier(dbl_all, [[[1,2],[3]]-[[2,4],[6]], [[0]]-[[0]], []-[]], [], [L, R]>>maplist(maplist([X, Y]>>(Y is 2 * X)), L, R), nested, "double every element of a list of lists").
hier(sq_all, [[[1,2],[3]]-[[1,4],[9]], [[0]]-[[0]], []-[]], [], [L, R]>>maplist(maplist([X, Y]>>(Y is X * X)), L, R), nested, "square every element of a list of lists").
hier(dec_all, [[[1,2],[3]]-[[0,1],[2]], [[5]]-[[4]], []-[]], [], [L, R]>>maplist(maplist([X, Y]>>(Y is X - 1)), L, R), nested, "subtract one from every element of a list of lists").
hier(evens, [[1,2,3,4]-[2,4], [5,6]-[6], [7]-[], [-2,1]-[-2]], [], [L, R]>>include([X]>>(X mod 2 =:= 0), L, R), flat, "keep the even elements").
hier(odds, [[1,2,3,4]-[1,3], [5,6]-[5], [8]-[], [-1,2]-[-1]], [], [L, R]>>include([X]>>(X mod 2 =:= 1), L, R), flat, "keep the odd elements").
hier(positives, [[1,-2,3,0]-[1,3], [-5,6]-[6], [-1]-[]], [], [L, R]>>include([X]>>(X > 0), L, R), flat, "keep the positive elements").
hier(non_negative, [[1,-2,3,0]-[1,3,0], [-5,6]-[6], [-1]-[]], [], [L, R]>>include([X]>>(X >= 0), L, R), flat, "keep the elements that are not negative").
hier(nonzero, [[1,0,3,0]-[1,3], [0,-6]-[-6], [0]-[]], [], [L, R]>>include([X]>>(X =\= 0), L, R), flat, "drop the zeros").
hier(above_one, [[1,2,3,0]-[2,3], [5,1]-[5], [1]-[]], [], [L, R]>>include([X]>>(X > 1), L, R), flat, "keep the elements greater than one").
hier(below_two, [[1,2,3,0]-[1,0], [5,-1]-[-1], [2]-[]], [], [L, R]>>include([X]>>(X < 2), L, R), flat, "keep the elements below two").
hier(negatives, [[1,-2,3,-1]-[-2,-1], [5]-[], [-3,0]-[-3]], [], [L, R]>>include([X]>>(X < 0), L, R), flat, "keep the negative elements").
hier(zeros, [[1,0,3,0]-[0,0], [5]-[], [0,-1]-[0]], [], [L, R]>>include([X]>>(X =:= 0), L, R), flat, "keep the zeros").
hier(at_least_two, [[1,2,3,0]-[2,3], [5,1]-[5], [2]-[2]], [], [L, R]>>include([X]>>(X >= 2), L, R), flat, "keep the elements of at least two").
hier(evens_each, [[[1,2,4],[3,4]]-[[2,4],[4]], [[5,6,8]]-[[6,8]], [[]]-[[]], [[7,1]]-[[]], []-[]], [], [L, R]>>maplist(include([X]>>(X mod 2 =:= 0)), L, R), nested, "keep the even elements of each sublist (map of filter)").
hier(positives_each, [[[1,0,2],[0,3]]-[[1,2],[3]], [[0,2,0]]-[[2]], [[-1,4]]-[[4]], [[]]-[[]], []-[]], [], [L, R]>>maplist(include([X]>>(X > 0)), L, R), nested, "keep the positive elements of each sublist").
hier(dropmin, [[3,1,2]-[3,2], [7,9,8]-[9,8], [5,6,4]-[5,6]], [], [L, R]>>(L == [] -> R = [] ; min_list(L, M), exclude(==(M), L, R)), flat, "drop the minimum (a test gated by the whole list)").
hier(dropmax, [[3,1,2]-[1,2], [7,9,8]-[7,8], [5,6,4]-[5,4]], [], [L, R]>>(L == [] -> R = [] ; max_list(L, M), exclude(==(M), L, R)), flat, "drop the maximum").
hier(keep_max, [[3,1,2]-[3], [7,9]-[9], [5,6,4,1]-[6], [2,2]-[2,2], []-[]], [], [L, R]>>(L == [] -> R = [] ; max_list(L, M), include(==(M), L, R)), flat, "keep only the maximum").
hier(keep_min, [[3,1,2]-[1], [7,9]-[7], [5,6,4,8]-[4], [2,2]-[2,2], []-[]], [], [L, R]>>(L == [] -> R = [] ; min_list(L, M), include(==(M), L, R)), flat, "keep only the minimum").
hier(above_length, [[4,1,2]-[4], [7,0,1]-[7], [5,6,4,1]-[5,6], [9]-[9], []-[], [-2]-[], [0,4,1]-[4]], [], [L, R]>>(length(L, N), include([X]>>(X > N), L, R)), flat, "keep the elements greater than the list's length").
hier(like_first, [[3,1,3]-[3,3], [7,9,7]-[7,7], [5,6]-[5]], [], [L, R]>>(L = [H|_] -> include(==(H), L, R) ; R = []), flat, "keep the elements equal to the first").
hier(below_last, [[3,1,2]-[1], [7,9,8]-[7], [5,1,6]-[5,1]], [], [L, R]>>(L == [] -> R = [] ; last(L, Z), include([X]>>(X < Z), L, R)), flat, "keep the elements less than the last").
hier(dropmin_each, [[[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]]], [], [L, R]>>maplist([S, T]>>(S == [] -> T = [] ; min_list(S, M), exclude(==(M), S, T)), L, R), nested, "drop the minimum from each sublist (the example in the notes)").
hier(dropmax_each, [[[1,3,5],[5,3,2]]-[[1,3],[3,2]], [[7,9],[4]]-[[7],[]]], [], [L, R]>>maplist([S, T]>>(S == [] -> T = [] ; max_list(S, M), exclude(==(M), S, T)), L, R), nested, "drop the maximum from each sublist").
hier(submin, [[3,5,4]-[0,2,1], [7,9]-[0,2], [2]-[0]], [], [L, R]>>(L == [] -> R = [] ; min_list(L, M), maplist([X, Y]>>(Y is X - M), L, R)), flat, "subtract the minimum from each element (a map with context)").
hier(from_max, [[3,5,4]-[2,0,1], [7,9]-[2,0], [2]-[0]], [], [L, R]>>(L == [] -> R = [] ; max_list(L, M), maplist([X, Y]>>(Y is M - X), L, R)), flat, "distance of each element below the maximum").
hier(plus_length, [[3,5,4]-[6,8,7], [7,9]-[9,11], [2]-[3]], [], [L, R]>>(length(L, N), maplist([X, Y]>>(Y is X + N), L, R)), flat, "add the list's length to each element").
hier(times_length, [[3,5,4]-[9,15,12], [7,9]-[14,18], [2]-[2]], [], [L, R]>>(length(L, N), maplist([X, Y]>>(Y is X * N), L, R)), flat, "multiply each element by the list's length").
hier(minmax, [[3,1,2]-(1-3), [5,9]-(5-9), [4]-(4-4)], [], [L, Mn-Mx]>>(min_list(L, Mn), max_list(L, Mx)), flat, "minimum and maximum (template from anti-unification)").
hier(sum_len, [[3,1,2]-(6-3), [5,9]-(14-2), [4]-(4-1)], [], [L, S-N]>>(sum_list(L, S), length(L, N)), flat, "sum and length together").
hier(first_last, [[3,1,2]-(3-2), [5,9]-(5-9), [4]-(4-4)], [], [L, F-Z]>>(L = [F|_], last(L, Z)), flat, "first and last element").
hier(three_stats, [[3,1,2]-s(1,3,3), [5,9]-s(5,9,2), [4]-s(4,4,1)], [], [L, s(Mn, Mx, N)]>>(min_list(L, Mn), max_list(L, Mx), length(L, N)), flat, "minimum, maximum and length in one term").
hier(min_max_list, [[3,1,2,5]-[1,5], [5,9]-[5,9], [4,0,2]-[0,4]], [], [L, [Mn, Mx]]>>(min_list(L, Mn), max_list(L, Mx)), flat, "minimum and maximum as a two-element list").
hier(head_tail, [[3,1,2]-(3-[1,2]), [5,9]-(5-[9]), [4]-(4-[])], [], [L, H-T]>>(L = [H|T]), flat, "head and tail as a pair").
hier(sum_fold, [[1,2,3]-6, [4]-4, []-0, [2,5]-7], [exclude([sum])], [L, S]>>sum_list(L, S), flat, "sum without sum_list (foldr)").
hier(length_fold, [[1,2,3]-3, [4]-1, []-0, [5,6]-2], [exclude([len])], [L, N]>>length(L, N), flat, "length without length (foldr)").
hier(reverse_fold, [[1,2,3]-[3,2,1], [4]-[4], []-[], [2,5]-[5,2]], [exclude([rev])], [L, R]>>reverse(L, R), flat, "reverse without reverse (foldr with append)").
hier(product, [[1,2,3]-6, [4]-4, []-1, [2,5]-10], [], [L, P]>>foldl([X, A0, A]>>(A is A0 * X), L, 1, P), flat, "product of the elements (foldr)").
hier(count_odds, [[1,2,3]-2, [4]-0, []-0, [5,7,9]-3, [2,4,1]-1], [], [L, N]>>(include([X]>>(X mod 2 =:= 1), L, O), length(O, N)), flat, "count the odd elements (foldr)").
hier(sum_squares, [[1,2,3]-14, [4]-16, []-0, [2,5]-29], [], [L, S]>>foldl([X, A0, A]>>(A is A0 + X * X), L, 0, S), flat, "sum of squares (foldr)").
hier(sum_doubles, [[1,2,3]-12, [4]-8, []-0, [2,5]-14], [exclude([sum])], [L, S]>>foldl([X, A0, A]>>(A is A0 + 2 * X), L, 0, S), flat, "sum of doubled elements (foldr)").
hier(max_fold, [[1,3,2]-3, [4]-4, [2,5]-5, [0,1]-1, []-0], [exclude([maxl, msort, sort, last])], [L, M]>>(L == [] -> M = 0 ; max_list([0|L], M)), flat, "maximum without max_list (foldr)").
hier(flatten, [[[1,2],[3]]-[1,2,3], [[4]]-[4], []-[], [[],[5]]-[5]], [], [L, R]>>append(L, R), nested, "flatten a list of lists (foldr with append)").
hier(sorted, [[3,1,2]-[1,2,3], [5,4]-[4,5], [2,2,1]-[1,2,2]], [], [L, R]>>msort(L, R), flat, "sort keeping duplicates").
hier(sorted_set, [[3,1,2]-[1,2,3], [5,4]-[4,5], [2,2,1]-[1,2]], [], [L, R]>>sort(L, R), flat, "sort and remove duplicates").
hier(reversed, [[3,1,2]-[2,1,3], [5,4]-[4,5], []-[]], [], [L, R]>>reverse(L, R), flat, "reverse").
hier(descending, [[3,1,2]-[3,2,1], [5,4,6]-[6,5,4], [1]-[1]], [], [L, R]>>(msort(L, S), reverse(S, R)), flat, "sort into descending order").
hier(count, [[3,1,2]-3, [5,4]-2, []-0], [], [L, N]>>length(L, N), flat, "length").
hier(total, [[3,1,2]-6, [5,4]-9, []-0], [], [L, S]>>sum_list(L, S), flat, "sum").
hier(final, [[3,1,2]-2, [5,4]-4, [7]-7], [], [L, Z]>>last(L, Z), flat, "last element").
hier(doubled_list, [[3,1]-[3,1,3,1], [5]-[5,5], []-[]], [], [L, R]>>append(L, L, R), flat, "the list followed by itself").
hier(sums_each, [[[1,2],[3]]-[3,3], [[4,5]]-[9], []-[]], [], [L, R]>>maplist(sum_list, L, R), nested, "the sum of each sublist").
hier(lengths_each, [[[1,2],[3]]-[2,1], [[]]-[0], []-[]], [], [L, R]>>maplist(length, L, R), nested, "the length of each sublist").
hier(max_each, [[[1,2],[3]]-[2,3], [[0,5]]-[5], []-[]], [], [L, R]>>maplist(max_list, L, R), nested, "the maximum of each sublist").
hier(reverse_each, [[[1,2],[3]]-[[2,1],[3]], [[0,5,1]]-[[1,5,0]], []-[]], [], [L, R]>>maplist(reverse, L, R), nested, "reverse each sublist").
hier(sort_each, [[[2,1],[3]]-[[1,2],[3]], [[0,5,1]]-[[0,1,5]], []-[]], [], [L, R]>>maplist(msort, L, R), nested, "sort each sublist").
hier(minmax_each, [[[3,1],[5]]-[1-3,5-5], [[0,2,1]]-[0-2], []-[]], [], [L, R]>>maplist([S, Mn-Mx]>>(min_list(S, Mn), max_list(S, Mx)), L, R), nested, "minimum and maximum of each sublist (map of a template)").

% ga(Name, Examples, Seed, Reference, Title)
ga(sum_sq_evens, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0], 1, [L, S]>>(include([X]>>(X mod 2 =:= 0), L, E), foldl([X, A0, A]>>(A is A0 + X * X), E, 0, S)), "sum of squares of the even elements, seed 1").
ga(sum_sq_evens, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0], 2, [L, S]>>(include([X]>>(X mod 2 =:= 0), L, E), foldl([X, A0, A]>>(A is A0 + X * X), E, 0, S)), "sum of squares of the even elements, seed 2").
ga(sum_sq_evens, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0], 3, [L, S]>>(include([X]>>(X mod 2 =:= 0), L, E), foldl([X, A0, A]>>(A is A0 + X * X), E, 0, S)), "sum of squares of the even elements, seed 3").
ga(sum_sq_evens, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0], 4, [L, S]>>(include([X]>>(X mod 2 =:= 0), L, E), foldl([X, A0, A]>>(A is A0 + X * X), E, 0, S)), "sum of squares of the even elements, seed 4").
ga(sum_sq_evens, [[1,2,3,4]-20, [2]-4, [1,3]-0, [6,1]-36, []-0], 5, [L, S]>>(include([X]>>(X mod 2 =:= 0), L, E), foldl([X, A0, A]>>(A is A0 + X * X), E, 0, S)), "sum of squares of the even elements, seed 5").
ga(count_positives, [[1,-2,3]-2, [0]-0, [4,5,-1,6]-3, []-0], 1, [L, N]>>(include([X]>>(X > 0), L, P), length(P, N)), "number of positive elements").
ga(sum_odd_doubles, [[1,2,3]-8, [4]-0, [5,7]-24, []-0], 1, [L, S]>>(include([X]>>(X mod 2 =:= 1), L, O), foldl([X, A0, A]>>(A is A0 + 2 * X), O, 0, S)), "sum of the doubled odd elements").
ga(max_square, [[1,-3,2]-9, [2]-4, [0,1]-1], 1, [L, M]>>(maplist([X, Y]>>(Y is X * X), L, Q), max_list(Q, M)), "largest square").
ga(count_evens, [[1,2,4]-2, [3]-0, [6,8,1,0]-3, []-0, [3,5]-0, [-1,2]-1], 1, [L, N]>>(include([X]>>(X mod 2 =:= 0), L, E), length(E, N)), "number of even elements").
ga(sorted_squares, [[3,-1,2]-[1,4,9], [-2,0]-[0,4], []-[]], 1, [L, R]>>(maplist([X, Y]>>(Y is X * X), L, Q), msort(Q, R)), "squares in ascending order").
ga(reversed_evens, [[1,2,3,4]-[4,2], [6,8]-[8,6], [5]-[]], 1, [L, R]>>(include([X]>>(X mod 2 =:= 0), L, E), reverse(E, R)), "the even elements in reverse order").
ga(sum_incremented, [[1,2,3]-9, [0]-1, []-0, [5,5]-12, [2]-3], 1, [L, S]>>(maplist([X, Y]>>(Y is X + 1), L, I), sum_list(I, S)), "sum after adding one to each element").
ga(min_doubled, [[3,1,2]-2, [5]-10, [4,-1]-(-2), [2,0,3]-0, [-2,1]-(-4)], 1, [L, M]>>(maplist([X, Y]>>(Y is 2 * X), L, D), min_list(D, M)), "smallest doubled element").
ga(sum_positives, [[1,-2,3]-4, [-5]-0, [2,2,-1]-4, []-0], 1, [L, S]>>(include([X]>>(X > 0), L, P), sum_list(P, S)), "sum of the positive elements").
ga(largest_sorted, [[3,1,2]-3, [5,9,4]-9, [7]-7], 1, [L, M]>>(msort(L, S), last(S, M)), "last element after sorting").
ga(first_reversed, [[3,1,2]-2, [5,9,4]-4, [7]-7], 1, [L, F]>>(reverse(L, [F|_])), "first element after reversing").
ga(squares_of_odds, [[1,2,3]-[1,9], [4,5]-[25], [2]-[]], 1, [L, R]>>(include([X]>>(X mod 2 =:= 1), L, O), maplist([X, Y]>>(Y is X * X), O, R)), "squares of the odd elements").
ga(distinct_count, [[3,1,3]-2, [5,5,5]-1, [1,2]-2, []-0], 1, [L, N]>>(sort(L, S), length(S, N)), "number of distinct elements").
ga(sum_halves, [[4,5,6]-7, [1]-0, [9,9]-8, []-0], 1, [L, S]>>(maplist([X, Y]>>(Y is X // 2), L, H), sum_list(H, S)), "sum of the halved elements").
ga(double_sum, [[1,2,3]-12, [5]-10, []-0], 1, [L, S]>>(sum_list(L, T), S is 2 * T), "twice the sum").

% act(Name, Oracle, Pool, Options, Title)
act(dropmin_each, [L, R]>>maplist([S, T]>>(S == [] -> T = [] ; min_list(S, M), exclude(==(M), S, T)), L, R), nested, [initial([[[1,3,5],[5,3,2]]])], "drop the minimum from each sublist, from the notes' single example").
act(dropmin, [L, R]>>(L == [] -> R = [] ; min_list(L, M), exclude(==(M), L, R)), small, [initial([[3,1,2]])], "drop the minimum, from one example").
act(dropmax, [L, R]>>(L == [] -> R = [] ; max_list(L, M), exclude(==(M), L, R)), small, [initial([[3,1,2]])], "drop the maximum, from one example").
act(evens, [L, R]>>include([X]>>(X mod 2 =:= 0), L, R), small, [initial([[1,2,3,4]])], "keep the even elements, from one example").
act(positives, [L, R]>>include([X]>>(X > 0), L, R), small, [initial([[1,-2,3]])], "keep the positive elements, from one example").
act(double, [L, R]>>maplist([X, Y]>>(Y is 2 * X), L, R), small, [initial([[1,2,3]])], "double each element, from one example").
act(square, [L, R]>>maplist([X, Y]>>(Y is X * X), L, R), small, [initial([[2,3]])], "square each element, from one example").
act(inc, [L, R]>>maplist([X, Y]>>(Y is X + 1), L, R), small, [initial([[1,2]])], "add one to each element, from one example").
act(submin, [L, R]>>(L == [] -> R = [] ; min_list(L, M), maplist([X, Y]>>(Y is X - M), L, R)), small, [initial([[3,5,4]])], "subtract the minimum, from one example").
act(minmax, [L, Mn-Mx]>>(min_list(L, Mn), max_list(L, Mx)), small, [initial([[3,1,2]])], "minimum and maximum, from one example").
act(first_last, [L, F-Z]>>(L = [F|_], last(L, Z)), small, [initial([[3,1,2]])], "first and last element, from one example").
act(sorted, [L, R]>>msort(L, R), small, [initial([[3,1,2]])], "sort, from one example").
act(reversed, [L, R]>>reverse(L, R), small, [initial([[3,1,2]])], "reverse, from one example").
act(count, [L, N]>>length(L, N), small, [initial([[3,1,2]])], "length, from one example").
act(total, [L, S]>>sum_list(L, S), small, [initial([[3,1,2]])], "sum, from one example").
act(keep_max, [L, R]>>(L == [] -> R = [] ; max_list(L, M), include(==(M), L, R)), small, [initial([[3,1,2]])], "keep only the maximum, from one example").
act(inc_all, [L, R]>>maplist(maplist([X, Y]>>(Y is X + 1)), L, R), nested, [initial([[[1,2],[3]]])], "add one to every element of a list of lists, from one example").
act(evens_each, [L, R]>>maplist(include([X]>>(X mod 2 =:= 0)), L, R), nested, [initial([[[1,2],[3,4]]])], "keep the even elements of each sublist, from one example").
act(sums_each, [L, R]>>maplist(sum_list, L, R), nested, [initial([[[1,2],[3]]])], "sum of each sublist, from one example").
act(above_one, [L, R]>>include([X]>>(X > 1), L, R), small, [initial(2)], "keep the elements greater than one, from the first two pool inputs").

% sig(Examples, Title)
sig([[1,2,3]-[2,4,6], [5]-[10]], "length kept: a map").
sig([[1,2,3,4]-[2,4], [5,6]-[6]], "an ordered subsequence: a filter").
sig([[3,1,2]-[1,2,3], [5,4]-[4,5]], "a permutation").
sig([[3,1,2]-6, [5,4]-9], "a scalar from a list: an aggregate").
sig([[[1,3,5],[5,3,2]]-[[3,5],[5,3]]], "nested lists, per-sublist behaviour").
sig([[3,1,2]-(1-3), [5,9]-(5-9)], "a shared output template").
sig([[1,2]-ok, [3]-ok, []-ok], "the same output every time").
sig([[]-0, [1]-1, [1,2]-3], "an empty-list case").
sig([[1,2]-[1], [3,4,5]-[3,5]], "elements dropped").
sig([[[1],[2,3]]-[[1],[2,3]], [[4]]-[[4]]], "depth kept").
sig([[1,2,3]-[1,2,3,1,2,3], [4]-[4,4]], "output longer than the input").
sig([[a,b]-[b,a], [c]-[c]], "atoms: a permutation").
sig([[1,2]-f(1,2), [3,4]-f(3,4)], "a template with the input's elements").
sig([1-2, 5-10], "scalar input").
sig([[3,1,2]-[3,1], [5,9]-[5]], "a prefix: a subsequence").
sig([[[1,2],[3]]-[1,2,3], [[4]]-[4]], "depth reduced: a flatten").
sig([[3,1,2]-[1,3], [5,9,7]-[5,9]], "fixed-length outputs from variable-length inputs").
sig([[1,2,3]-[3,2,1], [4,5]-[5,4]], "a permutation of the same length").
sig([[2,4]-true, [1]-false], "boolean-like outputs").
sig([[1,1,2]-[1,2], [3,3]-[3]], "duplicates removed").

% lgg(Terms, Title)
lgg([1-3, 5-9], "two pairs").
lgg([f(a, 1), f(a, 2)], "a shared constant").
lgg([g(1, 1), g(2, 2)], "the same tuple twice: one variable").
lgg([h(1), h(1)], "equal terms").
lgg([[1, 2], [3, 4]], "two-element lists").
lgg([[1, 2], [3, 4, 5]], "lists of different lengths").
lgg([p(q(1), 2), p(q(3), 4)], "a nested template").
lgg([p(q(1), 2), p(r(1), 2)], "different inner functors").
lgg([a, b], "two atoms").
lgg([s(1, 2, 3), s(4, 5, 6), s(7, 8, 9)], "three terms").
lgg([t(1, x), t(2, x), t(3, x)], "a constant argument over three terms").
lgg([k(1, 2), k(2, 1)], "swapped arguments: two variables").
lgg([1-[a], 2-[b]], "a pair holding a list").
lgg([f(g(1), g(1)), f(g(2), g(2))], "a repeated subterm").
lgg([f(1), g(1)], "different functors").
lgg([m(1, n(2, 3)), m(1, n(4, 3))], "one hole deep inside").
lgg([[1|t], [2|t]], "an improper list tail").
lgg([e, e, e], "the same atom three times").
lgg([v(1, 2), v(1, 2), v(1, 3)], "one argument differs once").
lgg([pair(min, 1), pair(max, 2)], "labels and values").

% stat(Vars, Envs, Size, Title)
stat([x-list(int)], [[x=[1,3,5]], [x=[5,3,2]]], 2, "one list, two examples, size 2").
stat([x-list(int)], [[x=[1,3,5]], [x=[5,3,2]]], 3, "one list, two examples, size 3").
stat([x-list(int)], [[x=[1,3,5]], [x=[5,3,2]]], 4, "one list, two examples, size 4").
stat([x-list(int)], [[x=[1,2]]], 4, "one list, one example, size 4").
stat([x-list(int)], [[x=[1,2]], [x=[3]], [x=[]]], 4, "one list, three examples, size 4").
stat([x-int], [[x=1], [x=2], [x=3]], 2, "one integer, size 2").
stat([x-int], [[x=1], [x=2], [x=3]], 3, "one integer, size 3").
stat([x-int], [[x=1], [x=2], [x=3]], 4, "one integer, size 4").
stat([x-int], [[x=(-1)], [x=0], [x=1], [x=2], [x=3]], 4, "one integer on five values, size 4").
stat([r-int, x-int], [[r=0, x=1], [r=1, x=2], [r=2, x=3]], 3, "fold combiner, three probe pairs, size 3").
stat([r-int, x-int], [[r=0, x=1], [r=1, x=2], [r=2, x=3]], 4, "fold combiner, three probe pairs, size 4").
stat([r-int, x-int], [[r=0, x=1], [r=1, x=2], [r=2, x=3], [r=5, x=0]], 5, "fold combiner, four probe pairs, size 5").
stat([x-int, l-list(int)], [[x=1, l=[1,2]], [x=2, l=[1,2]]], 3, "element and its list, size 3").
stat([x-int, l-list(int)], [[x=1, l=[1,2]], [x=2, l=[1,2]], [x=5, l=[5]]], 4, "element and its list, size 4").
stat([r-list(int), x-int], [[r=[], x=1], [r=[2], x=3]], 4, "list fold combiner, size 4").

% check(Kind, Query, Title)
check_pair(proof, "show_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is X+X, e(Xs,Ys))], e, [list(int), any])", "2*X and X+X: proved").
check_pair(proof, "show_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is 2*X+1, e(Xs,Ys))], e, [list(int), any])", "2*X and 2*X+1: not proved").
check_pair(proof, "show_equal([(s(L, R) :- msort(L, R))], s, [(t(L, R) :- sort(L, R))], t, [list(int), any])", "msort and sort are different library calls: not proved").
check_pair(proof, "show_equal([f([],[]), (f([X|Xs],R) :- (X > 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X >= 2 -> R=[X|R1] ; R=R1), g(Xs,R1))], g, [list(int), any])", "X > 1 and X >= 2 on integers: proved").
check_pair(proof, "show_equal([f([],[]), (f([X|Xs],R) :- (X mod 2 < 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X mod 2 =:= 1 -> R=R1 ; R=[X|R1]), g(Xs,R1))], g, [list(int), any])", "residues and a flipped if-then-else: proved").
check_pair(proof, "show_equal([f([],_,[]), (f([X|Xs],M,R) :- (X =\\= M -> R=[X|R1] ; R=R1), f(Xs,M,R1))], f, [g([],_,[]), (g([X|Xs],M,R) :- (X == M -> R=R1 ; R=[X|R1]), g(Xs,M,R1))], g, [list(int), int, any])", "== on integers read as =:=: proved").
check_pair(proof, "show_equal([f([],_,[]), (f([X|Xs],M,R) :- (X =\\= M -> R=[X|R1] ; R=R1), f(Xs,M,R1))], f, [g([],_,[]), (g([X|Xs],M,R) :- (X == M -> R=R1 ; R=[X|R1]), g(Xs,M,R1))], g, [list(any), any, any])", "== on terms of unknown type is not =:=: not proved").
check_pair(proof, "show_equal([c([],0), (c([_|Xs],N) :- c(Xs,M), N is M+1)], c, [d([],0), (d([X|Xs],N) :- d([X|Xs],M), N is M+1)], d, [list(int), any])", "a recursive call that is not on the tail cannot use the induction hypothesis: not proved").
check_pair(run_all, "show_run_all([q(X, Y) :- Y is X + 1], q, [1-2, 2-4])", "the first example not reproduced").
check_pair(run_all, "show_run_all([q(X, Y) :- Y is X + 1], q, [1-2, 2-3])", "every example reproduced").
check_pair(run_all, "show_run_all([(loop(X, Y) :- loop(X, Y))], loop, [1-1])", "runaway recursion stops at the inference limit").
check_pair(run_all, "show_run_all([f(a, 1)], f, [a-1, b-2])", "a call that fails").
check_pair(run_all, "show_run_all([(h(L, X) :- L = [X|_])], h, [[1,2]-1, []-0])", "head of the empty list fails").
check_pair(run_all, "show_run_all([(t(X, Y) :- Y is 10 // X)], t, [2-5, 0-0])", "an exception counts as no answer").
check_pair(fold_spec, "show_fold_spec([r([], []), (r([X|Xs], R) :- r(Xs, R1), append(R1, [X], R))], r)", "append becomes app, and app's definition is added").
check_pair(fold_spec, "show_fold_spec([s([], 0), (s([X|Xs], S) :- s(Xs, S0), S is S0 + X)], s)", "a sum specification is kept as it is").
check_pair(fold_spec, "show_fold_spec([(m(L, M) :- min_list(L, M))], m)", "a library call is refused").
check_pair(fold_spec, "show_fold_spec([e([], []), (e([X|Xs], R) :- (X > 0 -> R = [X|R1] ; R = R1), e(Xs, R1))], e)", "if-then-else is refused").
check_pair(fold_spec, "show_fold_spec([l([], 0), (l([_|Xs], N) :- l(Xs, N0), N is N0 + 1)], l)", "a length specification").
check_pair(fold_spec, "show_fold_spec([f([], []), (f([X|Xs], R) :- f(Xs, R1), append(X, R1, R))], f)", "flatten: append becomes app").

% algo(Name, Examples, Exclude, Mode, Size, Title)
algo(sum, [[1,2,3]-6, [4]-4, []-0, [2,5]-7], [sum], [in(list(int)), out], 4, "sum").
algo(len, [[1,2,3]-3, [4]-1, []-0, [5,6]-2], [len], [in(list(any)), out], 7, "length").
algo(rev, [[1,2,3]-[3,2,1], [4]-[4], []-[], [2,5]-[5,2]], [rev], [in(list(any)), out], 7, "naive reverse").
algo(sumsq, [[1,2,3]-14, [4]-16, []-0, [2,5]-29], [], [in(list(int)), out], 4, "sum of squares").
algo(sumdbl, [[1,2,3]-12, [4]-8, []-0, [2,5]-14], [sum], [in(list(int)), out], 4, "sum of doubles").
algo(prod, [[1,2,3]-6, [4]-4, []-1, [2,5]-10], [], [in(list(int)), out], 4, "product").
algo(cnt_odd, [[1,2,3]-2, [4]-0, []-0, [5,7,9]-3, [2,4,1]-1], [len], [in(list(int)), out], 4, "count the odd elements").
algo(flat2, [[[1,2],[3]]-[1,2,3], [[4]]-[4], []-[], [[],[5]]-[5]], [], [in(list(list(any))), out], 3, "flatten a list of lists").
algo(len_plus, [[1,2,3]-6, [4]-2, []-0, [5,6]-4], [len], [in(list(any)), out], 7, "twice the length").
algo(sum_inc, [[1,2,3]-9, [4]-5, []-0, [2,5]-9], [sum], [in(list(int)), out], 4, "sum of incremented elements").
algo(sum_neg, [[1,2,3]-(-6), [4]-(-4), []-0, [2,5]-(-7)], [sum], [in(list(int)), out], 4, "negated sum").
algo(cnt_pos, [[1,2,3]-3, [4]-1, []-0, [2,5]-2], [len], [in(list(int)), out], 4, "length of integer lists").
algo(sum_abs, [[1,-2,3]-6, [4]-4, []-0, [-2,5]-7], [sum], [in(list(int)), out], 4, "sum of absolute values").
algo(sum_halves_fold, [[4,5,6]-7, [1]-0, []-0, [9,9]-8], [sum], [in(list(int)), out], 4, "sum of halved elements").
algo(maxf, [[1,3,2]-3, [4]-4, [2,5]-5, [0,1]-1, []-0], [maxl, msort, sort, last], [in(list(int)), out], 4, "maximum of non-negative integers").

% ---------------------------------------------------------------- main
main :-
    io_dir(D),
    atom_concat(D, '/io_synth_pairs.jsonl', J), atom_concat(D, '/io_synth_pairs.md', M),
    open_pairs(J),
    forall(sig(Exs, T), qpair('io_synth/signals', T, "", "show_signals(~q)", [Exs])),
    forall(lgg(Ts, T), qpair('io_synth/anti-unification', T, "", "show_lgg(~q)", [Ts])),
    forall(hier(N, Exs, Opts, _, Pool, T),
           ( ref_text(N, RT), string_concat("% reference program\n", RT, Prog),
             qpair('io_synth/hierarchy', T, Prog, "show_synth(~q, ~q, ~q, ~q)", [N, Exs, Opts, Pool]) )),
    forall(stat(Vs, Es, S, T), qpair('io_synth/reductions', T, "", "show_stats(~q, ~q, ~q)", [Vs, Es, S])),
    forall(ga(N, Exs, Seed, _, T),
           ( ref_text(N, RT), string_concat("% reference program\n", RT, Prog),
             qpair('io_synth/genetic', T, Prog, "show_ga(~q, ~q, ~q)", [N, Exs, Seed]) )),
    forall(act(N, _, Pool, Opts, T),
           ( ref_text(N, RT), string_concat("% reference program (the oracle)\n", RT, Prog),
             qpair('io_synth/active', T, Prog, "show_active(~q, ~q, ~q)", [N, Pool, Opts]) )),
    forall(check_pair(K, Q, T), ( atom_concat('io_synth/checks-', K, Cat), pair(Cat, T, "", Q) )),
    forall(algo(N, Exs, Ex, Mode, Size, T),
           ( ref_text(N, RT), string_concat("% reference program\n", RT, Prog),
             qpair('io_synth/to-algorithm', T, Prog, "show_to_algorithm(~q, ~q, ~q, ~q, ~q)", [N, Exs, Ex, Mode, Size]) )),
    close_pairs,
    to_markdown(J, M, "io_synth",
        "Each pair is a query to `prolog/io_synth.pl`, which finds nested and hierarchical predicates from input/output examples: structural signals, anti-unification, hierarchies found by top-down propagation (each checked against a reference predicate on every input of a pool), the size of the search with and without observational equivalence, the genetic algorithm, active learning with an oracle, the checks, and input/output to an algorithm through `fold.pl`. Each program found is proved equal to a reference program for every input of the declared types (`prolog/io_proof.pl`), or the output says that it is not proved; each is also run against its reference on a pool of inputs. Every output was produced by running this repository's code with `io_pairs/generate_io_synth.pl`; nothing was written by hand."),
    format(user_error, "~ndone~n", []).

% qpair: the query text from a format string, with variables written as A, B, ...
qpair(Cat, Title, Prog, Fmt, Args) :-
    copy_term(Args, A1), numbervars(A1, 0, _),
    format(string(Q), Fmt, A1),
    pair(Cat, Title, Prog, Q).
