:- encoding(utf8).
/*  harvest.pl -- collect the non-LLM algorithms in a set of repositories into a dictionary.

    swipl harvest.pl -- Out.pl Repo1Dir Repo2Dir ...

    For each Prolog file (.pl) under each repository:
      * a file that mentions an LLM, an LLM service or a chatbot (openai, chatgpt, gpt, llm,
        ollama, anthropic, claude, gemini, copilot, api_key, chatbot) is skipped entirely;
      * its clauses are read (with the file's own op/3 declarations, DCG rules translated);
      * a predicate is kept when it and every predicate it reaches call only pure built-ins
        (arithmetic, comparison, list, atom and string operations, findall, maplist, foldl,
        include, exclude, ...): nothing that reads, writes, asserts, calls the shell or the
        network, no call of a variable, and no random or clock arithmetic;
      * a kept predicate of arity 1, 2 or 3 is probed on the inputs of each type (dict.pl,
        pool/2) and becomes an entry with the first input type on which it gives a ground
        answer for at least 60% of the inputs; a test (arity 1) must say both true and false;
        a predicate that is constant or the identity there is dropped.
    Entries with the same behaviour on their pool are one entry (the smallest code); the
    others are listed in also(...), and dict_gen.pl tries to prove them equal.

    The dictionary is written as entry(Id, Info, Clauses) terms (see dict.pl).
*/
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(yall)).
:- use_module(library(pairs)).
:- use_module(library(assoc)).
:- use_module(library(readutil)).
:- use_module(library(modules)).
:- use_module(dict).

:- initialization(main, main).

main :-
    current_prolog_flag(argv, [Out|Repos]), Repos \== [], !,
    findall(op(P, T, N), current_op(P, T, N), Std),
    set_prolog_flag(stack_limit, 1 000 000 000),
    harvest(Repos, Entries, Stats),
    forall(( current_op(P, T, N), \+ memberchk(op(P, T, N), Std) ), catch(op(0, T, N), _, true)),
    write_dictionary(Out, Repos, Entries, Stats),
    format(user_error, "~w~n", [Stats]).
main :- format(user_error, "usage: swipl harvest.pl -- Out.pl RepoDir ...~n", []), halt(1).

:- dynamic used_id/1, cand/6.

harvest(Repos, Entries, stats(files(NF), skipped_llm(NS), unreadable(NU), pure(NP), entries(NE))) :-
    retractall(used_id(_)), retractall(cand(_, _, _, _, _, _)),
    flag(h_files, _, 0), flag(h_llm, _, 0), flag(h_bad, _, 0), flag(h_pure, _, 0),
    forall(member(R, Repos), harvest_repo(R)),
    findall(Key-c(Size, Id, Info, Cs), cand(Key, Size, Id, Info, Cs, _), KC0),
    keysort(KC0, KC), group_pairs_by_key(KC, Groups),
    maplist(pick_group, Groups, Entries0),
    sort(Entries0, Entries1), pairs_values(Entries1, Entries2), append(Entries2, Entries),
    include([E]>>( E = entry(_, _, _) ), Entries, Es), length(Es, NE),
    flag(h_files, NF, NF), flag(h_llm, NS, NS), flag(h_bad, NU, NU), flag(h_pure, NP, NP).

% the smallest code stands for its behaviour; the others become alt(Id, AltId, Info, Clauses),
% equalities that dict_gen.pl tries to prove
pick_group(_-Cands, (Type-Id)-[entry(Id, Info, Cs)|Alts]) :-
    findall(k(S, I)-C, ( member(C, Cands), C = c(S, I, _, _) ), KCs), keysort(KCs, SKCs),
    pairs_values(SKCs, [c(_, Id, Info0, Cs)|Rest]),
    memberchk(in(Type), Info0),
    findall(S, ( member(c(_, _, I, _), Rest), memberchk(S, I), S = source(_, _, _) ), Also),
    Info = [also(Also)|Info0],
    abstract_names(Id, Cs, K0),
    findall(alt(Id, A, AI, ACs), ( member(c(_, A, AI, ACs), Rest),
                                   abstract_names(A, ACs, K), \+ K =@= K0 ), Alts0),
    dedupe_alts(Alts0, Alts).

