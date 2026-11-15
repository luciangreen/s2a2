:- encoding(utf8).
/*  web.pl -- the predicates the S2A2 web app (webapp/) calls. Each takes its input as
    text, runs S2A2, and returns everything S2A2 printed, as text, in Out. A syntax error or
    an exception is returned as text too, so a call from the page always succeeds once.

      web_families(-Out)                             the 13 families, one per line
      web_family_show(+Family, -Out)                 its training pairs and test programs
      web_family(+Family, -Out)                      learn, apply to the tests, compare, prove
      web_io_synth(+Examples, +Options, -Out)        nested predicates from input/output
      web_io_prove(+Examples, +Reference, +Types, -Out)  ... then proved equal to a reference
      web_active(+Reference, +Initial, -Out)         active learning, the reference as oracle
      web_dict_synth(+Examples, -Out)                from the dictionary (neg(I-O) allowed)
      web_dict_code(+Code, -Out)                     only code: dictionary match, proof
      web_dict_search(+Query, -Out)                  entries whose name or source has Query
      web_dict_entry(+Id, -Out)                      an entry: code, behaviour, lemmas
      web_dict_run(+Id, +Input, -Out)
      web_prove(+Prog1, +Prog2, +Types, -Out)        io_proof: two programs equal
      web_fold(+Spec, +Target, +Mode, -Out)          spec to algorithm with fold/unfold
      web_types(+Program, -Out)                      proof/types
      web_mnn(+Family, -Out)                         search nodes, fixed order vs MNN order

    In the browser (SWI-Prolog compiled to WebAssembly) there are no alarms, so
    call_with_time_limit/2,3 is replaced by an inference limit of about the same length
    (web_time_shim/0).
*/
:- module(web, [ web_families/1, web_family_show/2, web_family/2, web_mnn/2, web_io_synth/3,
                 web_io_prove/4, web_active/3, web_dict_stats/1, web_dict_synth/2, web_dict_code/2,
                 web_dict_search/2, web_dict_entry/2, web_dict_run/3, web_dict_lemmas/2,
                 web_prove/4, web_fold/4, web_types/2 ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

% ---------------------------------------------------------------- time limits without alarms
:- if(exists_source(library(time))).
:- use_module(library(time)).
:- endif.
:- dynamic web_lips/1.
web_lips(50000000).

% When call_with_time_limit/2,3 is missing (library(time) is not in the WebAssembly build) or
% cannot run (no alarms), user:call_with_time_limit/2,3 count inferences instead; a module
% that could not import library(time) finds them in user.
web_time_shim :-
    (   getenv('S2A2_WEB_SHIM', _) -> true
    ;   \+ exists_source(library(time)) -> true
    ;   catch(call_with_time_limit(1, true), _, fail) -> fail
    ;   true ),
    !,
    (   current_predicate(time:call_with_time_limit/3)
    ->  catch(( abolish(time:call_with_time_limit/2), abolish(time:call_with_time_limit/3) ), _, true),
        assertz(time:(call_with_time_limit(T, G) :- web:limit_inf(T, G, time_limit_exceeded))),
        assertz(time:(call_with_time_limit(T, G, C) :- web:limit_inf(T, G, time_limit_exceeded(C))))
    ;   true ),
    assertz(user:(call_with_time_limit(T, G) :- web:limit_inf(T, G, time_limit_exceeded))),
    assertz(user:(call_with_time_limit(T, G, C) :- web:limit_inf(T, G, time_limit_exceeded(C)))).
web_time_shim.

limit_inf(T, G, Ball) :-
    web_lips(L), N is max(100000, round(T * L)),
    call_with_inference_limit(G, N, R),
    ( R == inference_limit_exceeded -> throw(Ball) ; true ).

:- web_time_shim.

:- use_module(s2a2).
:- use_module(axioms).
:- use_module(instances).
:- use_module(prover).
:- use_module(types).
:- use_module(fold).
:- use_module(io_synth).
:- use_module(io_proof).
:- use_module(io_synth_refs, []).
:- use_module(dict).
:- ensure_loaded(experiment).          % proof/4, same_algorithm/3

:- dynamic dict_loaded/0.

% ---------------------------------------------------------------- calling from the page
% web(+Goal, -Out): Goal's output (and any error) as one string; never fails
web(G, Out) :-
    with_output_to(string(Out0),
        (   catch(( call(G) -> true ; format("~n(no answer)~n") ), E, show_error(E)) )),
    Out = Out0.

show_error(E) :- message_to_codes_safe(E, S), format("~nError: ~s~n", [S]).
message_to_codes_safe(E, S) :-
    catch(( message_to_codes(E, S0) -> S = S0 ; format(codes(S), "~q", [E]) ), _, format(codes(S), "~q", [E])).
message_to_codes(E, S) :- catch(( '$messages':translate_message(E, L, []), with_output_to(codes(S), print_message_lines(current_output, '', L)) ), _, fail).

% text to terms
read_terms(Text, Ts) :-
    setup_call_cleanup(open_string(Text, S), read_all(S, Ts), close(S)).
read_all(S, Ts) :-
    read_term(S, T, []),
    ( T == end_of_file -> Ts = [] ; Ts = [T|Ts1], read_all(S, Ts1) ).

% a list of examples, written as a Prolog list or one per line
examples(Text, Exs) :-
    split_string(Text, "", " \t\n\r", [T0]),
    (   sub_string(T0, 0, 1, _, "[") , catch(term_string(L, T0), _, fail), is_list(L) -> Exs = L
    ;   split_string(T0, "\n", " \t\r,", Lines0), exclude(==(""), Lines0, Lines),
        maplist([Ln, E]>>( term_string(E, Ln) ), Lines, Exs) ).

head_name(Cs, N) :- Cs = [C|_], ( C = (H :- _) -> true ; H = C ), functor(H, N, _).

print_examples(Exs) :- forall(member(E, Exs), format("    ~q~n", [E])).

% ================================================================ families
web_families(Out) :- web(( families(Fs), forall(member(F, Fs), writeln(F)) ), Out).

web_family_show(F0, Out) :- web(family_show(F0), Out).
family_show(F0) :-
    atom_string(F, F0), axioms(F, Ax),
    format("== ~w~n~nThe reference optimiser, written before learning (axioms.pl):~n", [F]),
    show_algorithm(Ax),
    format("~nTraining pairs (the only thing S2A2 learns from):~n"),
    forall(inst(F, train, Name, Cs, T),
           (   program_from_clauses(Cs, B), apply_algorithm(Ax, B, T, A, _),
               format("~n--- ~w (targets ~w)~n  unoptimised:~n", [Name, T]), show_prog(B),
               format("  optimised:~n"), show_prog(A) )),
    format("~nTest programs (never seen in training):~n"),
    forall(inst(F, test, Name, Cs, T),
           ( program_from_clauses(Cs, B), format("~n--- ~w (targets ~w)~n", [Name, T]), show_prog(B) )).

show_prog(P) :- program_to_clauses(P, Cs),
    forall(member(C, Cs), ( copy_term(C, C1), numbervars(C1, 0, _, [singletons(true)]),
                            format("    ~W.~n", [C1, [spacing(next_argument), numbervars(true), quoted(true), portray(true)]]) )).

web_family(F0, Out) :- web(family_run(F0), Out).
family_run(F0) :-
    atom_string(F, F0), axioms(F, Ax),
    findall(pair(B, A, T), ( inst(F, train, _, Cs, T), program_from_clauses(Cs, B),
                             apply_algorithm(Ax, B, T, A, _) ), Pairs),
    length(Pairs, NP),
    format("== ~w: learning from ~w training pairs~n~n", [F, NP]),
    statistics(cputime, T0),
    (   catch(learn(Pairs, Alg), E, ( show_error(E), Alg = failed )) -> true ; Alg = failed ),
    statistics(cputime, T1), Secs is T1 - T0,
    (   Alg == failed -> writeln('learning failed')
    ;   format("Learned algorithm (~2f s):~n", [Secs]), show_algorithm(Alg) ),
    same_algorithm(Alg, Ax, Same),
    format("~nThe learned algorithm equals the reference axioms: ~w~n", [Same]),
    format("~nApplied to the test programs, which it never saw:~n"),
    forall(inst(F, test, Name, Cs, T),
           (   program_from_clauses(Cs, P0),
               apply_algorithm(Ax, P0, T, Ref, _),
               (   Alg == failed -> Got = none, Exact = false
               ;   apply_algorithm(Alg, P0, T, Got, _),
                   preds_of(P0, Fixed), ( same_program(Got, Ref, Fixed) -> Exact = true ; Exact = false ) ),
               format("~n--- ~w~n  before:~n", [Name]), show_prog(P0),
               ( Got == none -> true ; format("  after:~n"), show_prog(Got) ),
               proof(P0, Got, T, Proof),
               format("  same as the reference optimiser: ~w~n  proof that after = before: ~w~n", [Exact, Proof]) )).

web_mnn(F0, Out) :- web(mnn_run(F0), Out).
mnn_run(F0) :-
    atom_string(F, F0), axioms(F, Ax),
    findall(pair(B, A, T), ( inst(F, _, _, Cs, T), program_from_clauses(Cs, B), apply_algorithm(Ax, B, T, A, _) ), Pairs),
    families(Fs),
    format("Training the MNN on the derivations of the other families (leave ~w out)...~n", [F]),
    findall(D-P, ( member(G, Fs), G \== F, axioms(G, AG), inst(G, _, _, CG, TG), program_from_clauses(CG, BG),
                   apply_algorithm(AG, BG, TG, AA, _), P = pair(BG, AA, TG),
                   mnn(false), s2a2:limited(20, pair_derivation(P, D)) ), DPs),
    pairs_keys_values(DPs, Ds, Ps), length(Ds, ND),
    train_mnn(Ds, Ps),
    format("  trained on ~w derivations~n~n", [ND]),
    count(false, Pairs, N1, S1), count(true, Pairs, N2, S2), mnn(false), length(Pairs, NP),
    format("search nodes to find every derivation of ~w (~w programs):~n", [F, NP]),
    format("  fixed operator order: ~w nodes (~w solved)~n", [N1, S1]),
    format("  MNN operator order:   ~w nodes (~w solved)~n", [N2, S2]),
    ( N1 > 0, N2 > 0 -> R is N1 / N2, format("  speed-up: ~2fx~n", [R]) ; true ).
count(M, Pairs, N, S) :-
    mnn(M),
    foldl([pair(B, A, T), N0-S0, N9-S9]>>( reset_nodes,
              ( s2a2:limited(60, derive(B, A, T, 8, _)) -> S9 is S0 + 1, nodes(K), N9 is N0 + K ; S9 = S0, N9 = N0 ) ),
          Pairs, 0-0, N-S).

% ================================================================ input/output
web_io_synth(ExT, OptT, Out) :- web(io_synth_run(ExT, OptT), Out).
io_synth_run(ExT, OptT) :-
    examples(ExT, Exs), opts(OptT, Opts),
    format("examples:~n"), print_examples(Exs),
    signals(Exs, Sig), copy_term(Sig, Sig1), numbervars(Sig1, 0, _),
    format("~nstructural signals (they decide which hypotheses are tried):~n  ~p~n", [Sig1]),
    (   synth(f, Exs, Opts, P, report(Tree, _, Stats))
    ->  format("~nhypothesis tree:~n"), show_tree(Tree),
        format("~nprogram found (f/2):~n"), show_program(P),
        format("~nsearch: ~w~n", [Stats]),
        run_all(P, f, Exs, R), format("reproduces every example: ~w~n", [R]),
        (   catch(( to_fold_spec(P, f, SpecCs), clauses(SpecCs, S),
                    spec_to_algorithm(S, f/2, [], P0, report(St, _, Used, _, _)) ), _, fail)
        ->  format("~nhanded to fold.pl as a specification; derived by ~w (lemmas ~w):~n", [St, Used]), show(P0)
        ;   true )
    ;   format("~nno program found within the hypothesis space~n") ).

opts(T, Opts) :- ( split_string(T, "", " \t\n", [""]) -> Opts = [] ; term_string(Opts, T), is_list(Opts) ).

web_io_prove(ExT, RefT, TypesT, Out) :- web(io_prove_run(ExT, RefT, TypesT), Out).
io_prove_run(ExT, RefT, TypesT) :-
    examples(ExT, Exs), read_terms(RefT, Ref), head_name(Ref, RN), term_string(Types, TypesT),
    (   synth(f, Exs, [], P, _)
    ->  format("program found from ~w examples:~n", [Exs]), show_program(P),
        format("~nreference ~w/2:~n", [RN]), show_program(Ref),
        prove_equal(P, f, Ref, RN, Types, Proof),
        format("~nproof that f/2 = ~w/2 for every input of types ~w:~n", [RN, Types]), show_proof(Proof)
    ;   format("no program found~n") ).

web_active(RefT, InitT, Out) :- web(active_run(RefT, InitT), Out).
active_run(RefT, InitT) :-
    read_terms(RefT, Ref), head_name(Ref, RN), term_string(Init, InitT),
    nested_int_lists(2, 3, 0, 3, Pool0),
    ( Init = [I0|_], integer(I0) -> int_lists(4, 0, 4, Pool) ; Init = [I1|_], is_list(I1), I1 = [X|_], integer(X) -> int_lists(4, 0, 4, Pool) ; Pool = Pool0 ),
    format("oracle: the reference ~w/2~n", [RN]), show_program(Ref),
    format("~nstarting from the input(s) ~q, S2A2 asks the oracle only where its candidates disagree:~n", [Init]),
    (   active_synth(f, web:oracle(Ref, RN), Pool, [initial(Init)], P, active(R, examples(N), Trace, Final))
    ->  forall(member(T, Trace), format("  query: ~q~n", [T])),
        format("rounds: ~w; examples used: ~w; final check on the pool: ~w~nprogram:~n", [R, N, Final]),
        show_program(P)
    ;   format("no program found~n") ).
oracle(Ref, RN, In, Out) :- run_program(Ref, RN, In, Out).

% ================================================================ dictionary
ensure_dict :-
    (   dict_loaded -> true
    ;   dict_file('dictionary.pl', F1), dict_file('generated.pl', F2),
        load_dictionary([F1, F2]), assertz(dict_loaded) ).
dict_file(B, F) :-
    member(D, ['../dictionary/', 'dictionary/', '/s2a2/dictionary/']), atom_concat(D, B, F), exists_file(F), !.

web_dict_stats(Out) :- web(dict_stats, Out).
dict_stats :-
    ensure_dict,
    aggregate_all(count, ( dict_entry(_, I, _), memberchk(source(_, _, _), I) ), NH),
    aggregate_all(count, ( dict_entry(_, I, _), memberchk(invented(_, _), I) ), NI),
    aggregate_all(count, ( dict_entry(_, I, _), memberchk(joined(_, _), I) ), NJ),
    aggregate_all(count, dict_lemma(_, _, proved(_)), LP),
    aggregate_all(count, dict_lemma(_, _, tested(_)), LT),
    aggregate_all(count, dict_lemma(_, _, refuted(_)), LR),
    format("~w harvested, ~w invented, ~w joined; lemmas: ~w proved, ~w tested, ~w refuted~n", [NH, NI, NJ, LP, LT, LR]).

web_dict_synth(ExT, Out) :- web(dict_synth_run(ExT), Out).
dict_synth_run(ExT) :-
    ensure_dict, examples(ExT, Exs),
    format("examples (neg(...) = must not hold):~n"), print_examples(Exs),
    (   dict_synth(f, Exs, [], P, R)
    ->  ( R = dictionary(Tree) -> format("~nfound in the dictionary: ~w~n", [Tree]), describe_tree(Tree)
        ; format("~nnothing in the dictionary fits; io_synth found it~n") ),
        format("~nprogram (f/2 and every clause it needs):~n"), show_program(P)
    ;   format("~nno program found~n") ).

describe_tree(entry(Id)) :- describe(Id).
describe_tree(join(F, G)) :- format("  first:~n"), describe(F), format("  then:~n"), describe(G).
describe(Id) :- dict_entry(Id, I, _), origin(I, O), memberchk(in(T), I), memberchk(out(OT), I),
    format("    ~w : ~w -> ~w   (~w)~n", [Id, T, OT, O]).

web_dict_code(CodeT, Out) :- web(dict_code_run(CodeT), Out).
dict_code_run(CodeT) :-
    ensure_dict, read_terms(CodeT, Code), head_name(Code, N),
    format("code given (~w/2):~n", [N]), show_program(Code),
    (   dict_synth_code(Code, N, [], P, report(Type, Tree, Proof, Run))
    ->  format("~ninput type found by running it: ~w~ndictionary match: ~w~n", [Type, Tree]), describe_tree(Tree),
        format("~nprogram:~n"), show_program(P),
        format("~nrun against the code on the pool: ~w~nproof:~n", [Run]), show_proof(Proof)
    ;   format("~nno dictionary entry (or two joined) behaves like this code~n") ).

web_dict_search(Q0, Out) :- web(dict_search(Q0), Out).
dict_search(Q0) :-
    ensure_dict, string_lower(Q0, Q),
    findall(Id-I, ( dict_entry(Id, I, _), ( Q == "" -> true ; format(string(S), "~w ~w", [Id, I]), string_lower(S, SL), once(sub_string(SL, _, _, _, Q)) ) ), L),
    length(L, N), format("~w entries~n", [N]),
    forall(limit(300, member(Id-I, L)), ( origin(I, O), memberchk(in(T), I), memberchk(out(OT), I), format("~w\t~w -> ~w\t~w~n", [Id, T, OT, O]) )).
origin(I, O) :- ( memberchk(source(R, F, P), I) -> format(string(O), "~w: ~w ~w", [R, F, P])
                ; memberchk(invented(S, Fs), I) -> format(string(O), "invented: ~w ~w", [S, Fs])
                ; memberchk(joined(H, Fs), I) -> format(string(O), "joined: ~w ~w", [H, Fs]) ; O = "" ).

web_dict_entry(Id0, Out) :- web(dict_entry_show(Id0), Out).
dict_entry_show(Id0) :-
    ensure_dict, atom_string(Id, Id0),
    (   dict_entry(Id, I, _) -> true ; format("no entry ~w~n", [Id]), fail ),
    origin(I, O), memberchk(in(T), I), memberchk(out(OT), I),
    format("~w : ~w -> ~w~n~w~n", [Id, T, OT, O]),
    ( memberchk(also(A), I), A \== [] -> format("also found in: ~w~n", [A]) ; true ),
    format("~ncode:~n"), entry_program(Id, Cs), show_program(Cs),
    format("~nbehaviour on the probe inputs:~n"), pool(T, P),
    forall(member(X, P), ( dict_run(Id, X, Y) -> format("  ~q -> ~q~n", [X, Y]) ; format("  ~q -> (undefined)~n", [X]) )),
    findall(K-Ids-St, ( dict_lemma(K, Ids, St), sub_term(Id, Ids) ), Ls),
    ( Ls == [] -> true ; format("~nlemmas:~n"), forall(member(K-Ids-St, Ls), ( status_word(St, W), format("  ~w ~w: ~w~n", [K, Ids, W]) )) ).
status_word(proved(_), proved) :- !.
status_word(S, S).

web_dict_run(Id0, InT, Out) :- web(dict_run_show(Id0, InT), Out).
dict_run_show(Id0, InT) :-
    ensure_dict, atom_string(Id, Id0), term_string(In, InT),
    ( dict_run(Id, In, O) -> format("~q~n", [O]) ; format("(undefined on this input)~n") ).

web_dict_lemmas(Kind0, Out) :- web(dict_lemmas(Kind0), Out).
dict_lemmas(Kind0) :-
    ensure_dict, atom_string(Kind, Kind0),
    forall(( member(St0, [proved, tested, refuted]),
             dict_lemma(Kind, Ids, St), functor(St, St0, _) ),
           ( St = refuted(X) -> format("~w\t~w\tcounter-example ~q~n", [St0, Ids, X])
           ; St = tested(N) -> format("~w\t~w\ton ~w inputs~n", [St0, Ids, N])
           ; format("~w\t~w~n", [St0, Ids]) )).

% ================================================================ proofs and fold
web_prove(P1T, P2T, TypesT, Out) :- web(prove_run(P1T, P2T, TypesT), Out).
prove_run(P1T, P2T, TypesT) :-
    read_terms(P1T, P1), read_terms(P2T, P2), head_name(P1, N1), head_name(P2, N2),
    term_string(Types, TypesT),
    format("prove ~w/2 = ~w/2 for every input of types ~w~n~n", [N1, N2, Types]),
    prove_equal(P1, N1, P2, N2, Types, R), show_proof(R),
    (   R = proved(_) -> true
    ;   Types = [T|_], catch(pool(T, Pool), _, fail)
    ->  run_closed(P1, N1, Pool, O1), run_closed(P2, N2, Pool, O2), length(Pool, NP),
        (   nth1(K, O1, A), nth1(K, O2, B), A \=@= B
        ->  nth1(K, Pool, X), format("~ncounter-example: on ~q, ~w gives ~q and ~w gives ~q~n", [X, N1, A, N2, B])
        ;   format("~nno counter-example: they agree on all ~w probe inputs of type ~w~n", [NP, T]) )
    ;   true ).

web_fold(SpecT, TargetT, ModeT, Out) :- web(fold_run(SpecT, TargetT, ModeT), Out).
fold_run(SpecT, TargetT, ModeT) :-
    read_terms(SpecT, Cs), clauses(Cs, S), term_string(K, TargetT), term_string(Mode, ModeT),
    format("specification:~n"), show(S),
    (   spec_to_algorithm(S, K, [], P0, report(St, _Trace, Used, Att, Disc))
    ->  format("~nstrategy: ~w (attempt ~w); lemmas used: ~w~n", [St, Att, Used]),
        ( Disc == [] -> true ; format("lemmas discovered when stuck:~n"), forall(member(D, Disc), show_disc(D)) ),
        verify(S, P0, K, Mode, verdict(total(T), functional(F), typed_answers(Ty), integer_arithmetic(IA), P)),
        format("~nderived program:~n"), show(P),
        format("~ntotal for ~w: ~w; specification functional: ~w; typed answers: ~w; integer arithmetic: ~w~n", [Mode, T, F, Ty, IA]),
        catch(( bounded_equal(S, K, P, K, Mode, 4, B), format("bounded check: ~w~n", [B]) ), _, true)
    ;   format("~nno derivation found~n") ).

show_disc(D) :- copy_term(D, D1), numbervars(D1, 0, _),
    ( D1 = proved(lemma(N, L, R)) -> format("  ~w proved: ~p <=> ~p~n", [N, L, R])
    ; D1 = refuted(lemma(N, _, _), CE) -> format("  ~w refuted by ~p~n", [N, CE])
    ; format("  ~p~n", [D1]) ).

web_types(ProgT, Out) :- web(types_run(ProgT), Out).
types_run(ProgT) :-
    read_terms(ProgT, Cs), program_from_clauses(Cs, P),
    show_types(P),
    forall(( member(I, [1,2,3,4,5,6,7,8]), catch(implied_guard(P, I, J, G), _, fail) ),
           format("guard ~w of clause ~w: ~w~n", [J, I, G])).
