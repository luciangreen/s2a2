:- encoding(utf8).
/*  types_tests.pl -- tests for proof/types (types.pl).
    swipl -q -g main -t 'halt(1)' types_tests.pl      (exits 1 if any test fails)

    Every inclusion the proof rules give is also checked semantically on all inputs over a small
    domain, so a wrong proof rule would show up as a refuted inclusion. */
:- use_module(prover).
:- use_module(types).
:- use_module(s2a2, [program_from_clauses/2]).

:- dynamic failed/1.

prog(reach, [(reach(X,Y) :- edge(X,Y)), (reach(X1,Y1) :- edge(X1,Z1), reach(Z1,Y1))]).
prog(family, [(person(A) :- parent(A,_)), (person(B) :- parent(_,B)),
              (sib(S,T) :- person(S), parent(P,S), parent(P,T), S \= T),
              (adult(X) :- person(X), age(X,G), G >= 18)]).
prog(numbers, [(pos(N) :- num(N), N > 0), (val(I,V) :- pos(I), V is 1+2*I)]).
prog(physics, [(force(O,F) :- mass(O,M), acc(O,A), F is M*A)]).
prog(physics_bad, [(force(O,F) :- mass(O,M), acc(O,A), F is M+A)]).
% the same clause shapes as family, with other names (for the memo)
prog(family2, [(member_(A) :- belongs(A,_)), (member_(B) :- belongs(_,B)),
               (pair(S,T) :- member_(S), belongs(P,S), belongs(P,T), S \= T)]).

p(Name, P) :- prog(Name, Cs), program_from_clauses(Cs, P).

t(Name, Goal) :- ( catch(Goal, E, (print_message(error, E), fail)) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]), assertz(failed(Name)) ).

main :-
    memo_reset,
    p(reach, R), p(family, F), p(numbers, N), p(physics, Ph), p(physics_bad, Pb), p(family2, F2),
    t(reach_flow_proof, ( includes(R, (reach/2):1, (edge/2):1, Pr), Pr = [flow(_, _)] )),
    t(reach_same_type_as_edge, ( same_type(R, (reach/2):2, (edge/2):2, _) )),
    t(reach_inclusion_holds_on_all_inputs, check_inclusion(R, (reach/2):1, (edge/2):1, [edge/2], [a,b,c], proved(all_inputs(512)))),
    t(wrong_inclusion_is_refuted, ( \+ includes(R, (reach/2):2, (edge/2):1, _),
                                     check_inclusion(R, (reach/2):2, (edge/2):1, [edge/2], [a,b,c], refuted(_, _)) )),
    t(parent_is_contained_in_person, ( includes(F, (parent/2):2, (person/1):1, [cover(_, _, _)]) )),
    t(sibling_is_contained_in_person, ( includes(F, (sib/2):1, (person/1):1, _),
                                        check_inclusion(F, (sib/2):1, (person/1):1, [parent/2, age/2], [a,b], proved(_)) )),
    t(guard_implied_by_related_variable, implied_guard(F, 3, 1, implied(_, by((parent/2):2), _))),
    t(guard_not_implied_is_kept, \+ implied_guard(F, 4, 1, _)),
    t(age_not_contained_in_person, check_inclusion(F, (age/2):1, (person/1):1, [parent/2, age/2], [a,b], refuted(_, _))),
    t(related_slots_form_one_class, ( type_classes(F, Cs), member(C, Cs), memberchk((sib/2):1, C), memberchk((parent/2):1, C),
                                      memberchk((person/1):1, C), memberchk((adult/1):1, C) )),
    t(refinement_template, ( templates(N, Ts), memberchk(refine((num/1):1, ['X'>0], (pos/1):1), Ts) )),
    t(conversion_template, ( templates(N, Ts2), member(convert((pos/1):1, ('Y' is 1+2*'X'), (val/2):2), Ts2) )),
    Decls = [((mass/2):2)-[kg-1], ((acc/2):2)-[m-1, s-(-2)], ((force/2):2)-[kg-1, m-1, s-(-2)]],
    t(dimensions_force_is_mass_times_acceleration, ( dimensions(Ph, Decls, ok(SU)), memberchk(((force/2):2)-U, SU), U == [kg-1, m-1, s-(-2)] )),
    t(dimensions_mass_plus_acceleration_refuted, dimensions(Pb, Decls, refuted(_, _))),
    t(every_inferred_inclusion_holds_semantically, all_inclusions_hold(R, [edge/2], [a,b,c])),
    t(every_inferred_inclusion_holds_semantically_family, all_inclusions_hold(F, [parent/2, age/2], [a,b])),
    memo_stats(H0, _), infer_types(F2, _), memo_stats(H1, _),
    t(memo_reuses_templates_for_the_same_clause_shape, H1 > H0),
    ( failed(_) -> halt(1) ; format("all types tests passed~n"), halt(0) ).

% every inclusion between slots of rule-defined and input predicates is confirmed on all inputs
all_inclusions_hold(P, Edb, Consts) :-
    infer_types(P, types(Incl, _, _, _)),
    forall(( member(A-B, Incl), A = (K:_), B = (K2:_), relevant(P, K, Edb), relevant(P, K2, Edb) ),
           ( check_inclusion(P, A, B, Edb, Consts, R), R = proved(_) -> true ; format("    not confirmed: ~w ⊆ ~w~n", [A, B]), fail )).
relevant(prog(_, Rs), K, Edb) :- ( memberchk(K, Edb) -> true ; member(H-_, Rs), functor(H, N, A), K = N/A, ! ).