% the code with its own Id prefix removed, so copies of one file in several repositories match
abstract_names(Id, Cs, K) :- strip_term(Id, Cs, K).
strip_term(_, T, T) :- var(T), !.
strip_term(Id, T, K) :- atom(T), !, ( strip_id(Id, T, K0) -> K = K0 ; K = T ).
strip_term(_, T, T) :- atomic(T), !.
strip_term(Id, T, K) :- compound_name_arguments(T, F, As), strip_term(Id, F, F1),
    maplist(strip_term(Id), As, As1), compound_name_arguments(K, F1, As1).
strip_id(Id, A, B) :- atom(A), sub_atom(A, 0, L, R, Id), ( R =:= 0 -> B = '$self' ; sub_atom(A, L, R, 0, B) ).

dedupe_alts([], []).
dedupe_alts([alt(I, A, AI, Cs)|R], [alt(I, A, AI, Cs)|R1]) :-
    abstract_names(A, Cs, K),
    exclude(same_code(K), R, R0), dedupe_alts(R0, R1).
same_code(K, alt(_, A, _, Cs)) :- abstract_names(A, Cs, K1), K1 =@= K.

harvest_repo(Dir) :-
    file_base_name(Dir, Repo0), atom_string(Repo, Repo0),
    directory_files_rec(Dir, Files),
    forall(member(F, Files), catch(harvest_file(Repo, Dir, F), _, flag(h_bad, B, B + 1))).

directory_files_rec(Dir, Files) :-
    findall(F, file_under(Dir, F), Fs), sort(Fs, Files).
file_under(Dir, F) :-
    directory_files(Dir, Es), member(E, Es), \+ sub_atom(E, 0, 1, _, '.'),
    directory_file_path(Dir, E, P),
    (   exists_directory(P) -> file_under(P, F)
    ;   file_name_extension(_, pl, E), F = P ).

harvest_file(Repo, Dir, File) :-
    flag(h_files, N, N + 1),
    read_file_to_string(File, Text, [encoding(utf8)]),
    (   mentions_llm(Text) -> flag(h_llm, L, L + 1)
    ;   atom_length(Dir, DL), D1 is DL + 1, sub_atom(File, D1, _, 0, Rel),
        read_clauses(File, Clauses),
        harvest_clauses(Repo, Rel, Clauses) ).

mentions_llm(Text) :-
    string_lower(Text, Low),
    split_string(Low, " \t\n\r()[]{},.;:'\"`/\\|=+*!?<>#%&@$^~-", "", Toks),
    member(T, Toks), llm_word(T), !.
llm_word("openai"). llm_word("chatgpt"). llm_word("gpt"). llm_word("gpt3"). llm_word("gpt4").
llm_word("llm"). llm_word("llms"). llm_word("ollama"). llm_word("anthropic").
llm_word("claude"). llm_word("gemini"). llm_word("copilot"). llm_word("api_key").
llm_word("apikey"). llm_word("chatbot").

% ---------------------------------------------------------------- reading
read_clauses(File, Clauses) :-
    in_temporary_module(M, true,
        setup_call_cleanup(open(File, read, S, [encoding(utf8)]), read_all(S, M, 0, Clauses), close(S))).

read_all(S, M, Errs, Cs) :-
    catch(read_term(S, T, [module(M)]), _, T = '$error'),
    (   T == end_of_file -> Cs = []
    ;   T == '$error' -> ( Errs > 200 -> Cs = [] ; E1 is Errs + 1, read_all(S, M, E1, Cs) )
    ;   T = (:- D) -> directive(M, D), read_all(S, M, Errs, Cs)
    ;   T = (_ --> _) -> ( catch(dcg_translate_rule(T, C), _, fail) -> Cs = [C|Cs1] ; Cs = Cs1 ),
        read_all(S, M, Errs, Cs1)
    ;   Cs = [T|Cs1], read_all(S, M, Errs, Cs1) ).

