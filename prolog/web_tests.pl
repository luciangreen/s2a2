:- encoding(utf8).
/*  web_tests.pl -- the predicates the web app (webapp/) calls, on its own examples.
    S2A2_WEB_SHIM=1 swipl -q -g main -t 'halt(1)' web_tests.pl
    With S2A2_WEB_SHIM set, time limits count inferences, as they do in the browser.
*/
:- use_module(web).

t(Name, Goal, Wanted) :-
    (   catch(call(Goal), E, ( print_message(error, E), fail )),
        arg(_, Goal, Out), string(Out), forall(member(W, Wanted), sub_string(Out, _, _, _, W))
    ->  format("  ~w: ok~n", [Name])
    ;   format("  ~w: FAILED~n", [Name]), assertz(failed(Name)) ).
:- dynamic failed/1.

main :-
    t(families, web_families(_), ["plop", "proof_types"]),
    t(family_pid, web_family("pid", _), ["axioms: true", "proved"]),
    t(family_show, web_family_show("plop", _), ["Training pairs", "Test programs"]),
    t(io_synth, web_io_synth("[ [[1,3,5],[5,3,2]]-[[3,5],[5,3]], [[7,9],[4]]-[[9],[]] ]", "", _), ["min_list", "reproduces every example: ok"]),
    t(io_synth_to_fold, web_io_synth("[ [1,2,3]-6, [4]-4, []-0, [2,5]-7 ]", "[exclude([sum]), ga(false)]", _), ["handed to fold.pl", "accumulate"]),
    t(io_prove, web_io_prove("[ [1,2]-[2,4], [3]-[6], []-[] ]", "ref_double([], []).\nref_double([X|Xs], [Y|Ys]) :- Y is X * 2, ref_double(Xs, Ys).", "[list(int), any]", _), ["proved for every input"]),
    t(active, web_active("ref_dropmin_each([], []).\nref_dropmin_each([L|Ls], [R|Rs]) :- min_list(L, M), exclude(==(M), L, R), ref_dropmin_each(Ls, Rs).", "[[[1,3,5],[5,3,2]]]", _), ["query:", "equal_on"]),
    t(dict_stats, web_dict_stats(_), ["harvested", "lemmas"]),
    t(dict_synth, web_dict_synth("[ [1,2]-5, [3]-9, []-0, [1,1,1]-3 ]", _), ["found in the dictionary", "join("]),
    t(dict_negative, web_dict_synth("[ 3-9, neg(2-4) ]", _), ["found in the dictionary"]),
    t(dict_code, web_dict_code("total([], 0).\ntotal([H|T], S) :- total(T, S0), S is H + S0.", _), ["detlog2_det_sum", "proved"]),
    t(dict_search, web_dict_search("sum", _), ["detlog2_det_sum"]),
    t(dict_entry, web_dict_entry("detlog2_det_sum", _), ["code:", "lemmas:"]),
    t(dict_run, web_dict_run("detlog2_det_sum", "[4,5,6]", _), ["15"]),
    t(dict_lemmas, web_dict_lemmas("commute", _), ["proved"]),
    t(prove, web_prove("f([], []).\nf([X|Xs], [Y|Ys]) :- Y is (X + 1) * (X + 1), f(Xs, Ys).", "g([], []).\ng([X|Xs], [Y|Ys]) :- Y is X * X + 2 * X + 1, g(Xs, Ys).", "[list(int), any]", _), ["proved", "polynomials"]),
    t(prove_counter_example, web_prove("f([], []).\nf([X|Xs], [Y|Ys]) :- Y is X * X, f(Xs, Ys).", "g([], []).\ng([X|Xs], [Y|Ys]) :- Y is X + X, g(Xs, Ys).", "[list(int), any]", _), ["counter-example: on [1]"]),
    t(fold_rev, web_fold("app([], L, L).\napp([H|T], L, [H|R]) :- app(T, L, R).\nrev([], []).\nrev([H|T], R) :- rev(T, RT), app(RT, [H], R).", "rev/2", "[in(list(any)), out]", _), ["accumulate", "bounded check: equal_on"]),
    t(fold_fib, web_fold("fib(0, 0).\nfib(s(0), 1).\nfib(s(s(N)), F) :- fib(s(N), F1), fib(N, F2), F is F1 + F2.", "fib/2", "[in(nat), out]", _), ["tuple"]),
    t(types, web_types("person(A) :- parent(A, _).\nperson(B) :- parent(_, B).\nsib(S, T) :- person(S), parent(P, S), parent(P, T), S \\= T.\nadult(X) :- person(X), age(X, G), G >= 18.", _), ["parent/2:1", "person/1:1"]),
    t(syntax_error_is_reported, web_prove("f(", "g.", "[int]", _), ["Error"]),
    ( failed(_) -> halt(1) ; format("all web tests passed~n"), halt(0) ).
