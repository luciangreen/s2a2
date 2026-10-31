/*  s2a2.pl -- Spec to Algorithm 2: learn an optimisation algorithm from pairs of
    (unoptimised program, optimised program), then apply it to programs it has
    not seen, of any length and shape.

    Why a new S2A. S2A (Philosophy/s2a) and S2GN (Philosophy/s2g/normalise.pl)
    learn from strings. A program then has to be flattened to a string, which
    (1) fixes the number and length of clauses in the learned pattern, so a
    rewrite learned on two-clause programs does not fire on a three-clause
    program, and (2) cannot build a literal that is not already in the input.
    S2A2 learns on TERMS instead:

      * predicate names and variables are matched structurally, never as words
        (only plain data words would need S2GN-style symbol normalisation);
      * a program is a set of rules plus a set of facts, so the position and
        number of clauses do not matter: every rewrite is local to the clauses
        it touches, and the rest of the program is an optional segment of any
        length, including empty (S2G's empty base case, without the grammar);
      * a rewrite is one of a small set of operators (delete a clause, delete a
        literal, unfold a call, merge two calls, replace a clause by a learned
        template, extract an independent group of goals, replace a recurrence
        by its formula, replace a negated guard by its complement, invert a
        formula) together with CONDITIONS learned from the examples;
      * the learned algorithm is the ordered list of (operator, conditions)
        that is applied until nothing changes, so a chain of any length is
        handled by repeating the step.

    Learning. For each training pair, a derivation (a sequence of operator
    applications turning the unoptimised program into the optimised one, up
    to variable renaming, body order, clause order and invented predicate
    names) is found by iterative deepening. Every step gives a POSITIVE
    instance of its operator; every other instance of the same operator that
    was applicable in the same state but not taken gives a NEGATIVE instance.
    For each operator, the conditions are the smallest conjunction of features
    from a fixed feature library that holds for all positives and for no
    negative. Replacement templates are the anti-unification (Plotkin's least
    general generalisation) of the replaced clause pairs, with predicate names
    generalised as well.

    Main predicates
      learn(+Pairs, -Algorithm)          Pairs = [pair(Before, After, Targets)]
      apply_algorithm(+Algorithm, +Program, +Targets, -Optimised, -Trace)
      same_program(+P1, +P2, +Fixed)     equal up to renaming (Fixed = predicate names
                                         that may not be renamed)
    A program is prog(Facts, Rules); a rule is Head-BodyList.
*/
:- module(s2a2, [ learn/2, apply_algorithm/5, same_program/3, derive/5, derive/6,
                  program_from_clauses/2, program_to_clauses/2, op_instances/4,
                  apply_op/4, features/4, show_algorithm/1, preds_of/2,
                  train_mnn/2, mnn/1, reset_nodes/0, nodes/1, pair_derivation/2 ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(yall)).
:- use_module(library(ordsets)).
:- use_module(library(pairs)).
:- use_module(prover).

% ---------------------------------------------------------------- representation
program_from_clauses(Cs, prog(Facts, Rules)) :-
    partition([C]>>(C \= (_ :- _)), Cs, Facts0, RuleCs),
    sort(Facts0, Facts),
    maplist([(H :- B), H-L]>>conj_list(B, L), RuleCs, Rules).
program_to_clauses(prog(Fs, Rs), Cs) :-
    maplist([H-L, (H :- B)]>>list_conj(L, B), Rs, RCs), append(Fs, RCs, Cs).

conj_list((A, B), L) :- !, conj_list(A, LA), conj_list(B, LB), append(LA, LB, L).
conj_list(true, []) :- !.
conj_list(G, [G]).
list_conj([], true).
list_conj([G], G) :- !.
list_conj([G|Gs], (G, B)) :- list_conj(Gs, B).

builtin(G) :- \+ callable(G), !.
builtin(\+ _).
builtin(G) :- functor(G, F, A), memberchk(F/A, [(is)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (=:=)/2,
                                                 (=\=)/2, (=)/2, (\=)/2, neq/2, between/3]).
user_lit(G) :- \+ builtin(G).

key(G, P/N) :- functor(G, P, N).
rule_key(H-_, K) :- key(H, K).

preds_of(prog(Fs, Rs), Ps) :-
    findall(K, ( member(F, Fs), key(F, K) ; member(R, Rs), rule_key(R, K)
               ; member(_-B, Rs), member(G, B), user_or_neg(G, G1), key(G1, K) ), K0),
    sort(K0, Ps).
user_or_neg(\+ G, G) :- !.
user_or_neg(G, G) :- user_lit(G).

% rules defining P/N
defs(prog(_, Rs), K, Ds) :- include({K}/[R]>>rule_key(R, K), Rs, Ds).
calls(prog(_, Rs), K, N) :-
    aggregate_all(count, ( member(_-B, Rs), member(G, B), user_or_neg(G, G1), key(G1, K) ), N).
is_edb(prog(Fs, Rs), K) :- member(F, Fs), key(F, K), \+ ( member(R, Rs), rule_key(R, K) ), !.

% ---------------------------------------------------------------- equality up to renaming
% Clauses are equal up to variable renaming and body order; programs up to clause order
% and up to a bijective renaming of predicates that are not in Fixed (invented names).
same_program(prog(F1, R1), prog(F2, R2), Fixed) :-
    msort(F1, S1), msort(F2, S2), S1 == S2,
    length(R1, N), length(R2, N),
    preds_of(prog(F1, R1), P1), preds_of(prog(F2, R2), P2),
    subtract(P1, Fixed, Inv1), subtract(P2, Fixed, Inv2),
    length(Inv1, NI), length(Inv2, NI),
    permutation(Inv2, Inv2p), pairs_keys_values(Map, Inv1, Inv2p),
    maplist(rename_rule(Map), R1, R1m),
    match_rules(R1m, R2), !.
rename_rule(Map, H-B, H1-B1) :- rename_lit(Map, H, H1), maplist(rename_lit(Map), B, B1).
rename_lit(Map, \+ G, \+ G1) :- !, rename_lit(Map, G, G1).
rename_lit(Map, G, G1) :- callable(G), key(G, K), memberchk(K-(P2/_), Map), !, G =.. [_|As], G1 =.. [P2|As].
rename_lit(_, G, G).
match_rules([], []).
match_rules([R|Rs], R2s) :- select(R2, R2s, Rest), rule_variant(R, R2), !, match_rules(Rs, Rest).
rule_variant(H1-B1, H2-B2) :-
    length(B1, N), length(B2, N),
    \+ \+ ( copy_term(H1-B1, H-B), permutation(B, P), (H-P) =@= (H2-B2) ).

% ---------------------------------------------------------------- operators
% op_instances(+Op, +Program, +Targets, -Instances): every place Op can apply
op_instances(del_clause, prog(_, Rs), _, Is) :-
    length(Rs, N), numlist(1, N, Is0), maplist([I, del_clause(I)]>>true, Is0, Is).
op_instances(del_lit, prog(_, Rs), _, Is) :-
    findall(del_lit(I, J), ( nth1(I, Rs, _-B), length(B, NB), NB > 1, between(1, NB, J) ), Is).
op_instances(unfold, P, Targets, Is) :-
    P = prog(_, Rs),
    findall(unfold(I, J), ( nth1(I, Rs, H-B), nth1(J, B, G), user_lit(G), key(G, K),
                            \+ memberchk(K, Targets), key(H, KH), K \== KH,
                            defs(P, K, [D]), D = DH-_, \+ \+ DH = G, \+ recursive(P, K) ), Is).
op_instances(merge, prog(_, Rs), _, Is) :-
    findall(merge(I, J, K), ( nth1(I, Rs, _-B), nth1(J, B, G1), user_lit(G1), nth1(K, B, G2), K > J,
                              key(G1, Key), key(G2, Key), arg(1, G1, A1), arg(1, G2, A2), A1 == A2,
                              G1 \== G2, \+ \+ G1 = G2 ), Is).
op_instances(extract, prog(_, Rs), _, Is) :-
    % the group is stored as body positions: findall copies terms, so literals would no
    % longer be identical (==) to the rule's own literals when the step is applied
    findall(extract(I, Ps), ( nth1(I, Rs, H-B), length(B, NB), NB >= 3, components(H, B, Cs),
                              length(Cs, NC), NC >= 2, member(G, Cs), length(G, NG), NG >= 2,
                              positions(G, B, Ps) ), Is).
op_instances(closed_form, P, _, Is) :-
    findall(closed_form(K), ( P = prog(_, Rs), member(H-_, Rs), key(H, K), K = _/2, recursive(P, K) ), I0),
    sort(I0, Is).
op_instances(complement_guard, P, _, Is) :-
    P = prog(_, Rs),
    findall(complement_guard(I, J), ( nth1(I, Rs, _-B), nth1(J, B, \+ G), key(G, K), defs(P, K, [_-DB]),
                                      DB = [_, C], comparison(C) ), Is).
op_instances(invert_formula, P, _, Is) :-
    P = prog(_, Rs),
    findall(invert_formula(I), ( nth1(I, Rs, H-[G]), user_lit(G), key(G, K), defs(P, K, [_-DB]),
                                 DB = [_, (_ is _)], H =.. [_, V, X], G =.. [_, X1, V1], X == X1, V == V1 ), Is).
op_instances(replace(T), prog(_, Rs), _, Is) :-
    findall(replace(T, I), ( nth1(I, Rs, R), template_matches(T, R, _) ), Is).

comparison(C) :- functor(C, F, 2), memberchk(F, [<, >, =<, >=, =:=, =\=]).

recursive(P, K) :- reach_pred(P, K, K, [K]).
reach_pred(P, From, To, Seen) :-
    defs(P, From, Ds), member(_-B, Ds), member(G, B), user_or_neg(G, G1), key(G1, K1),
    ( K1 == To -> true ; \+ memberchk(K1, Seen), reach_pred(P, K1, To, [K1|Seen]) ), !.

% connected groups of body literals that share variables other than the head's
components(H, B, Comps) :-
    term_variables(H, HV),
    include(user_lit, B, Ls),
    length(Ls, N), numlist(1, N, Is),
    group(Is, Ls, HV, Comps0),
    maplist({Ls}/[Ix, G]>>maplist({Ls}/[I, L]>>nth1(I, Ls, L), Ix, G), Comps0, Comps).
group([], _, _, []).
group([I|Is], Ls, HV, [C|Cs]) :-
    closure_group([I], Is, Ls, HV, C, Rest), group(Rest, Ls, HV, Cs).
closure_group(Acc, Is, Ls, HV, C, Rest) :-
    (   select(J, Is, Is1), member(I, Acc), nth1(I, Ls, LI), nth1(J, Ls, LJ),
        term_variables(LI, VI), term_variables(LJ, VJ), shared_nonhead(VI, VJ, HV)
    ->  closure_group([J|Acc], Is1, Ls, HV, C, Rest)
    ;   msort(Acc, C), Rest = Is
    ).
shared_nonhead(VI, VJ, HV) :- member(V, VI), member(W, VJ), V == W, \+ ( member(X, HV), X == V ), !.

% apply_op(+Instance, +Program, -Program1, +Targets)
apply_op(del_clause(I), prog(F, Rs), prog(F, Rs1), _) :- nth1(I, Rs, _, Rs1).
apply_op(del_lit(I, J), prog(F, Rs), prog(F, Rs1), _) :-
    nth1(I, Rs, H-B, Rest), nth1(J, B, _, B1), nth1(I, Rs1, H-B1, Rest).
apply_op(unfold(I, J), P, prog(F, Rs1), _) :-
    P = prog(F, Rs), nth1(I, Rs, H0-B0, Rest), copy_term(H0-B0, H-B),
    nth1(J, B, G, BRest), key(G, K), defs(P, K, [D]), copy_term(D, G-DB),
    J0 is J - 1, length(Pre, J0), append(Pre, Post, BRest),
    append([Pre, DB, Post], B1), nth1(I, Rs1, H-B1, Rest).
apply_op(merge(I, J, K), prog(F, Rs), prog(F, Rs1), _) :-
    nth1(I, Rs, H0-B0, Rest), copy_term(H0-B0, H-B),
    nth1(J, B, G1), nth1(K, B, G2), G1 = G2, nth1(K, B, _, B1), nth1(I, Rs1, H-B1, Rest).
apply_op(extract(I, Ps), P, prog(F, Rs2), _) :-
    P = prog(F, Rs), nth1(I, Rs, R0, Rest), copy_term(R0, H-B),
    maplist({B}/[Ix, L]>>nth1(Ix, B, L), Ps, G),
    fresh_pred(P, inv, Name),
    partition({G}/[L]>>(member(X, G), X == L), B, _, Others),
    term_variables(G, GV), term_variables(H-Others, OV),
    include({OV}/[V]>>(member(X, OV), X == V), GV, Shared),
    New =.. [Name|Shared],
    first_index(B, G, Pos), length(Pre, Pos), append(Pre, _, B),
    exclude({G}/[L]>>(member(X, G), X == L), Pre, Pre1),
    exclude({G}/[L]>>(member(X, G), X == L), B, Keep), append(Pre1, Post, Keep),
    append(Pre1, [New|Post], B1),
    nth1(I, Rs1, H-B1, Rest), append(Rs1, [New-G], Rs2).
apply_op(closed_form(K), P, prog(F1, Rs1), _) :-
    P = prog(F, Rs), K = Name/2, exclude({K}/[Fa]>>key(Fa, K), F, F1),
    recurrence_domain(P, K, Dom),
    table_of(P, K, Table), Table = [_, _|_],
    affine_fit(Table, A, B),
    exclude({K}/[R]>>rule_key(R, K), Rs, Rest), Head =.. [Name, I, V], D =.. [Dom, I],
    formula(A, B, I, Expr),
    append(Rest, [Head-[D, V is Expr]], Rs1).
apply_op(complement_guard(I, J), P, prog(F, Rs1), _) :-
    P = prog(F, Rs), nth1(I, Rs, H0-B0, Rest), copy_term(H0-B0, H-B),
    nth1(J, B, \+ G), key(G, K), defs(P, K, [D]), copy_term(D, G-[_, C]),
    negate(C, NC), replace_nth1(J, B, NC, B1), nth1(I, Rs1, H-B1, Rest).
apply_op(invert_formula(I), P, prog(F, Rs1), _) :-
    P = prog(F, Rs), nth1(I, Rs, H0-[G0], Rest), copy_term(H0-G0, H-G),
    key(G, K), defs(P, K, [D]), copy_term(D, G-[DomG, (V is Expr)]),
    G =.. [_, X, V], affine_of(Expr, X, A, Bc), Bc =\= 0,
    DomG =.. [Dom, X],
    findall(Xv, member_fact(P, Dom, Xv), Xs), Xs \== [],
    min_list(Xs, XMin), max_list(Xs, XMax),
    L0 is A + Bc*XMin, H1 is A + Bc*XMax, Lo is min(L0, H1), Hi is max(L0, H1),
    NewB = [between(Lo, Hi, V), (V - A) mod Bc =:= 0, X is (V - A) // Bc, DomG],
    nth1(I, Rs1, H-NewB, Rest).
apply_op(replace(T, I), prog(F, Rs), prog(F, Rs1), _) :-
    nth1(I, Rs, R, Rest), template_matches(T, R, New), nth1(I, Rs1, New, Rest).

positions(G, B, Ps) :- maplist({B}/[L, Ix]>>(nth1(Ix, B, X), X == L), G, Ps).
first_index(B, G, Pos) :- nth0(Pos, B, L), member(X, G), X == L, !.
replace_nth1(1, [_|T], X, [X|T]) :- !.
replace_nth1(N, [H|T], X, [H|T1]) :- N1 is N - 1, replace_nth1(N1, T, X, T1).
member_fact(prog(F, _), Dom, X) :- member(Fa, F), Fa =.. [Dom, X].

negate(A > B, A =< B).  negate(A >= B, A < B).  negate(A < B, A >= B).
negate(A =< B, A > B).  negate(A =:= B, A =\= B). negate(A =\= B, A =:= B).

fresh_pred(P, Base, Name) :-
    preds_of(P, Ps), between(1, inf, N), format(atom(Name), '~w_~w', [Base, N]),
    \+ memberchk(Name/_, Ps), !.

% -------- closed forms: the recurrence's table, computed by bottom-up evaluation
recurrence_domain(P, K, Dom) :-
    defs(P, K, Ds), member(_-B, Ds), member(G, B), user_lit(G), key(G, Dom/1), is_edb(P, Dom/1), !.
% bounded: a candidate program in the search may have lost the guard that stops its
% recursion (e.g. I > 0 deleted), and its least model is then infinite
table_of(P, Name/2, Table) :-
    program_to_clauses(P, Cs),
    limited(2, prover:least_model(Cs, [], M)),
    findall(X-Y, ( member(At, M), At =.. [Name, X, Y] ), T0), sort(T0, Table).
affine_fit([X1-Y1, X2-Y2|Rest], A, B) :-
    X2 =\= X1, B is (Y2 - Y1) / (X2 - X1), A is Y1 - B*X1,
    integer_or_rat(A), integer_or_rat(B),
    forall(member(X-Y, Rest), Y =:= A + B*X).
integer_or_rat(V) :- number(V).
formula(A, B, I, Expr) :- AI is A, BI is B, ( AI =:= 0 -> Expr = BI*I ; Expr = AI + BI*I ).
affine_of(A + B*X0, X, A, B) :- X0 == X, !.
affine_of(B*X0, X, 0, B) :- X0 == X.

% -------- templates: anti-unification of clause pairs, predicate names included
% A template is tmpl(Old, New) over the "lifted" form of a rule, in which every literal
% p(A1..An) becomes l(P, [A1..An]) so that P can be a variable.
lift(H-B, lr(LH, LB)) :- lift_lit(H, LH), maplist(lift_lit, B, LB).
lift_lit(\+ G, neg(L)) :- !, lift_lit(G, L).
lift_lit(G, l(P, As)) :- callable(G), \+ builtin(G), !, G =.. [P|As].
lift_lit(G, b(G)).
unlift(lr(LH, LB), H-B) :- unlift_lit(LH, H), maplist(unlift_lit, LB, B).
unlift_lit(neg(L), \+ G) :- !, unlift_lit(L, G).
unlift_lit(l(P, As), G) :- !, G =.. [P|As].
unlift_lit(b(G), G).

% lgg of two terms with a shared substitution table (Plotkin)
lgg(A, B, G, S0, S) :-
    (   A == B -> G = A, S = S0
    ;   compound(A), compound(B), A =.. [F|As], B =.. [F|Bs], same_length(As, Bs)
    ->  foldl(lgg3, As, Bs, Gs, S0, S), G =.. [F|Gs]
    ;   is_list(A), is_list(B), same_length(A, B)
    ->  foldl(lgg3, A, B, G, S0, S)
    ;   member((A1-B1)-V, S0), A1 == A, B1 == B -> G = V, S = S0
    ;   S = [(A-B)-G|S0]
    ).
lgg3(A, B, G, S0, S) :- lgg(A, B, G, S0, S).

template_from_pairs([Old-New|Rest], tmpl(TO, TN)) :-
    lift(Old, LO), lift(New, LN),
    foldl([O2-N2, LO0-LN0, LO1-LN1]>>(
              lift(O2, LO2), lift(N2, LN2),
              lgg(LO0-LN0, LO2-LN2, LO1-LN1, [], _)),
          Rest, LO-LN, TO-TN).

template_matches(tmpl(TO, TN), R, New) :-
    copy_term(TO-TN, O-N), lift(R, LR), LR = O, ground_ok(N), unlift(N, New).
ground_ok(_).

% ---------------------------------------------------------------- features (conditions)
% features(+Instance, +Program, +Targets, -Features): the library of facts that may
% condition an operator. Every feature is decidable from the program alone.
features(del_clause(I), P, Targets, Fs) :-
    P = prog(_, Rs), nth1(I, Rs, R), R = H-B, key(H, K),
    findall(F, (
        ( nth1(J, Rs, R2), J \== I, rule_variant(R, R2) -> F = duplicate_of_another_clause
        ; member(R2, Rs), R2 \== R, subsumes_rule(R2, R), \+ rule_variant(R, R2) -> F = subsumed_by_other_clause
        ; member(G, B), G == H -> F = calls_itself_unchanged
        ; calls(P, K, 0), \+ memberchk(K, Targets) -> F = defines_unused_non_target
        ; B = [_, _], other_rules_imply(P, I) -> F = implied_by_the_other_clauses
        ; fail )), Fs0),
    sort(Fs0, Fs).
features(del_lit(I, J), prog(_, Rs), _, Fs) :-
    nth1(I, Rs, _-B), nth1(J, B, G),
    findall(F, ( ( nth1(J2, B, G2), J2 \== J, G2 == G -> F = repeats_another_literal ; fail ) ), Fs0), sort(Fs0, Fs).
features(unfold(I, J), P, Targets, Fs) :-
    P = prog(_, Rs), nth1(I, Rs, _-B), nth1(J, B, G), key(G, K), defs(P, K, [_-DB]),
    findall(F, ( calls(P, K, 1), F = callee_called_once
               ; length(DB, 1), F = callee_is_a_wrapper
               ; \+ memberchk(K, Targets), F = callee_not_a_target
               ; nth1(I, Rs, H-_), key(H, KH), memberchk(KH, Targets), F = caller_is_a_target ), Fs0), sort(Fs0, Fs).
features(merge(I, J, _), P, _, Fs) :-
    P = prog(_, Rs), nth1(I, Rs, _-B), nth1(J, B, G), key(G, K),
    findall(F, ( functional(P, K) -> F = functional_in_first_argument ; F = not_functional ), Fs0), sort(Fs0, Fs).
features(extract(_, G), _, _, Fs) :- length(G, N), ( N >= 2 -> Fs = [independent_group] ; Fs = [] ).
features(closed_form(K), P, _, Fs) :-
    ( recurrence_domain(P, K, _), table_of(P, K, T), T = [_, _|_], affine_fit(T, _, _) -> Fs = [affine_recurrence] ; Fs = [] ).
features(complement_guard(_, _), _, _, [negated_single_guard]).
features(invert_formula(_), _, _, [affine_formula_call]).
features(replace(_, _), _, _, [template_matches]).

subsumes_rule(H1-B1, H2-B2) :-
    \+ \+ ( copy_term(H1-B1, H-B), numbervars(H2-B2, 0, _), H = H2, subset_unify(B, B2) ).
subset_unify([], _).
subset_unify([G|Gs], B) :- member(G, B), subset_unify(Gs, B).

% a clause whose body is a two-step chain of a recursive predicate's base relation is
% implied when the program also has the base clause and the recursive clause
other_rules_imply(P, I) :-
    P = prog(F, Rs), nth1(I, Rs, _, Rest),
    program_to_clauses(prog(F, Rs), Cs1), program_to_clauses(prog(F, Rest), Cs2),
    findall(K, ( member(H-_, Rs), key(H, K) ), Ks0), sort(Ks0, Ks),
    findall(E, ( member(Fa, F), key(Fa, E) ), Es0), sort(Es0, Es),
    Es \== [],
    \+ \+ limited(30, prover:equivalent(Cs1, Cs2, Ks, edb(Es, [a, b, c]), proved(_))).

% functional: in the program's own facts, the first argument determines the rest
% (for a derived predicate, in the least model of the program on its own facts)
functional(P, Name/N) :-
    N >= 2, P = prog(F, Rs),
    (   Rs == [] -> M = F
    ;   program_to_clauses(P, Cs), limited(2, prover:least_model(Cs, [], M))
    ),
    findall(X-Rest, ( member(Fa, M), Fa =.. [Name, X|Rest] ), XR), XR \== [],
    forall(( member(X-R1, XR), member(X-R2, XR) ), R1 == R2).

% ---------------------------------------------------------------- derivations
ops([del_clause, del_lit, unfold, merge, extract, closed_form, complement_guard, invert_formula]).

% derive(+Before, +After, +Targets, +MaxDepth, -Steps): Steps = [step(Instance, State)]
derive(Before, After, Targets, Max, Steps) :-
    derive(Before, After, Targets, Max, true, Steps).
% UseTemplates = false: only the fixed operators (used to judge whether a step that was
% not taken could still have led to the target; a template made from that state could
% reach anything and would hide every counter-example)
derive(Before, After, Targets, Max, UseTemplates, Steps) :-
    preds_of(Before, Fixed0), preds_of(After, FA), intersection(Fixed0, FA, Fixed),
    ( UseTemplates == true -> replacement_templates(Before, After, Ts) ; Ts = [] ),
    between(0, Max, D),
    dfs(Before, After, Targets, Fixed, Ts, D, Steps), !.

dfs(S, After, _, Fixed, _, _, []) :- same_program(S, After, Fixed), !.
dfs(S, After, Targets, Fixed, Ts, D, [step(I, S)|Steps]) :-
    D > 0, D1 is D - 1,
    ordered_candidates(S, Targets, Ts, Cands),
    member(I, Cands),
    count_node,
    apply_op(I, S, S1, Targets),
    dfs(S1, After, Targets, Fixed, Ts, D1, Steps).

% ---------------------------------------------------------------- the MNN speed-up
% A small neural network (one logistic unit over binary features: the operator, and each
% cheap feature of the candidate) scores candidate steps. It is trained on the steps of
% earlier derivations (chosen = 1, other candidates in the same state = 0) and only
% ORDERS the search: every candidate is still tried, so results are unchanged and only
% the number of nodes expanded falls. mnn_weight/2 holds the learned weights as facts.
:- dynamic mnn_weight/2, mnn_on/0.
count_node :- ( nb_current(s2a2_nodes, N) -> true ; N = 0 ), N1 is N + 1, nb_setval(s2a2_nodes, N1).
reset_nodes :- nb_setval(s2a2_nodes, 0).
nodes(N) :- ( nb_current(s2a2_nodes, N) -> true ; N = 0 ).

ordered_candidates(S, Targets, Ts, Cands) :-
    findall(I, candidate(S, Targets, Ts, I), C0),
    (   mnn_on
    ->  maplist({S, Targets}/[I, Sc-I]>>(mnn_score(I, S, Targets, Sc0), Sc is -Sc0), C0, Sc), keysort(Sc, Sorted),
        pairs_values(Sorted, Cands)
    ;   Cands = C0
    ).

mnn_inputs(I, S, Targets, [op(Op)|Fs]) :-
    op_name(I, Op), ( quiet(cheap_features(I, S, Targets, Fs0)) -> true ; Fs0 = [] ),
    maplist({Op}/[F, f(Op, F)]>>true, Fs0, Fs).
cheap_features(del_clause(I), P, Targets, Fs) :- !,
    P = prog(_, Rs), nth1(I, Rs, R), R = H-B, key(H, K),
    findall(F, ( nth1(J, Rs, R2), J \== I, rule_variant(R, R2), F = duplicate_of_another_clause
               ; member(R2, Rs), R2 \== R, subsumes_rule(R2, R), \+ rule_variant(R, R2), F = subsumed_by_other_clause
               ; member(G, B), G == H, F = calls_itself_unchanged
               ; calls(P, K, 0), \+ memberchk(K, Targets), F = defines_unused_non_target ), Fs0), sort(Fs0, Fs).
cheap_features(closed_form(_), _, _, []) :- !.
cheap_features(I, P, T, Fs) :- features(I, P, T, Fs).

mnn_score(I, S, T, Score) :-
    mnn_inputs(I, S, T, Xs),
    ( mnn_weight(bias, B) -> true ; B = 0.0 ),
    foldl([X, A0, A]>>( mnn_weight(X, W) -> A is A0 + W ; A = A0 ), Xs, B, Z),
    Score is 1 / (1 + exp(-Z)).

% train_mnn(+Derivations, +Pairs): logistic regression by gradient descent, 200 epochs
train_mnn(Derivs, Pairs) :-
    retractall(mnn_weight(_, _)),
    findall(Xs-Y, ( nth1(K, Derivs, D), nth1(K, Pairs, pair(_, _, T)), member(step(I, S), D),
                    findall(I2, candidate(S, T, [], I2), Is0), ( memberchk(I, Is0) -> Is = Is0 ; Is = [I|Is0] ),
                    member(I2, Is), mnn_inputs(I2, S, T, Xs), ( I2 =@= I -> Y = 1 ; Y = 0 ) ), Data),
    forall(between(1, 200, _), forall(member(Xs-Y, Data), sgd(Xs, Y, 0.5))).
sgd(Xs, Y, Rate) :-
    ( mnn_weight(bias, B) -> true ; B = 0.0 ),
    foldl([X, A0, A]>>( mnn_weight(X, W) -> A is A0 + W ; A = A0 ), Xs, B, Z),
    P is 1 / (1 + exp(-Z)), G is Y - P,
    forall(member(X, [bias|Xs]), ( ( retract(mnn_weight(X, W0)) -> true ; W0 = 0.0 ), W1 is W0 + Rate*G, assertz(mnn_weight(X, W1)) )).
mnn(On) :- ( On == true -> ( mnn_on -> true ; assertz(mnn_on) ) ; retractall(mnn_on) ).

candidate(S, Targets, _Ts, I) :-
    ops(Ops), member(Op, Ops), op_instances(Op, S, Targets, Is), member(I, Is).
candidate(S, Targets, Ts, I) :-
    member(T, Ts), op_instances(replace(T), S, Targets, Is), member(I, Is).

% a clause of Before with no counterpart in After, paired with an After clause for the
% same head predicate that has no counterpart in Before: a candidate replacement
replacement_templates(prog(_, RB), prog(_, RA), Ts) :-
    findall(tmpl(TO, TN),
            ( member(O, RB), \+ ( member(X, RA), rule_variant(O, X) ),
              member(N, RA), \+ ( member(X, RB), rule_variant(N, X) ),
              rule_key(O, K), rule_key(N, K),
              O = _-OB, N = _-NB, same_length(OB, NB),     % a rewrite of the clause, not a swap
              lift(O, TO), lift(N, TN) ), Ts).

% ---------------------------------------------------------------- learning
learn(Pairs, algorithm(Rules)) :-
    maplist(pair_derivation, Pairs, Derivs),
    % replacement templates are generalised across all pairs that used them
    findall(O-N, ( member(D, Derivs), member(step(replace(tmpl(LO, LN), _), _), D),
                   unlift(LO, O), unlift(LN, N) ), RepPairs),
    (   RepPairs == [] -> Templates = []
    ;   template_from_pairs(RepPairs, T), Templates = [T]
    ),
    findall(Op, ( member(D, Derivs), member(step(I, _), D), op_name(I, Op) ), Ops0),
    remove_dups_keep_order(Ops0, Ops),
    findall(Rs,
            ( member(Op, Ops), Op \== replace,
              positives(Op, Derivs, Pairs, Pos), negatives(Op, Derivs, Pairs, Neg),
              cover(Pos, Neg, CondSets),
              findall(rule(Op, C), member(C, CondSets), Rs) ), RuleLists),
    append(RuleLists, Rules0),
    findall(rule(replace(T), [template_matches]), member(T, Templates), RRules),
    append(Rules0, RRules, Rules1),
    maplist(refine_rule(Derivs, Pairs), Rules1, Rules).

% ---------------------------------------------------------------- prover-guided refinement
% Conditions learned from two examples can be too weak: if every training merge happened
% to be safe, nothing in the data says WHY. So each learned rule is replayed on its training
% steps and the prover checks each rewrite for every input built from the program's input
% predicates (not only the facts given). When the prover finds a counter-example input,
% the instance's features are recomputed with that input as the facts; the features that
% disappear are exactly what made the rewrite safe, and they are added to the conditions.
refine_rule(Derivs, Pairs, rule(Op, Conds), rule(Op, Conds1)) :-
    findall(Missing,
            ( Op \= replace(_),
              nth1(K, Derivs, D), nth1(K, Pairs, pair(_, _, T)), member(step(I, S), D), op_name(I, Op),
              apply_op(I, S, S1, T),
              counterexample(S, S1, T, CE),
              S = prog(_, Rs), features(I, S, T, Fs), features(I, prog(CE, Rs), T, FsCE),
              subtract(Fs, FsCE, Missing), Missing \== [] ), Ms),
    append([Conds|Ms], All), sort(All, Conds1).

counterexample(S, S1, Targets, Facts) :-
    S = prog(F, _),
    findall(N/A, ( member(Fa, F), functor(Fa, N, A) ), E0), sort(E0, Edb), Edb \== [],
    findall(X, ( member(Fa, F), Fa =.. [_|As], member(X, As) ), X0), sort(X0, Xs),
    ( length(Xs, NX), NX > 3 -> length(Consts, 3), append(Consts, _, Xs) ; Consts = Xs ),
    program_to_clauses(S, C0), program_to_clauses(S1, C1),
    include([C]>>(C = (_ :- _)), C0, R0), include([C]>>(C = (_ :- _)), C1, R1),
    limited(60, prover:equivalent(R0, R1, Targets, edb(Edb, Consts), Res)),
    Res = refuted(input(Facts), _, _).

pair_derivation(pair(B, A, T), D) :-
    (   derive(B, A, T, 8, D) -> true
    ;   throw(no_derivation(B, A))
    ).
op_name(I, Op) :- functor(I, F, _), ( F == replace -> Op = replace ; Op = F ).
remove_dups_keep_order([], []).
remove_dups_keep_order([X|Xs], [X|Ys]) :- exclude(==(X), Xs, Xs1), remove_dups_keep_order(Xs1, Ys).

positives(Op, Derivs, Pairs, Pos) :-
    findall(Fs, ( nth1(K, Derivs, D), nth1(K, Pairs, pair(_, _, T)), member(step(I, S), D),
                  op_name(I, Op), features(I, S, T, Fs) ), Pos).
negatives(Op, Derivs, Pairs, Neg) :-
    findall(Fs, ( nth1(K, Derivs, D), nth1(K, Pairs, pair(_, After, T)), member(step(I, S), D),
                  op_instances(Op, S, T, Is), member(I2, Is), I2 \= I,
                  \+ leads_towards(I2, S, After, T),
                  features(I2, S, T, Fs) ), Neg0),
    sort(Neg0, Neg).
% an instance that also appears later in the same derivation, or that leaves a state
% from which the target is still reachable in one step, is not a counter-example
leads_towards(I, S, After, T) :-
    apply_op(I, S, S1, T), preds_of(S, P0), preds_of(After, PA), intersection(P0, PA, Fixed),
    ( same_program(S1, After, Fixed) -> true
    ; derive(S1, After, T, 4, false, _) ).

% sequential covering: while some positive is uncovered, take the smallest conjunction of
% one uncovered positive's features that no negative has, preferring the one that covers
% the most positives; so one operator can be learned under several alternative conditions
% (a disjunction), as when a clause is deleted for being a duplicate OR for being subsumed
cover([], _, []) :- !.
cover(Pos, Neg, [C|Cs]) :-
    Pos = [P1|_],
    findall(N-Cand, ( conj_of(P1, Neg, Cand),
                      include({Cand}/[F]>>subset(Cand, F), Pos, Cov), length(Cov, N0), N is -N0 ), Cands),
    (   Cands == []
    ->  C = P1, exclude(==(P1), Pos, Rest)
    ;   keysort(Cands, [_-C|_]), exclude({C}/[F]>>subset(C, F), Pos, Rest)
    ),
    cover(Rest, Neg, Cs).
% conjunctions of a positive's features, smallest first, that no negative satisfies
conj_of(Fs, Neg, Conds) :-
    length(Fs, N), between(0, N, K), length(Conds, K), subseq(Fs, Conds),
    \+ ( member(NF, Neg), subset(Conds, NF) ).

% the smallest set of features true in every positive and missing from every negative
choose_conditions(Pos, Neg, Conds) :-
    intersection_all(Pos, Common),
    length(Common, N), between(0, N, K), length(Conds, K),
    subseq(Common, Conds),
    \+ ( member(NF, Neg), subset(Conds, NF) ), !.
choose_conditions(Pos, _, Common) :- intersection_all(Pos, Common).
intersection_all([F|Fs], C) :- foldl([X, A0, A]>>intersection(A0, X, A), Fs, F, C).
subseq([], []).
subseq([X|Xs], [X|Ys]) :- subseq(Xs, Ys).
subseq([_|Xs], Ys) :- subseq(Xs, Ys).

show_algorithm(algorithm(Rules)) :-
    forall(nth1(I, Rules, rule(Op, Conds)),
           ( Op = replace(tmpl(O, N)) -> copy_term(O-N, O1-N1), numbervars(O1-N1, 0, _),
                                           show_lr(O1, OS), show_lr(N1, NS),
                                           format("~w. replace ~w by ~w~n", [I, OS, NS])
           ; format("~w. ~w when ~w~n", [I, Op, Conds]) )).

% ---------------------------------------------------------------- applying
apply_algorithm(algorithm(Rules), P0, Targets, P, Trace) :-
    apply_loop(Rules, P0, Targets, 0, P, Trace).
apply_loop(Rules, P0, Targets, N, P, [step(I)|Trace]) :-
    N < 50,
    member(rule(Op, Conds), Rules),
    op_instances(Op, P0, Targets, Is), member(I, Is),
    features(I, P0, Targets, Fs), subset(Conds, Fs),
    apply_op(I, P0, P1, Targets), !,
    N1 is N + 1, apply_loop(Rules, P1, Targets, N1, P, Trace).
apply_loop(_, P, _, _, P, []).

% print a lifted clause; a predicate-name variable prints as a capital letter
show_lr(lr(H, B), S) :- show_l(H, HS), maplist(show_l, B, BS), atomic_list_concat(BS, ', ', BJ),
    format(atom(S), '~w :- ~w', [HS, BJ]).
show_l(l(P, As), S) :- !, format(atom(S), '~p(~p)', [P, As]).
show_l(neg(L), S) :- !, show_l(L, S0), atom_concat('\\+ ', S0, S).
show_l(b(G), S) :- format(atom(S), '~p', [G]).

% ---------------------------------------------------------------- time limits
% limited(+Secs, :Goal): fail if Goal takes longer than Secs or raises an error. Only
% THIS limit's own exception is caught: an enclosing time limit (for example the one
% around a whole derivation) is passed on, so it can never be swallowed here.
limited(T, G) :-
    gensym(s2a2_limit_, C),
    catch(call_with_time_limit(T, G, C), E, limit_error(E, C)).
limit_error(time_limit_exceeded(C), C) :- !, fail.
limit_error(E, _) :- outer_limit(E), !, throw(E).
limit_error(_, _) :- fail.
% quiet(:Goal): Goal, failing on an error, but never hiding a time limit
quiet(G) :- catch(G, E, ( outer_limit(E) -> throw(E) ; fail )).
outer_limit(time_limit_exceeded).
outer_limit(time_limit_exceeded(_)).
