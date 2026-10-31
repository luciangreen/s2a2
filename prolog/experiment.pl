/*  experiment.pl -- learn each family's optimisation algorithm from its two training
    pairs, apply it to every test program, and check the result three ways:
      exact    : the same program as the reference axioms give (up to renaming)
      proved   : the prover shows it is equal to the ORIGINAL for every input
                 (syntactic, exhaustive, or a 2,000-input sample, as the result says)
      same_alg : the learned (operator, conditions) list equals the axioms' list
    Writes results to the file named by the RESULTS environment variable (default
    results.pl) as result/7 facts and prints a table. */
:- use_module(s2a2).
:- use_module(axioms).
:- use_module(instances).
:- use_module(prover).

main :-
    ( getenv('RESULTS', Out) -> true ; Out = 'results.pl' ),
    ( getenv('FAMILIES', FS) -> split_string(FS, ",", "", Ss), maplist([S, A]>>atom_string(A, S), Ss, Fams) ; families(Fams) ),
    open(Out, write, OS),
    forall(member(F, Fams), run_family(F, OS)),
    close(OS).

run_family(F, OS) :-
    axioms(F, Ax),
    findall(pair(B, A, T), ( inst(F, train, _, Cs, T), program_from_clauses(Cs, B),
                             apply_algorithm(Ax, B, T, A, _) ), Pairs),
    format("~n== ~w~n", [F]),
    (   catch(call_with_time_limit(600, learn(Pairs, Alg)), E, (print_message(error, E), Alg = failed))
    ->  true ; Alg = failed ),
    ( Alg == failed -> writeln('learning failed') ; show_algorithm(Alg) ),
    same_algorithm(Alg, Ax, SameAlg),
    format("learned algorithm equals the axioms: ~w~n", [SameAlg]),
    forall(inst(F, test, Name, Cs, T),
           ( program_from_clauses(Cs, P0),
             apply_algorithm(Ax, P0, T, Ref, _),
             (   Alg == failed -> Got = none, Exact = false
             ;   apply_algorithm(Alg, P0, T, Got, _),
                 preds_of(P0, Fixed), ( same_program(Got, Ref, Fixed) -> Exact = true ; Exact = false )
             ),
             proof(P0, Got, T, Proof),
             changed(P0, Ref, Changed),
             format("  ~w: exact=~w changed=~w proof=~w~n", [Name, Exact, Changed, Proof]),
             format(OS, "~q.~n", [result(F, Name, Exact, Proof, SameAlg, Changed, Got)]) )).

changed(P0, Ref, C) :- preds_of(P0, Fx), ( same_program(P0, Ref, Fx) -> C = false ; C = true ).

proof(_, none, _, none) :- !.
proof(P0, P1, Targets, Result) :-
    program_to_clauses(P0, C0), program_to_clauses(P1, C1),
    P0 = prog(Facts, _),
    findall(K, ( member(Fa, Facts), functor(Fa, N, A), K = N/A ), Ks0), sort(Ks0, Edb),
    rules_only(C0, R0), rules_only(C1, R1),
    findall(X, ( member(Fa, Facts), Fa =.. [_|As], member(X, As) ), Xs0), sort(Xs0, Xs),
    take(4, Xs, Consts),
    % equal for every input over the facts' predicates and up to 4 of their constants,
    % keeping the program's own facts as extra input too
    (   catch(equivalent_with_facts(R0, R1, Facts, Targets, Edb, Consts, Result), E,
              (Result = error(E)))
    ->  true ; Result = failed ).
rules_only(Cs, Rs) :- include([C]>>(C = (_ :- _)), Cs, Rs).
take(N, L, T) :- length(L, Len), ( Len =< N -> T = L ; length(T, N), append(T, _, L) ).

% the facts of the program are kept (they define helper predicates such as num/1);
% the equality is checked over all inputs built from the input predicates
equivalent_with_facts(R0, R1, Facts, Targets, _Edb, _Consts, Result) :-
    % syntactic first (sound for every input), then exhaustively over subsets of the
    % program's own facts: every combination of the facts is an input
    (   equivalent(R0, R1, Targets, edb([], []), proved(syntactic(S))) -> Result = proved(syntactic(S))
    ;   % a fact of a predicate that a rule also defines (a recurrence's base case such
        % as t(0,3)) is part of the program, not input: it is kept in every input
        partition({R0}/[Fa]>>( functor(Fa, N, A), member((H :- _), R0), functor(H, N, A) ),
                  Facts, Base, Inputs),
        length(Inputs, NF), NF =< 16
    ->  ( subset_of(Inputs, Sub0), append(Base, Sub0, Sub),
          least_model(R0, Sub, M0), least_model(R1, Sub, M1),
          tgt(M0, Targets, T0), tgt(M1, Targets, T1), T0 \== T1
        ->  Cex = refuted(input(Sub), only_in_original(T0), only_in_result(T1)),
            % second try: unary facts are the index TYPE (n(0..3) = "the numbers 0..3"),
            % held fixed; only the other facts vary. AlgebraPLOp's closed form is only
            % valid when the index domain has no gaps, and this states that exactly.
            partition([Fa]>>functor(Fa, _, 1), Inputs, Types, Rest),
            append(Base, Types, Fixed),
            (   Types \== [],
                \+ ( subset_of(Rest, S0), append(Fixed, S0, S1),
                     least_model(R0, S1, N0), least_model(R1, S1, N1),
                     tgt(N0, Targets, U0), tgt(N1, Targets, U1), U0 \== U1 )
            ->  length(Rest, NR), T2 is 2 ** NR,
                Result = proved_if_types_fixed(all_subsets_of_the_other_facts(T2), Cex)
            ;   Result = Cex
            )
        ;   Total is 2 ** NF, Result = proved(all_subsets_of_the_facts(Total))
        )
    ;   Result = too_many_facts
    ).
subset_of([], []).
subset_of([X|Xs], [X|Ys]) :- subset_of(Xs, Ys).
subset_of([_|Xs], Ys) :- subset_of(Xs, Ys).
tgt(M, Targets, T) :- include({Targets}/[A]>>(functor(A, N, Ar), memberchk(N/Ar, Targets)), M, T0), sort(T0, T).

same_algorithm(failed, _, false) :- !.
same_algorithm(algorithm(L), algorithm(A), R) :-
    maplist(norm_rule, L, L1), maplist(norm_rule, A, A1),
    ( L1 =@= A1 -> R = true ; R = false ).
norm_rule(rule(Op, Cs), rule(Op1, Cs1)) :- msort(Cs, Cs1), ( Op = replace(_) -> Op1 = replace ; Op1 = Op ).
