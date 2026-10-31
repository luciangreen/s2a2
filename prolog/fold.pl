:- encoding(utf8).
/*  fold.pl -- spec to algorithm: derive an efficient program from a naive one by
    unfold/fold transformation (Burstall and Darlington 1977; Tamaki and Sato 1984),
    with eureka definitions and a database of proved lemmas.

    S2A2's other operators only make a program smaller. Deriving a new algorithm
    sometimes needs the opposite first: introduce a new predicate (a "eureka"
    definition), unfold it, rewrite with a lemma, then FOLD the result back into a
    call to the new predicate. This module adds those steps.

    A program is a list of clauses Head-BodyList over pure, function-free-or-list
    Prolog (no builtins). The rules, each with the side conditions that make it sound:

      define     add  d(V1..Vn) :- G1,...,Gk  for a new name d
      unfold     replace a clause by all its resolvents on one body literal
      fold       replace an instance of a definition's body by its head; the
                 definition's local variables must map to distinct variables that
                 occur nowhere else in the clause (Tamaki-Sato condition), and a clause
                 that came from a definition must have been unfolded at least once
      lemma      replace an instance of one side of a PROVED lemma by the other side,
                 under the same local-variable condition
      normalise  unfold a literal whose case argument is already a constructor and that
                 matches at most one clause (deterministic, always sound)

    Strategies
      deforest   a conjunctive definition p(..) :- q(..), r(..) is unfolded on its
                 induction variable and folded back, removing the intermediate structure
      accumulate a recursive clause p([H|T],..) :- p(T,X), q(X,[H],..) that does work
                 after its recursive call gets a eureka definition by GENERALISING the
                 constants after the call (here [H] becomes a fresh accumulator A); the
                 definition is unfolded, rewritten with lemmas from the database, and
                 folded; the original clause is then folded with the definition
    Both search for the steps by iterative deepening.

    Correctness
      * unfold/fold only (deforest, lemma proofs): the least model is preserved
        exactly (Tamaki and Sato 1984).
      * with lemma steps (accumulate): every step keeps every clause true in the least
        model M0 of the specification plus definitions, so M(result) is a subset of M0
        (soundness). Equality then follows from three checks done here:
          total(Result, P, Mode)       the result answers every input of the mode
                                       (case analysis on a list argument, structural
                                       recursion, mode-correct calls)
          functional(Spec, P, Mode)    the specification has at most one answer
          list_slot(Spec, P, I)        the specification answers only list inputs
        so for every ground input both have exactly the same answer.
      * lemmas enter the database only when prove_lemma/3 proves them: both sides are
        deforested on the same induction variable and must give the same program.
      * bounded_equal/7 independently compares two programs on every input up to a
        size, and returns a counter-example when they differ.

    Main predicates
      spec_to_algorithm(+Spec, +Target, +Lemmas, -Program, -Report)
      prove_lemma(+Spec, +Lemma, -Result)          Lemma = lemma(Name, Lhs, Rhs)
      total/3, functional/3, list_slot/3, bounded_equal/7, steps/4, show/1
*/
:- module(fold, [ spec_to_algorithm/5, prove_lemma/3, total/3, functional/3, list_slot/3,
                  bounded_equal/7, steps/4, show/1, clauses/2, same_clauses/2,
                  unfold/4, fold_with/3, lemma_step/4 ]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% ---------------------------------------------------------------- representation
clauses([], []).
clauses([C|Cs], [H-B|Rs]) :- ( C = (H :- Bd) -> conj(Bd, B) ; H = C, B = [] ), clauses(Cs, Rs).
conj((A, B), L) :- !, conj(A, LA), conj(B, LB), append(LA, LB, L).
conj(true, []) :- !.
conj(G, [G]).

key(G, N/A) :- functor(G, N, A).
clauses_of(P, K, Cs) :- findall(H-B, ( member(H-B, P), key(H, K) ), Cs).

show(Cs) :- forall(member(C, Cs), show_clause(C)).
show_clause(H-B) :-
    copy_term(H-B, H1-B1), numbervars(H1-B1, 0, _),
    (   B1 == [] -> format("    ~p.~n", [H1])
    ;   atomic_list_concat_terms(B1, S), format("    ~p :- ~w.~n", [H1, S]) ).
atomic_list_concat_terms(Gs, S) :-
    maplist([G, A]>>format(atom(A), "~p", [G]), Gs, As), atomic_list_concat(As, ', ', S).

% the argument that a predicate's clauses analyse by cases ([] or [_|_] in every head)
case_pos(P, K, I) :-
    clauses_of(P, K, Cs), Cs = [H0-_|_], functor(H0, _, A), between(1, A, I),
    forall(member(H-_, Cs), ( arg(I, H, X), ( X == [] ; subsumes_term([_|_], X) ) )), !.

% ---------------------------------------------------------------- unfold
unfold(Spec, H-B, J, Cs) :-
    nth1(J, B, L), key(L, K), clauses_of(Spec, K, Ds), Ds \== [],
    findall(H1-B1, ( copy_term(H-B, H1-B0), nth1(J, B0, L1, Rest),
                     member(D, Ds), copy_term(D, DH-DB),
                     unify_with_occurs_check(L1, DH),
                     J0 is J - 1, length(Pre, J0), append(Pre, Post, Rest),
                     append([Pre, DB, Post], B1) ), Cs).

% deterministic unfolding of literals whose case argument is a constructor
normalise(Spec, DefKs, C, Out) :-
    C = _-B,
    (   nth1(J, B, L), key(L, K), \+ memberchk(K, DefKs), case_pos(Spec, K, I),
        arg(I, L, X), nonvar(X), unfold(Spec, C, J, Cs), length(Cs, N), N =< 1
    ->  ( Cs = [C1] -> normalise(Spec, DefKs, C1, Out) ; Out = failed )
    ;   Out = C
    ).

% ---------------------------------------------------------------- matching goals
% match the patterns onto distinct body literals, binding only the patterns' variables
match_goals([], _, []).
match_goals([P|Ps], B, [I|Is]) :-
    nth1(I, B, G), subsumes_term(P, G), P = G, match_goals(Ps, B, Is), \+ memberchk(I, Is).

others(B, Idx, Os) :- others_(B, 1, Idx, Os).
others_([], _, _, []).
others_([G|Gs], I, Idx, Os) :- I1 is I + 1,
    ( memberchk(I, Idx) -> Os = Os1 ; Os = [G|Os1] ), others_(Gs, I1, Idx, Os1).

replace_at(B, Idx, New, B1) :- min_list(Idx, M), rep(B, 1, Idx, M, New, B1).
rep([], _, _, _, _, []).
rep([G|Gs], I, Idx, M, New, Out) :- I1 is I + 1,
    (   I == M -> append(New, Rest, Out)
    ;   memberchk(I, Idx) -> Out = Rest
    ;   Out = [G|Rest] ),
    rep(Gs, I1, Idx, M, New, Rest).

vsub(Xs, Ys, Zs) :- exclude({Ys}/[X]>>( member(Y, Ys), Y == X ), Xs, Zs).
vint(Xs, Ys, Zs) :- include({Ys}/[X]>>( member(Y, Ys), Y == X ), Xs, Zs).

% local variables must be distinct variables that occur nowhere else in the clause
locals_ok(Ex, H, B, Idx, Extra) :-
    maplist(var, Ex), sort(Ex, S), length(S, N), length(Ex, N),
    others(B, Idx, Os), term_variables(H-Os-Extra, OV),
    \+ ( member(E, Ex), member(V, OV), E == V ).

% ---------------------------------------------------------------- fold and lemma steps
fold_with(def(DH0, DB0), H-B, H-B1) :-
    copy_term(DH0-DB0, DH-DB),
    term_variables(DH, HV), term_variables(DB, BV), vsub(BV, HV, Ex),
    match_goals(DB, B, Idx), locals_ok(Ex, H, B, Idx, DH),
    replace_at(B, Idx, [DH], B1).

lemma_step(lemma(_, L0, R0), Dir, H-B, H-B1) :-
    copy_term(L0-R0, L-R),
    ( Dir == lr -> F = L, T = R ; F = R, T = L ),
    term_variables(F, FV), term_variables(T, TV), vsub(FV, TV, Ex),
    match_goals(F, B, Idx), locals_ok(Ex, H, B, Idx, T),
    replace_at(B, Idx, T, B1).

% ---------------------------------------------------------------- search for one clause
% goal: a step clause (constructor at the induction argument) calls only new predicates
goal(DefKs, Case, H-B) :-
    arg(Case, H, X),
    ( subsumes_term([_|_], X) -> forall(member(G, B), ( key(G, K), memberchk(K, DefKs) )) ; true ).

solve_clause(Spec, Defs, Lemmas, Case, Max, C, C1-Steps) :-
    def_keys(Defs, DK),
    between(0, Max, D), search(Spec, Defs, DK, Lemmas, Case, D, C, C1, Steps), !.

search(_, _, DK, _, Case, _, C, C, []) :- goal(DK, Case, C), !.
search(Spec, Defs, DK, Lemmas, Case, D, C, Cf, [S-C2|Ss]) :-
    D > 0, D1 is D - 1,
    step_op(Defs, Lemmas, C, C1, S),
    normalise(Spec, DK, C1, C2), C2 \== failed,
    search(Spec, Defs, DK, Lemmas, Case, D1, C2, Cf, Ss).

step_op(Defs, _, C, C1, fold(N)) :- member(D, Defs), D = def(DH, _), key(DH, N/_), fold_with(D, C, C1).
step_op(_, Lemmas, C, C1, lemma(N, Dir)) :-
    member(Lm, Lemmas), Lm = lemma(N, _, _), member(Dir, [lr, rl]), lemma_step(Lm, Dir, C, C1).

def_keys(Defs, Ks) :- findall(K, ( member(def(H, _), Defs), key(H, K) ), Ks).

% ---------------------------------------------------------------- strategies
% deforest_on(+Spec, +Def, +Case, +Lemmas, -Clauses, -Trace)
deforest_on(Spec, H-B, Case, Lemmas, Clauses, Trace) :-
    arg(Case, H, X), var(X),
    nth1(J, B, L), key(L, K), case_pos(Spec, K, I), arg(I, L, Y), Y == X, !,
    Def = def(H, B), def_keys([Def], DK),
    unfold(Spec, H-B, J, Cs0),
    maplist(normalise(Spec, DK), Cs0, Cs1), exclude(==(failed), Cs1, Cs2),
    maplist(solve_clause(Spec, [Def], Lemmas, Case, 4), Cs2, Rs),
    pairs_keys_values(Rs, Clauses, StepLists),
    Trace = [define(H-B), unfold(J, Cs2), steps(StepLists)].

spec_to_algorithm(Spec, Target, Lemmas, Program, Report) :-
    clauses_of(Spec, Target, TCs),
    (   TCs = [H-B], B = [_, _|_], \+ ( member(G, B), key(G, Target) )
    ->  % deforestation of a conjunctive definition
        functor(H, _, A), between(1, A, Case),
        deforest_on(Spec, H-B, Case, Lemmas, Derived, Trace), !,
        reachable([Target], Derived, Spec, Program),
        uses_lemmas(Trace, Used),
        Report = report(deforest, Trace, Used)
    ;   % accumulation: eureka by generalisation after the recursive call
        member(H-B, TCs), B = [R|Rest], key(R, Target), Rest \== [],
        term_variables(H, HV0), generalise(Rest, HV0, Rest1, Gen),
        GB = [R|Rest1],
        term_variables(H, HV), term_variables(GB, BV),
        include({HV, Gen}/[V]>>( ( member(W, HV), W == V ) ; ( member(W, Gen), W == V ) ), BV, Iface),
        Target = TN/_, atom_concat(TN, '_acc', DN), DH =.. [DN|Iface],
        case_pos(Spec, Target, I), arg(I, R, X), nth1(Case, Iface, X1), X1 == X,
        deforest_on([DH-GB|Spec], DH-GB, Case, Lemmas, Derived, Trace0), !,
        Def = def(DH, GB),
        maplist(fold_greedy([Def]), TCs, TCs1),
        append(TCs1, Derived, P0),
        reachable([Target], P0, Spec, Program),
        append([eureka(DH-GB, generalised(Rest, Rest1))|Trace0], [fold_target(TCs1)], Trace),
        uses_lemmas(Trace, Used),
        Report = report(accumulate, Trace, Used)
    ).

% replace each non-variable argument built only from head variables by a fresh variable
generalise([], _, [], []).
generalise([L|Ls], HV, [L1|Ls1], Gen) :-
    L =.. [F|As], foldl(gen_arg(HV), As, As1, [], G1), L1 =.. [F|As1],
    generalise(Ls, HV, Ls1, G2), append(G1, G2, Gen).
gen_arg(_, A, A, G, G) :- var(A), !.
gen_arg(HV, A, V, G, [V|G]) :- term_variables(A, AV), forall(member(X, AV), ( member(Y, HV), Y == X )), !.
gen_arg(_, A, A, G, G).

fold_greedy(Defs, C, C1) :- ( member(D, Defs), fold_with(D, C, C2) -> C1 = C2 ; C1 = C ).

uses_lemmas(Trace, Used) :-
    findall(N, ( member(steps(SL), Trace), member(Ss, SL), member(lemma(N, _)-_, Ss) ), U), sort(U, Used).

% clauses of the predicates reachable from Roots; a predicate with new clauses is defined by
% those only, the others by the specification's clauses
reachable(Roots, New, Spec, Program) :-
    findall(K, ( member(H-_, New), key(H, K) ), NK0), sort(NK0, NewKs),
    reach(Roots, New, Spec, NewKs, [], Ks),
    findall(C, ( member(C, New), C = H-_, key(H, K), memberchk(K, Ks) ), P1),
    findall(C, ( member(C, Spec), C = H-_, key(H, K), memberchk(K, Ks), \+ memberchk(K, NewKs) ), P2),
    append(P1, P2, Program).
reach([], _, _, _, Ks, Ks).
reach([K|Rs], New, Spec, NewKs, Seen, Ks) :-
    (   memberchk(K, Seen) -> reach(Rs, New, Spec, NewKs, Seen, Ks)
    ;   ( memberchk(K, NewKs) -> Src = New ; Src = Spec ),
        findall(K2, ( member(H-B, Src), key(H, K), member(G, B), key(G, K2) ), Ns),
        append(Rs, Ns, Rs1), reach(Rs1, New, Spec, NewKs, [K|Seen], Ks) ).

% ---------------------------------------------------------------- lemmas
% Both sides become predicates over their shared variables and are deforested on the same
% induction variable; the lemma is proved when the two derived programs are the same up to
% the predicate name (unfold/fold preserves the least model, so both sides denote one relation).
prove_lemma(Spec, lemma(N, L0, R0), Result) :-
    copy_term(L0-R0, L-R),
    term_variables(L, LV), term_variables(R, RV), vint(LV, RV, Iface),
    atom_concat(N, '_lhs', LN), atom_concat(N, '_rhs', RN),
    LH =.. [LN|Iface], RH =.. [RN|Iface],
    (   nth1(Case, Iface, _),
        deforest_on(Spec, LH-L, Case, [], LP, _),
        deforest_on(Spec, RH-R, Case, [], RP, _),
        maplist(rename_head(RN, LN), RP, RP1),
        same_clauses(LP, RP1)
    ->  nth1(Case, Iface, IV), copy_term(LP-IV, LPc-_), Result = proved(induction_on(Case), LPc)
    ;   Result = not_proved
    ).

rename_head(From, To, H-B, H1-B1) :- ren(From, To, H, H1), maplist(ren(From, To), B, B1).
ren(From, To, G, G1) :- G =.. [F|As], ( F == From -> G1 =.. [To|As] ; G1 = G ).

% same clauses up to clause order, body order and variable renaming
same_clauses(A, B) :- length(A, N), length(B, N), same_(A, B).
same_([], []).
same_([C|Cs], Bs) :- select(D, Bs, Rest), variant_clause(C, D), !, same_(Cs, Rest).
variant_clause(H1-B1, H2-B2) :- length(B1, N), length(B2, N), permutation(B1, P), (H1-P) =@= (H2-B2), !.

% ---------------------------------------------------------------- totality
% Mode: list of in(list), in(any), out. The result has an answer for every ground input whose
% in(list) arguments are lists.
total(P, K, TM) :- total_(P, K, TM, []).
total_(P, K, TM, Stack) :-
    clauses_of(P, K, Cs), Cs \== [],
    covers(Cs, TM, CasePos),
    forall(member(C, Cs), clause_total(P, K, TM, CasePos, [K|Stack], C)).

covers([H-_], TM, none) :- other_inputs_vars(H, TM, none), !.
covers(Cs, TM, I) :-
    nth1(I, TM, in(list)),
    forall(member(H-_, Cs), ( arg(I, H, X), ( X == [] ; nonvar(X), X = [E|T], var(E), var(T) ) )),
    once(( member(H1-_, Cs), arg(I, H1, X1), X1 == [] )),
    once(( member(H2-_, Cs), arg(I, H2, X2), nonvar(X2), X2 = [_|_] )),
    forall(member(H-_, Cs), other_inputs_vars(H, TM, I)), !.

other_inputs_vars(H, TM, I) :-
    findall(J, ( nth1(J, TM, in(_)), J \== I ), Js),
    maplist({H}/[J, A]>>arg(J, H, A), Js, As), maplist(var, As), sort(As, S), length(S, N), length(As, N),
    ( I == none -> true ; arg(I, H, C), term_variables(C, CV), \+ ( member(A, As), member(V, CV), A == V ) ).

clause_total(P, K, TM, CasePos, Stack, H-B) :-
    findall(J, nth1(J, TM, in(_)), InJs), maplist({H}/[J, A]>>arg(J, H, A), InJs, InAs),
    term_variables(InAs, Bound0),
    findall(J, nth1(J, TM, in(list)), LJs), maplist({H}/[J, A]>>arg(J, H, A), LJs, LAs),
    include(var, LAs, LV0),
    (   CasePos \== none, arg(CasePos, H, C), nonvar(C), C = [_|Tail] -> ListV = [Tail|LV0]
    ;   Tail = none, ListV = LV0 ),
    body_total(B, P, K, TM, CasePos, Tail, Stack, Bound0, ListV, Bound),
    findall(J, nth1(J, TM, out), OutJs), maplist({H}/[J, A]>>arg(J, H, A), OutJs, OutAs),
    term_variables(OutAs, OV), forall(member(V, OV), ( member(W, Bound), W == V )).

body_total([], _, _, _, _, _, _, Bound, _, Bound).
body_total([L|Ls], P, K, TM, CasePos, Tail, Stack, Bound0, ListV, Bound) :-
    key(L, Q), L =.. [_|Args],
    maplist(arg_mode(Bound0, ListV), Args, QTM),
    % output arguments are fresh distinct variables, so the call cannot fail on them
    findall(A, ( nth1(J, QTM, out), nth1(J, Args, A) ), Outs),
    maplist(var, Outs), sort(Outs, SO), length(SO, NO), length(Outs, NO),
    (   Q == K
    ->  CasePos \== none, nth1(CasePos, Args, CA), CA == Tail,
        maplist(at_least, QTM, TM)
    ;   \+ memberchk(Q, Stack), total_(P, Q, QTM, Stack)
    ),
    term_variables(L, LVs), append(Bound0, LVs, Bound1),
    body_total(Ls, P, K, TM, CasePos, Tail, Stack, Bound1, ListV, Bound).

arg_mode(Bound, ListV, A, M) :-
    term_variables(A, Vs),
    (   forall(member(V, Vs), ( member(W, Bound), W == V ))
    ->  ( list_term(A, ListV) -> M = in(list) ; M = in(any) )
    ;   M = out ).
list_term(A, _) :- A == [], !.
list_term(A, LV) :- var(A), !, member(W, LV), W == A, !.
list_term(A, LV) :- A = [_|T], list_term(T, LV).

% the recursive call's mode is at least as strong as the clause's own
at_least(in(list), in(list)).
at_least(in(_), in(any)).
at_least(_, out).

% ---------------------------------------------------------------- functionality
% at most one answer for each ground input: heads do not overlap on the input arguments,
% every call is functional in the mode it is called in, and every output is bound
functional(P, K, M) :- functional_(P, K, M, []).
functional_(_, K, M, Seen) :- member(K-M0, Seen), M0 == M, !.
functional_(P, K, M, Seen) :-
    clauses_of(P, K, Cs), Cs \== [],
    \+ ( nth1(I, Cs, C1), nth1(J, Cs, C2), I < J, inputs_overlap(C1, C2, M) ),
    forall(member(C, Cs), clause_fun(P, M, [K-M|Seen], C)).

% (no findall here: it would copy the clause's variables)
in_args(H, M, As) :- H =.. [_|Args], mode_args(Args, M, in, As).
out_args(H, M, As) :- H =.. [_|Args], mode_args(Args, M, out, As).
mode_args([], [], _, []).
mode_args([A|As], [Md|Ms], W, Out) :-
    ( ( W == out -> Md == out ; Md \== out ) -> Out = [A|Out1] ; Out = Out1 ), mode_args(As, Ms, W, Out1).
inputs_overlap(H1-_, H2-_, M) :- in_args(H1, M, A1), in_args(H2, M, A2), \+ \+ unify_with_occurs_check(A1, A2).

clause_fun(P, M, Seen, H-B) :-
    in_args(H, M, InAs), term_variables(InAs, Bound0),
    foldl(lit_fun(P, Seen), B, Bound0, Bound),
    out_args(H, M, OutAs), term_variables(OutAs, OV),
    forall(member(V, OV), ( member(W, Bound), W == V )).
lit_fun(P, Seen, L, Bound0, Bound) :-
    key(L, Q), L =.. [_|Args],
    maplist({Bound0}/[A, Md]>>( term_variables(A, Vs), ( forall(member(V, Vs), ( member(W, Bound0), W == V )) -> Md = in ; Md = out ) ),
            Args, QM),
    functional_(P, Q, QM, Seen),
    term_variables(L, LV), append(Bound0, LV, Bound).

% ---------------------------------------------------------------- list-typed argument slots
% every answer has a list at argument I (induction on derivation height)
list_slot(P, K, I) :- list_slot_(P, K, I, []).
list_slot_(_, K, I, Seen) :- memberchk(K-I, Seen), !.
list_slot_(P, K, I, Seen) :-
    clauses_of(P, K, Cs), Cs \== [],
    forall(member(H-B, Cs), ( arg(I, H, X), slot_list(X, B, P, [K-I|Seen]) )).
slot_list(X, _, _, _) :- X == [], !.
slot_list(X, B, P, S) :- nonvar(X), X = [_|T], !, slot_list(T, B, P, S).
slot_list(X, B, P, S) :- var(X), member(G, B), key(G, Q), arg(J, G, Y), Y == X, list_slot_(P, Q, J, S), !.

% ---------------------------------------------------------------- evaluation
% top-down evaluation with a resolution-step count (and a limit, so a wrong program stops)
answers(P, G, As) :- findall(G, solve(P, [G], 0, _), As0), sort(As0, As).
steps(P, G, N, As) :- findall(G-N0, solve(P, [G], 0, N0), L), pairs_keys_values(L, As, Ns), sum_list(Ns, N).

solve(_, [], N, N).
solve(P, [G|Gs], N0, N) :-
    N0 < 200000, member(C, P), copy_term(C, H-B), unify_with_occurs_check(H, G),
    N1 is N0 + 1, append(B, Gs, Gs1), solve(P, Gs1, N1, N).

% compare two programs on every input: in(list) arguments range over all lists of length =< MaxLen
% over Alphabet, in(any) arguments over the same lists plus two non-lists
bounded_equal(P1, K1, P2, K2, Mode, inputs(Alphabet, MaxLen), Result) :-
    findall(L, ( between(0, MaxLen, Len), length(L, Len), maplist([X]>>member(X, Alphabet), L) ), Ls0),
    append(Ls0, [c, [a|c]], Any),
    K1 = N1/A, K2 = N2/A,
    findall(J, nth1(J, Mode, in(_)), InJs),
    findall(Vs, ( member(J, InJs), nth1(J, Mode, in(T)), ( T == list -> Vs = Ls0 ; Vs = Any ) ), Sets),
    aggregate_all(count, maplist(member, _, Sets), Total),
    (   maplist(member, Tuple, Sets),
        length(Args, A), place(InJs, Tuple, Args),
        G1 =.. [N1|Args], G2 =.. [N2|Args],
        answers(P1, G1, S1), answers(P2, G2, S2b), maplist(ren(N2, N1), S2b, S2), sort(S2, S2s),
        S1 \== S2s
    ->  Result = refuted(input(Tuple), first(S1), second(S2b))
    ;   Result = equal_on(Total)
    ).
place([], [], _).
place([J|Js], [V|Vs], Args) :- nth1(J, Args, V), place(Js, Vs, Args).
