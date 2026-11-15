:- encoding(utf8).
/*  dict_gen.pl -- generate new dictionary entries and lemmas from the harvested dictionary.

    swipl dict_gen.pl          reads  ../dictionary/dictionary.pl  (harvest.pl)
                               writes ../dictionary/generated.pl   and ../results/dictionary.txt

    Nothing here is given an algorithm to find: every new entry is built from the entries
    already in the dictionary and kept only when it behaves differently, on the probe
    inputs, from every entry before it (observational equivalence), so the dictionary
    only grows by new behaviours.

    LEMMA PROVERS. A conjecture is made only when it holds on the probe pool, then
      1. it is run on a larger pool (every short list over a small range, and so on); a
         counter-example there refutes it, and the refutation is kept;
      2. otherwise io_proof:prove_equal/6 tries to prove it for every input of the
         declared types (unfolding, induction on lists, polynomial arithmetic, ...);
      3. a conjecture that is not refuted and not proved is kept as tested(N).
    The conjectures are
      equal(A, B)          two harvested definitions with the same behaviour (from
                           different files or repositories) are the same predicate;
      idempotent(F)        F(F(X)) = F(X)
      involution(F)        F(F(X)) = X
      commute(F, G)        G(F(X)) = F(G(X))
      equal(New, Old)      an invented or joined entry behaves like an existing one
    Proved and tested lemmas prune the joiners: F after F is not built when F is
    idempotent or an involution, and of G after F and F after G only one is built when F
    and G commute.

    INVENTORS (one entry F or test T, a scheme over it)
      map(F)        int -> X              gives  list(int) -> list(X)
      filter(T)     int -> bool           gives  list(int) -> list(int)
      count(T)      int -> bool           gives  list(int) -> int
      all(T), any(T) int -> bool          gives  list(int) -> bool
      per_sublist(F) list(int) -> X       gives  list(list(int)) -> list(X)
      fold(F)       pair(int,int) -> int  gives  list(int) -> int (from the first element)
      twice(F)      T -> T                gives  T -> T

    JOINERS (two or three entries)
      compose(F, G)   X -> G(F(X))           when F's output type is G's input type
      fork(F, G)      X -> F(X)-G(X)         same input type
      cond(T, F, G)   X -> F(X) if T(X) is true, else G(X)
*/
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(assoc)).
:- use_module(dict).
:- use_module(io_synth, [int_lists/4, nested_int_lists/5]).
:- use_module(io_proof, [prove_equal/6]).

:- initialization(main, main).

cap(per_first, 2).        % joins kept with the same first entry
cap(compose, 300).
cap(fork, 60).
cap(cond, 60).
cap(commute_per_type, 30). % entries per type tried pairwise for commutation

:- dynamic seen/2, lemma/3, kept/2.

main :-
    set_prolog_flag(stack_limit, 2 000 000 000),
    generate('../dictionary/dictionary.pl', '../dictionary/generated.pl', '../results/dictionary.txt').

generate(In, Out, Report) :-
    clear_dictionary, retractall(seen(_, _)), retractall(lemma(_, _, _)), retractall(kept(_, _)),
    load_dictionary([In]),
    harvested(Base1), length(Base1, NB),
    forall(member(Id, Base1), ( entry_key(Id, K) -> assertz(seen(K, Id)) ; true )),
    format(user_error, "harvested: ~w~n", [NB]),
    alt_lemmas, format(user_error, "alt lemmas done~n", []),
    algebra_lemmas(Base1), format(user_error, "algebra lemmas done~n", []),
    invent(Base1),
    findall(I, kept(I, invented), Inv), append(Base1, Inv, Pool0),
    by_definedness(Pool0, Pool1),
    format(user_error, "invented done~n", []),
    join(Pool1), format(user_error, "joined done~n", []),
    write_generated(Out),
    write_report(Report, NB).

% entries defined on more of their pool first, then smaller first (a stable order)
by_definedness(Ids, Sorted) :-
    findall(k(TR, NE, S, Id), ( member(Id, Ids), entry_type(Id, T, O), type_rank(T, O, TR), signature(Id, T, Sig),
                            include(==(err), Sig, Es), length(Es, NE),
                            dict_entry(Id, I, _), memberchk(size(S), I) ), Ks),
    msort(Ks, SKs), findall(Id, member(k(_, _, _, Id), SKs), Sorted).

% numbers, truth values and lists of them first; atoms and mixed data after
type_rank(I, O, 0) :- numeric(I), numeric(O), !.
type_rank(_, _, 1).
numeric(int). numeric(bool).
numeric(list(T)) :- nonvar(T), numeric(T).
numeric(pair(A, B)) :- numeric(A), numeric(B).