directive(M, op(P, T, N)) :- !, catch(M:op(P, T, N), _, true).
directive(M, module(_, Ex)) :- !, ( is_list(Ex) -> forall(member(op(P, T, N), Ex), catch(M:op(P, T, N), _, true)) ; true ).
directive(_, _).

% ---------------------------------------------------------------- purity
harvest_clauses(Repo, Rel, Clauses0) :-
    include(callable, Clauses0, Clauses),
    findall(F/A-C, ( member(C, Clauses), clause_head(C, H), callable(H), functor(H, F, A) ), Pairs0),
    keysort(Pairs0, Pairs), group_pairs_by_key(Pairs, Defs),
    pairs_keys(Defs, Keys), list_to_assoc_keys(Keys, Local),
    pure_fixpoint(Defs, Local, Pure),
    length(Pure, NP), flag(h_pure, P0, P0 + NP),
    forall(( member(Key, Pure), Key = F/A, memberchk(A, [1,2,3]), main_candidate(F, A, Defs) ),
           ignore(catch(probe(Repo, Rel, Key, Defs, Pure), _, true))).

clause_head((H :- _), H) :- !.
clause_head(H, H).
clause_body((_ :- B), B) :- !.
clause_body(_, true).

list_to_assoc_keys(Keys, A) :- findall(K-t, member(K, Keys), KV), list_to_assoc(KV, A).

% the largest set of local predicates whose clauses call only pure built-ins and members of the set
pure_fixpoint(Defs, Local, Pure) :-
    pairs_keys(Defs, Keys0),
    include([K]>>( \+ builtin_key(K) ), Keys0, Keys),
    fix(Keys, Defs, Local, Pure).
fix(Keys, Defs, Local, Pure) :-
    list_to_assoc_keys(Keys, Set),
    include(pure_def(Defs, Set, Local), Keys, Keys1),
    (   length(Keys, N), length(Keys1, N) -> Pure = Keys1 ; fix(Keys1, Defs, Local, Pure) ).

pure_def(Defs, Set, Local, K) :-
    memberchk(K-Cs, Defs),
    forall(member(C, Cs), ( clause_body(C, B), pure_goal(B, Set, Local) )).

builtin_key(F/A) :- functor(H, F, A), predicate_property(system:H, built_in).

% a main candidate has at least one rule that does something
main_candidate(F, A, Defs) :-
    \+ sub_atom(F, 0, _, _, test), \+ memberchk(F, [main, run, go, demo, example]),
    memberchk(F/A-Cs, Defs),
    member((_ :- B), Cs), B \== true, !.

pure_goal(G, _, _) :- var(G), !, fail.
pure_goal((A, B), S, L) :- !, pure_goal(A, S, L), pure_goal(B, S, L).
pure_goal((A ; B), S, L) :- !, pure_goal(A, S, L), pure_goal(B, S, L).
pure_goal((A -> B), S, L) :- !, pure_goal(A, S, L), pure_goal(B, S, L).
pure_goal((A *-> B), S, L) :- !, pure_goal(A, S, L), pure_goal(B, S, L).
pure_goal(\+ A, S, L) :- !, pure_goal(A, S, L).
pure_goal(not(A), S, L) :- !, pure_goal(A, S, L).
pure_goal(once(A), S, L) :- !, pure_goal(A, S, L).
pure_goal(ignore(A), S, L) :- !, pure_goal(A, S, L).
pure_goal(forall(A, B), S, L) :- !, pure_goal(A, S, L), pure_goal(B, S, L).
pure_goal(findall(_, G, _), S, L) :- !, pure_goal(G, S, L).
pure_goal(findall(_, G, _, _), S, L) :- !, pure_goal(G, S, L).
pure_goal(aggregate_all(_, G, _), S, L) :- !, pure_goal(G, S, L).
pure_goal(setof(_, G, _), S, L) :- !, strip_carets(G, G1), pure_goal(G1, S, L).
pure_goal(bagof(_, G, _), S, L) :- !, strip_carets(G, G1), pure_goal(G1, S, L).
pure_goal(G, S, L) :- meta_call(G, Closure, Extra), !, pure_closure(Closure, Extra, S, L).
pure_goal(G, S, _) :- callable(G), functor(G, F, A), ( get_assoc(F/A, S, _) -> true ; safe(F/A) ),
    \+ impure_arith(G).

