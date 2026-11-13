:- encoding(utf8).
/*  io_synth.pl -- find nested and hierarchical predicates from input/output examples.

    Given examples In-Out of an unknown predicate p(In, Out), io_synth writes a Prolog
    program for p, inventing helper predicates where one flat rule cannot express it
    (an outer map over sublists whose elements are kept by a test on the sublist's own
    minimum, a filter followed by a map followed by an aggregate, and so on). Each
    helper is a predicate of its own, so the hierarchy is visible in the program.

    Plain brute-force induction is too slow: the number of candidate programs grows
    doubly exponentially with nesting depth. io_synth uses five reductions:

      1. STRUCTURAL SIGNALS (signals/2). The shapes of the examples (length kept,
         output a subsequence, a permutation, a scalar, per-sublist behaviour, a
         shared output template) decide which hypotheses are tried at all.
      2. TOP-DOWN PROPAGATION. A hypothesis about the outer structure turns the
         examples into examples for the inner predicates, which are then solved on
         their own: map gives element pairs, filter gives kept/dropped elements,
         anti-unification of the outputs gives one sub-problem per hole. One deep
         search becomes several shallow ones.
      3. OBSERVATIONAL EQUIVALENCE. Expressions are built bottom-up by size and run on
         the examples; an expression whose outputs equal an earlier one's is dropped.
      4. TYPES. Components are typed; an argument of the wrong type is never built.
      5. ANTI-UNIFICATION. The least general generalisation of the outputs (Plotkin)
         is a template whose holes are solved separately.

    When no top-down hypothesis fits, a GENETIC ALGORITHM searches pipelines of
    components (list operations, map(E), filter(T), aggregates), with the genes
    themselves taken from the observationally distinct expressions, partial-credit
    fitness, and duplicate behaviours penalised to keep the population diverse.

    With an oracle (the original program, or a network), active_synth/6 runs a
    counter-example-guided loop: when the candidate programs disagree, it asks the
    oracle about the input that splits them most; otherwise it checks the candidate
    on a pool of inputs and adds the first counter-example.

    Every program returned has been run on every example and reproduces it.

    Main predicates
      synth(+Name, +Examples, -Program, -Report)             Examples = [In-Out, ...]
      synth(+Name, +Examples, +Options, -Program, -Report)
          options: depth(D) leaf_size(S) test_size(S) fold_size(S) exclude(Components)
                   ga(Bool) seed(N) population(N) generations(N)
      synth_nd(+Name, +Examples, +Options, -Program, -Tree)  alternatives on backtracking
      signals(+Examples, -Signals)
      ga_synth(+Name, +Examples, +Options, -Program, -Report)
      active_synth(+Name, :Oracle, +Pool, +Options, -Program, -Report)
          options: initial(N or Inputs) alternatives(K) rounds(R), plus those of synth
      agrees(+Program, +Name, :Oracle, +Inputs, -Result)     equal_on(N) | counter_example(In, Got, Want)
      run_program(+Program, +Name, +In, -Out)
      enumeration_stats(+Vars, +Envs, +Options, -Stats)
      to_fold_spec(+Program, +Name, -Spec)                   for fold.pl's spec_to_algorithm
      int_lists/4, nested_int_lists/5, show_program/1, show_tree/1
*/
:- module(io_synth, [ synth/4, synth/5, synth_nd/5, signals/2, ga_synth/5,
                      active_synth/6, agrees/5, run_program/4, run_all/4,
                      enumeration_stats/4, to_fold_spec/3, int_lists/4,
                      nested_int_lists/5, show_program/1, show_tree/1, lgg_all/3 ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(yall)).
:- use_module(library(pairs)).
:- use_module(library(assoc)).
:- use_module(library(modules)).
:- use_module(library(solution_sequences)).

:- meta_predicate active_synth(+, 2, +, +, -, -), agrees(+, +, 2, +, -).

% ================================================================ options
option_or(Opt, Opts, _) :- memberchk(Opt, Opts), !.
option_or(Opt, _, Default) :- arg(1, Opt, Default).

default_leaf_size(4).

% ================================================================ values and types
vtype(V, int) :- integer(V), !.
vtype([], list(_)) :- !.
vtype(L, list(T)) :- is_list(L), !, maplist(vtype, L, Ts), join_types(Ts, T).
vtype(V, atom) :- atom(V), !.
vtype(_, any).

join_types([], _).
join_types([T|Ts], J) :- foldl(join2, Ts, T, J).
join2(T, A, J) :- ( \+ \+ A = T -> A = T, J = A ; J = any ).

% ================================================================ components
% comp(Name, ArgTypes, ResultType): the typed building blocks of expressions.
comp(inc,   [int], int).
comp(dec,   [int], int).
comp(dbl,   [int], int).
comp(sq,    [int], int).
comp(neg,   [int], int).
comp(abs,   [int], int).
comp(half,  [int], int).
comp(mod2,  [int], int).
comp(add,   [int, int], int).
comp(sub,   [int, int], int).
comp(mul,   [int, int], int).
comp(max,   [int, int], int).
comp(min,   [int, int], int).
comp(sum,   [list(int)], int).
comp(maxl,  [list(int)], int).
comp(minl,  [list(int)], int).
comp(len,   [list(_)], int).
comp(head,  [list(T)], T).
comp(last,  [list(T)], T).
comp(rev,   [list(T)], list(T)).
comp(msort, [list(T)], list(T)).
comp(sort,  [list(T)], list(T)).
comp(tail,  [list(T)], list(T)).
comp(app,   [list(T), list(T)], list(T)).
comp(cons,  [T, list(T)], list(T)).

arith(inc). arith(dec). arith(dbl). arith(sq). arith(neg). arith(abs). arith(half).
arith(mod2). arith(add). arith(sub). arith(mul). arith(max). arith(min).

constant(c(0), int).
constant(c(1), int).
constant(c([]), list(_)).

% op_eval(+Name, +Args, -Value): fails where the component is undefined
op_eval(F, As, V) :- catch(op_eval_(F, As, V), _, fail).
op_eval_(inc,  [A], V) :- integer(A), V is A + 1.
op_eval_(dec,  [A], V) :- integer(A), V is A - 1.
op_eval_(dbl,  [A], V) :- integer(A), V is 2 * A.
op_eval_(sq,   [A], V) :- integer(A), V is A * A.
op_eval_(neg,  [A], V) :- integer(A), V is -A.
op_eval_(abs,  [A], V) :- integer(A), V is abs(A).
op_eval_(half, [A], V) :- integer(A), V is A // 2.
op_eval_(mod2, [A], V) :- integer(A), V is A mod 2.
op_eval_(add,  [A, B], V) :- integer(A), integer(B), V is A + B.
op_eval_(sub,  [A, B], V) :- integer(A), integer(B), V is A - B.
op_eval_(mul,  [A, B], V) :- integer(A), integer(B), V is A * B.
op_eval_(max,  [A, B], V) :- integer(A), integer(B), V is max(A, B).
op_eval_(min,  [A, B], V) :- integer(A), integer(B), V is min(A, B).
op_eval_(sum,  [L], V) :- int_list(L), sum_list(L, V).
op_eval_(maxl, [L], V) :- int_list(L), L \== [], max_list(L, V).
op_eval_(minl, [L], V) :- int_list(L), L \== [], min_list(L, V).
op_eval_(len,  [L], V) :- is_list(L), length(L, V).
op_eval_(head, [[H|_]], H).
op_eval_(last, [L], V) :- is_list(L), last(L, V).
op_eval_(rev,  [L], V) :- is_list(L), reverse(L, V).
op_eval_(msort, [L], V) :- is_list(L), msort(L, V).
op_eval_(sort, [L], V) :- is_list(L), sort(L, V).
op_eval_(tail, [[_|T]], T).
op_eval_(app,  [A, B], V) :- is_list(A), is_list(B), append(A, B, V).
op_eval_(cons, [A, B], [A|B]) :- is_list(B).

int_list(L) :- is_list(L), maplist(integer, L).

% ev(+Expr, +Env, -Value): Env is a list Name=Value
ev(v(N), Env, V) :- memberchk(N=V, Env).
ev(c(K), _, K).
ev(f(F, As), Env, V) :- ev_list(As, Env, Xs), op_eval(F, Xs, V).
ev(cmp(Op, A, B), Env, V) :- ev(A, Env, X), ev(B, Env, Y), ( compare_ints(Op, X, Y) -> V = true ; V = false ).
ev_list([], _, []).
ev_list([A|As], Env, [X|Xs]) :- ev(A, Env, X), ev_list(As, Env, Xs).

compare_ints(Op, X, Y) :- integer(X), integer(Y), G =.. [Op, X, Y], call(G).

expr_size(v(_), 1).
expr_size(c(_), 1).
expr_size(f(_, As), S) :- foldl([A, S0, S1]>>( expr_size(A, SA), S1 is S0 + SA ), As, 1, S).
expr_size(cmp(_, A, B), S) :- expr_size(A, SA), expr_size(B, SB), S is SA + SB + 1.

mentions(E, N) :- sub_term(T, E), T == v(N), !.

% ================================================================ bottom-up enumeration
% enum(+Vars, +Envs, +Opts, :Test, -Entry): entries e(Size, Type, Expr, Sig) in order of
% size, Sig the values on Envs (err where undefined). Each entry has a signature no
% smaller entry had (observational equivalence); on backtracking, the next one passing Test.
:- meta_predicate enum(+, +, +, 1, -).
enum(Vars, Envs, Opts, Test, E) :-
    option_or(max_size(Max), Opts, 4),
    option_or(exclude(Ex), Opts, []),
    option_or(dedupe(Dd), Opts, true),
    empty_assoc(Seen0),
    levels(1, Max, Vars, Envs, Ex, Dd, [], Seen0, Test, E).

levels(S, Max, Vars, Envs, Ex, Dd, Lv0, Seen0, Test, E) :-
    S =< Max,
    findall(T-Ex1-Sig, raw(S, Vars, Envs, Ex, Lv0, T, Ex1, Sig), Raw),
    length(Raw, NR), flag(io_candidates, C0, C0 + NR),
    keep_new(Raw, Dd, S, Seen0, Seen1, New),
    append(Lv0, [New], Lv1),
    (   member(E, New), call(Test, E)
    ;   S1 is S + 1, levels(S1, Max, Vars, Envs, Ex, Dd, Lv1, Seen1, Test, E)
    ).

keep_new([], _, _, Seen, Seen, []).
keep_new([T-E-Sig|R], Dd, S, Seen0, Seen, Out) :-
    (   all_err(Sig) -> Seen1 = Seen0, Out = Out1
    ;   Dd == true, get_assoc(Sig, Seen0, _) -> flag(io_pruned, P, P + 1), Seen1 = Seen0, Out = Out1
    ;   put_assoc(Sig, Seen0, E, Seen1), Out = [e(S, T, E, Sig)|Out1]
    ),
    keep_new(R, Dd, S, Seen1, Seen, Out1).

all_err(Sig) :- forall(member(X, Sig), X == err).

raw(1, Vars, Envs, _, _, T, v(N), Sig) :-
    member(N-T0, Vars), copy_term(T0, T),
    findall(V, ( member(Env, Envs), ( memberchk(N=V, Env) -> true ; V = err ) ), Sig).
raw(1, _, Envs, _, _, T, C, Sig) :-
    constant(C, T), C = c(K), length(Envs, NE), length(Sig, NE), maplist(=(K), Sig).
raw(S, _, _, Ex, Lv, RT, f(F, As), Sig) :-
    S > 1,
    comp(F, ATs0, RT0), \+ memberchk(F, Ex),
    copy_term(ATs0-RT0, ATs-RT),
    length(ATs, K), S1 is S - 1, parts(K, S1, Parts),
    pick_args(ATs, Parts, Lv, As, ASigs),
    sig_apply(F, ASigs, Sig).

parts(1, N, [N]) :- !, N >= 1.
parts(K, N, [P|Ps]) :- K > 1, K1 is K - 1, Max is N - K1, between(1, Max, P), N1 is N - P, parts(K1, N1, Ps).

pick_args([], [], _, [], []).
pick_args([AT|ATs], [P|Ps], Lv, [A|As], [Sg|Sgs]) :-
    nth1(P, Lv, Entries),
    member(e(_, T0, A, Sg), Entries),
    copy_term(T0, T),
    (   T = AT -> true ; flag(io_type_rejected, R, R + 1), fail ),
    pick_args(ATs, Ps, Lv, As, Sgs).

sig_apply(F, ASigs, Sig) :- transpose_sigs(ASigs, Rows), maplist(apply_row(F), Rows, Sig).
apply_row(F, Args, V) :- ( memberchk(X, Args), X == err -> V = err ; op_eval(F, Args, V) -> true ; V = err ).

transpose_sigs([S], Rows) :- !, maplist([X, [X]]>>true, S, Rows).
transpose_sigs([S1, S2], Rows) :- maplist([X, Y, [X, Y]]>>true, S1, S2, Rows).

% all entries up to a size
bank(Vars, Envs, Opts, Entries) :- findall(E, enum(Vars, Envs, Opts, [_]>>true, E), Entries).

reset_stats :- flag(io_candidates, _, 0), flag(io_pruned, _, 0), flag(io_type_rejected, _, 0).
read_stats(stats(candidates(C), pruned_equivalent(P), type_rejected(R))) :-
    flag(io_candidates, C, C), flag(io_pruned, P, P), flag(io_type_rejected, R, R).

% enumeration_stats(+Vars, +Envs, +Opts, -Stats): the size of a bank with and without
% observational-equivalence pruning
enumeration_stats(Vars, Envs, Opts, enum(with_pruning(NW, CW), without_pruning(NO, CO))) :-
    reset_stats, bank(Vars, Envs, [dedupe(true)|Opts], BW), length(BW, NW), flag(io_candidates, CW, CW),
    reset_stats, bank(Vars, Envs, [dedupe(false)|Opts], BO), length(BO, NO), flag(io_candidates, CO, CO).

% ================================================================ tests (boolean expressions)
% test_entries(+Vars, +Envs, +Opts, -Tests): cmp(Op, E1, E2) that mention x, observationally
% distinct, in order of size
test_entries(Vars, Envs, Opts, Tests) :-
    option_or(test_size(TMax), Opts, 5),
    ArgMax is TMax - 2,
    bank(Vars, Envs, [max_size(ArgMax)|Opts], B),
    include([e(_, T, _, _)]>>( T == int ), B, Ints),
    findall(S-cmp(Op, E1, E2)-Sig,
            ( member(e(S1, _, E1, G1), Ints), mentions(E1, x),
              member(e(S2, _, E2, G2), Ints), E1 \== E2,
              S is S1 + S2 + 1, S =< TMax,
              member(Op, [<, >, =<, >=, =:=, =\=]),
              maplist(cmp_val(Op), G1, G2, Sig) ),
            All0),
    keysort(All0, All),
    length(All, NA), flag(io_candidates, C0, C0 + NA),
    empty_assoc(A0), dedupe_tests(All, A0, Tests).
cmp_val(Op, X, Y, V) :- ( ( X == err ; Y == err ) -> V = err ; compare_ints(Op, X, Y) -> V = true ; V = false ).
dedupe_tests([], _, []).
dedupe_tests([_-T-Sig|R], A0, Out) :-
    (   ( memberchk(err, Sig) ; get_assoc(Sig, A0, _) ) -> flag(io_pruned, P, P + 1), Out = Out1, A1 = A0
    ;   put_assoc(Sig, A0, T, A1), Out = [T-Sig|Out1] ),
    dedupe_tests(R, A1, Out1).

% ================================================================ structural signals
signals(Exs, Signals) :-
    pairs_keys_values(Exs, Ins, Outs),
    maplist(vtype, Ins, ITs), join_types(ITs, IT),
    maplist(vtype, Outs, OTs), join_types(OTs, OT),
    findall(S, signal(Exs, Ins, Outs, IT, OT, S), Signals0),
    Signals = [in_type(IT), out_type(OT)|Signals0].

signal(_, _, Outs, _, _, constant_output) :- Outs = [O|Os], Os \== [], ground(O), maplist(==(O), Os).
signal(Exs, _, _, _, _, length_preserved) :-
    maplist([I-O]>>( is_list(I), is_list(O), length(I, N), length(O, N) ), Exs).
signal(Exs, _, _, _, _, subsequence) :- maplist([I-O]>>( is_list(I), is_list(O), subseq(O, I) ), Exs).
signal(Exs, _, _, _, _, drops_elements) :-
    member(I-O, Exs), is_list(I), is_list(O), length(I, NI), length(O, NO), NO < NI, !.
signal(Exs, _, _, _, _, permutation) :- maplist([I-O]>>( is_list(I), is_list(O), msort(I, S), msort(O, S) ), Exs).
signal(_, _, _, list(_), int, aggregate_of_list).
signal(_, _, _, list(list(_)), _, nested_input).
signal(_, _, _, list(list(_)), list(list(_)), per_sublist) :- true.
signal(Exs, _, _, _, _, empty_case(O)) :- memberchk([]-O, Exs).
signal(_, _, Outs, _, _, output_template(G)) :- lgg_all(Outs, G, _), nonvar(G), \+ ground(G), \+ is_list_skeleton(G).
signal(Exs, _, _, _, _, depth_preserved) :- maplist([I-O]>>( depth(I, D), depth(O, D) ), Exs).

is_list_skeleton(G) :- nonvar(G), G = [_|_].

subseq([], _).
subseq([X|Xs], [Y|Ys]) :- ( X == Y -> subseq(Xs, Ys) ; subseq([X|Xs], Ys) ).

depth(V, 0) :- \+ is_list(V), !.
depth([], 1) :- !.
depth(L, D) :- maplist(depth, L, Ds), max_list(Ds, M), D is M + 1.

% ================================================================ anti-unification
% lgg_all(+Terms, -G, -Holes): G is the least general generalisation of Terms (Plotkin);
% Holes is a list Var-Values, Values being the subterm of each term at that hole. The same
% tuple of subterms always gets the same variable.
lgg_all(Ts, G, Holes) :- lgg_n(Ts, G, [], Holes0), reverse(Holes0, Holes).
lgg_n(Ts, G, H0, H) :-
    Ts = [T|Rest],
    (   ground(T), maplist(==(T), Rest) -> G = T, H = H0
    ;   compound(T), functor(T, F, A),
        forall(member(X, Rest), ( compound(X), functor(X, F, A) ))
    ->  functor(G, F, A), numlist(1, A, Is),
        foldl(lgg_arg(Ts, G), Is, H0, H)
    ;   member(V-Vs, H0), Vs == Ts -> G = V, H = H0
    ;   H = [G-Ts|H0]
    ).
lgg_arg(Ts, G, I, H0, H) :- maplist(arg(I), Ts, Args), arg(I, G, GA), lgg_n(Args, GA, H0, H).

% ================================================================ synthesis
synth(Name, Exs, Program, Report) :- synth(Name, Exs, [], Program, Report).
synth(Name, Exs, Opts, Program, report(Tree, Signals, Stats)) :-
    reset_stats,
    signals(Exs, Signals),
    (   once(synth_nd(Name, Exs, Opts, Program, Tree)) -> true
    ;   option_or(ga(GA), Opts, true), GA == true,
        ga_synth(Name, Exs, Opts, Program, ga_report(Gens, Genome)),
        Tree = node(Name, ga(Genome, generations(Gens)), [])
    ),
    read_stats(Stats).

% synth_nd(+Name, +Examples, +Opts, -Program, -Tree): each answer reproduces every example
synth_nd(Name, Exs, Opts, Program, Tree) :-
    option_or(depth(D), Opts, 3),
    hyp(D, Name, Exs, Opts, Program, Tree),
    run_all(Program, Name, Exs, ok).

% hyp(+Depth, +Name, +Examples, +Opts, -Clauses, -Tree), in order of cost
hyp(_, Name, Exs, _, [C], node(Name, constant(O), [])) :-
    Exs = [_-O|R], ground(O), forall(member(_-O1, R), O1 == O),
    C =.. [Name, _, O].
hyp(_, Name, Exs, Opts, Cs, node(Name, expression(E), [])) :-
    leaf(Name, Exs, Opts, E, Cs).
hyp(D, Name, Exs, Opts, Cs, node(Name, map, [Sub])) :-
    D > 0, signals(Exs, Sg), memberchk(length_preserved, Sg),
    \+ forall(member(I-O, Exs), I == O),
    findall(X-Y, ( member(I-O, Exs), nth1(K, I, X), nth1(K, O, Y) ), Sub0), sort(Sub0, SubExs),
    SubExs \== [],
    atom_concat(Name, '_el', El), D1 is D - 1,
    (   functional(SubExs), hyp(D1, El, SubExs, Opts, ElCs, Sub)
    ;   context_leaf(El, Exs, Opts, E, ElCs),
        Sub = node(El, expression_with_context(E), [])
    ),
    emit_map(Name, El, ElCs, Cs).
hyp(D, Name, Exs, Opts, Cs, node(Name, filter(Kind, Test), [])) :-
    D > 0, signals(Exs, Sg), memberchk(subsequence, Sg), memberchk(drops_elements, Sg),
    filter_test(Exs, Opts, Kind, Test),
    emit_filter(Name, Kind, Test, Cs).
hyp(D, Name, Exs, Opts, Cs, node(Name, template(GT), Subs)) :-
    D > 0, pairs_keys_values(Exs, Ins, Outs),
    lgg_all(Outs, G, Holes), nonvar(G), Holes \== [],
    \+ ( is_list_skeleton(G), \+ fixed_length_outputs(Outs, Ins) ),
    D1 is D - 1,
    length(Holes, NH), numlist(1, NH, Is),
    maplist(hole_sub(Name, Ins, Opts, D1), Is, Holes, SubCss, Subs),
    template_goals(Is, Holes, Name, In, Goals),
    Head =.. [Name, In, G], list_to_conj(Goals, Body),
    append([[(Head :- Body)]|SubCss], Cs),
    copy_term(G, GT).
hyp(_, Name, Exs, Opts, Cs, node(Name, foldr(Base, C), [])) :-
    signals(Exs, Sg), memberchk(in_type(list(_)), Sg),
    foldr_hyp(Name, Exs, Opts, Base, C, Cs).

fixed_length_outputs(Outs, Ins) :-
    maplist(is_list, Outs), maplist(length, Outs, [N|Ns]), maplist(==(N), Ns),
    \+ ( maplist(is_list, Ins), maplist(length, Ins, [N|Ms]), maplist(==(N), Ms) ).

hole_sub(Name, Ins, Opts, D, I, _-Vals, Cs, Tree) :-
    sub_name(Name, I, SN), pairs_keys_values(SubExs, Ins, Vals),
    hyp(D, SN, SubExs, Opts, Cs, Tree).
sub_name(Name, I, SN) :- format(atom(SN), '~w_~w', [Name, I]).

template_goals([], [], _, _, []).
template_goals([I|Is], [V-_|Hs], Name, In, [G|Gs]) :-
    sub_name(Name, I, SN), G =.. [SN, In, V], template_goals(Is, Hs, Name, In, Gs).

functional(Exs) :- \+ ( member(X-Y1, Exs), member(X2-Y2, Exs), X == X2, Y1 \== Y2 ).

list_to_conj([G], G) :- !.
list_to_conj([G|Gs], (G, C)) :- list_to_conj(Gs, C).

% ---------------------------------------------------------------- leaf: one expression
leaf(Name, Exs, Opts, E, [Clause]) :-
    pairs_keys_values(Exs, Ins, Outs),
    maplist(vtype, Ins, ITs), join_types(ITs, IT),
    findall([x=I], member(I, Ins), Envs),
    default_leaf_size(LS0), option_or(leaf_size(LS), Opts, LS0),
    option_or(exclude(Ex), Opts, []),
    enum([x-IT], Envs, [max_size(LS), exclude(Ex)], sig_is(Outs), e(_, _, E, _)),
    cexpr(E, [x-X], V, Gs),
    head_clause(Name, [X], V, Gs, Clause).

sig_is(Outs, e(_, _, _, Sig)) :- Sig == Outs.

head_clause(Name, Ins, Out, Gs, Clause) :-
    append(Ins, [Out], Args), H =.. [Name|Args],
    ( Gs == [] -> Clause = H ; list_to_conj(Gs, B), Clause = (H :- B) ).

% context_leaf(+El, +OuterExs, +Opts, -E, -ctx(Hoist, Clauses)): an element expression that
% also uses the whole list l (subtract the minimum from each element). The parts that depend
% on l only are hoisted out of the recursion and computed once by the outer predicate.
context_leaf(El, Exs, Opts, E, ctx(Hoist, [Clause])) :-
    findall([x=X, l=I], ( member(I-O, Exs), nth1(K, I, X), nth1(K, O, _) ), Envs),
    findall(Y, ( member(I-O, Exs), nth1(K, O, Y), nth1(K, I, _) ), Outs),
    Envs \== [],
    findall(T, ( member(I-_, Exs), vtype(I, T) ), Ts), join_types(Ts, LT), nonvar(LT), LT = list(ET),
    default_leaf_size(LS0), option_or(leaf_size(LS), Opts, LS0), option_or(exclude(Ex), Opts, []),
    enum([x-ET, l-list(ET)], Envs, [max_size(LS), exclude(Ex)], ctx_ok(Outs), e(_, _, E, _)),
    hoist(E, E1, [], Hoist),
    ctx_env(Hoist, CtxEnv, CVs),
    cexpr(E1, [x-XV|CtxEnv], V, Gs),
    head_clause(El, [XV|CVs], V, Gs, Clause).

ctx_ok(Outs, e(_, _, E, Sig)) :- Sig == Outs, mentions(E, l), mentions(E, x).

ctx_env([], [], []).
ctx_env([CN-_|Hs], [CN-V|Es], [V|Vs]) :- ctx_env(Hs, Es, Vs).

% hoist(+E, -E1, +H0, -H): each largest subexpression that uses l but not x becomes a
% context variable cK
hoist(E, v(CN), H0, H) :- E \= v(_), mentions(E, l), \+ mentions(E, x), !,
    (   member(CN-E0, H0), E0 == E -> H = H0
    ;   length(H0, N), N1 is N + 1, format(atom(CN), 'c~w', [N1]), append(H0, [CN-E], H) ).
hoist(f(F, As), f(F, As1), H0, H) :- !, hoist_list(As, As1, H0, H).
hoist(cmp(Op, A, B), cmp(Op, A1, B1), H0, H) :- !, hoist(A, A1, H0, H1), hoist(B, B1, H1, H).
hoist(E, E, H, H).
hoist_list([], [], H, H).
hoist_list([A|As], [B|Bs], H0, H) :- hoist(A, B, H0, H1), hoist_list(As, Bs, H1, H).

% ---------------------------------------------------------------- filter
% filter_test(+Examples, +Opts, -Kind, -Test): plain tests on the element come first, then
% tests that also use the whole list (an outer predicate gating the inner one)
filter_test(Exs, Opts, Kind, Test) :-
    labels(Exs, LEs),
    findall([x=X], member(X-_-_, LEs), Envs1),
    findall([x=X, l=L], member(X-L-_, LEs), Envs2),
    findall(B, member(_-_-B, LEs), Labels),
    (   Kind = plain, test_entries([x-int], Envs1, Opts, Tests)
    ;   Kind = context, LEs = [_-L0-_|_], vtype(L0, list(int)),
        test_entries([x-int, l-list(int)], Envs2, Opts, Tests0),
        include([T-_]>>mentions(T, l), Tests0, Tests)
    ),
    member(Test-Sig, Tests), Sig == Labels,
    filter_reproduces(Kind, Test, Exs).

labels(Exs, LEs) :- findall(X-I-B, ( member(I-O, Exs), align(I, O, Bs), nth1(K, I, X), nth1(K, Bs, B) ), LEs).
align([], [], []).
align([X|Xs], [Y|Ys], [true|Bs]) :- X == Y, !, align(Xs, Ys, Bs).
align([_|Xs], Ys, [false|Bs]) :- align(Xs, Ys, Bs).

filter_reproduces(Kind, Test, Exs) :-
    forall(member(I-O, Exs), ( filter_ev(Kind, Test, I, I, O1), O1 == O )).
filter_ev(_, _, [], _, []).
filter_ev(Kind, T, [X|Xs], L, R) :-
    env_for(Kind, X, L, Env),
    ( ev(T, Env, true) -> R = [X|R1] ; R = R1 ),
    filter_ev(Kind, T, Xs, L, R1).
env_for(plain, X, _, [x=X]).
env_for(context, X, L, [x=X, l=L]).

% ---------------------------------------------------------------- foldr
% Name([], Base).  Name([X|Xs], V) :- Name(Xs, R), <V from the combiner on X and R>.
% Combiners are built bottom-up and pruned by their values on probe pairs (R, X) taken from
% the examples; each is then checked by folding it over every example input.
foldr_hyp(Name, Exs, Opts, Base, C, [BaseC, StepC]) :-
    pairs_keys_values(Exs, Ins, Outs),
    maplist(vtype, Ins, ITs), join_types(ITs, IT), nonvar(IT), IT = list(ET),
    maplist(vtype, Outs, OTs), join_types(OTs, OT), OT \== any,
    (   memberchk([]-B0, Exs) -> Bases = [B0]
    ;   OT == int -> Bases = [0, 1]
    ;   nonvar(OT), OT = list(_) -> Bases = [[]]
    ;   Bases = [] ),
    member(Base, Bases),
    findall(X, ( member(I, Ins), member(X, I) ), Xs0), sort(Xs0, Xs1), take(5, Xs1, Xs),
    sort([Base|Outs], Rs1), take(5, Rs1, Rs),
    findall([r=R, x=X], ( member(R, Rs), member(X, Xs) ), Envs), Envs \== [],
    option_or(fold_size(FS), Opts, 5), option_or(exclude(Ex), Opts, []),
    enum([r-OT, x-ET], Envs, [max_size(FS), exclude(Ex)], fold_ok(OT, Base, Exs), e(_, _, C, _)),
    BaseC =.. [Name, [], Base],
    cexpr(C, [r-R1, x-X1], V, Gs),
    Rec =.. [Name, Xs2, R1],
    head_clause(Name, [[X1|Xs2]], V, [Rec|Gs], StepC).

fold_ok(OT, Base, Exs, e(_, T, C, _)) :-
    \+ \+ T = OT, mentions(C, r), fold_reproduces(C, Base, Exs).
fold_reproduces(C, Base, Exs) :- forall(member(I-O, Exs), ( foldr_ev(C, Base, I, V), V == O )).
foldr_ev(_, Base, [], Base).
foldr_ev(C, Base, [X|Xs], V) :- foldr_ev(C, Base, Xs, R), ev(C, [r=R, x=X], V).

take(N, L, T) :- length(L, Len), ( Len =< N -> T = L ; length(T, N), append(T, _, L) ).

% ================================================================ emitting code
% cexpr(+Expr, +Env, -Value, -Goals): Env is a list Name-Var. Arithmetic subtrees become one
% is/2; list constructors become terms; other components become library calls.
cexpr(v(N), Env, V, []) :- memberchk(N-V, Env), !.
cexpr(c(K), _, K, []) :- !.
cexpr(E, Env, V, Gs) :- E = f(F, _), arith(F), !, carith(E, Env, AE, Gs0), append(Gs0, [V is AE], Gs).
cexpr(f(cons, [A, B]), Env, [VA|VB], Gs) :- !, cexpr(A, Env, VA, G1), cexpr(B, Env, VB, G2), append(G1, G2, Gs).
cexpr(f(F, As), Env, V, Gs) :- !, cexpr_list(As, Env, Vs, G0), goal_of(F, Vs, V, G), append(G0, [G], Gs).
cexpr(cmp(Op, A, B), Env, true, Gs) :-
    carith(A, Env, AA, G1), carith(B, Env, BB, G2), T =.. [Op, AA, BB], append([G1, G2, [T]], Gs).

cexpr_list([], _, [], []).
cexpr_list([A|As], Env, [V|Vs], Gs) :- cexpr(A, Env, V, G1), cexpr_list(As, Env, Vs, G2), append(G1, G2, Gs).

carith(v(N), Env, V, []) :- !, memberchk(N-V, Env).
carith(c(K), _, K, []) :- !.
carith(f(F, As), Env, AE, Gs) :- arith(F), !, carith_list(As, Env, Xs, Gs), arith_term(F, Xs, AE).
carith(E, Env, V, Gs) :- cexpr(E, Env, V, Gs).
carith_list([], _, [], []).
carith_list([A|As], Env, [X|Xs], Gs) :- carith(A, Env, X, G1), carith_list(As, Env, Xs, G2), append(G1, G2, Gs).

arith_term(inc, [A], A + 1).
arith_term(dec, [A], A - 1).
arith_term(dbl, [A], 2 * A).
arith_term(sq, [A], A * A).
arith_term(neg, [A], -A).
arith_term(abs, [A], abs(A)).
arith_term(half, [A], A // 2).
arith_term(mod2, [A], A mod 2).
arith_term(add, [A, B], A + B).
arith_term(sub, [A, B], A - B).
arith_term(mul, [A, B], A * B).
arith_term(max, [A, B], max(A, B)).
arith_term(min, [A, B], min(A, B)).

goal_of(sum, [A], V, sum_list(A, V)).
goal_of(maxl, [A], V, max_list(A, V)).
goal_of(minl, [A], V, min_list(A, V)).
goal_of(len, [A], V, length(A, V)).
goal_of(head, [A], V, A = [V|_]).
goal_of(last, [A], V, last(A, V)).
goal_of(rev, [A], V, reverse(A, V)).
goal_of(msort, [A], V, msort(A, V)).
goal_of(sort, [A], V, sort(A, V)).
goal_of(tail, [A], V, A = [_|V]).
goal_of(app, [A, B], V, append(A, B, V)).

% context goals for hoisted expressions over the list L
ctx_goals([], _, [], []).
ctx_goals([_-E|Hs], L, [V|Vs], Gs) :- cexpr(E, [l-L], V, G1), ctx_goals(Hs, L, Vs, G2), append(G1, G2, Gs).

% emit_map(+Name, +El, +ElClauses, -Clauses)
%   Name([], []).
%   Name([X|Xs], [Y|Ys]) :- El(X, Y), Name(Xs, Ys).
% With hoisted context, ctx(Hoist, ElClauses), the context is computed once:
%   Name([], []).
%   Name([X|Xs], R) :- <context goals on [X|Xs]>, Name_each([X|Xs], C1..Ck, R).
%   Name_each([], C1..Ck, []).
%   Name_each([X|Xs], C1..Ck, [Y|Ys]) :- El(X, C1..Ck, Y), Name_each(Xs, C1..Ck, Ys).
emit_map(Name, El, ctx(Hoist, ElCs), Cs) :- !,
    atom_concat(Name, '_each', Each),
    L = [_|_], ctx_goals(Hoist, L, CVs, CtxGs),
    append([L|CVs], [R], OArgs), OCall =.. [Each|OArgs],
    H0 =.. [Name, [], []], H1 =.. [Name, L, R],
    append(CtxGs, [OCall], B1), list_to_conj(B1, Body1),
    length(Hoist, NC), length(CVs2, NC),
    append([[]|CVs2], [[]], EArgs0), E0 =.. [Each|EArgs0],
    append([[X|Xs]|CVs2], [[Y|Ys]], EArgs1), E1 =.. [Each|EArgs1],
    append([X|CVs2], [Y], ElArgs), ElCall =.. [El|ElArgs],
    append([Xs|CVs2], [Ys], RecArgs), Rec =.. [Each|RecArgs],
    copy_term((H1 :- Body1), Outer),
    append([H0, Outer, E0, (E1 :- ElCall, Rec)], ElCs, Cs).
emit_map(Name, El, ElCs, Cs) :-
    H0 =.. [Name, [], []], H1 =.. [Name, [X|Xs], [Y|Ys]],
    ElCall =.. [El, X, Y], Rec =.. [Name, Xs, Ys],
    append([H0, (H1 :- ElCall, Rec)], ElCs, Cs).

% emit_filter(+Name, +Kind, +Test, -Clauses): the test is a predicate of its own
%   plain:   Name([], []).
%            Name([X|Xs], R) :- ( Name_test(X) -> R = [X|R1] ; R = R1 ), Name(Xs, R1).
%   context: Name([], []).
%            Name([X|Xs], R) :- <context goals on [X|Xs]>, Name_sel([X|Xs], C1..Ck, R).
%            Name_sel([], C1..Ck, []).
%            Name_sel([X|Xs], C1..Ck, R) :- ( Name_test(X, C1..Ck) -> R = [X|R1] ; R = R1 ),
%                                          Name_sel(Xs, C1..Ck, R1).
emit_filter(Name, plain, Test, Cs) :-
    atom_concat(Name, '_test', TN),
    cexpr(Test, [x-TX], _, TGs), list_to_conj(TGs, TB), TH =.. [TN, TX],
    H0 =.. [Name, [], []], H1 =.. [Name, [X|Xs], R],
    TC =.. [TN, X], Rec =.. [Name, Xs, R1],
    Cs = [H0, (H1 :- ( TC -> R = [X|R1] ; R = R1 ), Rec), (TH :- TB)].
emit_filter(Name, context, Test, Cs) :-
    atom_concat(Name, '_test', TN), atom_concat(Name, '_sel', SN),
    hoist(Test, T1, [], Hoist),
    L = [_|_], ctx_goals(Hoist, L, CVs, CtxGs),
    append([L|CVs], [R], SArgs), SCall =.. [SN|SArgs],
    H0 =.. [Name, [], []], H1 =.. [Name, L, R],
    append(CtxGs, [SCall], B1), list_to_conj(B1, Body1),
    copy_term((H1 :- Body1), Outer),
    ctx_env(Hoist, CEnv, TCVs),
    cexpr(T1, [x-TX|CEnv], _, TGs), list_to_conj(TGs, TB), TH =.. [TN, TX|TCVs],
    length(Hoist, NC), length(CVs2, NC),
    append([[]|CVs2], [[]], S0Args), S0 =.. [SN|S0Args],
    append([[X|Xs]|CVs2], [R2], S1Args), S1 =.. [SN|S1Args],
    TC =.. [TN, X|CVs2],
    append([Xs|CVs2], [R3], RecArgs), Rec =.. [SN|RecArgs],
    Cs = [H0, Outer, S0, (S1 :- ( TC -> R2 = [X|R3] ; R2 = R3 ), Rec), (TH :- TB)].

% ================================================================ running programs
% run_program(+Clauses, +Name, +In, -Out): first answer, within an inference limit
run_program(Cs, Name, In, Out) :- run_inputs(Cs, Name, [In], [R]), R \== err, Out = R.

% run_inputs(+Clauses, +Name, +Inputs, -Results): err where the call fails, throws or runs
% past the inference limit
run_inputs(Cs, Name, Ins, Rs) :-
    in_temporary_module(M,
        forall(member(C, Cs), assertz(M:C)),
        maplist(io_synth:run1(M, Name), Ins, Rs)).
run1(M, Name, In, R) :-
    G =.. [Name, In, Out],
    (   catch(call_with_inference_limit(once(M:G), 200000, Lim), _, fail),
        Lim \== inference_limit_exceeded
    ->  R = Out ; R = err ).

% run_all(+Clauses, +Name, +Examples, -Result): ok, or differs(In, Got, Wanted)
run_all(Cs, Name, Exs, Result) :-
    pairs_keys_values(Exs, Ins, Outs), run_inputs(Cs, Name, Ins, Rs),
    (   nth1(K, Outs, O), nth1(K, Rs, R), R \=@= O -> nth1(K, Ins, I), Result = differs(I, R, O)
    ;   Result = ok ).

% agrees(+Program, +Name, :Oracle, +Inputs, -Result): equal_on(N) or counter_example(In, Got, Want)
agrees(Cs, Name, Oracle, Ins, Result) :-
    run_inputs(Cs, Name, Ins, Rs),
    maplist(oracle_out(Oracle), Ins, Ws),
    (   nth1(K, Ws, W), nth1(K, Rs, R), R \=@= W -> nth1(K, Ins, I), Result = counter_example(I, R, W)
    ;   length(Ins, N), Result = equal_on(N) ).
oracle_out(Oracle, In, W) :- ( catch(call(Oracle, In, W0), _, fail) -> W = W0 ; W = err ).

% ================================================================ genetic algorithm
% A genome is a list of genes applied in order: op(F) (a list operation or aggregate),
% map(E), filter(T) and scalar(E). E and T are the observationally distinct expressions and
% tests over x on probe values, so no two genes behave alike there.
ga_synth(Name, Exs, Opts, Program, ga_report(Gen, Genome)) :-
    option_or(seed(Seed), Opts, 1), rng_seed(Seed),
    option_or(population(PN), Opts, 80), option_or(generations(GMax), Opts, 150),
    pairs_keys_values(Exs, Ins, _), maplist(vtype, Ins, ITs), join_types(ITs, IT),
    genes(Opts, Genes),
    length(Pop0, PN), maplist(random_genome(Genes, IT), Pop0),
    ga_loop(0, GMax, Genes, IT, Exs, Pop0, Gen, Best),
    minimise(Best, IT, Exs, Genome),
    emit_genome(Name, Genome, Program).

genes(Opts, Genes) :-
    option_or(exclude(Ex), Opts, []),
    numlist(-3, 6, Probe), findall([x=X], member(X, Probe), Envs),
    bank([x-int], Envs, [max_size(2), exclude(Ex)], B),
    findall(E, ( member(e(_, T, E, _), B), T == int, E \= v(_), E \= c(_) ), Es),
    test_entries([x-int], Envs, [test_size(4), exclude(Ex)], Ts0),
    findall(T, member(T-_, Ts0), Ts),
    findall(op(F), ( member(F, [rev, msort, sort, tail, sum, maxl, minl, len, head, last]), \+ memberchk(F, Ex) ), Ops),
    findall(map(E), member(E, Es), Maps),
    findall(filter(T), member(T, Ts), Filters),
    findall(scalar(E), member(E, Es), Scalars),
    append([Ops, Maps, Filters, Scalars], Genes).

gene_type(op(F), In, Out) :- comp(F, [A0], R0), copy_term(A0-R0, A-R), A = In, Out = R.
gene_type(map(_), list(int), list(int)).
gene_type(filter(_), list(int), list(int)).
gene_type(scalar(_), int, int).

well_typed(Genome, IT, OT) :- copy_term(IT, T0), well_typed_(Genome, T0, OT).
well_typed_([], T, T).
well_typed_([G|Gs], T0, T) :- nonvar(T0), gene_type(G, T0, T1), well_typed_(Gs, T1, T).

random_genome(Genes, IT, G) :-
    rng_between(1, 4, N), length(G0, N), maplist(random_gene(Genes), G0),
    ( well_typed(G0, IT, _) -> G = G0 ; random_genome(Genes, IT, G) ).

random_gene(Genes, X) :- rng_member(X, Genes).

% A small linear congruential generator, so a seed gives the same run on every SWI-Prolog
% build (the built-in generator differs between builds with and without GMP).
rng_seed(S) :- X is S mod 2147483648, nb_setval(io_synth_rng, X).
rng_next(X) :-
    ( nb_current(io_synth_rng, X0) -> true ; X0 = 1 ),
    X is (1103515245 * X0 + 12345) mod 2147483648, nb_setval(io_synth_rng, X).
rng_between(L, H, V) :- rng_next(X), V is L + (X >> 8) mod (H - L + 1).
rng_member(E, List) :- length(List, N), rng_between(1, N, I), nth1(I, List, E).
rng_float(F) :- rng_next(X), F is X / 2147483648.
step_name(Name, I, G, S-G) :- format(atom(S), '~w_s~w', [Name, I]).
member_of(L, X) :- member(X, L).

run_gene(op(F), V0, V) :- op_eval(F, [V0], V).
run_gene(map(E), V0, V) :- is_list(V0), maplist(map_ev(E), V0, V).
run_gene(filter(T), V0, V) :- is_list(V0), include(test_ev(T), V0, V).
run_gene(scalar(E), V0, V) :- ev(E, [x=V0], V).
map_ev(E, X, Y) :- ev(E, [x=X], Y).
test_ev(T, X) :- ev(T, [x=X], true).
run_genome(G, In, Out) :- ( foldl(run_gene, G, In, Out0) -> Out = Out0 ; Out = err ).

% fitness: partial credit per example, minus a little per gene
fitness(G, IT, Exs, F-Outs) :-
    (   well_typed(G, IT, _)
    ->  findall(S-R, ( member(I-O, Exs), run_genome(G, I, R), score(R, O, S) ), SRs),
        pairs_keys_values(SRs, Ss, Outs),
        sum_list(Ss, T), length(Exs, N), length(G, L), F is T / N - 0.01 * L
    ;   F = 0, Outs = none ).

score(R, O, 1) :- R == O, !.
score(R, O, S) :- integer(R), integer(O), !, S is 0.5 / (1 + abs(R - O)).
score(R, O, S) :- is_list(R), is_list(O), !,
    length(R, LR), length(O, LO), M is max(LR, LO),
    ( M =:= 0 -> S = 1 ; common(R, O, C), S is 0.5 * C / M ).
score(_, _, 0).
common([], _, 0).
common([X|Xs], Ys, N) :- ( selectchk(X, Ys, Ys1) -> common(Xs, Ys1, N0), N is N0 + 1 ; common(Xs, Ys, N) ).

exact(G, Exs) :- forall(member(I-O, Exs), ( run_genome(G, I, R), R == O )).

ga_loop(Gen, GMax, Genes, IT, Exs, Pop, GenOut, Best) :-
    findall(F-Os-G, ( member(G, Pop), fitness(G, IT, Exs, F-Os) ), Scored0),
    diversity(Scored0, Scored),
    (   member(_-_-G, Scored), exact(G, Exs) -> GenOut = Gen, Best = G
    ;   Gen < GMax,
        map_list_to_pairs([F-_-_, F]>>true, Scored, Keyed0),
        keysort(Keyed0, Asc), reverse(Asc, Desc), pairs_values(Desc, Sorted),
        Sorted = [_-_-E1, _-_-E2|_],
        length(Pop, PN), N is PN - 2, length(Kids, N),
        maplist(child(Genes, IT, Sorted), Kids),
        Gen1 is Gen + 1,
        ga_loop(Gen1, GMax, Genes, IT, Exs, [E1, E2|Kids], GenOut, Best)
    ).

% observational equivalence in the population: an individual whose outputs on the examples
% equal those of a fitter (or equally fit and shorter) one loses 0.1
diversity(Scored0, Scored) :-
    map_list_to_pairs(div_key, Scored0, K0), keysort(K0, Asc), reverse(Asc, Desc),
    pairs_values(Desc, Ordered), empty_assoc(A0), div_pass(Ordered, A0, Scored).
div_key(F-_-G, F-NL) :- length(G, L), NL is -L.
div_pass([], _, []).
div_pass([F-Os-G|R], A0, [F1-Os-G|R1]) :-
    (   Os == none -> F1 = F, A1 = A0
    ;   get_assoc(Os, A0, _) -> F1 is F - 0.1, A1 = A0
    ;   F1 = F, put_assoc(Os, A0, t, A1) ),
    div_pass(R, A1, R1).

child(Genes, IT, Sorted, K) :-
    tournament(Sorted, P1), tournament(Sorted, P2),
    rng_float(R1), ( R1 < 0.7 -> crossover(P1, P2, K0) ; K0 = P1 ),
    rng_float(R2), ( R2 < 0.4 -> mutate(Genes, K0, K1) ; K1 = K0 ),
    (   K1 \== [], length(K1, L), L =< 6, well_typed(K1, IT, _) -> K = K1
    ;   random_genome(Genes, IT, K) ).

% tournament of three: Sorted is fittest first
tournament(Sorted, G) :-
    length(Sorted, N), findall(I, ( between(1, 3, _), rng_between(1, N, I) ), Is),
    min_list(Is, Best), nth1(Best, Sorted, _-_-G).

% one-point crossover: a prefix of one parent and a suffix of the other
crossover(A, B, C) :-
    length(A, LA), length(B, LB),
    rng_between(0, LA, I), rng_between(0, LB, J),
    length(A1, I), append(A1, _, A),
    length(B0, J), append(B0, B2, B),
    append(A1, B2, C).

% mutation: replace, insert or delete one gene
mutate(Genes, G, M) :-
    rng_between(1, 3, K), length(G, L),
    (   K =:= 1, L > 0 -> rng_between(1, L, P), rng_member(X, Genes), nth1(P, G, _, Rest), nth1(P, M, X, Rest)
    ;   K =:= 2 -> rng_between(0, L, P), rng_member(X, Genes), length(Pre, P), append(Pre, Post, G), append(Pre, [X|Post], M)
    ;   L > 1 -> rng_between(1, L, P), nth1(P, G, _, M)
    ;   M = G ).

% drop runs of consecutive genes (shortest first) while every example is still reproduced;
% a run such as "halve, then double" only goes as a whole
minimise(G, IT, Exs, M) :-
    length(G, L), L1 is L - 1,
    (   between(1, L1, K), length(Run, K), append(Pre, Rest, G), append(Run, Post, Rest),
        append(Pre, Post, G1), well_typed(G1, IT, _), exact(G1, Exs)
    ->  minimise(G1, IT, Exs, M)
    ;   M = G ).

% emit_genome(+Name, +Genome, -Clauses): Name(X0, Xn) :- Name_s1(X0, X1), ..., Name_sn(Xn-1, Xn).
emit_genome(Name, Genome, Cs) :-
    length(Genome, N), N1 is N + 1, length(Vs, N1), Vs = [V0|_], last(Vs, VN),
    numlist(1, N, Is),
    maplist(step_name(Name), Is, Genome, Steps),
    chain_goals(Steps, Vs, Goals), list_to_conj(Goals, Body),
    Head =.. [Name, V0, VN],
    maplist([S-G, GCs]>>gene_clauses(S, G, GCs), Steps, GCss),
    append([[(Head :- Body)]|GCss], Cs).
chain_goals([], [_], []).
chain_goals([S-_|Ss], [A, B|Vs], [G|Gs]) :- G =.. [S, A, B], chain_goals(Ss, [B|Vs], Gs).

gene_clauses(S, op(F), [(H :- G)]) :- goal_of(F, [A], B, G), H =.. [S, A, B].
gene_clauses(S, map(E), Cs) :-
    atom_concat(S, '_el', El), cexpr(E, [x-X], V, Gs), head_clause(El, [X], V, Gs, C),
    emit_map(S, El, [C], Cs).
gene_clauses(S, filter(T), Cs) :- emit_filter(S, plain, T, Cs).
gene_clauses(S, scalar(E), [C]) :- cexpr(E, [x-X], V, Gs), head_clause(S, [X], V, Gs, C).

% ================================================================ active learning (CEGIS)
% active_synth(+Name, :Oracle, +Pool, +Opts, -Program, -Report)
%   Oracle(In, Out) is the black box; Pool the inputs it may be asked about, smallest first.
%   Each round collects up to alternatives(K) candidate programs for the examples so far.
%   If they behave differently on the pool, the oracle is asked about the pool input on which
%   they give the most different answers (a distinguishing input); otherwise the one candidate
%   is checked against the oracle on the pool, and the first counter-example is added.
%   Report = active(Rounds, examples(NExamples), Trace, Final)
active_synth(Name, Oracle, Pool0, Opts, Program, active(Rounds, examples(NE), Trace, Final)) :-
    include(defined_on(Oracle), Pool0, Pool),
    option_or(initial(Init0), Opts, 2),
    (   is_list(Init0) -> Init = Init0 ; take(Init0, Pool, Init) ),
    maplist(ask(Oracle), Init, Exs0),
    option_or(rounds(Max), Opts, 20),
    active_loop(1, Max, Name, Oracle, Pool, Opts, Exs0, Program, Trace, Rounds, Exs, Final),
    length(Exs, NE).

defined_on(Oracle, In) :- oracle_out(Oracle, In, W), W \== err.
ask(Oracle, In, In-Out) :- call(Oracle, In, Out), !.

active_loop(R, Max, Name, Oracle, Pool, Opts, Exs, Program, Trace, Rounds, ExsF, Final) :-
    R =< Max,
    option_or(alternatives(K), Opts, 4),
    findall(P, limit(K, synth_nd(Name, Exs, Opts, P, _)), Ps), Ps \== [],
    findall(Rs-P, ( member(P, Ps), run_inputs(P, Name, Pool, Rs) ), RPs0),
    distinct_behaviours(RPs0, RPs),
    (   RPs = [_, _|_]
    ->  distinguishing(RPs, Pool, In), ask(Oracle, In, Ex),
        Trace = [distinguish(Ex, candidates(N))|T1], length(RPs, N),
        R1 is R + 1,
        active_loop(R1, Max, Name, Oracle, Pool, Opts, [Ex|Exs], Program, T1, Rounds, ExsF, Final)
    ;   RPs = [_-P1], agrees(P1, Name, Oracle, Pool, Res),
        (   Res = equal_on(_)
        ->  Program = P1, Trace = [], Rounds = R, ExsF = Exs, Final = Res
        ;   Res = counter_example(I, _, W),
            Trace = [counter_example(I-W)|T1], R1 is R + 1,
            active_loop(R1, Max, Name, Oracle, Pool, Opts, [I-W|Exs], Program, T1, Rounds, ExsF, Final)
        )
    ).

distinct_behaviours(RPs0, RPs) :- foldl(add_behaviour, RPs0, [], RPsR), reverse(RPsR, RPs).
add_behaviour(Rs-P, Acc, Acc1) :- ( memberchk(Rs0-_, Acc), Rs0 =@= Rs -> Acc1 = Acc ; Acc1 = [Rs-P|Acc] ).

% the pool input with the most distinct candidate answers; the first (smallest) on a tie
distinguishing(RPs, Pool, In) :-
    length(Pool, N), numlist(1, N, Ks),
    findall(NegD-K, ( member(K, Ks), findall(V, ( member(Rs-_, RPs), nth1(K, Rs, V) ), Vs),
                      sort(Vs, Ds), length(Ds, D), D > 1, NegD is -D ), Scored),
    keysort(Scored, [_-KB|_]), nth1(KB, Pool, In).

% ================================================================ hand-over to fold.pl
% to_fold_spec(+Program, +Name, -Spec): Program as a specification for fold.pl's
% spec_to_algorithm: append/3 becomes the user predicate app/3 (whose definition is added),
% and only is/2, comparisons, =/2 and the program's own predicates may occur.
to_fold_spec(Cs, _Name, Spec) :-
    findall(N/A, ( member(C, Cs), ( C = (H :- _) -> true ; H = C ), functor(H, N, A) ), Own0), sort(Own0, Own),
    maplist(fold_clause(Own), Cs, Cs1),
    (   sub_term(T, Cs1), compound(T), functor(T, app, 3)
    ->  append(Cs1, [app([], L, L), (app([H1|T1], L1, [H1|R1]) :- app(T1, L1, R1))], Spec)
    ;   Spec = Cs1 ).
fold_clause(Own, (H :- B), (H :- B1)) :- !, fold_body(Own, B, B1).
fold_clause(_, H, H).
fold_body(Own, (A, B), (A1, B1)) :- !, fold_body(Own, A, A1), fold_body(Own, B, B1).
fold_body(_, append(X, Y, Z), app(X, Y, Z)) :- !.
fold_body(Own, G, G) :-
    functor(G, F, A),
    (   memberchk(F/A, [(is)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (=:=)/2, (=\=)/2, (=)/2]) -> true
    ;   memberchk(F/A, Own) ).

% ================================================================ input pools
% int_lists(+MaxLen, +Lo, +Hi, -Lists): every list of length 0..MaxLen over Lo..Hi, shortest first
int_lists(MaxLen, Lo, Hi, Ls) :-
    findall(L, ( between(0, MaxLen, N), length(L, N), maplist(between(Lo, Hi), L) ), Ls).
% nested_int_lists(+MaxOuter, +MaxInner, +Lo, +Hi, -Lists)
nested_int_lists(MaxO, MaxI, Lo, Hi, Ls) :-
    int_lists(MaxI, Lo, Hi, Inner),
    findall(L, ( between(0, MaxO, N), length(L, N), maplist(member_of(Inner), L) ), Ls).

% ================================================================ display
show_program(Cs) :- forall(member(C, Cs), show_clause(C)).
show_clause(C) :-
    with_output_to(string(S), portray_clause(C)), split_string(S, "\n", "", Ls),
    forall(( member(L, Ls), L \== "" ), format("    ~s~n", [L])).

show_tree(T) :- show_tree(T, 4).
show_tree(node(N, K, Subs), I) :-
    kind_atom(K, A), format("~*c~w: ~w~n", [I, 0' , N, A]),
    I1 is I + 2, forall(member(S, Subs), show_tree(S, I1)).

kind_atom(constant(O), A) :- format(atom(A), "constant ~q", [O]).
kind_atom(expression(E), A) :- pp(E, P), format(atom(A), "expression ~w", [P]).
kind_atom(expression_with_context(E), A) :- pp(E, P), format(atom(A), "expression on the element x and its list l: ~w", [P]).
kind_atom(map, 'map: each element by the sub-predicate').
kind_atom(filter(K, T), A) :- pp(T, P), format(atom(A), "filter (~w): keep x when ~w", [K, P]).
kind_atom(template(G), A) :- copy_term(G, G1), numbervars(G1, 0, _), format(atom(A), "template ~p from anti-unification of the outputs", [G1]).
kind_atom(foldr(B, C), A) :- pp(C, P), format(atom(A), "foldr: [] gives ~q, [x|xs] gives ~w with r the result for xs", [B, P]).
kind_atom(ga(G, generations(N)), A) :- maplist(pp_gene, G, Ps), atomic_list_concat(Ps, ' then ', S),
    format(atom(A), "genetic algorithm, generation ~w: ~w", [N, S]).

pp_gene(op(F), A) :- comp_label(F, A).
pp_gene(map(E), A) :- pp(E, P), format(atom(A), "map(~w)", [P]).
pp_gene(filter(T), A) :- pp(T, P), format(atom(A), "filter(~w)", [P]).
pp_gene(scalar(E), A) :- pp(E, P), format(atom(A), "~w", [P]).

pp(v(N), N) :- !.
pp(c(K), A) :- !, format(atom(A), "~q", [K]).
pp(f(F, As), A) :- arith(F), !, maplist(pp, As, Ps), arith_term(F, Ps, T), format(atom(A), "(~w)", [T]).
pp(f(cons, [X, Y]), A) :- !, pp(X, PX), pp(Y, PY), format(atom(A), "[~w|~w]", [PX, PY]).
pp(f(F, As), A) :- !, comp_label(F, L), maplist(pp, As, Ps), atomic_list_concat(Ps, ', ', S), format(atom(A), "~w(~w)", [L, S]).
pp(cmp(Op, X, Y), A) :- pp(X, PX), pp(Y, PY), format(atom(A), "~w ~w ~w", [PX, Op, PY]).

comp_label(sum, sum_list) :- !.
comp_label(maxl, max_list) :- !.
comp_label(minl, min_list) :- !.
comp_label(len, length) :- !.
comp_label(rev, reverse) :- !.
comp_label(app, append) :- !.
comp_label(F, F).
