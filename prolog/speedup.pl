/*  speedup.pl -- does the MNN make the derivation search faster?
    For every instance of every family, find the derivation from the original program to
    its reference (axioms) result, counting search nodes, first in the fixed operator
    order and then with the MNN ordering, trained leave-one-family-out (the network
    never sees the family it is measured on). Prints per-family node counts. */
:- use_module(s2a2).
:- use_module(axioms).
:- use_module(instances).

pairs_of(F, Pairs) :-
    axioms(F, Ax),
    findall(pair(B, A, T), ( inst(F, _, _, Cs, T), program_from_clauses(Cs, B), apply_algorithm(Ax, B, T, A, _) ), Pairs).

% nodes are counted for solved pairs only: an unsolved pair runs until the time limit, so its
% count measures the machine's speed, not the search
count_family(Pairs, Total, Solved) :-
    foldl([pair(B, A, T), N0-S0, N-S]>>(
              reset_nodes,
              (   s2a2:limited(120, derive(B, A, T, 8, _))
              ->  S is S0 + 1, nodes(K), N is N0 + K
              ;   S = S0, N = N0
              ) ),
          Pairs, 0-0, Total-Solved).

main :-
    families(Fs),
    findall(F-Pairs, ( member(F, Fs), pairs_of(F, Pairs) ), FP),
    % derivations of every family, for training
    findall(F-Ds-Pairs, ( member(F-Pairs, FP), mnn(false),
                          findall(D, ( member(P, Pairs), s2a2:limited(120, pair_derivation(P, D)) ), Ds) ), All),
    format("~w~t~22|~w~t~36|~w~t~50|~w~n", [family, 'nodes (fixed order)', 'nodes (MNN order)', 'solved fixed/MNN']),
    ( getenv('MEASURE', MS) -> split_string(MS, ",", "", MSs), maplist([X, A]>>atom_string(A, X), MSs, Measure) ; Measure = Fs ),
    forall(( member(F-Pairs, FP), memberchk(F, Measure) ),
           ( mnn(false), count_family(Pairs, N1, S1),
             findall(D, ( member(G-Ds-_, All), G \== F, member(D, Ds) ), TrainD),
             findall(P, ( member(G-Ds-Ps, All), G \== F, length(Ds, ND), length(Ps2, ND), append(Ps2, _, Ps), member(P, Ps2) ), TrainP),
             train_mnn(TrainD, TrainP), mnn(true), count_family(Pairs, N2, S2), mnn(false),
             length(Pairs, NP),
             format("~w~t~22|~w~t~36|~w~t~50|~w/~w, ~w/~w~n", [F, N1, N2, S1, NP, S2, NP]),
             format(user_error, "~q.~n", [speed(F, N1, N2, S1, S2, NP)]) )).