harvested(Ids) :-
    findall(S-Id, ( dict_entry(Id, Info, _), memberchk(source(_, _, _), Info), memberchk(size(S), Info) ), L0),
    msort(L0, L), pairs_values(L, Ids).

entry_key(Id, T-Sig) :- entry_type(Id, T, _), signature(Id, T, Sig).

% ================================================================ larger pools
big_pool(int, P) :- numlist(-6, 12, P).
big_pool(list(int), P) :- int_lists(3, -2, 3, P).
big_pool(list(list(int)), P) :- nested_int_lists(2, 2, 0, 2, P).
big_pool(pair(int,int), P) :- findall(A-B, ( between(-3, 6, A), between(-3, 6, B) ), P).
big_pool(pair(list(int),list(int)), P) :- int_lists(2, 0, 2, L), findall(A-B, ( member(A, L), member(B, L) ), P).
big_pool(pair(list(int),int), P) :- int_lists(2, -1, 2, L), findall(A-B, ( member(A, L), between(-1, 3, B) ), P).
big_pool(pair(int,list(int)), P) :- big_pool(pair(list(int),int), Q), findall(B-A, member(A-B, Q), P).

% ================================================================ lemma provers
% status(+Holds, +ProveGoal, -Status): refuted on the larger pool, else proved, else tested
lemma_status(Type, Check, P1, N1, P2, N2, OutT, Status) :-
    big_pool(Type, Big),
    (   member(X, Big), \+ call(Check, X) -> Status = refuted(X)
    ;   proof_type(Type, PT), proof_type(OutT, PO),
        (   catch(prove_equal(P1, N1, P2, N2, [PT, PO], R), _, fail), R = proved(Steps)
        ->  Status = proved(Steps)
        ;   length(Big, N), Status = tested(N) ) ).

add_lemma(K, Ids, St) :- ( lemma(K, Ids, _) -> true ; assertz(lemma(K, Ids, St)) ).

% equal(A, B) for each harvested alternative definition
alt_lemmas :-
    forall(dict_alt(Id, A, _, ACs),
           (   entry_type(Id, T, O), entry_program(Id, P1),
               lemma_status(T, same_on_alt(Id, A, ACs), P1, Id, ACs, A, O, St),
               add_lemma(equal, [Id, A], St) )).

same_on_alt(Id, A, ACs, X) :-
    run_closed(ACs, A, [X], [R]), ( dict_run(Id, X, R1) -> R1 =@= R ; R == err ).

same_out(F, G, X) :- ( dict_run(F, X, A) -> ( dict_run(G, X, B) -> A =@= B ; fail ) ; \+ dict_run(G, X, _) ).
twice_out(F, X, Y) :- dict_run(F, X, Z), dict_run(F, Z, Y).
then_out(F, G, X, Y) :- dict_run(F, X, Z), dict_run(G, Z, Y).

idem_check(F, X) :- ( twice_out(F, X, Y) -> dict_run(F, X, Y1), Y1 =@= Y ; true ).
invol_check(F, X) :- ( twice_out(F, X, Y) -> Y =@= X ; \+ dict_run(F, X, _) ).
commute_check(F, G, X) :- ( then_out(F, G, X, A) -> then_out(G, F, X, B), A =@= B ; \+ then_out(G, F, X, _) ).

endo(Id, T) :- entry_type(Id, T, O), T == O, memberchk(T, [int, list(int), list(list(int))]).

algebra_lemmas(Base) :-
    forall(( member(F, Base), endo(F, T) ),
           (   pool(T, P),
               (   forall(member(X, P), invol_check(F, X)), once(( member(X, P), dict_run(F, X, _) ))
               ->  two_prog(F, F, ff, P1), id_prog(P2),
                   lemma_status(T, invol_check(F), P1, ff, P2, id, T, St), add_lemma(involution, [F], St)
               ;   forall(member(X, P), idem_check(F, X))
               ->  two_prog(F, F, ff, P1), entry_program(F, P2),
                   lemma_status(T, idem_check(F), P1, ff, P2, F, T, St), add_lemma(idempotent, [F], St)
               ;   true ) )),
    cap(commute_per_type, CK),
    forall(member(T, [int, list(int), list(list(int))]),
           (   findall(F, ( member(F, Base), endo(F, T) ), Fs0), take(CK, Fs0, Fs),
               forall(( append(_, [F|Rest], Fs), member(G, Rest) ),
                      (   pool(T, P),
                          (   forall(member(X, P), commute_check(F, G, X)),
                              once(( member(X, P), then_out(F, G, X, _) )),
                              \+ forall(member(X, P), same_out(F, G, X))
                          ->  two_prog(F, G, fg, P1), two_prog(G, F, fg, P2),
                              lemma_status(T, commute_check(F, G), P1, fg, P2, fg, T, St),
                              add_lemma(commute, [F, G], St)
                          ;   true ) )) )).

