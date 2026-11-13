:- encoding(utf8).
/*  io_synth_refs.pl -- reference programs for the io_synth problems, written by hand as
    plain recursive Prolog, the way one would define each task. A program found from
    input/output is proved equal to its reference by io_proof:prove_equal/6.

    ref(Name, ArgTypes, Clauses): Clauses define ref_Name/2 (and its helpers).
*/
:- module(io_synth_refs, [ref/3, ref_text/2]).
:- discontiguous r/3.

ref_text(Name, Text) :- ref(Name, _, Cs), with_output_to(string(Text), forall(member(C, Cs), portray_clause(C))).

flat([list(int), any]).
nested([list(list(int)), any]).

ref(N, T, Cs) :- r(N, K, Cs), ( K == flat -> flat(T) ; nested(T) ).

% ---------------------------------------------------------------- maps
r(inc, flat, [ref_inc([], []), (ref_inc([X|Xs], [Y|Ys]) :- Y is X + 1, ref_inc(Xs, Ys))]).
r(dec, flat, [ref_dec([], []), (ref_dec([X|Xs], [Y|Ys]) :- Y is X - 1, ref_dec(Xs, Ys))]).
r(double, flat, [ref_double([], []), (ref_double([X|Xs], [Y|Ys]) :- Y is X * 2, ref_double(Xs, Ys))]).
r(square, flat, [ref_square([], []), (ref_square([X|Xs], [Y|Ys]) :- Y is X * X, ref_square(Xs, Ys))]).
r(negate, flat, [ref_negate([], []), (ref_negate([X|Xs], [Y|Ys]) :- Y is 0 - X, ref_negate(Xs, Ys))]).
r(absolute, flat, [ref_absolute([], []), (ref_absolute([X|Xs], [Y|Ys]) :- Y is abs(X), ref_absolute(Xs, Ys))]).
r(halve, flat, [ref_halve([], []), (ref_halve([X|Xs], [Y|Ys]) :- Y is X // 2, ref_halve(Xs, Ys))]).
r(parity, flat, [ref_parity([], []), (ref_parity([X|Xs], [Y|Ys]) :- Y is X mod 2, ref_parity(Xs, Ys))]).
r(triple, flat, [ref_triple([], []), (ref_triple([X|Xs], [Y|Ys]) :- Y is 3 * X, ref_triple(Xs, Ys))]).
r(sq_plus_one, flat, [ref_sq_plus_one([], []), (ref_sq_plus_one([X|Xs], [Y|Ys]) :- Y is X * X + 1, ref_sq_plus_one(Xs, Ys))]).
r(odd_number, flat, [ref_odd_number([], []), (ref_odd_number([X|Xs], [Y|Ys]) :- Y is 2 * X + 1, ref_odd_number(Xs, Ys))]).
r(sq_minus, flat, [ref_sq_minus([], []), (ref_sq_minus([X|Xs], [Y|Ys]) :- Y is X * (X - 1), ref_sq_minus(Xs, Ys))]).

% ---------------------------------------------------------------- maps inside maps
r(inc_all, nested, [ref_inc_all([], []), (ref_inc_all([L|Ls], [R|Rs]) :- inc_row(L, R), ref_inc_all(Ls, Rs)),
                    inc_row([], []), (inc_row([X|Xs], [Y|Ys]) :- Y is X + 1, inc_row(Xs, Ys))]).
r(dbl_all, nested, [ref_dbl_all([], []), (ref_dbl_all([L|Ls], [R|Rs]) :- dbl_row(L, R), ref_dbl_all(Ls, Rs)),
                    dbl_row([], []), (dbl_row([X|Xs], [Y|Ys]) :- Y is X + X, dbl_row(Xs, Ys))]).
r(sq_all, nested, [ref_sq_all([], []), (ref_sq_all([L|Ls], [R|Rs]) :- sq_row(L, R), ref_sq_all(Ls, Rs)),
                   sq_row([], []), (sq_row([X|Xs], [Y|Ys]) :- Y is X * X, sq_row(Xs, Ys))]).
r(dec_all, nested, [ref_dec_all([], []), (ref_dec_all([L|Ls], [R|Rs]) :- dec_row(L, R), ref_dec_all(Ls, Rs)),
                    dec_row([], []), (dec_row([X|Xs], [Y|Ys]) :- Y is X - 1, dec_row(Xs, Ys))]).

% ---------------------------------------------------------------- filters
r(evens, flat, F) :- filter(ref_evens, X, X mod 2 =:= 0, F).
r(odds, flat, F) :- filter(ref_odds, X, X mod 2 =:= 1, F).
r(positives, flat, F) :- filter(ref_positives, X, X > 0, F).
r(non_negative, flat, F) :- filter(ref_non_negative, X, X >= 0, F).
r(nonzero, flat, F) :- filter(ref_nonzero, X, X =\= 0, F).
r(above_one, flat, F) :- filter(ref_above_one, X, X > 1, F).
r(below_two, flat, F) :- filter(ref_below_two, X, X < 2, F).
r(negatives, flat, F) :- filter(ref_negatives, X, X < 0, F).
r(zeros, flat, F) :- filter(ref_zeros, X, X =:= 0, F).
r(at_least_two, flat, F) :- filter(ref_at_least_two, X, X >= 2, F).
r(evens_each, nested, [ref_evens_each([], []), (ref_evens_each([L|Ls], [R|Rs]) :- evens_row(L, R), ref_evens_each(Ls, Rs))|F]) :-
    filter(evens_row, X, 0 =:= X mod 2, F).
r(positives_each, nested, [ref_positives_each([], []), (ref_positives_each([L|Ls], [R|Rs]) :- pos_row(L, R), ref_positives_each(Ls, Rs))|F]) :-
    filter(pos_row, X, 0 < X, F).

% filter(+Name, ?X, +Test, -Clauses): keep the elements X for which Test holds
filter(N, X, Test, [H0, (H1 :- ( Test -> R = [X|R1] ; R = R1 ), Rec)]) :-
    H0 =.. [N, [], []], H1 =.. [N, [X|Xs], R], Rec =.. [N, Xs, R1].

% ---------------------------------------------------------------- filters on the whole list
r(dropmin, flat, [ref_dropmin([], []), (ref_dropmin([X|Xs], R) :- min_list([X|Xs], M), del_eq([X|Xs], M, R)),
                  del_eq([], _, []), (del_eq([X|Xs], M, R) :- ( X == M -> R = R1 ; R = [X|R1] ), del_eq(Xs, M, R1))]).
% every element is at most the maximum, so dropping the maximum keeps the elements below it
r(dropmax, flat, [ref_dropmax([], []), (ref_dropmax([X|Xs], R) :- max_list([X|Xs], M), below([X|Xs], M, R)),
                  below([], _, []), (below([X|Xs], M, R) :- ( X < M -> R = [X|R1] ; R = R1 ), below(Xs, M, R1))]).
r(keep_max, flat, [ref_keep_max([], []), (ref_keep_max([X|Xs], R) :- max_list([X|Xs], M), keep_eq([X|Xs], M, R)),
                   keep_eq([], _, []), (keep_eq([X|Xs], M, R) :- ( X == M -> R = [X|R1] ; R = R1 ), keep_eq(Xs, M, R1))]).
r(keep_min, flat, [ref_keep_min([], []), (ref_keep_min([X|Xs], R) :- min_list([X|Xs], M), keep_eq([X|Xs], M, R)),
                   keep_eq([], _, []), (keep_eq([X|Xs], M, R) :- ( X == M -> R = [X|R1] ; R = R1 ), keep_eq(Xs, M, R1))]).
r(above_length, flat, [ref_above_length([], []), (ref_above_length([X|Xs], R) :- length([X|Xs], N), above([X|Xs], N, R)),
                       above([], _, []), (above([X|Xs], N, R) :- ( X > N -> R = [X|R1] ; R = R1 ), above(Xs, N, R1))]).
r(like_first, flat, [ref_like_first([], []), (ref_like_first([F|Xs], R) :- keep_eq([F|Xs], F, R)),
                     keep_eq([], _, []), (keep_eq([X|Xs], M, R) :- ( X == M -> R = [X|R1] ; R = R1 ), keep_eq(Xs, M, R1))]).
r(below_last, flat, [ref_below_last([], []), (ref_below_last([X|Xs], R) :- last([X|Xs], Z), below([X|Xs], Z, R)),
                     below([], _, []), (below([X|Xs], M, R) :- ( X < M -> R = [X|R1] ; R = R1 ), below(Xs, M, R1))]).
r(dropmin_each, nested, [ref_dropmin_each([], []), (ref_dropmin_each([L|Ls], [R|Rs]) :- drop_min(L, R), ref_dropmin_each(Ls, Rs)),
                         drop_min([], []), (drop_min([X|Xs], R) :- min_list([X|Xs], M), del_eq([X|Xs], M, R)),
                         del_eq([], _, []), (del_eq([X|Xs], M, R) :- ( X == M -> R = R1 ; R = [X|R1] ), del_eq(Xs, M, R1))]).
r(dropmax_each, nested, [ref_dropmax_each([], []), (ref_dropmax_each([L|Ls], [R|Rs]) :- drop_max(L, R), ref_dropmax_each(Ls, Rs)),
                         drop_max([], []), (drop_max([X|Xs], R) :- max_list([X|Xs], M), below([X|Xs], M, R)),
                         below([], _, []), (below([X|Xs], M, R) :- ( X < M -> R = [X|R1] ; R = R1 ), below(Xs, M, R1))]).

% ---------------------------------------------------------------- maps on the whole list
r(submin, flat, [ref_submin([], []), (ref_submin([X|Xs], R) :- min_list([X|Xs], M), minus([X|Xs], M, R)),
                 minus([], _, []), (minus([X|Xs], M, [Y|Ys]) :- Y is X - M, minus(Xs, M, Ys))]).
r(from_max, flat, [ref_from_max([], []), (ref_from_max([X|Xs], R) :- max_list([X|Xs], M), gap([X|Xs], M, R)),
                   gap([], _, []), (gap([X|Xs], M, [Y|Ys]) :- Y is M - X, gap(Xs, M, Ys))]).
r(plus_length, flat, [ref_plus_length([], []), (ref_plus_length([X|Xs], R) :- length([X|Xs], N), plus([X|Xs], N, R)),
                      plus([], _, []), (plus([X|Xs], N, [Y|Ys]) :- Y is N + X, plus(Xs, N, Ys))]).
r(times_length, flat, [ref_times_length([], []), (ref_times_length([X|Xs], R) :- length([X|Xs], N), times([X|Xs], N, R)),
                       times([], _, []), (times([X|Xs], N, [Y|Ys]) :- Y is N * X, times(Xs, N, Ys))]).

% ---------------------------------------------------------------- templates
r(minmax, flat, [(ref_minmax(L, Min-Max) :- min_list(L, Min), max_list(L, Max))]).
r(sum_len, flat, [(ref_sum_len(L, S-N) :- sum_list(L, S), length(L, N))]).
r(first_last, flat, [(ref_first_last([F|T], F-Z) :- last([F|T], Z))]).
r(three_stats, flat, [(ref_three_stats(L, s(Min, Max, N)) :- min_list(L, Min), max_list(L, Max), length(L, N))]).
r(min_max_list, flat, [(ref_min_max_list(L, [Min, Max]) :- min_list(L, Min), max_list(L, Max))]).
r(head_tail, flat, [ref_head_tail([H|T], H-T)]).

% ---------------------------------------------------------------- folds
r(sum_fold, flat, [ref_sum_fold([], 0), (ref_sum_fold([X|Xs], S) :- ref_sum_fold(Xs, S0), S is X + S0)]).
r(length_fold, flat, [ref_length_fold([], 0), (ref_length_fold([_|Xs], N) :- ref_length_fold(Xs, M), N is 1 + M)]).
r(reverse_fold, flat, [ref_reverse_fold([], []), (ref_reverse_fold([X|Xs], R) :- ref_reverse_fold(Xs, T), append(T, [X], R))]).
r(product, flat, [ref_product([], 1), (ref_product([X|Xs], P) :- ref_product(Xs, P0), P is X * P0)]).
r(count_odds, flat, [ref_count_odds([], 0), (ref_count_odds([X|Xs], N) :- ref_count_odds(Xs, N0), N is N0 + X mod 2)]).
r(sum_squares, flat, [ref_sum_squares([], 0), (ref_sum_squares([X|Xs], S) :- ref_sum_squares(Xs, S0), S is S0 + X * X)]).
r(sum_doubles, flat, [ref_sum_doubles([], 0), (ref_sum_doubles([X|Xs], S) :- ref_sum_doubles(Xs, S0), S is S0 + 2 * X)]).
r(max_fold, flat, [ref_max_fold([], 0), (ref_max_fold([X|Xs], M) :- ref_max_fold(Xs, M0), M is max(X, M0))]).
r(flatten, nested, [ref_flatten([], []), (ref_flatten([L|Ls], R) :- ref_flatten(Ls, R0), append(L, R0, R))]).

% ---------------------------------------------------------------- one library call or two
r(sorted, flat, [(ref_sorted(L, S) :- msort(L, S))]).
r(sorted_set, flat, [(ref_sorted_set(L, S) :- sort(L, S))]).
r(reversed, flat, [(ref_reversed(L, R) :- reverse(L, R))]).
r(descending, flat, [(ref_descending(L, R) :- msort(L, S), reverse(S, R))]).
r(count, flat, [(ref_count(L, N) :- length(L, N))]).
r(total, flat, [(ref_total(L, S) :- sum_list(L, S))]).
r(final, flat, [(ref_final(L, Z) :- last(L, Z))]).
r(doubled_list, flat, [(ref_doubled_list(L, R) :- append(L, L, R))]).

% ---------------------------------------------------------------- maps of library calls
r(sums_each, nested, [ref_sums_each([], []), (ref_sums_each([L|Ls], [S|Ss]) :- sum_list(L, S), ref_sums_each(Ls, Ss))]).
r(lengths_each, nested, [ref_lengths_each([], []), (ref_lengths_each([L|Ls], [N|Ns]) :- length(L, N), ref_lengths_each(Ls, Ns))]).
r(max_each, nested, [ref_max_each([], []), (ref_max_each([L|Ls], [M|Ms]) :- max_list(L, M), ref_max_each(Ls, Ms))]).
r(reverse_each, nested, [ref_reverse_each([], []), (ref_reverse_each([L|Ls], [R|Rs]) :- reverse(L, R), ref_reverse_each(Ls, Rs))]).
r(sort_each, nested, [ref_sort_each([], []), (ref_sort_each([L|Ls], [S|Ss]) :- msort(L, S), ref_sort_each(Ls, Ss))]).
r(minmax_each, nested, [ref_minmax_each([], []), (ref_minmax_each([L|Ls], [Min-Max|Rs]) :- min_list(L, Min), max_list(L, Max), ref_minmax_each(Ls, Rs))]).

% ---------------------------------------------------------------- pipelines (genetic algorithm)
r(sum_sq_evens, flat, [(ref_sum_sq_evens(L, S) :- evens(L, E), squares(E, Q), sum_list(Q, S))|Fs]) :-
    filter(evens, X, X mod 2 =:= 0, F1), squares(F2), append(F1, F2, Fs).
r(count_positives, flat, [(ref_count_positives(L, N) :- pos(L, P), length(P, N))|F]) :- filter(pos, X, X > 0, F).
r(sum_odd_doubles, flat, [(ref_sum_odd_doubles(L, S) :- odds(L, O), doubles(O, D), sum_list(D, S))|Fs]) :-
    filter(odds, X, X mod 2 =:= 1, F1), doubles(F2), append(F1, F2, Fs).
r(max_square, flat, [(ref_max_square(L, M) :- squares(L, Q), max_list(Q, M))|F]) :- squares(F).
r(count_evens, flat, [(ref_count_evens(L, N) :- evens(L, E), length(E, N))|F]) :- filter(evens, X, X mod 2 =:= 0, F).
r(sorted_squares, flat, [(ref_sorted_squares(L, S) :- squares(L, Q), msort(Q, S))|F]) :- squares(F).
r(reversed_evens, flat, [(ref_reversed_evens(L, R) :- evens(L, E), reverse(E, R))|F]) :- filter(evens, X, X mod 2 =:= 0, F).
r(sum_incremented, flat, [(ref_sum_incremented(L, S) :- incs(L, I), sum_list(I, S)), incs([], []), (incs([X|Xs], [Y|Ys]) :- Y is X + 1, incs(Xs, Ys))]).
r(min_doubled, flat, [(ref_min_doubled(L, M) :- doubles(L, D), min_list(D, M))|F]) :- doubles(F).
r(sum_positives, flat, [(ref_sum_positives(L, S) :- pos(L, P), sum_list(P, S))|F]) :- filter(pos, X, X > 0, F).
r(largest_sorted, flat, [(ref_largest_sorted(L, M) :- msort(L, S), last(S, M))]).
r(first_reversed, flat, [(ref_first_reversed(L, F) :- reverse(L, [F|_]))]).
r(squares_of_odds, flat, [(ref_squares_of_odds(L, R) :- odds(L, O), squares(O, R))|Fs]) :-
    filter(odds, X, X mod 2 =:= 1, F1), squares(F2), append(F1, F2, Fs).
r(distinct_count, flat, [(ref_distinct_count(L, N) :- sort(L, S), length(S, N))]).
r(sum_halves, flat, [(ref_sum_halves(L, S) :- halves(L, H), sum_list(H, S)), halves([], []), (halves([X|Xs], [Y|Ys]) :- Y is X // 2, halves(Xs, Ys))]).
r(double_sum, flat, [(ref_double_sum(L, S) :- sum_list(L, T), S is 2 * T)]).

squares([squares([], []), (squares([X|Xs], [Y|Ys]) :- Y is X * X, squares(Xs, Ys))]).
doubles([doubles([], []), (doubles([X|Xs], [Y|Ys]) :- Y is 2 * X, doubles(Xs, Ys))]).

% ---------------------------------------------------------------- specifications for fold.pl
r(sum, flat, [ref_sum([], 0), (ref_sum([X|Xs], S) :- ref_sum(Xs, S0), S is X + S0)]).
r(len, flat, [ref_len([], 0), (ref_len([_|Xs], N) :- ref_len(Xs, M), N is M + 1)]).
r(rev, flat, [ref_rev([], []), (ref_rev([X|Xs], R) :- ref_rev(Xs, T), append(T, [X], R))]).
r(sumsq, flat, [ref_sumsq([], 0), (ref_sumsq([X|Xs], S) :- ref_sumsq(Xs, S0), S is X * X + S0)]).
r(sumdbl, flat, [ref_sumdbl([], 0), (ref_sumdbl([X|Xs], S) :- ref_sumdbl(Xs, S0), S is S0 + X + X)]).
r(prod, flat, [ref_prod([], 1), (ref_prod([X|Xs], P) :- ref_prod(Xs, P0), P is P0 * X)]).
r(cnt_odd, flat, [ref_cnt_odd([], 0), (ref_cnt_odd([X|Xs], N) :- ref_cnt_odd(Xs, N0), N is X mod 2 + N0)]).
r(flat2, nested, [ref_flat2([], []), (ref_flat2([L|Ls], R) :- ref_flat2(Ls, R0), append(L, R0, R))]).
r(len_plus, flat, [ref_len_plus([], 0), (ref_len_plus([_|Xs], N) :- ref_len_plus(Xs, M), N is M + 2)]).
r(sum_inc, flat, [ref_sum_inc([], 0), (ref_sum_inc([X|Xs], S) :- ref_sum_inc(Xs, S0), S is S0 + X + 1)]).
r(sum_neg, flat, [ref_sum_neg([], 0), (ref_sum_neg([X|Xs], S) :- ref_sum_neg(Xs, S0), S is S0 - X)]).
r(cnt_pos, flat, [ref_cnt_pos([], 0), (ref_cnt_pos([_|Xs], N) :- ref_cnt_pos(Xs, M), N is M + 1)]).
r(sum_abs, flat, [ref_sum_abs([], 0), (ref_sum_abs([X|Xs], S) :- ref_sum_abs(Xs, S0), S is S0 + abs(X))]).
r(sum_halves_fold, flat, [ref_sum_halves_fold([], 0), (ref_sum_halves_fold([X|Xs], S) :- ref_sum_halves_fold(Xs, S0), S is S0 + X // 2)]).
r(maxf, flat, [ref_maxf([], 0), (ref_maxf([X|Xs], M) :- ref_maxf(Xs, M0), M is max(M0, X))]).
