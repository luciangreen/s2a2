:- encoding(utf8).
/*  fold_examples.pl -- spec to algorithm with fold and eureka definitions.
    swipl -q -g main -t 'halt(1)' fold_examples.pl     (writes ../results/fold.txt too)

    1. Prove the associativity of append, and fail to prove a false "lemma".
    2. Deforest app3 (append three lists) into one pass.
    3. Naive reverse to accumulator reverse: without the lemma (no derivation is found),
       then with the lemma database (derived, proved, measured).
*/
:- use_module(fold).

spec(append, [ app([], L, L), (app([H|T], L, [H|R]) :- app(T, L, R)) ]).
spec(nrev,   [ rev([], []), (rev([H|T], R) :- rev(T, RT), app(RT, [H], R)) ]).
spec(app3,   [ (app3(X, Y, Z, R) :- app(X, Y, W), app(W, Z, R)) ]).

lemma(assoc, [app(X, Y, W), app(W, Z, R)], [app(Y, Z, V), app(X, V, R)]).
lemma(commutes, [app(X, Y, R)], [app(Y, X, R)]).        % false

program(Names, P) :- foldl([N, A0, A]>>( spec(N, Cs), fold:clauses(Cs, P1), append(A0, P1, A) ), Names, [], P).

% the lemma database holds only lemmas that prove_lemma/3 has proved
database(Spec, Names, DB) :-
    findall(lemma(N, L, R), ( member(N, Names), lemma(N, L, R), prove_lemma(Spec, lemma(N, L, R), proved(_, _)) ), DB).

main :- run(Out), atom_concat('../results/', 'fold.txt', F),
        setup_call_cleanup(open(F, write, S), write(S, Out), close(S)),
        write(Out), ( sub_atom(Out, _, _, _, 'FAILED') -> halt(1) ; halt(0) ).

run(Out) :- with_output_to(atom(Out), examples).

check(Name, G) :- ( catch(G, E, ( print_message(error, E), fail )) -> format("  ~w: ok~n", [Name]) ; format("  ~w: FAILED~n", [Name]) ).