two_prog(F, G, N, [(H :- (BF, BG))|Cs]) :-
    H =.. [N, X, Y], BF =.. [F, X, Z], BG =.. [G, Z, Y],
    entry_program(F, CF), entry_program(G, CG), append(CF, CG, Cs0), dedupe(Cs0, Cs).
id_prog([id(X, X)]).

dedupe([], []).
dedupe([C|Cs], [C|Rs]) :- exclude(==(C), Cs, Cs1), dedupe(Cs1, Rs).

take(N, L, P) :- length(L, Len), ( Len =< N -> P = L ; length(P, N), append(P, _, L) ).

holds(K, Ids) :- lemma(K, Ids, St), St \= refuted(_).

% ================================================================ adding a candidate
% try(+Id, +Info, +Clauses): keep it when its behaviour is new; when it equals an existing
% entry, conjecture the equality
try(Id, Info0, Cs, Kind) :-
    \+ dict_entry(Id, _, _),
    memberchk(in(T), Info0),
    dict_add(Id, [out(any)|Info0], Cs),
    signature(Id, T, Sig),
    (   acceptable(T, Sig)
    ->  K = T-Sig,
        (   seen(K, Old)
        ->  dict_remove(Id),
            ( Kind == invented -> equal_new(Id, Info0, Cs, Old, T) ; true ),
            fail
        ;   out_type(Sig, O), entry_program(Id, Prog), term_size(Prog, S),
            dict_remove(Id),
            Info = [out(O), size(S)|Info0],
            dict_add(Id, Info, Cs),
            assertz(seen(K, Id)), assertz(kept(Id, Kind)) )
    ;   dict_remove(Id), fail ).

acceptable(T, Sig) :-
    pool(T, P), length(P, N),
    exclude(==(err), Sig, Ok), length(Ok, NOk), NOk * 5 >= N * 3,
    maplist(plain_data, Ok),
    sort(Ok, [_, _|_]),
    \+ forall(nth1(K, Sig, S), ( S == err ; nth1(K, P, S) )).

% an invented entry that behaves like an existing one: equal(New, Old)
equal_new(Id, Info0, Cs, Old, T) :-
    dict_add(Id, [out(any)|Info0], Cs),
    entry_program(Id, P1), entry_program(Old, P2), entry_type(Old, _, O),
    lemma_status(T, same_out(Id, Old), P1, Id, P2, Old, O, St),
    dict_remove(Id),
    memberchk(invented(Sch, Fs), Info0),
    add_lemma(equal, [scheme(Sch, Fs), Old], St).

% ================================================================ inventors
invent(Base) :-
    forall(member(F, Base), invent_from(F)).

invent_from(F) :-
    entry_type(F, In, Out),
    forall(scheme(In, Out, Sch, NewIn), ( make_scheme(Sch, F, NewIn, Id, Info, Cs) -> ignore(try(Id, Info, Cs, invented)) ; true )).

scheme(int, O, map, list(int)) :- O \== bool.
scheme(int, bool, filter, list(int)).
scheme(int, bool, count, list(int)).
scheme(int, bool, all, list(int)).
scheme(int, bool, any, list(int)).
scheme(list(int), _, per_sublist, list(list(int))).
scheme(pair(int,int), int, fold, list(int)).
scheme(T, T, twice, T) :- memberchk(T, [int, list(int), list(list(int))]).

inv_id(Sch, F, Id) :- atomic_list_concat([inv, Sch, F], '_', Id).

make_scheme(map, F, T, Id, Info, [(H :- maplist(F, L, M))]) :-
    inv_id(map, F, Id), H =.. [Id, L, M], info(map, [F], T, Info).
make_scheme(per_sublist, F, T, Id, Info, [(H :- maplist(F, L, M))]) :-
    inv_id(per_sublist, F, Id), H =.. [Id, L, M], info(per_sublist, [F], T, Info).
make_scheme(filter, F, T, Id, Info, [(H :- include(K, L, M)), (KH :- KB)]) :-
    inv_id(filter, F, Id), keep(Id, F, K, KH, KB), H =.. [Id, L, M], info(filter, [F], T, Info).
make_scheme(count, F, T, Id, Info, [(H :- (include(K, L, M), length(M, N))), (KH :- KB)]) :-
    inv_id(count, F, Id), keep(Id, F, K, KH, KB), H =.. [Id, L, N], info(count, [F], T, Info).
