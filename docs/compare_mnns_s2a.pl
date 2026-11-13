/*  compare_mnns_s2a.pl -- run mnns's s2a/4 and S2A2's io_synth on the same tasks, and test
    each program on held-out inputs that neither saw.
    From the S2A2 root, with a clone of github.com/luciangreen/mnns next to it:
        MNNS=../mnns swipl -q -g main -t halt docs/compare_mnns_s2a.pl */
:- ( getenv('MNNS', D) -> true ; D = '../mnns' ), atom_concat(D, '/prolog/s2a/s2a', F), use_module(F).
:- prolog_load_context(directory, Dir), atom_concat(Dir, '/../prolog/io_synth', F), use_module(F).

% task(Name, TrainingExamples, HeldOutExamples)
task(projection, [box(red,[5,6])-[5,6], box(blue,[7,8])-[7,8]], [box(green,[1,2,3])-[1,2,3]]).
task(swap_pair, [[5,6]-[6,5], [7,8]-[8,7]], [[1,9]-[9,1]]).
task(affine, [1-5, 2-7, 4-11], [10-23, -3-(-3)]).
task(quadratic, [1-2, 2-5, 3-10, 5-26], [7-50, -2-5]).
task(cubic, [0-1, 1-2, 2-9, 3-28, 4-65], [5-126]).
task(reverse, [[1,2,3]-[3,2,1], [4,5,6,7]-[7,6,5,4]], [[1,2]-[2,1], [8]-[8]]).
task(double_each, [[1,2,3]-[2,4,6], [5]-[10], []-[]], [[7,0]-[14,0]]).
task(evens, [[1,2,3,4]-[2,4], [5,6]-[6], [7]-[], [-2,1]-[-2]], [[8,9,10]-[8,10]]).
task(sum, [[1,2,3]-6, [4]-4, []-0, [2,5]-7], [[10,20,30]-60]).
task(minmax, [[3,1,2]-(1-3), [5,9]-(5-9), [4]-(4-4)], [[8,2,6]-(2-8)]).
task(dropmin_each, [[[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]], [[6,8,7]]-[[8,7]]], [[[4,2,9],[3]]-[[4,9],[]]]).
task(inc_all, [[[1,2],[3]]-[[2,3],[4]], [[5]]-[[6]], []-[]], [[[0],[9,9]]-[[1],[10,10]]]).

spec(Exs, Spec) :- findall([[input, [['A', I]]], [output, [['B', O]]]], member(I-O, Exs), Spec).
run_mnns(Name, Exs, Res, Cs) :-
    spec(Exs, Spec), mnn_s2a:s2a(Name, Spec, [], P),
    (   P = mnn_program(_, _, Preds, _, trace([T|_]))
    ->  findall((H :- B), ( member(mnn_pred(_, _, _, Cl, _), Preds), member(mnn_clause(_, H, B, _), Cl) ), Cs),
        functor(T, Res, _)
    ;   P = no_algorithm(R), Res = no_algorithm(R), Cs = [] ).
held(Cs, Name, Held, Ok) :- ( Cs == [] -> Ok = '-' ; run_all(Cs, Name, Held, R), ( R == ok -> Ok = yes ; Ok = no ) ).

main :-
    format("| task | mnns s2a/4 | held out | S2A2 io_synth | held out |~n| --- | --- | --- | --- | --- |~n"),
    forall(task(N, Tr, Ho),
      ( ( catch(run_mnns(N, Tr, MR, MCs), E, ( MR = error(E), MCs = [] )) -> true ; MR = failed, MCs = [] ),
        held(MCs, N, Ho, MH),
        (   catch(call_with_time_limit(60, synth(N, Tr, [], SP, report(node(_, K, _), _, _))), _, fail)
        ->  functor(K, SK, _) ; SK = none, SP = [] ),
        held(SP, N, Ho, SH),
        format("| ~w | ~w | ~w | ~w | ~w |~n", [N, MR, MH, SK, SH]) )).
