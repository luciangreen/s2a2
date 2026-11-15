:- encoding(utf8).
/*  dict_tests.pl -- tests of the dictionary (harvest.pl, dict_gen.pl) and of synthesis from
    it (dict.pl).
    swipl -q -g main -t 'halt(1)' dict_tests.pl
*/
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(dict).
:- use_module(io_synth, [show_program/1]).
:- use_module(io_proof, [show_proof/1]).
:- use_module(library(assoc)).
:- ensure_loaded(harvest).        % pure_goal/3

files(['../dictionary/dictionary.pl', '../dictionary/generated.pl']).

main :-
    files(Fs), load_dictionary(Fs),
    findall(T, test(T), Ts),
    include(failed, Ts, Bad),
    (   Bad == [] -> format("all dictionary tests passed~n"), halt(0)
    ;   format("FAILED: ~w~n", [Bad]), halt(1) ).

failed(T) :- \+ catch(run_test(T), E, ( print_message(error, E), fail )).
run_test(T) :- ( call(T) -> format("  ~w: ok~n", [T]) ; format("  ~w: FAILED~n", [T]), fail ).

test(harvested_from_many_repositories).
test(every_entry_runs_on_its_pool).
test(no_two_entries_behave_alike).
test(code_is_closed_and_pure).
test(lemmas_hold_on_the_pool).
test(inventors_and_joiners_present).
test(io_one_entry).
test(io_two_entries_joined).
test(io_invented_entry).
test(io_negative_examples).
test(io_invented_then_harvested).
test(io_falls_back_to_io_synth).
test(code_only_proved).

harvested_from_many_repositories :-
    findall(R, ( dict_entry(_, I, _), memberchk(source(R, _, _), I) ), Rs), sort(Rs, Repos),
    length(Repos, NR), NR >= 30,
    aggregate_all(count, ( dict_entry(_, I, _), memberchk(source(_, _, _), I) ), N), N >= 300.

every_entry_runs_on_its_pool :-
    forall(dict_entry(Id, I, _),
           (   memberchk(in(T), I), pool(T, P), length(P, NP),
               aggregate_all(count, ( member(X, P), dict_run(Id, X, _) ), NOk),
               NOk * 5 >= NP * 3 )).

no_two_entries_behave_alike :-
    findall(T-Sig, ( dict_entry(Id, I, _), memberchk(in(T), I), signature(Id, T, Sig) ), Ks),
    length(Ks, N), sort(Ks, S), length(S, N).

% every clause calls only predicates of its own program or pure built-ins (harvest.pl's test)
code_is_closed_and_pure :-
    forall(dict_entry(Id, _, _),
           (   entry_program(Id, Cs),
               findall(F/A-t, ( member(C, Cs), ( C = (H :- _) -> true ; H = C ), functor(H, F, A) ), KV0),
               sort(KV0, KV), list_to_assoc(KV, Def),
               forall(( member(C, Cs), C = (_ :- B) ), user:pure_goal(B, Def, Def)) )).

lemmas_hold_on_the_pool :-
    forall(( dict_lemma(K, Ids, St), St \= refuted(_) ), lemma_holds(K, Ids)).
lemma_holds(equal, [A, B]) :- atom(A), atom(B), !,
    entry_type(A, T, _), pool(T, P),
    ( dict_alt(A, B, _, Cs) -> forall(member(X, P), same_alt(A, B, Cs, X))
    ; forall(member(X, P), same(A, B, X)) ).
lemma_holds(equal, [scheme(_, _), _]) :- !.
lemma_holds(idempotent, [F]) :- entry_type(F, T, _), pool(T, P),
    forall(( member(X, P), dict_run(F, X, Y), dict_run(F, Y, Z) ), Z =@= Y).
lemma_holds(involution, [F]) :- entry_type(F, T, _), pool(T, P),
    forall(( member(X, P), dict_run(F, X, Y) ), ( dict_run(F, Y, Z), Z =@= X )).
lemma_holds(commute, [F, G]) :- entry_type(F, T, _), pool(T, P),
    forall(( member(X, P), dict_run(F, X, Y), dict_run(G, Y, Z) ), ( dict_run(G, X, Y2), dict_run(F, Y2, Z2), Z2 =@= Z )).
same(A, B, X) :- ( dict_run(A, X, Y) -> dict_run(B, X, Y2), Y2 =@= Y ; \+ dict_run(B, X, _) ).
same_alt(A, B, Cs, X) :- run_closed(Cs, B, [X], [R]), ( dict_run(A, X, Y) -> Y =@= R ; R == err ).

inventors_and_joiners_present :-
    forall(member(S, [map, filter, count, per_sublist, fold, twice]),
           once(( dict_entry(_, I, _), memberchk(invented(S, _), I) ))),
    forall(member(J, [compose, fork, cond]),
           once(( dict_entry(_, I, _), memberchk(joined(J, _), I) ))),
    once(dict_lemma(_, _, proved(_))).

% ---------------------------------------------------------------- synthesis from input/output
synth_ok(Name, Exs, Tree) :-
    dict_synth(Name, Exs, [], P, R),
    format("    ~w: ~p~n", [Name, R]), show_program(P),
    R = dictionary(Tree).

io_one_entry :- synth_ok(square, [2-4, 3-9, -1-1], entry(_)).
io_two_entries_joined :- synth_ok(square_of_sum, [[1,2]-9, [3]-9, [2,2]-16, []-0], join(_, _)).
io_invented_entry :- synth_ok(square_each, [[1,2]-[1,4], [3]-[9], []-[]], entry(Id)),
    dict_entry(Id, I, _), ( memberchk(invented(_, _), I) ; memberchk(joined(_, _), I) ).
% 3 -> 9 fits the square, and the negative example 2 -> 4 rules the square out
io_negative_examples :-
    dict_synth(not_square, [3-9, neg(2-4)], [], P, dictionary(_)),
    io_synth:run_all(P, not_square, [3-9], ok), \+ io_synth:run_all(P, not_square, [2-4], ok).
% sum of squares: an invented entry (map of a harvested square) joined to a harvested sum
io_invented_then_harvested :-
    synth_ok(sum_of_squares, [[1,2]-5, [3]-9, []-0, [1,1,1]-3], join(F, _)),
    dict_entry(F, I, _), memberchk(invented(map, _), I).
% drop the minimum of each sublist is not in the dictionary: io_synth finds it
io_falls_back_to_io_synth :-
    Exs = [ [[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]] ],
    dict_synth(dropmin_each, Exs, [], P, R),
    R = io_synth(_), io_synth:run_all(P, dropmin_each, [[[2,1]]-[[2]]], ok).

% ---------------------------------------------------------------- synthesis from code only
code_only_proved :-
    Code = [ total([], 0), (total([H|T], S) :- total(T, S0), S is H + S0) ],
    dict_synth_code(Code, total, [], P, report(Type, Tree, Proof, Run)),
    format("    code total/2 (~w) -> ~w, ~w~n", [Type, Tree, Run]), show_program(P), show_proof(Proof),
    Proof = proved(_), Run = equal_on(_).