% arithmetic that gives a different answer each time
impure_arith(G) :- sub_term(T, G), compound(T) , T \= [_|_],
    functor(T, F, A), memberchk(F/A, [random/1, random_float/0, cputime/0, realtime/0, random/0]), !.
impure_arith(G) :- sub_term(T, G), atom(T), memberchk(T, [random_float, cputime, realtime]), !.

strip_carets(G, G) :- var(G), !.
strip_carets(_^G, G1) :- !, strip_carets(G, G1).
strip_carets(G, G).

pure_closure(C, _, _, _) :- var(C), !, fail.
pure_closure(_>>B, _, S, L) :- !, pure_goal(B, S, L).
pure_closure(_/(_>>B), _, S, L) :- !, pure_goal(B, S, L).
pure_closure(C, E, S, _) :- callable(C), functor(C, F, K), A is K + E,
    ( get_assoc(F/A, S, _) -> true ; safe(F/A) ).

meta_call(G, C, E) :- G =.. [maplist, C|Ls], length(Ls, E), E >= 1, E =< 6.
meta_call(G, C, E) :- G =.. [foldl, C|Ls], length(Ls, N), N >= 3, N =< 6, E is N.
meta_call(include(C, _, _), C, 1).
meta_call(exclude(C, _, _), C, 1).
meta_call(partition(C, _, _, _), C, 1).
meta_call(predsort(C, _, _), C, 3).
meta_call(G, C, E) :- G =.. [call, C|As], length(As, E).

safe(K) :- safe_list(L), memberchk(K, L), !.
safe_list([ true/0, fail/0, false/0, !/0, (=)/2, (\=)/2, (==)/2, (\==)/2, (@<)/2, (@>)/2,
            (@=<)/2, (@>=)/2, compare/3, (is)/2, (=:=)/2, (=\=)/2, (<)/2, (>)/2, (=<)/2,
            (>=)/2, succ/2, plus/3, integer/1, number/1, atom/1, atomic/1, is_list/1, var/1,
            nonvar/1, ground/1, compound/1, callable/1, string/1, functor/3, arg/3, (=..)/2,
            copy_term/2, length/2, append/3, append/2, reverse/2, nth0/3, nth1/3, last/2,
            member/2, memberchk/2, msort/2, sort/2, sort/4, permutation/2, sum_list/2,
            sumlist/2, max_list/2, min_list/2, max_member/2, min_member/2, numlist/3,
            between/3, select/3, selectchk/3, select/4, subtract/3, intersection/3, union/3,
            list_to_set/2, delete/3, exclude/3, flatten/2, nextto/3, sumlist/3, keysort/2,
            pairs_keys_values/3, pairs_keys/2, pairs_values/2, atom_length/2, atom_codes/2,
            atom_chars/2, char_code/2, atom_number/2, number_codes/2, atom_concat/3,
            sub_atom/5, atomic_list_concat/2, atomic_list_concat/3, string_concat/3,
            string_chars/2, string_codes/2, string_to_atom/2, split_string/4,
            string_length/2, sub_string/5, number_string/2, upcase_atom/2, downcase_atom/2,
            char_type/2, code_type/2, list_to_ord_set/2, ord_union/3, ord_subtract/3,
            ord_memberchk/2, ord_intersection/3, proper_length/2, string_code/3 ]).

% ---------------------------------------------------------------- probing
probe(Repo, Rel, F/A, Defs, Pure) :-
    reachable([F/A], Pure, Defs, Reach),
    new_id(Repo, F, Id),
    list_to_assoc_keys(Reach, RS),
    findall(C2, ( member(K, Reach), memberchk(K-Cs, Defs), member(C, Cs),
                  rename_clause(C, Id, F/A, RS, C2) ), Body0),
    wrapper(A, Id, F, W),
    append(W, Body0, Cs0),
    copy_term(Cs0, Code),
    in_types(A, Types),
    member(T, Types), closed_signature(Code, Id, T, Sig), accept(A, T, Sig), !,
    out_type(Sig, OT),
    term_size(Code, Size), length(Reach, NP),
    Info = [source(Repo, Rel, F/A), in(T), out(OT), size(Size), predicates(NP)],
    assertz(cand(T-Sig, Size, Id, Info, Code, Repo)).