examples :-
    program([append], App),
    format("== 1. Lemmas (proved by deforesting both sides on the same induction variable)~n~n"),
    lemma(assoc, AL, AR), prove_lemma(App, lemma(assoc, AL, AR), RA),
    format("  assoc: app(X,Y,W), app(W,Z,R)  <=>  app(Y,Z,V), app(X,V,R)~n"),
    (   RA = proved(How, Prog) -> format("  proved (~w); both sides become~n", [How]), show(Prog)
    ;   format("  not proved~n") ),
    check(assoc_is_proved, RA = proved(_, _)),
    lemma(commutes, CL, CR), prove_lemma(App, lemma(commutes, CL, CR), RC),
    format("~n  commutes: app(X,Y,R)  <=>  app(Y,X,R): ~w~n", [RC]),
    program([append], P1), fold:clauses([(cl(X, Y, R) :- app(X, Y, R))], CLc), fold:clauses([(cl(X1, Y1, R1) :- app(Y1, X1, R1))], CRc),
    append(P1, CLc, PL), append(P1, CRc, PR),
    bounded_equal(PL, cl/3, PR, cl/3, [in(list), in(list), out], inputs([a, b], 2), BC),
    format("  bounded check: ~w~n", [BC]),
    check(false_lemma_not_proved_and_refuted, ( RC == not_proved, BC = refuted(_, _, _) )),

    format("~n== 2. Deforestation: app3(X,Y,Z,R) :- app(X,Y,W), app(W,Z,R)~n~n"),
    program([append, app3], S2),
    spec_to_algorithm(S2, app3/4, [], P2, report(Str2, Tr2, U2)),
    format("  strategy ~w, lemmas used ~w, derived:~n", [Str2, U2]), show(P2),
    show_steps(Tr2),
    M2 = [in(list), in(list), in(list), out],
    bounded_equal(S2, app3/4, P2, app3/4, M2, inputs([a, b], 3), B2),
    format("  correctness: unfold/fold only, so the least model is preserved (Tamaki-Sato)~n"),
    format("  bounded check: ~w~n", [B2]),
    check(app3_deforested_and_equal, ( B2 = equal_on(_), \+ ( member(_-Bd, P2), member(G, Bd), functor(G, app, 3), fail ) )),
    numlist(1, 40, Xs), steps(S2, app3(Xs, Xs, [], _), N2a, _), steps(P2, app3(Xs, Xs, [], _), N2b, _),
    format("  steps for X and Y of length 40: ~w (spec) vs ~w (derived)~n", [N2a, N2b]),
    check(app3_fewer_steps, N2b < N2a),

    format("~n== 3. Naive reverse to accumulator reverse~n~n"),
    program([append, nrev], S3),
    format("  specification:~n"), show(S3),
    (   spec_to_algorithm(S3, rev/2, [], _, _) -> W0 = derived ; W0 = no_derivation ),
    format("~n  with an empty lemma database: ~w~n", [W0]),
    check(no_derivation_without_the_lemma, W0 == no_derivation),
    database(App, [assoc, commutes], DB), findall(N, member(lemma(N, _, _), DB), DBN),
    format("  lemma database (proved lemmas only): ~w~n", [DBN]),
    check(database_holds_only_proved_lemmas, DBN == [assoc]),
    spec_to_algorithm(S3, rev/2, DB, P3, report(Str3, Tr3, U3)),
    format("~n  strategy ~w, lemmas used ~w, derived:~n", [Str3, U3]), show(P3),
    show_steps(Tr3),
    TM = [in(list), out],
    format("~n  correctness for every ground first argument:~n"),
    format("    sound: each step keeps every clause true in the specification's least model~n"),
    ( total(P3, rev/2, TM) -> T3 = yes ; T3 = no ),
    format("    derived rev(+list,-) answers every list input: ~w~n", [T3]),
    ( functional(S3, rev/2, [in, out]) -> F3 = yes ; F3 = no ),
    format("    specification rev(+,-) has at most one answer: ~w~n", [F3]),
    ( list_slot(S3, rev/2, 1) -> L3 = yes ; L3 = no ),
    format("    specification answers only list inputs: ~w~n", [L3]),
    format("    so the derived program has exactly the specification's answers on every ground input~n"),
    check(reverse_proved, ( T3 == yes, F3 == yes, L3 == yes )),
    bounded_equal(S3, rev/2, P3, rev/2, TM, inputs([a, b], 7), B3),
    format("    bounded check (independent): ~w~n", [B3]),
    check(reverse_bounded_equal, B3 = equal_on(_)),
    check(reverse_has_no_append, \+ ( member(_-Bd3, P3), member(G3, Bd3), functor(G3, app, 3) )),
    format("~n  resolution steps for rev(L,R):~n    length  naive  derived~n"),
    forall(member(Len, [8, 16, 32, 64, 128]),
           ( numlist(1, Len, L), steps(S3, rev(L, _), Na, _), steps(P3, rev(L, _), Nd, _),
             format("    ~t~w~6|  ~t~w~13|  ~t~w~22|~n", [Len, Na, Nd]) )),
    numlist(1, 128, L128), steps(S3, rev(L128, _), N128a, _), steps(P3, rev(L128, _), N128b, _),
    check(reverse_linear, ( N128b =:= 128 + 1, N128a > 50 * N128b )).

show_steps(Trace) :-
    format("  derivation:~n"),
    forall(member(E, Trace), show_event(E)).
show_event(eureka(D, generalised(R, R1))) :-
    copy_term(D-R-R1, D1-Ra-Rb), numbervars(D1-Ra-Rb, 0, _),
    D1 = H-B, fold:atomic_list_concat_terms(B, BS),
    format("    eureka definition: ~p :- ~w.~n      (the goals after the recursive call, ~p, generalised to ~p)~n", [H, BS, Ra, Rb]).
show_event(define(_)).
show_event(fold_target(Cs)) :- format("    fold the specification's own clauses with the eureka definition:~n"), show(Cs).
show_event(unfold(J, Cs)) :- format("    unfold body literal ~w:~n", [J]), show(Cs).
show_event(steps(SL)) :-
    forall(member(Ss, SL), forall(member(S-C, Ss), ( format("    ~w, then normalise:~n", [S]), show([C]) ))).