make_scheme(all, F, T, Id, Info, [(H :- (exclude(K, L, []) -> B = true ; B = false)), (KH :- KB)]) :-
    inv_id(all, F, Id), keep(Id, F, K, KH, KB), H =.. [Id, L, B], info(all, [F], T, Info).
make_scheme(any, F, T, Id, Info, [(H :- (include(K, L, [_|_]) -> B = true ; B = false)), (KH :- KB)]) :-
    inv_id(any, F, Id), keep(Id, F, K, KH, KB), H =.. [Id, L, B], info(any, [F], T, Info).
make_scheme(fold, F, T, Id, Info, [(H :- foldl(S, Xs, X, R)), (SH :- SB)]) :-
    inv_id(fold, F, Id), atom_concat(Id, '__step', S), H =.. [Id, [X|Xs], R],
    SH =.. [S, E, A, B], SB =.. [F, A-E, B], info(fold, [F], T, Info).
make_scheme(twice, F, T, Id, Info, [(H :- (B1, B2))]) :-
    inv_id(twice, F, Id), H =.. [Id, X, Y], B1 =.. [F, X, Z], B2 =.. [F, Z, Y], info(twice, [F], T, Info).

keep(Id, F, K, KH, KB) :- atom_concat(Id, '__keep', K), KH =.. [K, X], KB =.. [F, X, true].
info(Sch, Fs, T, [invented(Sch, Fs), in(T), uses(Fs)]).

% ================================================================ joiners
join(Pool) :-
    flag(skipped_by_lemma, _, 0),
    cap(per_first, PF), cap(compose, CMax), cap(fork, FMax), cap(cond, KMax),
    flag(n_compose, _, 0), flag(n_fork, _, 0), flag(n_cond, _, 0),
    % compose
    forall(member(F, Pool),
           (   flag(per_first, _, 0),
               forall(( member(G, Pool), flag(n_compose, NC, NC), NC < CMax,
                        flag(per_first, NP, NP), NP < PF,
                        atom_concat(second_, G, KG), flag(KG, NG, NG), NG < PF,
                        composable(F, G) ),
                      (   compose_pruned(F, G) -> flag(skipped_by_lemma, S, S + 1)
                      ;   compose(F, G, Id, Info, Cs), try(Id, Info, Cs, joined)
                      ->  flag(n_compose, C1, C1 + 1), flag(per_first, P1, P1 + 1), flag(KG, G1, G1 + 1)
                      ;   true ) ) )),
    % fork
    forall(( append(_, [F|Rest], Pool), member(G, Rest), flag(n_fork, NF, NF), NF < FMax,
             entry_type(F, T, OF), entry_type(G, T, OG), OF \== bool, OG \== bool ),
           (   fork(F, G, Id, Info, Cs), try(Id, Info, Cs, joined) -> flag(n_fork, F1, F1 + 1) ; true )),
    % cond
    forall(( member(Tst, Pool), entry_type(Tst, T, bool),
             append(_, [F|Rest], Pool), entry_type(F, T, O), O \== bool,
             member(G, Rest), entry_type(G, T, O),
             flag(n_cond, NK, NK), NK < KMax ),
           (   cond(Tst, F, G, Id, Info, Cs), try(Id, Info, Cs, joined) -> flag(n_cond, K1, K1 + 1) ; true )).

composable(F, G) :-
    entry_type(F, _, O), O \== any, entry_type(G, I, _), \+ \+ I = O,
    \+ ( dict_entry(F, IF, _), memberchk(joined(_, _), IF) ),     % one level of joining
    \+ ( dict_entry(G, IG, _), memberchk(joined(_, _), IG) ).

compose_pruned(F, F) :- ( holds(idempotent, [F]) ; holds(involution, [F]) ), !.
compose_pruned(F, G) :- holds(commute, [G, F]).

compose(F, G, Id, [joined(compose, [F, G]), in(T), uses([F, G])], [(H :- (B1, B2))]) :-
    atomic_list_concat([join, F, then, G], '_', Id), entry_type(F, T, _),
    H =.. [Id, X, Y], B1 =.. [F, X, Z], B2 =.. [G, Z, Y].
fork(F, G, Id, [joined(fork, [F, G]), in(T), uses([F, G])], [(H :- (B1, B2))]) :-
    atomic_list_concat([fork, F, and, G], '_', Id), entry_type(F, T, _),
    H =.. [Id, X, A-B], B1 =.. [F, X, A], B2 =.. [G, X, B].