reachable([], _, _, []).
reachable(Front, Pure, Defs, Reach) :-
    reach_(Front, Pure, Defs, [], Reach).
reach_([], _, _, Seen, Seen).
reach_([K|Ks], Pure, Defs, Seen, R) :-
    (   memberchk(K, Seen) -> reach_(Ks, Pure, Defs, Seen, R)
    ;   memberchk(K-Cs, Defs),
        findall(K2, ( member(C, Cs), clause_body(C, B), called(B, K2), memberchk(K2, Pure) ), Ks2),
        append(Ks, Ks2, Ks3), reach_(Ks3, Pure, Defs, [K|Seen], R) ).

% called(+Body, -Key): every name/arity a body may call, closures included
called(G, _) :- var(G), !, fail.
called(G, K) :- control(G, Gs), !, member(G1, Gs), called(G1, K).
called(G, K) :- meta_call(G, C, E), !, ( C = _>>B -> called(B, K) ; C = _/(_>>B) -> called(B, K)
                                       ; callable(C), functor(C, F, N), A is N + E, K = F/A ).
called(G, F/A) :- callable(G), functor(G, F, A).

control((A, B), [A, B]). control((A ; B), [A, B]). control((A -> B), [A, B]).
control((A *-> B), [A, B]). control(\+ A, [A]). control(not(A), [A]). control(once(A), [A]).
control(ignore(A), [A]). control(forall(A, B), [A, B]). control(findall(_, G, _), [G]).
control(findall(_, G, _, _), [G]). control(aggregate_all(_, G, _), [G]).
control(setof(_, G, _), [G1]) :- strip_carets(G, G1).
control(bagof(_, G, _), [G1]) :- strip_carets(G, G1).

% rename_clause(+Clause, +Id, +Main, +Reach, -Clause2): local names become Id__name; the main
% predicate of arity 2 becomes Id itself
rename_clause(C, Id, Main, RS, C2) :-
    clause_head(C, H), clause_body(C, B),
    rename_call(H, Id, Main, RS, H2), rename_body(B, Id, Main, RS, B2),
    ( B2 == true -> C2 = H2 ; C2 = (H2 :- B2) ).

local_name(F/A, Id, F/2, _, Id) :- A == 2, !.
local_name(F/_, Id, _, _, N) :- atomic_list_concat([Id, '__', F], N).

rename_call(G, Id, Main, RS, G2) :-
    functor(G, F, A),
    (   get_assoc(F/A, RS, _) -> local_name(F/A, Id, Main, RS, N), G =.. [_|As], G2 =.. [N|As]
    ;   G2 = G ).

rename_body(G, _, _, _, G) :- var(G), !.
rename_body(G, Id, M, RS, G2) :- control_template(G, Gs, G2, Gs2), !,
    rename_bodies(Gs, Id, M, RS, Gs2).
rename_body(G, Id, M, RS, G2) :- meta_call(G, C, E), !,
    G =.. [P, C|Rest], rename_closure(C, E, Id, M, RS, C2), G2 =.. [P, C2|Rest].
rename_body(G, Id, M, RS, G2) :- rename_call(G, Id, M, RS, G2).

rename_bodies([], _, _, _, []).
rename_bodies([G|Gs], Id, M, RS, [G2|Gs2]) :- rename_body(G, Id, M, RS, G2), rename_bodies(Gs, Id, M, RS, Gs2).

rename_closure(Ps>>B, _, Id, M, RS, Ps>>B2) :- !, rename_body(B, Id, M, RS, B2).
rename_closure(Fr/(Ps>>B), _, Id, M, RS, Fr/(Ps>>B2)) :- !, rename_body(B, Id, M, RS, B2).
rename_closure(C, E, Id, M, RS, C2) :-
    functor(C, F, K), A is K + E,
    (   get_assoc(F/A, RS, _) -> local_name(F/A, Id, M, RS, N), C =.. [_|As], C2 =.. [N|As]
    ;   C2 = C ).

