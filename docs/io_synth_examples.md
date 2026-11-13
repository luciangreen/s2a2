# io_synth: input/output → program examples

Here are concrete I/O → program examples from S2A2's `io_synth.pl` (the part that reverse-engineers Prolog predicates from input/output examples), plus how it hands some of them to the optimisation stage.

## 1. Hierarchical / nested predicates (top-down propagation)

### Example: Drop the minimum from each sub-list

I/O examples:

```
[[1,3,5],[5,3,2]]  →  [[3,5],[5,3]]
[[7,9],[4]]        →  [[9],[]]
```

Hypothesis tree S2A2 finds:

- Outer: map over the list of lists
- Inner: filter (with context) that keeps x when `x =\= min_list(l)`

Learned program (multiple predicates invented):

```prolog
dropmin_each([], []).
dropmin_each([A|B], [C|D]) :-
    dropmin_each_el(A, C),
    dropmin_each(B, D).

dropmin_each_el([], []).
dropmin_each_el([A|B], C) :-
    min_list([A|B], D),
    dropmin_each_el_sel([A|B], D, C).

dropmin_each_el_sel([], _, []).
dropmin_each_el_sel([A|B], C, D) :-
    (   dropmin_each_el_test(A, C)
    ->  D = [A|E]
    ;   D = E
    ),
    dropmin_each_el_sel(B, C, E).

dropmin_each_el_test(A, B) :-
    A =\= B.
```

It invents three helper predicates. The system then proves this equal (by induction + test normalisation) to a hand-written reference that uses `del_eq` with `==`.

### Example: Nested map (increment every element of a list of lists)

I/O:

```
[[1,2],[3]]  →  [[2,3],[4]]
[[5]]        →  [[6]]
[]           →  []
```

Learned program:

```prolog
inc_all([], []).
inc_all([A|B], [C|D]) :-
    inc_all_el(A, C),
    inc_all(B, D).

inc_all_el([], []).
inc_all_el([A|B], [C|D]) :-
    inc_all_el_el(A, C),
    inc_all_el(B, D).

inc_all_el_el(A, B) :-
    B is A + 1.
```

Two levels of map, each producing its own predicate.

### Example: Drop the maximum (context filter)

I/O:

```
[3,1,2]  →  [1,2]
[7,9,8]  →  [7,8]
[5,6,4]  →  [5,4]
```

Learned program:

```prolog
dropmax([], []).
dropmax([A|B], C) :-
    max_list([A|B], D),
    dropmax_sel([A|B], D, C).

dropmax_sel([], _, []).
dropmax_sel([A|B], C, D) :-
    (   dropmax_test(A, C)
    ->  D = [A|E]
    ;   D = E
    ),
    dropmax_sel(B, C, E).

dropmax_test(A, B) :-
    A < B.
```

The proof uses an invariant from `max_list/2` ("every element ≤ the maximum") so that `X < M` is shown equivalent to `X =\= M` under that invariant.

## 2. Genetic algorithm for non-top-down pipelines

### Example: Sum of the squares of the even elements

I/O:

```
[1,2,3,4]  →  20
[2]        →  4
[1,3]      →  0
[6,1]      →  36
[]         →  0
```

Top-down cannot split this cleanly, so the GA searches pipelines and finds (after ~26 generations with one seed):

```prolog
sum_sq_evens(A, B) :-
    sum_sq_evens_s1(A, C),   % filter evens
    sum_sq_evens_s2(C, D),   % map square
    sum_sq_evens_s3(D, B).   % sum_list

% ... definitions of the three helpers ...
```

It invents three predicates (filter → map → aggregate). The prover shows it equal to a reference that does the same steps.

## 3. From I/O to algorithm (hand-over to `fold.pl`)

Once a recursive specification is synthesised from examples, S2A2 can pass it to the optimisation stage.

### Classic case: naive reverse → accumulator reverse

From a few I/O examples the synthesis stage produces a standard recursive reverse (using append). The fold/eureka machinery then:

1. Discovers the associativity lemma for append (it conjectures and proves it).
2. Introduces an accumulator definition.
3. Derives the efficient tail-recursive version:

   ```prolog
   rev_acc([], A, A).
   rev_acc([H|T], A, R) :-
       rev_acc(T, [H|A], R).
   ```

4. Proves the least models are equal (and measures a large reduction in resolution steps / pending goals).

Similar derivations work for sum, length, tree flatten, Fibonacci (tupling), etc.

## How this differs from Popper / Aleph on the same task

- S2A2 starts from pure positive I/O pairs, uses structural signals + top-down decomposition + observational equivalence + a small library of combinators (map/filter/template/foldr), invents a hierarchy of helpers, and can then optimise the result with a prover.
- Popper / Aleph expect positive + negative examples + background knowledge + a language bias (modes or declarations). They search a general clause space and are better suited to arbitrary relational or recursive definitions that do not fit the list-processing patterns S2A2 hard-wires.

S2A2 therefore succeeds on the examples above (and proves the results) because they fall inside its specialised fragment. It would not, without substantial extension, match Popper or Aleph on classic multi-predicate ILP benchmarks that require open-ended clause invention from mixed positive/negative examples and rich background knowledge.