cond(Tst, F, G, Id, [joined(cond, [Tst, F, G]), in(T), uses([Tst, F, G])], [(H :- (BT, R == true -> BF ; BG))]) :-
    atomic_list_concat([if, Tst, then, F, else, G], '_', Id), entry_type(F, T, _),
    H =.. [Id, X, Y], BT =.. [Tst, X, R], BF =.. [F, X, Y], BG =.. [G, X, Y].

% ================================================================ output
write_generated(Out) :-
    setup_call_cleanup(open(Out, write, S, [encoding(utf8)]),
        (   format(S, ":- encoding(utf8).~n% Generated by dict_gen.pl from dictionary.pl (do not edit).~n~n", []),
            forall(kept(Id, _), ( dict_entry(Id, Info, Cs), portray_clause(S, entry(Id, Info, Cs)) )),
            nl(S),
            forall(lemma(K, Ids, St), portray_clause(S, lemma(K, Ids, St))) ),
        close(S)).

write_report(File, NB) :-
    setup_call_cleanup(open(File, write, S, [encoding(utf8)]),
        with_output_to(S, report(NB)), close(S)).

report(NB) :-
    format("Dictionary of algorithms (dictionary/dictionary.pl, dictionary/generated.pl)~n~n"),
    format("== Harvested from the repositories (harvest.pl): ~w entries~n~n", [NB]),
    findall(R, ( dict_entry(_, I, _), memberchk(source(R, _, _), I) ), Rs), msort(Rs, SRs), clumped(SRs, CR),
    forall(member(R-N, CR), format("  ~w: ~w~n", [R, N])),
    findall(T, ( dict_entry(_, I, _), memberchk(source(_, _, _), I), memberchk(in(T), I) ), Ts), msort(Ts, STs), clumped(STs, CT),
    format("~n  by input type:~n"), forall(member(T-N, CT), format("    ~w: ~w~n", [T, N])),
    format("~n== Lemmas (conjectured on the probe pool, then refuted on a larger pool, proved by io_proof, or tested)~n~n"),
    forall(member(K, [equal, idempotent, involution, commute]),
           (   aggregate_all(count, lemma(K, _, proved(_)), P),
               aggregate_all(count, lemma(K, _, tested(_)), Te),
               aggregate_all(count, lemma(K, _, refuted(_)), Rf),
               format("  ~w: ~w proved, ~w tested only, ~w refuted~n", [K, P, Te, Rf]) )),
    format("~n  proved, for example:~n"),
    forall(limit(12, lemma(K, Ids, proved(_))), format("    ~w ~w~n", [K, Ids])),
    format("~n  refuted on the larger pool, for example:~n"),
    forall(limit(6, lemma(K, Ids, refuted(X))), format("    ~w ~w: counter-example ~w~n", [K, Ids, X])),
    flag(skipped_by_lemma, SK, SK),
    format("~n  compositions not built because a lemma makes them redundant: ~w~n", [SK]),
    format("~n== Invented (inventors, one scheme over one entry)~n~n"),
    findall(Sch, ( kept(Id, invented), dict_entry(Id, I, _), memberchk(invented(Sch, _), I) ), Ss), msort(Ss, SSs), clumped(SSs, CS),
    forall(member(Sc-N, CS), format("  ~w: ~w~n", [Sc, N])),
    format("~n  the first of each scheme:~n~n"),
    forall(member(Sc-_, CS), once(( kept(Id, invented), dict_entry(Id, I, _), memberchk(invented(Sc, _), I), example(Id) ))),
    format("== Joined (joiners, two or three entries)~n~n"),
    findall(H, ( kept(Id, joined), dict_entry(Id, I, _), memberchk(joined(H, _), I) ), Hs), msort(Hs, SHs), clumped(SHs, CH),
    forall(member(Hw-N, CH), format("  ~w: ~w~n", [Hw, N])),
    format("~n  the first three of each kind:~n~n"),
    forall(member(Hw-_, CH), forall(limit(3, ( kept(Id, joined), dict_entry(Id, I, _), memberchk(joined(Hw, _), I) )), example(Id))).

example(Id) :-
    dict_entry(Id, I, _), memberchk(in(T), I), memberchk(out(O), I),
    format("  ~w : ~w -> ~w~n", [Id, T, O]),
    pool(T, P), length(P, LP), Skip is max(0, LP - 5), length(Pre, Skip), append(Pre, P5, P), take(4, P5, P4),
    forall(member(X, P4), ( dict_run(Id, X, Y) -> format("    ~w -> ~w~n", [X, Y]) ; format("    ~w -> (undefined)~n", [X]) )),
    format("~n").