control_template((A, B), [A, B], (A2, B2), [A2, B2]).
control_template((A ; B), [A, B], (A2 ; B2), [A2, B2]).
control_template((A -> B), [A, B], (A2 -> B2), [A2, B2]).
control_template((A *-> B), [A, B], (A2 *-> B2), [A2, B2]).
control_template(\+ A, [A], \+ A2, [A2]).
control_template(not(A), [A], not(A2), [A2]).
control_template(once(A), [A], once(A2), [A2]).
control_template(ignore(A), [A], ignore(A2), [A2]).
control_template(forall(A, B), [A, B], forall(A2, B2), [A2, B2]).
control_template(findall(T, G, L), [G], findall(T, G2, L), [G2]).
control_template(findall(T, G, L, R), [G], findall(T, G2, L, R), [G2]).
control_template(aggregate_all(S, G, R), [G], aggregate_all(S, G2, R), [G2]).
control_template(setof(T, G, L), [G], setof(T, G2, L), [G2]).
control_template(bagof(T, G, L), [G], bagof(T, G2, L), [G2]).

wrapper(2, _, _, []).
wrapper(3, Id, F, [(H :- B)]) :- atomic_list_concat([Id, '__', F], N),
    H =.. [Id, X-Y, Z], B =.. [N, X, Y, Z].
wrapper(1, Id, F, [(H :- (B -> R = true ; R = false))]) :- atomic_list_concat([Id, '__', F], N),
    H =.. [Id, X, R], B =.. [N, X].

in_types(2, [list(int), int, list(list(int))]).
in_types(3, [pair(list(int),list(int)), pair(int,int), pair(list(int),int), pair(int,list(int))]).
in_types(1, [int, list(int)]).

accept(A, T, Sig) :-
    pool(T, P), length(P, N),
    exclude(==(err), Sig, Ok), length(Ok, NOk), NOk * 5 >= N * 3,
    maplist(plain_data, Ok),
    sort(Ok, Distinct), Distinct = [_, _|_],             % not constant
    (   A == 1 -> memberchk(true, Ok), memberchk(false, Ok)
    ;   \+ ( forall(nth1(K, Sig, S), ( S == err ; nth1(K, P, S) )) ) ).   % not the identity

new_id(Repo, F, Id) :-
    atom_codes(Repo, RC), atom_codes(F, FC),
    clean(RC, R1), clean(FC, F1),
    atom_codes(RA, R1), atom_codes(FA, F1),
    atomic_list_concat([RA, '_', FA], Id0),
    unique(Id0, Id).
clean(Cs, Out) :- maplist([C, D]>>( code_type(C, csym) -> code_type(D0, to_lower(C)), D = D0 ; D = 0'_ ), Cs, Out0),
    ( Out0 = [C0|_], code_type(C0, digit) -> Out = [0'r|Out0] ; Out = Out0 ).
unique(Id0, Id) :-
    (   \+ used_id(Id0) -> Id = Id0
    ;   between(2, inf, K), atomic_list_concat([Id0, '_', K], Id), \+ used_id(Id) -> true ),
    assertz(used_id(Id)).

% ---------------------------------------------------------------- writing
write_dictionary(Out, Repos, Entries, Stats) :-
    maplist(file_base_name, Repos, Names),
    setup_call_cleanup(open(Out, write, S, [encoding(utf8)]),
        (   format(S, ":- encoding(utf8).~n", []),
            format(S, "% Dictionary of non-LLM algorithms harvested by harvest.pl (do not edit).~n", []),
            format(S, "% Repositories: ~w~n% ~w~n~n", [Names, Stats]),
            forall(member(E, Entries), write_entry(S, E)) ),
        close(S)).

% an entry is written with standard operators only, so it reads back without its file's op/3
write_entry(S, E) :-
    with_output_to(string(Str), portray_clause(E)),
    (   catch(term_string(T, Str), _, fail), T =@= E -> write(S, Str)
    ;   \+ \+ ( numbervars(E, 0, _),
                write_term(S, E, [quoted(true), ignore_ops(true), numbervars(true), fullstop(true), nl(true)]) ) ).
