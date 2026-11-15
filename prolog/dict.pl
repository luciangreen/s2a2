:- encoding(utf8).
/*  dict.pl -- a dictionary of algorithms (harvested from the author's repositories, then
    extended by dict_gen.pl), and synthesis from it that takes only input and output, or
    only code, as Aleph takes examples and background knowledge.

    An entry is   entry(Id, Info, Clauses)
        Id        the name of its predicate Id/2, called as Id(In, Out)
        Info      [source(Repo, File, Name/Arity) | invented(Scheme, Ids) | joined(How, Ids),
                   in(Type), out(Type), size(S), also(Sources)]
        Clauses   a closed program: Id/2 and its helpers (named Id__helper), calling only
                  pure built-ins. A test P/1 becomes Id(X, true/false); a predicate
                  P(A, B, C) becomes Id(A-B, C).

    Types: int, list(int), list(list(int)), pair(T1, T2) (written T1-T2 in data), bool, atom,
    list(atom), any.

    Main predicates
      load_dictionary(+Files)            asserts the entries and their code
      dict_entry(?Id, ?Info, ?Clauses)
      dict_run(+Id, +In, -Out)           first answer, within an inference limit
      pool(+Type, -Inputs)               the probe inputs of a type
      signature(+Id, +Type, -Outputs)    outputs on pool(Type), err where undefined
      entry_program(+Id, -Clauses)       Id's clauses
      dict_synth(+Name, +Examples, -Program, -Report)
      dict_synth(+Name, +Examples, +Options, -Program, -Report)
          Examples: In-Out (positive) and neg(In-Out) (negative), like Aleph's E+ and E-.
          Options: depth(D) (1: one entry, 2: two joined, default 2), fallback(Bool) (try
          io_synth:synth/5 when nothing in the dictionary fits, default true),
          max_answers(N).
          Program is Name/2 and every clause it needs; it reproduces every positive example
          and no negative one.
      dict_synth_code(+Code, +CodeName, +Options, -Program, -Report)
          only code: Code (clauses of CodeName/2) is run on the pool of its input type to
          get examples; the dictionary program found is proved equal to Code with
          io_proof:prove_equal/6 where it can be, and run against it on the pool.
*/
:- module(dict, [ load_dictionary/1, clear_dictionary/0, dict_entry/3, dict_alt/4, dict_lemma/3, dict_remove/1, dict_run/3, admits/2,
                  pool/2, signature/3, entry_program/2, entry_type/3, out_type/2,
                  run_closed/4, closed_signature/4, dict_synth/4, dict_synth/5,
                  dict_synth_code/5, show_entry/1, value_type/2, term_size_ok/1,
                  dict_add/3, proof_type/2, plain_data/1 ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(yall)).
:- use_module(library(pairs)).
:- use_module(library(assoc)).
:- use_module(library(modules)).
:- use_module(io_synth, [synth/5, run_all/4]).
:- use_module(io_proof, [prove_equal/6]).

:- dynamic dict_entry/3, dict_alt/4, dict_lemma/3.

opt(Opt, Opts, _) :- memberchk(Opt, Opts), !.
opt(Opt, _, Default) :- arg(1, Opt, Default).

% ================================================================ pools
pool(int, [-2, -1, 0, 1, 2, 3, 5, 7]).
pool(list(int), [[], [0], [1], [3], [-2], [1,2], [2,1], [2,2], [3,1,2], [1,2,3], [5,-1,4,0],
                 [4,4,1,3], [0,7,3,7,2]]).
pool(list(list(int)), [[], [[]], [[1]], [[1,2],[3]], [[3,1],[2,5,4]], [[0],[],[2,2]],
                       [[4,1,3]], [[2],[1],[3]]]).
pool(pair(int,int), [0-0, 1-2, 2-1, 3-3, 5-2, -1-4, 2-7, 4-0]).
pool(pair(list(int),list(int)), [[]-[], [1]-[], []-[2], [1,2]-[3], [3,1]-[1,4], [2]-[2,5,1],
                                 [4,2]-[4,2]]).
pool(pair(list(int),int), [[]-0, [1,2]-1, [3,1,2]-2, [5,-1,4]-0, [2,2]-3, [1,2,3]-4, [7]-7]).
pool(pair(int,list(int)), Ps) :- pool(pair(list(int),int), Qs), maplist([L-N, N-L]>>true, Qs, Ps).

% ================================================================ values and types
value_type(V, int) :- integer(V), !.
value_type(V, bool) :- ( V == true ; V == false ), !.
value_type([], list(_)) :- !.
value_type(L, list(T)) :- is_list(L), !, maplist(value_type, L, Ts), join_all(Ts, T).
value_type(A-B, pair(TA, TB)) :- !, value_type(A, TA), value_type(B, TB).
value_type(V, atom) :- atom(V), !.
value_type(_, any).

join_all([], _).
join_all([T|Ts], J) :- foldl(join2, Ts, T, J).
join2(T, A, J) :- ( \+ \+ A = T -> A = T, J = A ; J = any ).

out_type(Outs, T) :- exclude(==(err), Outs, Os), maplist(value_type, Os, Ts), join_all(Ts, T0),
    ( var(T0) -> T = any ; T = T0 ), ground_type(T).
ground_type(T) :- term_variables(T, Vs), maplist(=(int), Vs).

% the type io_proof.pl is given for an input type
proof_type(int, int) :- !.
proof_type(list(int), list(int)) :- !.
proof_type(list(list(int)), list(list(int))) :- !.
proof_type(_, any).

% plain data: numbers, atoms, lists and pairs of them (no strings, no other compound terms)
plain_data(V) :- number(V), !.
plain_data(V) :- atom(V), !.
plain_data(V) :- is_list(V), !, maplist(plain_data, V).
plain_data(A-B) :- plain_data(A), plain_data(B).

term_size_ok(T) :- catch(( term_size(T, S), S < 4000 ), _, fail).

% ================================================================ running closed programs
% run_closed(+Clauses, +Name, +Inputs, -Results): Name/2 on each input in a fresh module; err
% where it fails, throws, runs past the limit, or leaves its output unbound
run_closed(Cs, Name, Ins, Rs) :-
    catch(in_temporary_module(M,
              forall(member(C, Cs), assertz(M:C)),
              maplist(dict:run1(M, Name), Ins, Rs)),
          E, ( print_message(error, E), maplist([_, err]>>true, Ins, Rs) )).

run1(M, Name, In, R) :-
    G =.. [Name, In, Out],
    (   catch(call_with_inference_limit(once(M:G), 100000, Lim), _, fail),
        Lim \== inference_limit_exceeded, ground(Out), term_size_ok(Out)
    ->  R = Out ; R = err ).

closed_signature(Cs, Name, Type, Sig) :- pool(Type, P), run_closed(Cs, Name, P, Sig).

% ================================================================ the loaded dictionary
% Every entry's clauses are asserted into dict_code, where the names are unique.
clear_dictionary :-
    retractall(dict_entry(_, _, _)), retractall(dict_alt(_, _, _, _)), retractall(dict_lemma(_, _, _)),
    forall(( current_predicate(dict_code:F/A), functor(H, F, A), \+ predicate_property(dict_code:H, imported_from(_)) ),
           abolish(dict_code:F/A)).

load_dictionary(Files) :-
    forall(member(F, Files),
           setup_call_cleanup(open(F, read, S, [encoding(utf8)]), read_entries(S), close(S))).
read_entries(S) :-
    read_term(S, T, []),
    (   T == end_of_file -> true
    ;   ( T = entry(Id, Info, Cs) -> dict_add(Id, Info, Cs)
        ; T = alt(Id, A, AI, ACs) -> assertz(dict_alt(Id, A, AI, ACs))
        ; T = lemma(K, Ids, St) -> assertz(dict_lemma(K, Ids, St))
        ; true ),
        read_entries(S) ).

dict_add(Id, Info, Cs) :-
    (   dict_entry(Id, _, _) -> true
    ;   assertz(dict_entry(Id, Info, Cs)),
        forall(member(C, Cs), assertz(dict_code:C)) ).

dict_run(Id, In, Out) :-
    G =.. [Id, In, Out0],
    catch(call_with_inference_limit(once(dict_code:G), 100000, Lim), _, fail),
    Lim \== inference_limit_exceeded, ground(Out0), term_size_ok(Out0), Out = Out0.

entry_type(Id, In, Out) :- dict_entry(Id, Info, _), memberchk(in(In), Info), memberchk(out(Out), Info).
% entry_program(+Id, -Clauses): Id's clauses and those of the entries it uses
entry_program(Id, Cs) :- closure_ids([Id], [], Ids), reverse(Ids, Ids1),
    findall(C, ( member(I, Ids1), dict_entry(I, _, Own), member(C, Own) ), Cs).
closure_ids([], Seen, Seen).
closure_ids([I|Is], Seen, Out) :-
    (   memberchk(I, Seen) -> closure_ids(Is, Seen, Out)
    ;   dict_entry(I, Info, _), ( memberchk(uses(U), Info) -> true ; U = [] ),
        append(Is, U, Is1), closure_ids(Is1, [I|Seen], Out) ).

dict_remove(Id) :-
    (   retract(dict_entry(Id, _, Cs))
    ->  forall(( member(C, Cs), ( C = (H :- _) -> true ; H = C ), functor(H, F, A) ),
               ( current_predicate(dict_code:F/A) -> abolish(dict_code:F/A) ; true ))
    ;   true ).

signature(Id, Type, Sig) :- pool(Type, P), maplist(run_or_err(Id), P, Sig).
run_or_err(Id, In, R) :- ( dict_run(Id, In, R0) -> R = R0 ; R = err ).

show_entry(Id) :-
    dict_entry(Id, Info, Cs),
    format("  ~w  ~w~n", [Id, Info]),
    forall(member(C, Cs), ( copy_term(C, C1), numbervars(C1, 0, _), format("    ~p.~n", [C1]) )).

% ================================================================ synthesis from examples
dict_synth(Name, Exs, Program, Report) :- dict_synth(Name, Exs, [], Program, Report).

dict_synth(Name, Exs, Opts, Program, Report) :-
    partition([neg(_)]>>true, Exs, Negs0, Pos),
    maplist([neg(E), E]>>true, Negs0, Negs),
    Pos \== [],
    opt(depth(D), Opts, 2),
    (   once(dict_hyp(D, Pos, Negs, Tree)) ->
        emit(Name, Tree, Program),
        io_synth:run_all(Program, Name, Pos, ok),
        forall(member(I-O, Negs), \+ io_synth:run_all(Program, Name, [I-O], ok)),
        Report = dictionary(Tree)
    ;   opt(fallback(FB), Opts, true), FB == true, Negs == [] ->
        synth(Name, Pos, [], Program, R), Report = io_synth(R)
    ).

% dict_hyp(+Depth, +Pos, +Negs, -Tree): Tree = entry(Id) | join(F, G) (G after F)
dict_hyp(_, Pos, Negs, entry(Id)) :-
    pairs_keys(Pos, Ins),
    candidate_entries(Ins, Ids),
    member(Id, Ids), fits(Id, Pos, Negs).
dict_hyp(D, Pos, Negs, join(F, G)) :-
    D >= 2,
    pairs_keys_values(Pos, Ins, Outs),
    candidate_entries(Ins, Fs),
    % first steps, one per distinct intermediate (observational equivalence)
    findall(Mids-F, ( member(F, Fs), maplist(dict_run(F), Ins, Mids), Mids \== Ins ), MF0),
    dedupe_keys(MF0, MF),
    member(Mids-F, MF),
    candidate_entries(Mids, Gs),
    member(G, Gs), G \== F,
    maplist(dict_run(G), Mids, Outs),
    \+ ( member(I-O, Negs), dict_run(F, I, M), dict_run(G, M, O) ).

dedupe_keys(KVs, Out) :- empty_assoc(A), dedupe_keys(KVs, A, Out).
dedupe_keys([], _, []).
dedupe_keys([K-V|R], A, Out) :-
    (   get_assoc(K, A, _) -> Out = Out1, A1 = A
    ;   put_assoc(K, A, t, A1), Out = [K-V|Out1] ),
    dedupe_keys(R, A1, Out1).

% entries whose input type admits every input, smallest first
candidate_entries(Ins, Ids) :-
    findall(S-Id, ( dict_entry(Id, Info, _), memberchk(in(T), Info), memberchk(size(S), Info),
                    forall(member(I, Ins), admits(T, I)) ), L0),
    keysort(L0, L), pairs_values(L, Ids).

admits(T, V) :- value_type(V, VT), ( \+ \+ VT = T -> true ; T = list(_), is_list(V) ).

fits(Id, Pos, Negs) :-
    forall(member(I-O, Pos), dict_run(Id, I, O)),
    \+ ( member(I-O, Negs), dict_run(Id, I, O) ).

% emit(+Name, +Tree, -Program): Name/2 calling the entries, with their closed code
emit(Name, entry(Id), [(H :- B)|Cs]) :-
    H =.. [Name, X, Y], B =.. [Id, X, Y], entry_program(Id, Cs).
emit(Name, join(F, G), [(H :- (BF, BG))|Cs]) :-
    H =.. [Name, X, Y], BF =.. [F, X, Z], BG =.. [G, Z, Y],
    entry_program(F, CF), entry_program(G, CG), append(CF, CG, Cs0), dedupe_clauses(Cs0, Cs).

dedupe_clauses([], []).
dedupe_clauses([C|Cs], [C|Rs]) :- exclude(=@=(C), Cs, Cs1), dedupe_clauses(Cs1, Rs).

% ================================================================ synthesis from code
dict_synth_code(Code, CodeName, Opts, Program, report(Type, Tree, Proof, Run)) :-
    member(Type, [list(int), int, list(list(int)), pair(int,int), pair(list(int),list(int)),
                  pair(list(int),int), pair(int,list(int))]),
    pool(Type, P), run_closed(Code, CodeName, P, Outs),
    pairs_keys_values(Ex0, P, Outs), exclude([_-O]>>( O == err ), Ex0, Exs),
    length(P, NP), length(Exs, NE), NE * 5 >= NP * 3, !,
    atom_concat(CodeName, '_dict', Name),
    dict_synth(Name, Exs, [fallback(false)|Opts], Program, dictionary(Tree)),
    proof_type(Type, PT), out_proof_type(Exs, OT),
    proof_subject(Tree, Program, Name, PProg, PName),
    (   catch(prove_equal(PProg, PName, Code, CodeName, [PT, OT], Proof0), _, fail) -> Proof = Proof0
    ;   Proof = not_proved ),
    run_closed(Program, Name, P, Got),
    (   nth1(K, Outs, W), W \== err, nth1(K, Got, G), G \=@= W -> nth1(K, P, In), Run = counter_example(In, G, W)
    ;   Run = equal_on(NE) ).

% a program that only calls one entry is proved through that entry (io_proof pairs
% predicates clause by clause, so a one-goal wrapper is skipped)
proof_subject(entry(Id), _, _, P, Id) :- !, entry_program(Id, P).
proof_subject(_, P, N, P, N).

out_proof_type(Exs, T) :- pairs_values(Exs, Os), out_type(Os, T0), proof_type(T0, T).
