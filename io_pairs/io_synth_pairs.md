# io_synth: 200 input/output pairs

Each pair is a query to `prolog/io_synth.pl`, which finds nested and hierarchical predicates from input/output examples: structural signals, anti-unification, hierarchies found by top-down propagation (each checked against a reference predicate on every input of a pool), the size of the search with and without observational equivalence, the genetic algorithm, active learning with an oracle, the checks, and input/output to an algorithm through `fold.pl`. Each program found is proved equal to a reference program for every input of the declared types (`prolog/io_proof.pl`), or the output says that it is not proved; each is also run against its reference on a pool of inputs. Every output was produced by running this repository's code with `io_pairs/generate_io_synth.pl`; nothing was written by hand.

| Category | Pairs |
|---|---|
| `io_synth/signals` | 20 |
| `io_synth/anti-unification` | 20 |
| `io_synth/hierarchy` | 70 |
| `io_synth/reductions` | 15 |
| `io_synth/genetic` | 20 |
| `io_synth/active` | 20 |
| `io_synth/checks-proof` | 8 |
| `io_synth/checks-run_all` | 6 |
| `io_synth/checks-fold_spec` | 6 |
| `io_synth/to-algorithm` | 15 |

## 1. length kept: a map

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2,3]-[2,4,6],[5]-[10]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
length_preserved
depth_preserved
```

## 2. an ordered subsequence: a filter

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2,3,4]-[2,4],[5,6]-[6]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
subsequence
drops_elements
```

## 3. a permutation

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[3,1,2]-[1,2,3],[5,4]-[4,5]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
length_preserved
permutation
depth_preserved
```

## 4. a scalar from a list: an aggregate

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[3,1,2]-6,[5,4]-9]).
```

**Output**

```text
in_type(list(int))
out_type(int)
aggregate_of_list
```

## 5. nested lists, per-sublist behaviour

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[[1,3,5],[5,3,2]]-[[3,5],[5,3]]]).
```

**Output**

```text
in_type(list(list(int)))
out_type(list(list(int)))
length_preserved
nested_input
per_sublist
depth_preserved
```

## 6. a shared output template

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[3,1,2]-(1-3),[5,9]-(5-9)]).
```

**Output**

```text
in_type(list(int))
out_type(any)
output_template(A-B)
```

## 7. the same output every time

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2]-ok,[3]-ok,[]-ok]).
```

**Output**

```text
in_type(list(int))
out_type(atom)
constant_output
empty_case(ok)
```

## 8. an empty-list case

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[]-0,[1]-1,[1,2]-3]).
```

**Output**

```text
in_type(list(int))
out_type(int)
aggregate_of_list
empty_case(0)
```

## 9. elements dropped

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2]-[1],[3,4,5]-[3,5]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
subsequence
drops_elements
```

## 10. depth kept

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[[1],[2,3]]-[[1],[2,3]],[[4]]-[[4]]]).
```

**Output**

```text
in_type(list(list(int)))
out_type(list(list(int)))
length_preserved
subsequence
permutation
nested_input
per_sublist
depth_preserved
```

## 11. output longer than the input

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2,3]-[1,2,3,1,2,3],[4]-[4,4]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
depth_preserved
```

## 12. atoms: a permutation

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[a,b]-[b,a],[c]-[c]]).
```

**Output**

```text
in_type(list(atom))
out_type(list(atom))
length_preserved
permutation
depth_preserved
```

## 13. a template with the input's elements

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2]-f(1,2),[3,4]-f(3,4)]).
```

**Output**

```text
in_type(list(int))
out_type(any)
output_template(f(A,B))
```

## 14. scalar input

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([1-2,5-10]).
```

**Output**

```text
in_type(int)
out_type(int)
depth_preserved
```

## 15. a prefix: a subsequence

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[3,1,2]-[3,1],[5,9]-[5]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
subsequence
drops_elements
```

## 16. depth reduced: a flatten

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[[1,2],[3]]-[1,2,3],[[4]]-[4]]).
```

**Output**

```text
in_type(list(list(int)))
out_type(list(int))
nested_input
```

## 17. fixed-length outputs from variable-length inputs

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[3,1,2]-[1,3],[5,9,7]-[5,9]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
drops_elements
```

## 18. a permutation of the same length

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,2,3]-[3,2,1],[4,5]-[5,4]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
length_preserved
permutation
depth_preserved
```

## 19. boolean-like outputs

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[2,4]-true,[1]-false]).
```

**Output**

```text
in_type(list(int))
out_type(atom)
```

## 20. duplicates removed

*Category:* `io_synth/signals`

**Input**

```prolog
?- show_signals([[1,1,2]-[1,2],[3,3]-[3]]).
```

**Output**

```text
in_type(list(int))
out_type(list(int))
subsequence
drops_elements
```

## 21. two pairs

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([1-3,5-9]).
```

**Output**

```text
template: A-B
  hole A takes [1,5]
  hole B takes [3,9]
```

## 22. a shared constant

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([f(a,1),f(a,2)]).
```

**Output**

```text
template: f(a,A)
  hole A takes [1,2]
```

## 23. the same tuple twice: one variable

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([g(1,1),g(2,2)]).
```

**Output**

```text
template: g(A,A)
  hole A takes [1,2]
```

## 24. equal terms

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([h(1),h(1)]).
```

**Output**

```text
template: h(1)
```

## 25. two-element lists

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([[1,2],[3,4]]).
```

**Output**

```text
template: [A,B]
  hole A takes [1,3]
  hole B takes [2,4]
```

## 26. lists of different lengths

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([[1,2],[3,4,5]]).
```

**Output**

```text
template: [A,B|C]
  hole A takes [1,3]
  hole B takes [2,4]
  hole C takes [[],[5]]
```

## 27. a nested template

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([p(q(1),2),p(q(3),4)]).
```

**Output**

```text
template: p(q(A),B)
  hole A takes [1,3]
  hole B takes [2,4]
```

## 28. different inner functors

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([p(q(1),2),p(r(1),2)]).
```

**Output**

```text
template: p(A,2)
  hole A takes [q(1),r(1)]
```

## 29. two atoms

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([a,b]).
```

**Output**

```text
template: A
  hole A takes [a,b]
```

## 30. three terms

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([s(1,2,3),s(4,5,6),s(7,8,9)]).
```

**Output**

```text
template: s(A,B,C)
  hole A takes [1,4,7]
  hole B takes [2,5,8]
  hole C takes [3,6,9]
```

## 31. a constant argument over three terms

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([t(1,x),t(2,x),t(3,x)]).
```

**Output**

```text
template: t(A,x)
  hole A takes [1,2,3]
```

## 32. swapped arguments: two variables

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([k(1,2),k(2,1)]).
```

**Output**

```text
template: k(A,B)
  hole A takes [1,2]
  hole B takes [2,1]
```

## 33. a pair holding a list

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([1-[a],2-[b]]).
```

**Output**

```text
template: A-[B]
  hole A takes [1,2]
  hole B takes [a,b]
```

## 34. a repeated subterm

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([f(g(1),g(1)),f(g(2),g(2))]).
```

**Output**

```text
template: f(g(A),g(A))
  hole A takes [1,2]
```

## 35. different functors

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([f(1),g(1)]).
```

**Output**

```text
template: A
  hole A takes [f(1),g(1)]
```

## 36. one hole deep inside

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([m(1,n(2,3)),m(1,n(4,3))]).
```

**Output**

```text
template: m(1,n(A,3))
  hole A takes [2,4]
```

## 37. an improper list tail

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([[1|t],[2|t]]).
```

**Output**

```text
template: [A|t]
  hole A takes [1,2]
```

## 38. the same atom three times

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([e,e,e]).
```

**Output**

```text
template: e
```

## 39. one argument differs once

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([v(1,2),v(1,2),v(1,3)]).
```

**Output**

```text
template: v(1,A)
  hole A takes [2,2,3]
```

## 40. labels and values

*Category:* `io_synth/anti-unification`

**Input**

```prolog
?- show_lgg([pair(min,1),pair(max,2)]).
```

**Output**

```text
template: pair(A,B)
  hole A takes [min,max]
  hole B takes [1,2]
```

## 41. add one to each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_inc([], []).
ref_inc([A|B], [C|D]) :-
    C is A+1,
    ref_inc(B, D).

?- show_synth(inc, [[1,2,3]-[2,3,4],[5]-[6],[]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [2,3,4]
  [5] -> [6]
  [] -> []
hypothesis tree:
    inc: map: each element by the sub-predicate
      inc_el: expression (x+1)
program:
    inc([], []).
    inc([A|B], [C|D]) :-
        inc_el(A, C),
        inc(B, D).
    inc_el(A, B) :-
        B is A+1.
candidates built: 688; dropped as observationally equivalent: 442; arguments refused by type: 792
proof against the reference ref_inc/2:
    proved for every input of the declared types:
      unfold inc_el/2 (one clause, not recursive)
      inc/2 = ref_inc/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 42. subtract one from each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dec([], []).
ref_dec([A|B], [C|D]) :-
    C is A-1,
    ref_dec(B, D).

?- show_synth(dec, [[1,2,3]-[0,1,2],[5]-[4],[]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [0,1,2]
  [5] -> [4]
  [] -> []
hypothesis tree:
    dec: map: each element by the sub-predicate
      dec_el: expression (x-1)
program:
    dec([], []).
    dec([A|B], [C|D]) :-
        dec_el(A, C),
        dec(B, D).
    dec_el(A, B) :-
        B is A-1.
candidates built: 688; dropped as observationally equivalent: 442; arguments refused by type: 792
proof against the reference ref_dec/2:
    proved for every input of the declared types:
      unfold dec_el/2 (one clause, not recursive)
      dec/2 = ref_dec/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 43. double each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_double([], []).
ref_double([A|B], [C|D]) :-
    C is A*2,
    ref_double(B, D).

?- show_synth(double, [[1,2,3]-[2,4,6],[5]-[10],[]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [2,4,6]
  [5] -> [10]
  [] -> []
hypothesis tree:
    double: map: each element by the sub-predicate
      double_el: expression (2*x)
program:
    double([], []).
    double([A|B], [C|D]) :-
        double_el(A, C),
        double(B, D).
    double_el(A, B) :-
        B is 2*A.
candidates built: 688; dropped as observationally equivalent: 442; arguments refused by type: 792
proof against the reference ref_double/2:
    proved for every input of the declared types:
      unfold double_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      double/2 = ref_double/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 44. square each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_square([], []).
ref_square([A|B], [C|D]) :-
    C is A*A,
    ref_square(B, D).

?- show_synth(square, [[1,2,3]-[1,4,9],[-2]-[4],[]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [1,4,9]
  [-2] -> [4]
  [] -> []
hypothesis tree:
    square: map: each element by the sub-predicate
      square_el: expression (x*x)
program:
    square([], []).
    square([A|B], [C|D]) :-
        square_el(A, C),
        square(B, D).
    square_el(A, B) :-
        B is A*A.
candidates built: 696; dropped as observationally equivalent: 451; arguments refused by type: 802
proof against the reference ref_square/2:
    proved for every input of the declared types:
      unfold square_el/2 (one clause, not recursive)
      square/2 = ref_square/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 45. negate each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_negate([], []).
ref_negate([A|B], [C|D]) :-
    C is 0-A,
    ref_negate(B, D).

?- show_synth(negate, [[1,-2,3]-[-1,2,-3],[0]-[0]], [], flat).
```

**Output**

```text
examples:
  [1,-2,3] -> [-1,2,-3]
  [0] -> [0]
hypothesis tree:
    negate: map: each element by the sub-predicate
      negate_el: expression (-x)
program:
    negate([], []).
    negate([A|B], [C|D]) :-
        negate_el(A, C),
        negate(B, D).
    negate_el(A, B) :-
        B is -A.
candidates built: 651; dropped as observationally equivalent: 478; arguments refused by type: 737
proof against the reference ref_negate/2:
    proved for every input of the declared types:
      unfold negate_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      negate/2 = ref_negate/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 46. absolute value of each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_absolute([], []).
ref_absolute([A|B], [C|D]) :-
    C is abs(A),
    ref_absolute(B, D).

?- show_synth(absolute, [[1,-2,3]-[1,2,3],[-5]-[5]], [], flat).
```

**Output**

```text
examples:
  [1,-2,3] -> [1,2,3]
  [-5] -> [5]
hypothesis tree:
    absolute: map: each element by the sub-predicate
      absolute_el: expression (abs(x))
program:
    absolute([], []).
    absolute([A|B], [C|D]) :-
        absolute_el(A, C),
        absolute(B, D).
    absolute_el(A, B) :-
        B is abs(A).
candidates built: 771; dropped as observationally equivalent: 518; arguments refused by type: 887
proof against the reference ref_absolute/2:
    proved for every input of the declared types:
      unfold absolute_el/2 (one clause, not recursive)
      absolute/2 = ref_absolute/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 47. halve each element (integer division)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_halve([], []).
ref_halve([A|B], [C|D]) :-
    C is A//2,
    ref_halve(B, D).

?- show_synth(halve, [[4,5,6]-[2,2,3],[9]-[4],[1]-[0]], [], flat).
```

**Output**

```text
examples:
  [4,5,6] -> [2,2,3]
  [9] -> [4]
  [1] -> [0]
hypothesis tree:
    halve: map: each element by the sub-predicate
      halve_el: expression (x//2)
program:
    halve([], []).
    halve([A|B], [C|D]) :-
        halve_el(A, C),
        halve(B, D).
    halve_el(A, B) :-
        B is A//2.
candidates built: 664; dropped as observationally equivalent: 434; arguments refused by type: 762
proof against the reference ref_halve/2:
    proved for every input of the declared types:
      unfold halve_el/2 (one clause, not recursive)
      halve/2 = ref_halve/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 48. parity of each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_parity([], []).
ref_parity([A|B], [C|D]) :-
    C is A mod 2,
    ref_parity(B, D).

?- show_synth(parity, [[4,5,6]-[0,1,0],[7]-[1],[-3]-[1]], [], flat).
```

**Output**

```text
examples:
  [4,5,6] -> [0,1,0]
  [7] -> [1]
  [-3] -> [1]
hypothesis tree:
    parity: map: each element by the sub-predicate
      parity_el: expression (x mod 2)
program:
    parity([], []).
    parity([A|B], [C|D]) :-
        parity_el(A, C),
        parity(B, D).
    parity_el(A, B) :-
        B is A mod 2.
candidates built: 688; dropped as observationally equivalent: 419; arguments refused by type: 792
proof against the reference ref_parity/2:
    proved for every input of the declared types:
      unfold parity_el/2 (one clause, not recursive)
      parity/2 = ref_parity/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 49. triple each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_triple([], []).
ref_triple([A|B], [C|D]) :-
    C is 3*A,
    ref_triple(B, D).

?- show_synth(triple, [[1,2,3]-[3,6,9],[5]-[15],[]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [3,6,9]
  [5] -> [15]
  [] -> []
hypothesis tree:
    triple: map: each element by the sub-predicate
      triple_el: expression (x+(2*x))
program:
    triple([], []).
    triple([A|B], [C|D]) :-
        triple_el(A, C),
        triple(B, D).
    triple_el(A, B) :-
        B is A+2*A.
candidates built: 1414; dropped as observationally equivalent: 980; arguments refused by type: 1449
proof against the reference ref_triple/2:
    proved for every input of the declared types:
      unfold triple_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      triple/2 = ref_triple/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 50. square plus one for each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sq_plus_one([], []).
ref_sq_plus_one([A|B], [C|D]) :-
    C is A*A+1,
    ref_sq_plus_one(B, D).

?- show_synth(sq_plus_one, [[1,2,3]-[2,5,10],[0]-[1]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [2,5,10]
  [0] -> [1]
hypothesis tree:
    sq_plus_one: map: each element by the sub-predicate
      sq_plus_one_el: expression ((x*x)+1)
program:
    sq_plus_one([], []).
    sq_plus_one([A|B], [C|D]) :-
        sq_plus_one_el(A, C),
        sq_plus_one(B, D).
    sq_plus_one_el(A, B) :-
        B is A*A+1.
candidates built: 722; dropped as observationally equivalent: 512; arguments refused by type: 810
proof against the reference ref_sq_plus_one/2:
    proved for every input of the declared types:
      unfold sq_plus_one_el/2 (one clause, not recursive)
      sq_plus_one/2 = ref_sq_plus_one/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 51. 2x + 1 for each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_odd_number([], []).
ref_odd_number([A|B], [C|D]) :-
    C is 2*A+1,
    ref_odd_number(B, D).

?- show_synth(odd_number, [[1,2,3]-[3,5,7],[0]-[1]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [3,5,7]
  [0] -> [1]
hypothesis tree:
    odd_number: map: each element by the sub-predicate
      odd_number_el: expression ((2*x)+1)
program:
    odd_number([], []).
    odd_number([A|B], [C|D]) :-
        odd_number_el(A, C),
        odd_number(B, D).
    odd_number_el(A, B) :-
        B is 2*A+1.
candidates built: 722; dropped as observationally equivalent: 512; arguments refused by type: 810
proof against the reference ref_odd_number/2:
    proved for every input of the declared types:
      unfold odd_number_el/2 (one clause, not recursive)
      odd_number/2 = ref_odd_number/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 52. x*x - x for each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sq_minus([], []).
ref_sq_minus([A|B], [C|D]) :-
    C is A*(A-1),
    ref_sq_minus(B, D).

?- show_synth(sq_minus, [[1,2,3]-[0,2,6],[4]-[12],[0]-[0]], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [0,2,6]
  [4] -> [12]
  [0] -> [0]
hypothesis tree:
    sq_minus: map: each element by the sub-predicate
      sq_minus_el: expression ((x*x)-x)
program:
    sq_minus([], []).
    sq_minus([A|B], [C|D]) :-
        sq_minus_el(A, C),
        sq_minus(B, D).
    sq_minus_el(A, B) :-
        B is A*A-A.
candidates built: 1406; dropped as observationally equivalent: 970; arguments refused by type: 1439
proof against the reference ref_sq_minus/2:
    proved for every input of the declared types:
      unfold sq_minus_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      sq_minus/2 = ref_sq_minus/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 53. add one to every element of a list of lists (map inside map)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_inc_all([], []).
ref_inc_all([A|B], [C|D]) :-
    inc_row(A, C),
    ref_inc_all(B, D).
inc_row([], []).
inc_row([A|B], [C|D]) :-
    C is A+1,
    inc_row(B, D).

?- show_synth(inc_all, [[[1,2],[3]]-[[2,3],[4]],[[5]]-[[6]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [[2,3],[4]]
  [[5]] -> [[6]]
  [] -> []
hypothesis tree:
    inc_all: map: each element by the sub-predicate
      inc_all_el: map: each element by the sub-predicate
        inc_all_el_el: expression (x+1)
program:
    inc_all([], []).
    inc_all([A|B], [C|D]) :-
        inc_all_el(A, C),
        inc_all(B, D).
    inc_all_el([], []).
    inc_all_el([A|B], [C|D]) :-
        inc_all_el_el(A, C),
        inc_all_el(B, D).
    inc_all_el_el(A, B) :-
        B is A+1.
candidates built: 1071; dropped as observationally equivalent: 724; arguments refused by type: 1316
proof against the reference ref_inc_all/2:
    proved for every input of the declared types:
      unfold inc_all_el_el/2 (one clause, not recursive)
      inc_all_el/2 = inc_row/2 by induction on argument 1
      inc_all/2 = ref_inc_all/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 54. double every element of a list of lists

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dbl_all([], []).
ref_dbl_all([A|B], [C|D]) :-
    dbl_row(A, C),
    ref_dbl_all(B, D).
dbl_row([], []).
dbl_row([A|B], [C|D]) :-
    C is A+A,
    dbl_row(B, D).

?- show_synth(dbl_all, [[[1,2],[3]]-[[2,4],[6]],[[0]]-[[0]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [[2,4],[6]]
  [[0]] -> [[0]]
  [] -> []
hypothesis tree:
    dbl_all: map: each element by the sub-predicate
      dbl_all_el: map: each element by the sub-predicate
        dbl_all_el_el: expression (2*x)
program:
    dbl_all([], []).
    dbl_all([A|B], [C|D]) :-
        dbl_all_el(A, C),
        dbl_all(B, D).
    dbl_all_el([], []).
    dbl_all_el([A|B], [C|D]) :-
        dbl_all_el_el(A, C),
        dbl_all_el(B, D).
    dbl_all_el_el(A, B) :-
        B is 2*A.
candidates built: 1063; dropped as observationally equivalent: 721; arguments refused by type: 1306
proof against the reference ref_dbl_all/2:
    proved for every input of the declared types:
      unfold dbl_all_el_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      dbl_all_el/2 = dbl_row/2 by induction on argument 1
      dbl_all/2 = ref_dbl_all/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 55. square every element of a list of lists

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sq_all([], []).
ref_sq_all([A|B], [C|D]) :-
    sq_row(A, C),
    ref_sq_all(B, D).
sq_row([], []).
sq_row([A|B], [C|D]) :-
    C is A*A,
    sq_row(B, D).

?- show_synth(sq_all, [[[1,2],[3]]-[[1,4],[9]],[[0]]-[[0]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [[1,4],[9]]
  [[0]] -> [[0]]
  [] -> []
hypothesis tree:
    sq_all: map: each element by the sub-predicate
      sq_all_el: map: each element by the sub-predicate
        sq_all_el_el: expression (x*x)
program:
    sq_all([], []).
    sq_all([A|B], [C|D]) :-
        sq_all_el(A, C),
        sq_all(B, D).
    sq_all_el([], []).
    sq_all_el([A|B], [C|D]) :-
        sq_all_el_el(A, C),
        sq_all_el(B, D).
    sq_all_el_el(A, B) :-
        B is A*A.
candidates built: 1063; dropped as observationally equivalent: 721; arguments refused by type: 1306
proof against the reference ref_sq_all/2:
    proved for every input of the declared types:
      unfold sq_all_el_el/2 (one clause, not recursive)
      sq_all_el/2 = sq_row/2 by induction on argument 1
      sq_all/2 = ref_sq_all/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 56. subtract one from every element of a list of lists

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dec_all([], []).
ref_dec_all([A|B], [C|D]) :-
    dec_row(A, C),
    ref_dec_all(B, D).
dec_row([], []).
dec_row([A|B], [C|D]) :-
    C is A-1,
    dec_row(B, D).

?- show_synth(dec_all, [[[1,2],[3]]-[[0,1],[2]],[[5]]-[[4]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [[0,1],[2]]
  [[5]] -> [[4]]
  [] -> []
hypothesis tree:
    dec_all: map: each element by the sub-predicate
      dec_all_el: map: each element by the sub-predicate
        dec_all_el_el: expression (x-1)
program:
    dec_all([], []).
    dec_all([A|B], [C|D]) :-
        dec_all_el(A, C),
        dec_all(B, D).
    dec_all_el([], []).
    dec_all_el([A|B], [C|D]) :-
        dec_all_el_el(A, C),
        dec_all_el(B, D).
    dec_all_el_el(A, B) :-
        B is A-1.
candidates built: 1071; dropped as observationally equivalent: 724; arguments refused by type: 1316
proof against the reference ref_dec_all/2:
    proved for every input of the declared types:
      unfold dec_all_el_el/2 (one clause, not recursive)
      dec_all_el/2 = dec_row/2 by induction on argument 1
      dec_all/2 = ref_dec_all/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 57. keep the even elements

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_evens([], []).
ref_evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_evens(B, D).

?- show_synth(evens, [[1,2,3,4]-[2,4],[5,6]-[6],[7]-[],[-2,1]-[-2]], [], flat).
```

**Output**

```text
examples:
  [1,2,3,4] -> [2,4]
  [5,6] -> [6]
  [7] -> []
  [-2,1] -> [-2]
hypothesis tree:
    evens: filter (plain): keep x when (x mod 2) < 1
program:
    evens([], []).
    evens([A|B], C) :-
        (   evens_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        evens(B, D).
    evens_test(A) :-
        A mod 2<1.
candidates built: 2556; dropped as observationally equivalent: 2169; arguments refused by type: 950
proof against the reference ref_evens/2:
    proved for every input of the declared types:
      unfold evens_test/1 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      evens/2 = ref_evens/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 58. keep the odd elements

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_odds([], []).
ref_odds([A|B], C) :-
    (   A mod 2=:=1
    ->  C=[A|D]
    ;   C=D
    ),
    ref_odds(B, D).

?- show_synth(odds, [[1,2,3,4]-[1,3],[5,6]-[5],[8]-[],[-1,2]-[-1]], [], flat).
```

**Output**

```text
examples:
  [1,2,3,4] -> [1,3]
  [5,6] -> [5]
  [8] -> []
  [-1,2] -> [-1]
hypothesis tree:
    odds: filter (plain): keep x when (x mod 2) =:= 1
program:
    odds([], []).
    odds([A|B], C) :-
        (   odds_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        odds(B, D).
    odds_test(A) :-
        A mod 2=:=1.
candidates built: 2468; dropped as observationally equivalent: 2103; arguments refused by type: 930
proof against the reference ref_odds/2:
    proved for every input of the declared types:
      unfold odds_test/1 (one clause, not recursive)
      odds/2 = ref_odds/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 59. keep the positive elements

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_positives([], []).
ref_positives([A|B], C) :-
    (   A>0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_positives(B, D).

?- show_synth(positives, [[1,-2,3,0]-[1,3],[-5,6]-[6],[-1]-[]], [], flat).
```

**Output**

```text
examples:
  [1,-2,3,0] -> [1,3]
  [-5,6] -> [6]
  [-1] -> []
hypothesis tree:
    positives: filter (plain): keep x when x > 0
program:
    positives([], []).
    positives([A|B], C) :-
        (   positives_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        positives(B, D).
    positives_test(A) :-
        A>0.
candidates built: 2775; dropped as observationally equivalent: 2295; arguments refused by type: 1202
proof against the reference ref_positives/2:
    proved for every input of the declared types:
      unfold positives_test/1 (one clause, not recursive)
      positives/2 = ref_positives/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 60. keep the elements that are not negative

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_non_negative([], []).
ref_non_negative([A|B], C) :-
    (   A>=0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_non_negative(B, D).

?- show_synth(non_negative, [[1,-2,3,0]-[1,3,0],[-5,6]-[6],[-1]-[]], [], flat).
```

**Output**

```text
examples:
  [1,-2,3,0] -> [1,3,0]
  [-5,6] -> [6]
  [-1] -> []
hypothesis tree:
    non_negative: filter (plain): keep x when x >= 0
program:
    non_negative([], []).
    non_negative([A|B], C) :-
        (   non_negative_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        non_negative(B, D).
    non_negative_test(A) :-
        A>=0.
candidates built: 2775; dropped as observationally equivalent: 2295; arguments refused by type: 1202
proof against the reference ref_non_negative/2:
    proved for every input of the declared types:
      unfold non_negative_test/1 (one clause, not recursive)
      non_negative/2 = ref_non_negative/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 61. drop the zeros

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_nonzero([], []).
ref_nonzero([A|B], C) :-
    (   A=\=0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_nonzero(B, D).

?- show_synth(nonzero, [[1,0,3,0]-[1,3],[0,-6]-[-6],[0]-[]], [], flat).
```

**Output**

```text
examples:
  [1,0,3,0] -> [1,3]
  [0,-6] -> [-6]
  [0] -> []
hypothesis tree:
    nonzero: filter (plain): keep x when x =\= 0
program:
    nonzero([], []).
    nonzero([A|B], C) :-
        (   nonzero_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        nonzero(B, D).
    nonzero_test(A) :-
        A=\=0.
candidates built: 2646; dropped as observationally equivalent: 2284; arguments refused by type: 1079
proof against the reference ref_nonzero/2:
    proved for every input of the declared types:
      unfold nonzero_test/1 (one clause, not recursive)
      nonzero/2 = ref_nonzero/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 62. keep the elements greater than one

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_above_one([], []).
ref_above_one([A|B], C) :-
    (   A>1
    ->  C=[A|D]
    ;   C=D
    ),
    ref_above_one(B, D).

?- show_synth(above_one, [[1,2,3,0]-[2,3],[5,1]-[5],[1]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3,0] -> [2,3]
  [5,1] -> [5]
  [1] -> []
hypothesis tree:
    above_one: filter (plain): keep x when x > 1
program:
    above_one([], []).
    above_one([A|B], C) :-
        (   above_one_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        above_one(B, D).
    above_one_test(A) :-
        A>1.
candidates built: 2313; dropped as observationally equivalent: 1969; arguments refused by type: 1023
proof against the reference ref_above_one/2:
    proved for every input of the declared types:
      unfold above_one_test/1 (one clause, not recursive)
      above_one/2 = ref_above_one/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 63. keep the elements below two

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_below_two([], []).
ref_below_two([A|B], C) :-
    (   A<2
    ->  C=[A|D]
    ;   C=D
    ),
    ref_below_two(B, D).

?- show_synth(below_two, [[1,2,3,0]-[1,0],[5,-1]-[-1],[2]-[]], [], flat).
```

**Output**

```text
examples:
  [1,2,3,0] -> [1,0]
  [5,-1] -> [-1]
  [2] -> []
hypothesis tree:
    below_two: filter (plain): keep x when x =< 1
program:
    below_two([], []).
    below_two([A|B], C) :-
        (   below_two_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        below_two(B, D).
    below_two_test(A) :-
        A=<1.
candidates built: 2617; dropped as observationally equivalent: 2230; arguments refused by type: 1073
proof against the reference ref_below_two/2:
    proved for every input of the declared types:
      unfold below_two_test/1 (one clause, not recursive)
      tests compared in normal form
      below_two/2 = ref_below_two/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 64. keep the negative elements

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_negatives([], []).
ref_negatives([A|B], C) :-
    (   A<0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_negatives(B, D).

?- show_synth(negatives, [[1,-2,3,-1]-[-2,-1],[5]-[],[-3,0]-[-3]], [], flat).
```

**Output**

```text
examples:
  [1,-2,3,-1] -> [-2,-1]
  [5] -> []
  [-3,0] -> [-3]
hypothesis tree:
    negatives: filter (plain): keep x when x < 0
program:
    negatives([], []).
    negatives([A|B], C) :-
        (   negatives_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        negatives(B, D).
    negatives_test(A) :-
        A<0.
candidates built: 2681; dropped as observationally equivalent: 2249; arguments refused by type: 1093
proof against the reference ref_negatives/2:
    proved for every input of the declared types:
      unfold negatives_test/1 (one clause, not recursive)
      negatives/2 = ref_negatives/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 65. keep the zeros

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_zeros([], []).
ref_zeros([A|B], C) :-
    (   A=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_zeros(B, D).

?- show_synth(zeros, [[1,0,3,0]-[0,0],[5]-[],[0,-1]-[0]], [], flat).
```

**Output**

```text
examples:
  [1,0,3,0] -> [0,0]
  [5] -> []
  [0,-1] -> [0]
hypothesis tree:
    zeros: filter (plain): keep x when x =:= 0
program:
    zeros([], []).
    zeros([A|B], C) :-
        (   zeros_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        zeros(B, D).
    zeros_test(A) :-
        A=:=0.
candidates built: 2662; dropped as observationally equivalent: 2264; arguments refused by type: 1129
proof against the reference ref_zeros/2:
    proved for every input of the declared types:
      unfold zeros_test/1 (one clause, not recursive)
      zeros/2 = ref_zeros/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 66. keep the elements of at least two

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_at_least_two([], []).
ref_at_least_two([A|B], C) :-
    (   A>=2
    ->  C=[A|D]
    ;   C=D
    ),
    ref_at_least_two(B, D).

?- show_synth(at_least_two, [[1,2,3,0]-[2,3],[5,1]-[5],[2]-[2]], [], flat).
```

**Output**

```text
examples:
  [1,2,3,0] -> [2,3]
  [5,1] -> [5]
  [2] -> [2]
hypothesis tree:
    at_least_two: filter (plain): keep x when x > 1
program:
    at_least_two([], []).
    at_least_two([A|B], C) :-
        (   at_least_two_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        at_least_two(B, D).
    at_least_two_test(A) :-
        A>1.
candidates built: 2337; dropped as observationally equivalent: 1979; arguments refused by type: 1053
proof against the reference ref_at_least_two/2:
    proved for every input of the declared types:
      unfold at_least_two_test/1 (one clause, not recursive)
      tests compared in normal form
      at_least_two/2 = ref_at_least_two/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 67. keep the even elements of each sublist (map of filter)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_evens_each([], []).
ref_evens_each([A|B], [C|D]) :-
    evens_row(A, C),
    ref_evens_each(B, D).
evens_row([], []).
evens_row([A|B], C) :-
    (   0=:=A mod 2
    ->  C=[A|D]
    ;   C=D
    ),
    evens_row(B, D).

?- show_synth(evens_each, [[[1,2,4],[3,4]]-[[2,4],[4]],[[5,6,8]]-[[6,8]],[[]]-[[]],[[7,1]]-[[]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2,4],[3,4]] -> [[2,4],[4]]
  [[5,6,8]] -> [[6,8]]
  [[]] -> [[]]
  [[7,1]] -> [[]]
  [] -> []
hypothesis tree:
    evens_each: map: each element by the sub-predicate
      evens_each_el: filter (plain): keep x when (x mod 2) < 1
program:
    evens_each([], []).
    evens_each([A|B], [C|D]) :-
        evens_each_el(A, C),
        evens_each(B, D).
    evens_each_el([], []).
    evens_each_el([A|B], C) :-
        (   evens_each_el_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        evens_each_el(B, D).
    evens_each_el_test(A) :-
        A mod 2<1.
candidates built: 2844; dropped as observationally equivalent: 2223; arguments refused by type: 1800
proof against the reference ref_evens_each/2:
    proved for every input of the declared types:
      unfold evens_each_el_test/1 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      evens_each_el/2 = evens_row/2 by induction on argument 1
      evens_each/2 = ref_evens_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 68. keep the positive elements of each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_positives_each([], []).
ref_positives_each([A|B], [C|D]) :-
    pos_row(A, C),
    ref_positives_each(B, D).
pos_row([], []).
pos_row([A|B], C) :-
    (   0<A
    ->  C=[A|D]
    ;   C=D
    ),
    pos_row(B, D).

?- show_synth(positives_each, [[[1,0,2],[0,3]]-[[1,2],[3]],[[0,2,0]]-[[2]],[[-1,4]]-[[4]],[[]]-[[]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,0,2],[0,3]] -> [[1,2],[3]]
  [[0,2,0]] -> [[2]]
  [[-1,4]] -> [[4]]
  [[]] -> [[]]
  [] -> []
hypothesis tree:
    positives_each: map: each element by the sub-predicate
      positives_each_el: filter (plain): keep x when x > 0
program:
    positives_each([], []).
    positives_each([A|B], [C|D]) :-
        positives_each_el(A, C),
        positives_each(B, D).
    positives_each_el([], []).
    positives_each_el([A|B], C) :-
        (   positives_each_el_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        positives_each_el(B, D).
    positives_each_el_test(A) :-
        A>0.
candidates built: 3231; dropped as observationally equivalent: 2602; arguments refused by type: 1850
proof against the reference ref_positives_each/2:
    proved for every input of the declared types:
      unfold positives_each_el_test/1 (one clause, not recursive)
      tests compared in normal form
      positives_each_el/2 = pos_row/2 by induction on argument 1
      positives_each/2 = ref_positives_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 69. drop the minimum (a test gated by the whole list)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dropmin([], []).
ref_dropmin([A|B], C) :-
    min_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_synth(dropmin, [[3,1,2]-[3,2],[7,9,8]-[9,8],[5,6,4]-[5,6]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [3,2]
  [7,9,8] -> [9,8]
  [5,6,4] -> [5,6]
hypothesis tree:
    dropmin: filter (context): keep x when x =\= min_list(l)
program:
    dropmin([], []).
    dropmin([A|B], C) :-
        min_list([A|B], D),
        dropmin_sel([A|B], D, C).
    dropmin_sel([], _, []).
    dropmin_sel([A|B], C, D) :-
        (   dropmin_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        dropmin_sel(B, C, E).
    dropmin_test(A, B) :-
        A=\=B.
candidates built: 4407; dropped as observationally equivalent: 3840; arguments refused by type: 1378
proof against the reference ref_dropmin/2:
    proved for every input of the declared types:
      unfold dropmin_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmin_sel/3 = del_eq/3 by induction on argument 1
      dropmin/2 = ref_dropmin/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 70. drop the maximum

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dropmax([], []).
ref_dropmax([A|B], C) :-
    max_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_synth(dropmax, [[3,1,2]-[1,2],[7,9,8]-[7,8],[5,6,4]-[5,4]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [1,2]
  [7,9,8] -> [7,8]
  [5,6,4] -> [5,4]
hypothesis tree:
    dropmax: filter (context): keep x when x < max_list(l)
program:
    dropmax([], []).
    dropmax([A|B], C) :-
        max_list([A|B], D),
        dropmax_sel([A|B], D, C).
    dropmax_sel([], _, []).
    dropmax_sel([A|B], C, D) :-
        (   dropmax_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        dropmax_sel(B, C, E).
    dropmax_test(A, B) :-
        A<B.
candidates built: 4407; dropped as observationally equivalent: 3840; arguments refused by type: 1378
proof against the reference ref_dropmax/2:
    proved for every input of the declared types:
      unfold dropmax_test/2 (one clause, not recursive)
      at the call, every element of argument 1 is at most argument 2 (library fact about max_list/2), and the tail keeps it
      tests compared on integers that satisfy the invariant
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmax_sel/3 = del_eq/3 by induction on argument 1, for inputs where every element of argument 1 is at most argument 2
      dropmax/2 = ref_dropmax/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 71. keep only the maximum

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_keep_max([], []).
ref_keep_max([A|B], C) :-
    max_list([A|B], D),
    keep_eq([A|B], D, C).
keep_eq([], _, []).
keep_eq([A|B], C, D) :-
    (   A==C
    ->  D=[A|E]
    ;   D=E
    ),
    keep_eq(B, C, E).

?- show_synth(keep_max, [[3,1,2]-[3],[7,9]-[9],[5,6,4,1]-[6],[2,2]-[2,2],[]-[]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [3]
  [7,9] -> [9]
  [5,6,4,1] -> [6]
  [2,2] -> [2,2]
  [] -> []
hypothesis tree:
    keep_max: filter (context): keep x when x =:= max_list(l)
program:
    keep_max([], []).
    keep_max([A|B], C) :-
        max_list([A|B], D),
        keep_max_sel([A|B], D, C).
    keep_max_sel([], _, []).
    keep_max_sel([A|B], C, D) :-
        (   keep_max_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        keep_max_sel(B, C, E).
    keep_max_test(A, B) :-
        A=:=B.
candidates built: 4588; dropped as observationally equivalent: 3856; arguments refused by type: 1532
proof against the reference ref_keep_max/2:
    proved for every input of the declared types:
      unfold keep_max_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      keep_max_sel/3 = keep_eq/3 by induction on argument 1
      keep_max/2 = ref_keep_max/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 72. keep only the minimum

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_keep_min([], []).
ref_keep_min([A|B], C) :-
    min_list([A|B], D),
    keep_eq([A|B], D, C).
keep_eq([], _, []).
keep_eq([A|B], C, D) :-
    (   A==C
    ->  D=[A|E]
    ;   D=E
    ),
    keep_eq(B, C, E).

?- show_synth(keep_min, [[3,1,2]-[1],[7,9]-[7],[5,6,4,8]-[4],[2,2]-[2,2],[]-[]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [1]
  [7,9] -> [7]
  [5,6,4,8] -> [4]
  [2,2] -> [2,2]
  [] -> []
hypothesis tree:
    keep_min: filter (context): keep x when x =:= min_list(l)
program:
    keep_min([], []).
    keep_min([A|B], C) :-
        min_list([A|B], D),
        keep_min_sel([A|B], D, C).
    keep_min_sel([], _, []).
    keep_min_sel([A|B], C, D) :-
        (   keep_min_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        keep_min_sel(B, C, E).
    keep_min_test(A, B) :-
        A=:=B.
candidates built: 4574; dropped as observationally equivalent: 3859; arguments refused by type: 1522
proof against the reference ref_keep_min/2:
    proved for every input of the declared types:
      unfold keep_min_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      keep_min_sel/3 = keep_eq/3 by induction on argument 1
      keep_min/2 = ref_keep_min/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 73. keep the elements greater than the list's length

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_above_length([], []).
ref_above_length([A|B], C) :-
    length([A|B], D),
    above([A|B], D, C).
above([], _, []).
above([A|B], C, D) :-
    (   A>C
    ->  D=[A|E]
    ;   D=E
    ),
    above(B, C, E).

?- show_synth(above_length, [[4,1,2]-[4],[7,0,1]-[7],[5,6,4,1]-[5,6],[9]-[9],[]-[],[-2]-[],[0,4,1]-[4]], [], flat).
```

**Output**

```text
examples:
  [4,1,2] -> [4]
  [7,0,1] -> [7]
  [5,6,4,1] -> [5,6]
  [9] -> [9]
  [] -> []
  [-2] -> []
  [0,4,1] -> [4]
hypothesis tree:
    above_length: filter (context): keep x when x > length(l)
program:
    above_length([], []).
    above_length([A|B], C) :-
        length([A|B], D),
        above_length_sel([A|B], D, C).
    above_length_sel([], _, []).
    above_length_sel([A|B], C, D) :-
        (   above_length_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        above_length_sel(B, C, E).
    above_length_test(A, B) :-
        A>B.
candidates built: 5445; dropped as observationally equivalent: 4535; arguments refused by type: 1558
proof against the reference ref_above_length/2:
    proved for every input of the declared types:
      unfold above_length_test/2 (one clause, not recursive)
      above_length_sel/3 = above/3 by induction on argument 1
      above_length/2 = ref_above_length/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 74. keep the elements equal to the first

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_like_first([], []).
ref_like_first([A|B], C) :-
    keep_eq([A|B], A, C).
keep_eq([], _, []).
keep_eq([A|B], C, D) :-
    (   A==C
    ->  D=[A|E]
    ;   D=E
    ),
    keep_eq(B, C, E).

?- show_synth(like_first, [[3,1,3]-[3,3],[7,9,7]-[7,7],[5,6]-[5]], [], flat).
```

**Output**

```text
examples:
  [3,1,3] -> [3,3]
  [7,9,7] -> [7,7]
  [5,6] -> [5]
hypothesis tree:
    like_first: filter (context): keep x when x =:= head(l)
program:
    like_first([], []).
    like_first([A|B], C) :-
        [A|B]=[D|_],
        like_first_sel([A|B], D, C).
    like_first_sel([], _, []).
    like_first_sel([A|B], C, D) :-
        (   like_first_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        like_first_sel(B, C, E).
    like_first_test(A, B) :-
        A=:=B.
candidates built: 4496; dropped as observationally equivalent: 3947; arguments refused by type: 1462
proof against the reference ref_like_first/2:
    proved for every input of the declared types:
      unfold like_first_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      like_first_sel/3 = keep_eq/3 by induction on argument 1
      like_first/2 = ref_like_first/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 75. keep the elements less than the last

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_below_last([], []).
ref_below_last([A|B], C) :-
    last([A|B], D),
    below([A|B], D, C).
below([], _, []).
below([A|B], C, D) :-
    (   A<C
    ->  D=[A|E]
    ;   D=E
    ),
    below(B, C, E).

?- show_synth(below_last, [[3,1,2]-[1],[7,9,8]-[7],[5,1,6]-[5,1]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [1]
  [7,9,8] -> [7]
  [5,1,6] -> [5,1]
hypothesis tree:
    below_last: filter (context): keep x when x < last(l)
program:
    below_last([], []).
    below_last([A|B], C) :-
        last([A|B], D),
        below_last_sel([A|B], D, C).
    below_last_sel([], _, []).
    below_last_sel([A|B], C, D) :-
        (   below_last_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        below_last_sel(B, C, E).
    below_last_test(A, B) :-
        A<B.
candidates built: 4393; dropped as observationally equivalent: 3833; arguments refused by type: 1368
proof against the reference ref_below_last/2:
    proved for every input of the declared types:
      unfold below_last_test/2 (one clause, not recursive)
      below_last_sel/3 = below/3 by induction on argument 1
      below_last/2 = ref_below_last/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 76. drop the minimum from each sublist (the example in the notes)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dropmin_each([], []).
ref_dropmin_each([A|B], [C|D]) :-
    drop_min(A, C),
    ref_dropmin_each(B, D).
drop_min([], []).
drop_min([A|B], C) :-
    min_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_synth(dropmin_each, [[[1,3,5],[5,3,2]]-[[3,5],[5,3]],[[7,9],[4]]-[[9],[]]], [], nested).
```

**Output**

```text
examples:
  [[1,3,5],[5,3,2]] -> [[3,5],[5,3]]
  [[7,9],[4]] -> [[9],[]]
hypothesis tree:
    dropmin_each: map: each element by the sub-predicate
      dropmin_each_el: filter (context): keep x when x =\= min_list(l)
program:
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
        ->  D=[A|E]
        ;   D=E
        ),
        dropmin_each_el_sel(B, C, E).
    dropmin_each_el_test(A, B) :-
        A=\=B.
candidates built: 4917; dropped as observationally equivalent: 4138; arguments refused by type: 2021
proof against the reference ref_dropmin_each/2:
    proved for every input of the declared types:
      unfold dropmin_each_el_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmin_each_el_sel/3 = del_eq/3 by induction on argument 1
      dropmin_each_el/2 = drop_min/2 clause by clause
      dropmin_each/2 = ref_dropmin_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 77. drop the maximum from each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_dropmax_each([], []).
ref_dropmax_each([A|B], [C|D]) :-
    drop_max(A, C),
    ref_dropmax_each(B, D).
drop_max([], []).
drop_max([A|B], C) :-
    max_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_synth(dropmax_each, [[[1,3,5],[5,3,2]]-[[1,3],[3,2]],[[7,9],[4]]-[[7],[]]], [], nested).
```

**Output**

```text
examples:
  [[1,3,5],[5,3,2]] -> [[1,3],[3,2]]
  [[7,9],[4]] -> [[7],[]]
hypothesis tree:
    dropmax_each: map: each element by the sub-predicate
      dropmax_each_el: filter (context): keep x when x < max_list(l)
program:
    dropmax_each([], []).
    dropmax_each([A|B], [C|D]) :-
        dropmax_each_el(A, C),
        dropmax_each(B, D).
    dropmax_each_el([], []).
    dropmax_each_el([A|B], C) :-
        max_list([A|B], D),
        dropmax_each_el_sel([A|B], D, C).
    dropmax_each_el_sel([], _, []).
    dropmax_each_el_sel([A|B], C, D) :-
        (   dropmax_each_el_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        dropmax_each_el_sel(B, C, E).
    dropmax_each_el_test(A, B) :-
        A<B.
candidates built: 4917; dropped as observationally equivalent: 4138; arguments refused by type: 2021
proof against the reference ref_dropmax_each/2:
    proved for every input of the declared types:
      unfold dropmax_each_el_test/2 (one clause, not recursive)
      at the call, every element of argument 1 is at most argument 2 (library fact about max_list/2), and the tail keeps it
      tests compared on integers that satisfy the invariant
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmax_each_el_sel/3 = del_eq/3 by induction on argument 1, for inputs where every element of argument 1 is at most argument 2
      dropmax_each_el/2 = drop_max/2 clause by clause
      dropmax_each/2 = ref_dropmax_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 78. subtract the minimum from each element (a map with context)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_submin([], []).
ref_submin([A|B], C) :-
    min_list([A|B], D),
    minus([A|B], D, C).
minus([], _, []).
minus([A|B], C, [D|E]) :-
    D is A-C,
    minus(B, C, E).

?- show_synth(submin, [[3,5,4]-[0,2,1],[7,9]-[0,2],[2]-[0]], [], flat).
```

**Output**

```text
examples:
  [3,5,4] -> [0,2,1]
  [7,9] -> [0,2]
  [2] -> [0]
hypothesis tree:
    submin: map: each element by the sub-predicate
      submin_el: expression on the element x and its list l: (x-min_list(l))
program:
    submin([], []).
    submin([A|B], C) :-
        min_list([A|B], D),
        submin_each([A|B], D, C).
    submin_each([], _, []).
    submin_each([A|B], C, [D|E]) :-
        submin_el(A, C, D),
        submin_each(B, C, E).
    submin_el(A, B, C) :-
        C is A-B.
candidates built: 2899; dropped as observationally equivalent: 1948; arguments refused by type: 3026
proof against the reference ref_submin/2:
    proved for every input of the declared types:
      unfold submin_el/3 (one clause, not recursive)
      submin_each/3 = minus/3 by induction on argument 1
      submin/2 = ref_submin/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 79. distance of each element below the maximum

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_from_max([], []).
ref_from_max([A|B], C) :-
    max_list([A|B], D),
    gap([A|B], D, C).
gap([], _, []).
gap([A|B], C, [D|E]) :-
    D is C-A,
    gap(B, C, E).

?- show_synth(from_max, [[3,5,4]-[2,0,1],[7,9]-[2,0],[2]-[0]], [], flat).
```

**Output**

```text
examples:
  [3,5,4] -> [2,0,1]
  [7,9] -> [2,0]
  [2] -> [0]
hypothesis tree:
    from_max: map: each element by the sub-predicate
      from_max_el: expression on the element x and its list l: (max_list(l)-x)
program:
    from_max([], []).
    from_max([A|B], C) :-
        max_list([A|B], D),
        from_max_each([A|B], D, C).
    from_max_each([], _, []).
    from_max_each([A|B], C, [D|E]) :-
        from_max_el(A, C, D),
        from_max_each(B, C, E).
    from_max_el(A, B, C) :-
        C is B-A.
candidates built: 2899; dropped as observationally equivalent: 1948; arguments refused by type: 3026
proof against the reference ref_from_max/2:
    proved for every input of the declared types:
      unfold from_max_el/3 (one clause, not recursive)
      from_max_each/3 = gap/3 by induction on argument 1
      from_max/2 = ref_from_max/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 80. add the list's length to each element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_plus_length([], []).
ref_plus_length([A|B], C) :-
    length([A|B], D),
    plus([A|B], D, C).
plus([], _, []).
plus([A|B], C, [D|E]) :-
    D is C+A,
    plus(B, C, E).

?- show_synth(plus_length, [[3,5,4]-[6,8,7],[7,9]-[9,11],[2]-[3]], [], flat).
```

**Output**

```text
examples:
  [3,5,4] -> [6,8,7]
  [7,9] -> [9,11]
  [2] -> [3]
hypothesis tree:
    plus_length: map: each element by the sub-predicate
      plus_length_el: expression on the element x and its list l: (x+length(l))
program:
    plus_length([], []).
    plus_length([A|B], C) :-
        length([A|B], D),
        plus_length_each([A|B], D, C).
    plus_length_each([], _, []).
    plus_length_each([A|B], C, [D|E]) :-
        plus_length_el(A, C, D),
        plus_length_each(B, C, E).
    plus_length_el(A, B, C) :-
        C is A+B.
candidates built: 2899; dropped as observationally equivalent: 1948; arguments refused by type: 3026
proof against the reference ref_plus_length/2:
    proved for every input of the declared types:
      unfold plus_length_el/3 (one clause, not recursive)
      plus_length_each/3 = plus/3 by induction on argument 1
      plus_length/2 = ref_plus_length/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 81. multiply each element by the list's length

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_times_length([], []).
ref_times_length([A|B], C) :-
    length([A|B], D),
    times([A|B], D, C).
times([], _, []).
times([A|B], C, [D|E]) :-
    D is C*A,
    times(B, C, E).

?- show_synth(times_length, [[3,5,4]-[9,15,12],[7,9]-[14,18],[2]-[2]], [], flat).
```

**Output**

```text
examples:
  [3,5,4] -> [9,15,12]
  [7,9] -> [14,18]
  [2] -> [2]
hypothesis tree:
    times_length: map: each element by the sub-predicate
      times_length_el: expression on the element x and its list l: (x*length(l))
program:
    times_length([], []).
    times_length([A|B], C) :-
        length([A|B], D),
        times_length_each([A|B], D, C).
    times_length_each([], _, []).
    times_length_each([A|B], C, [D|E]) :-
        times_length_el(A, C, D),
        times_length_each(B, C, E).
    times_length_el(A, B, C) :-
        C is A*B.
candidates built: 2899; dropped as observationally equivalent: 1948; arguments refused by type: 3026
proof against the reference ref_times_length/2:
    proved for every input of the declared types:
      unfold times_length_el/3 (one clause, not recursive)
      times_length_each/3 = times/3 by induction on argument 1
      times_length/2 = ref_times_length/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 82. minimum and maximum (template from anti-unification)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_minmax(A, B-C) :-
    min_list(A, B),
    max_list(A, C).

?- show_synth(minmax, [[3,1,2]-(1-3),[5,9]-(5-9),[4]-(4-4)], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 1-3
  [5,9] -> 5-9
  [4] -> 4-4
hypothesis tree:
    minmax: template A-B from anti-unification of the outputs
      minmax_1: expression min_list(x)
      minmax_2: expression max_list(x)
program:
    minmax(A, B-C) :-
        minmax_1(A, B),
        minmax_2(A, C).
    minmax_1(A, B) :-
        min_list(A, B).
    minmax_2(A, B) :-
        max_list(A, B).
candidates built: 899; dropped as observationally equivalent: 556; arguments refused by type: 1020
proof against the reference ref_minmax/2:
    proved for every input of the declared types:
      unfold minmax_1/2 (one clause, not recursive)
      unfold minmax_2/2 (one clause, not recursive)
      minmax/2 = ref_minmax/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 83. sum and length together

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sum_len(A, B-C) :-
    sum_list(A, B),
    length(A, C).

?- show_synth(sum_len, [[3,1,2]-(6-3),[5,9]-(14-2),[4]-(4-1)], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 6-3
  [5,9] -> 14-2
  [4] -> 4-1
hypothesis tree:
    sum_len: template A-B from anti-unification of the outputs
      sum_len_1: expression sum_list(x)
      sum_len_2: expression length(x)
program:
    sum_len(A, B-C) :-
        sum_len_1(A, B),
        sum_len_2(A, C).
    sum_len_1(A, B) :-
        sum_list(A, B).
    sum_len_2(A, B) :-
        length(A, B).
candidates built: 899; dropped as observationally equivalent: 556; arguments refused by type: 1020
proof against the reference ref_sum_len/2:
    proved for every input of the declared types:
      unfold sum_len_1/2 (one clause, not recursive)
      unfold sum_len_2/2 (one clause, not recursive)
      sum_len/2 = ref_sum_len/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 84. first and last element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_first_last([A|B], A-C) :-
    last([A|B], C).

?- show_synth(first_last, [[3,1,2]-(3-2),[5,9]-(5-9),[4]-(4-4)], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 3-2
  [5,9] -> 5-9
  [4] -> 4-4
hypothesis tree:
    first_last: template A-B from anti-unification of the outputs
      first_last_1: expression head(x)
      first_last_2: expression last(x)
program:
    first_last(A, B-C) :-
        first_last_1(A, B),
        first_last_2(A, C).
    first_last_1(A, B) :-
        A=[B|_].
    first_last_2(A, B) :-
        last(A, B).
candidates built: 899; dropped as observationally equivalent: 556; arguments refused by type: 1020
proof against the reference ref_first_last/2:
    proved for every input of the declared types:
      unfold first_last_1/2 (one clause, not recursive)
      unfold first_last_2/2 (one clause, not recursive)
      first_last/2 = ref_first_last/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 85. minimum, maximum and length in one term

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_three_stats(A, s(B, C, D)) :-
    min_list(A, B),
    max_list(A, C),
    length(A, D).

?- show_synth(three_stats, [[3,1,2]-s(1,3,3),[5,9]-s(5,9,2),[4]-s(4,4,1)], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> s(1,3,3)
  [5,9] -> s(5,9,2)
  [4] -> s(4,4,1)
hypothesis tree:
    three_stats: template s(A,B,C) from anti-unification of the outputs
      three_stats_1: expression min_list(x)
      three_stats_2: expression max_list(x)
      three_stats_3: expression length(x)
program:
    three_stats(A, s(B, C, D)) :-
        three_stats_1(A, B),
        three_stats_2(A, C),
        three_stats_3(A, D).
    three_stats_1(A, B) :-
        min_list(A, B).
    three_stats_2(A, B) :-
        max_list(A, B).
    three_stats_3(A, B) :-
        length(A, B).
candidates built: 939; dropped as observationally equivalent: 576; arguments refused by type: 1056
proof against the reference ref_three_stats/2:
    proved for every input of the declared types:
      unfold three_stats_1/2 (one clause, not recursive)
      unfold three_stats_2/2 (one clause, not recursive)
      unfold three_stats_3/2 (one clause, not recursive)
      three_stats/2 = ref_three_stats/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 86. minimum and maximum as a two-element list

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_min_max_list(A, [B, C]) :-
    min_list(A, B),
    max_list(A, C).

?- show_synth(min_max_list, [[3,1,2,5]-[1,5],[5,9]-[5,9],[4,0,2]-[0,4]], [], flat).
```

**Output**

```text
examples:
  [3,1,2,5] -> [1,5]
  [5,9] -> [5,9]
  [4,0,2] -> [0,4]
hypothesis tree:
    min_max_list: template [A,B] from anti-unification of the outputs
      min_max_list_1: expression min_list(x)
      min_max_list_2: expression max_list(x)
program:
    min_max_list(A, [B, C]) :-
        min_max_list_1(A, B),
        min_max_list_2(A, C).
    min_max_list_1(A, B) :-
        min_list(A, B).
    min_max_list_2(A, B) :-
        max_list(A, B).
candidates built: 907; dropped as observationally equivalent: 557; arguments refused by type: 1030
proof against the reference ref_min_max_list/2:
    proved for every input of the declared types:
      unfold min_max_list_1/2 (one clause, not recursive)
      unfold min_max_list_2/2 (one clause, not recursive)
      min_max_list/2 = ref_min_max_list/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 87. head and tail as a pair

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_head_tail([A|B], A-B).

?- show_synth(head_tail, [[3,1,2]-(3-[1,2]),[5,9]-(5-[9]),[4]-(4-[])], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 3-[1,2]
  [5,9] -> 5-[9]
  [4] -> 4-[]
hypothesis tree:
    head_tail: template A-B from anti-unification of the outputs
      head_tail_1: expression head(x)
      head_tail_2: expression tail(x)
program:
    head_tail(A, B-C) :-
        head_tail_1(A, B),
        head_tail_2(A, C).
    head_tail_1(A, B) :-
        A=[B|_].
    head_tail_2(A, B) :-
        A=[_|B].
candidates built: 899; dropped as observationally equivalent: 556; arguments refused by type: 1020
proof against the reference ref_head_tail/2:
    proved for every input of the declared types:
      unfold head_tail_1/2 (one clause, not recursive)
      unfold head_tail_2/2 (one clause, not recursive)
      head_tail/2 = ref_head_tail/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 88. sum without sum_list (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sum_fold([], 0).
ref_sum_fold([A|B], C) :-
    ref_sum_fold(B, D),
    C is A+D.

?- show_synth(sum_fold, [[1,2,3]-6,[4]-4,[]-0,[2,5]-7], [exclude([sum])], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 6
  [4] -> 4
  [] -> 0
  [2,5] -> 7
hypothesis tree:
    sum_fold: foldr: [] gives 0, [x|xs] gives (r+x) with r the result for xs
program:
    sum_fold([], 0).
    sum_fold([A|B], C) :-
        sum_fold(B, D),
        C is D+A.
candidates built: 812; dropped as observationally equivalent: 496; arguments refused by type: 860
proof against the reference ref_sum_fold/2:
    proved for every input of the declared types:
      sum_fold/2 = ref_sum_fold/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 89. length without length (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_length_fold([], 0).
ref_length_fold([_|A], B) :-
    ref_length_fold(A, C),
    B is 1+C.

?- show_synth(length_fold, [[1,2,3]-3,[4]-1,[]-0,[5,6]-2], [exclude([len])], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 3
  [4] -> 1
  [] -> 0
  [5,6] -> 2
hypothesis tree:
    length_fold: foldr: [] gives 0, [x|xs] gives (r+1) with r the result for xs
program:
    length_fold([], 0).
    length_fold([_|A], B) :-
        length_fold(A, C),
        B is C+1.
candidates built: 596; dropped as observationally equivalent: 360; arguments refused by type: 665
proof against the reference ref_length_fold/2:
    proved for every input of the declared types:
      arithmetic compared as polynomials
      length_fold/2 = ref_length_fold/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 90. reverse without reverse (foldr with append)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_reverse_fold([], []).
ref_reverse_fold([A|B], C) :-
    ref_reverse_fold(B, D),
    append(D, [A], C).

?- show_synth(reverse_fold, [[1,2,3]-[3,2,1],[4]-[4],[]-[],[2,5]-[5,2]], [exclude([rev])], flat).
```

**Output**

```text
examples:
  [1,2,3] -> [3,2,1]
  [4] -> [4]
  [] -> []
  [2,5] -> [5,2]
hypothesis tree:
    reverse_fold: foldr: [] gives [], [x|xs] gives append(r, [x|[]]) with r the result for xs
program:
    reverse_fold([], []).
    reverse_fold([A|B], C) :-
        reverse_fold(B, D),
        append(D, [A], C).
candidates built: 9307; dropped as observationally equivalent: 6319; arguments refused by type: 8668
proof against the reference ref_reverse_fold/2:
    proved for every input of the declared types:
      reverse_fold/2 = ref_reverse_fold/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 91. product of the elements (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_product([], 1).
ref_product([A|B], C) :-
    ref_product(B, D),
    C is A*D.

?- show_synth(product, [[1,2,3]-6,[4]-4,[]-1,[2,5]-10], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 6
  [4] -> 4
  [] -> 1
  [2,5] -> 10
hypothesis tree:
    product: foldr: [] gives 1, [x|xs] gives (r*x) with r the result for xs
program:
    product([], 1).
    product([A|B], C) :-
        product(B, D),
        C is D*A.
candidates built: 919; dropped as observationally equivalent: 554; arguments refused by type: 1025
proof against the reference ref_product/2:
    proved for every input of the declared types:
      product/2 = ref_product/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 92. count the odd elements (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_count_odds([], 0).
ref_count_odds([A|B], C) :-
    ref_count_odds(B, D),
    C is D+A mod 2.

?- show_synth(count_odds, [[1,2,3]-2,[4]-0,[]-0,[5,7,9]-3,[2,4,1]-1], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 2
  [4] -> 0
  [] -> 0
  [5,7,9] -> 3
  [2,4,1] -> 1
hypothesis tree:
    count_odds: foldr: [] gives 0, [x|xs] gives (r+(x mod 2)) with r the result for xs
program:
    count_odds([], 0).
    count_odds([A|B], C) :-
        count_odds(B, D),
        C is D+A mod 2.
candidates built: 2441; dropped as observationally equivalent: 1597; arguments refused by type: 2335
proof against the reference ref_count_odds/2:
    proved for every input of the declared types:
      count_odds/2 = ref_count_odds/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 93. sum of squares (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sum_squares([], 0).
ref_sum_squares([A|B], C) :-
    ref_sum_squares(B, D),
    C is D+A*A.

?- show_synth(sum_squares, [[1,2,3]-14,[4]-16,[]-0,[2,5]-29], [], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 14
  [4] -> 16
  [] -> 0
  [2,5] -> 29
hypothesis tree:
    sum_squares: foldr: [] gives 0, [x|xs] gives (r+(x*x)) with r the result for xs
program:
    sum_squares([], 0).
    sum_squares([A|B], C) :-
        sum_squares(B, D),
        C is D+A*A.
candidates built: 2246; dropped as observationally equivalent: 1478; arguments refused by type: 2113
proof against the reference ref_sum_squares/2:
    proved for every input of the declared types:
      sum_squares/2 = ref_sum_squares/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 94. sum of doubled elements (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sum_doubles([], 0).
ref_sum_doubles([A|B], C) :-
    ref_sum_doubles(B, D),
    C is D+2*A.

?- show_synth(sum_doubles, [[1,2,3]-12,[4]-8,[]-0,[2,5]-14], [exclude([sum])], flat).
```

**Output**

```text
examples:
  [1,2,3] -> 12
  [4] -> 8
  [] -> 0
  [2,5] -> 14
hypothesis tree:
    sum_doubles: foldr: [] gives 0, [x|xs] gives (r+(2*x)) with r the result for xs
program:
    sum_doubles([], 0).
    sum_doubles([A|B], C) :-
        sum_doubles(B, D),
        C is D+2*A.
candidates built: 2030; dropped as observationally equivalent: 1361; arguments refused by type: 1781
proof against the reference ref_sum_doubles/2:
    proved for every input of the declared types:
      sum_doubles/2 = ref_sum_doubles/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 95. maximum without max_list (foldr)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_max_fold([], 0).
ref_max_fold([A|B], C) :-
    ref_max_fold(B, D),
    C is max(A, D).

?- show_synth(max_fold, [[1,3,2]-3,[4]-4,[2,5]-5,[0,1]-1,[]-0], [exclude([maxl,msort,sort,last])], flat).
```

**Output**

```text
examples:
  [1,3,2] -> 3
  [4] -> 4
  [2,5] -> 5
  [0,1] -> 1
  [] -> 0
hypothesis tree:
    max_fold: foldr: [] gives 0, [x|xs] gives (max(r,x)) with r the result for xs
program:
    max_fold([], 0).
    max_fold([A|B], C) :-
        max_fold(B, D),
        C is max(D, A).
candidates built: 783; dropped as observationally equivalent: 444; arguments refused by type: 710
proof against the reference ref_max_fold/2:
    proved for every input of the declared types:
      max_fold/2 = ref_max_fold/2 by induction on argument 1
both run on every input of the pool: equal_on(1555)
```

## 96. flatten a list of lists (foldr with append)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_flatten([], []).
ref_flatten([A|B], C) :-
    ref_flatten(B, D),
    append(A, D, C).

?- show_synth(flatten, [[[1,2],[3]]-[1,2,3],[[4]]-[4],[]-[],[[],[5]]-[5]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [1,2,3]
  [[4]] -> [4]
  [] -> []
  [[],[5]] -> [5]
hypothesis tree:
    flatten: foldr: [] gives [], [x|xs] gives append(x, r) with r the result for xs
program:
    flatten([], []).
    flatten([A|B], C) :-
        flatten(B, D),
        append(A, D, C).
candidates built: 658; dropped as observationally equivalent: 392; arguments refused by type: 847
proof against the reference ref_flatten/2:
    proved for every input of the declared types:
      flatten/2 = ref_flatten/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 97. sort keeping duplicates

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sorted(A, B) :-
    msort(A, B).

?- show_synth(sorted, [[3,1,2]-[1,2,3],[5,4]-[4,5],[2,2,1]-[1,2,2]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [1,2,3]
  [5,4] -> [4,5]
  [2,2,1] -> [1,2,2]
hypothesis tree:
    sorted: expression msort(x)
program:
    sorted(A, B) :-
        msort(A, B).
candidates built: 40; dropped as observationally equivalent: 20; arguments refused by type: 36
proof against the reference ref_sorted/2:
    proved for every input of the declared types:
      sorted/2 = ref_sorted/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 98. sort and remove duplicates

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sorted_set(A, B) :-
    sort(A, B).

?- show_synth(sorted_set, [[3,1,2]-[1,2,3],[5,4]-[4,5],[2,2,1]-[1,2]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [1,2,3]
  [5,4] -> [4,5]
  [2,2,1] -> [1,2]
hypothesis tree:
    sorted_set: expression sort(x)
program:
    sorted_set(A, B) :-
        sort(A, B).
candidates built: 40; dropped as observationally equivalent: 20; arguments refused by type: 36
proof against the reference ref_sorted_set/2:
    proved for every input of the declared types:
      sorted_set/2 = ref_sorted_set/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 99. reverse

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_reversed(A, B) :-
    reverse(A, B).

?- show_synth(reversed, [[3,1,2]-[2,1,3],[5,4]-[4,5],[]-[]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [2,1,3]
  [5,4] -> [4,5]
  [] -> []
hypothesis tree:
    reversed: expression reverse(x)
program:
    reversed(A, B) :-
        reverse(A, B).
candidates built: 40; dropped as observationally equivalent: 21; arguments refused by type: 36
proof against the reference ref_reversed/2:
    proved for every input of the declared types:
      reversed/2 = ref_reversed/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 100. sort into descending order

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_descending(A, B) :-
    msort(A, C),
    reverse(C, B).

?- show_synth(descending, [[3,1,2]-[3,2,1],[5,4,6]-[6,5,4],[1]-[1]], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> [3,2,1]
  [5,4,6] -> [6,5,4]
  [1] -> [1]
hypothesis tree:
    descending: expression reverse(msort(x))
program:
    descending(A, B) :-
        msort(A, C),
        reverse(C, B).
candidates built: 164; dropped as observationally equivalent: 88; arguments refused by type: 186
proof against the reference ref_descending/2:
    proved for every input of the declared types:
      descending/2 = ref_descending/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 101. length

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_count(A, B) :-
    length(A, B).

?- show_synth(count, [[3,1,2]-3,[5,4]-2,[]-0], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 3
  [5,4] -> 2
  [] -> 0
hypothesis tree:
    count: expression length(x)
program:
    count(A, B) :-
        length(A, B).
candidates built: 40; dropped as observationally equivalent: 21; arguments refused by type: 36
proof against the reference ref_count/2:
    proved for every input of the declared types:
      count/2 = ref_count/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 102. sum

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_total(A, B) :-
    sum_list(A, B).

?- show_synth(total, [[3,1,2]-6,[5,4]-9,[]-0], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 6
  [5,4] -> 9
  [] -> 0
hypothesis tree:
    total: expression sum_list(x)
program:
    total(A, B) :-
        sum_list(A, B).
candidates built: 40; dropped as observationally equivalent: 21; arguments refused by type: 36
proof against the reference ref_total/2:
    proved for every input of the declared types:
      total/2 = ref_total/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 103. last element

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_final(A, B) :-
    last(A, B).

?- show_synth(final, [[3,1,2]-2,[5,4]-4,[7]-7], [], flat).
```

**Output**

```text
examples:
  [3,1,2] -> 2
  [5,4] -> 4
  [7] -> 7
hypothesis tree:
    final: expression last(x)
program:
    final(A, B) :-
        last(A, B).
candidates built: 40; dropped as observationally equivalent: 21; arguments refused by type: 36
proof against the reference ref_final/2:
    proved for every input of the declared types:
      final/2 = ref_final/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 104. the list followed by itself

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_doubled_list(A, B) :-
    append(A, A, B).

?- show_synth(doubled_list, [[3,1]-[3,1,3,1],[5]-[5,5],[]-[]], [], flat).
```

**Output**

```text
examples:
  [3,1] -> [3,1,3,1]
  [5] -> [5,5]
  [] -> []
hypothesis tree:
    doubled_list: expression append(x, x)
program:
    doubled_list(A, B) :-
        append(A, A, B).
candidates built: 138; dropped as observationally equivalent: 81; arguments refused by type: 158
proof against the reference ref_doubled_list/2:
    proved for every input of the declared types:
      doubled_list/2 = ref_doubled_list/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 105. the sum of each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sums_each([], []).
ref_sums_each([A|B], [C|D]) :-
    sum_list(A, C),
    ref_sums_each(B, D).

?- show_synth(sums_each, [[[1,2],[3]]-[3,3],[[4,5]]-[9],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [3,3]
  [[4,5]] -> [9]
  [] -> []
hypothesis tree:
    sums_each: map: each element by the sub-predicate
      sums_each_el: expression sum_list(x)
program:
    sums_each([], []).
    sums_each([A|B], [C|D]) :-
        sums_each_el(A, C),
        sums_each(B, D).
    sums_each_el(A, B) :-
        sum_list(A, B).
candidates built: 507; dropped as observationally equivalent: 340; arguments refused by type: 656
proof against the reference ref_sums_each/2:
    proved for every input of the declared types:
      unfold sums_each_el/2 (one clause, not recursive)
      sums_each/2 = ref_sums_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 106. the length of each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_lengths_each([], []).
ref_lengths_each([A|B], [C|D]) :-
    length(A, C),
    ref_lengths_each(B, D).

?- show_synth(lengths_each, [[[1,2],[3]]-[2,1],[[]]-[0],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [2,1]
  [[]] -> [0]
  [] -> []
hypothesis tree:
    lengths_each: map: each element by the sub-predicate
      lengths_each_el: expression length(x)
program:
    lengths_each([], []).
    lengths_each([A|B], [C|D]) :-
        lengths_each_el(A, C),
        lengths_each(B, D).
    lengths_each_el(A, B) :-
        length(A, B).
candidates built: 474; dropped as observationally equivalent: 329; arguments refused by type: 617
proof against the reference ref_lengths_each/2:
    proved for every input of the declared types:
      unfold lengths_each_el/2 (one clause, not recursive)
      lengths_each/2 = ref_lengths_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 107. the maximum of each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_max_each([], []).
ref_max_each([A|B], [C|D]) :-
    max_list(A, C),
    ref_max_each(B, D).

?- show_synth(max_each, [[[1,2],[3]]-[2,3],[[0,5]]-[5],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [2,3]
  [[0,5]] -> [5]
  [] -> []
hypothesis tree:
    max_each: map: each element by the sub-predicate
      max_each_el: expression max_list(x)
program:
    max_each([], []).
    max_each([A|B], [C|D]) :-
        max_each_el(A, C),
        max_each(B, D).
    max_each_el(A, B) :-
        max_list(A, B).
candidates built: 491; dropped as observationally equivalent: 332; arguments refused by type: 636
proof against the reference ref_max_each/2:
    proved for every input of the declared types:
      unfold max_each_el/2 (one clause, not recursive)
      max_each/2 = ref_max_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 108. reverse each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_reverse_each([], []).
ref_reverse_each([A|B], [C|D]) :-
    reverse(A, C),
    ref_reverse_each(B, D).

?- show_synth(reverse_each, [[[1,2],[3]]-[[2,1],[3]],[[0,5,1]]-[[1,5,0]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [[2,1],[3]]
  [[0,5,1]] -> [[1,5,0]]
  [] -> []
hypothesis tree:
    reverse_each: map: each element by the sub-predicate
      reverse_each_el: expression reverse(x)
program:
    reverse_each([], []).
    reverse_each([A|B], [C|D]) :-
        reverse_each_el(A, C),
        reverse_each(B, D).
    reverse_each_el(A, B) :-
        reverse(A, B).
candidates built: 535; dropped as observationally equivalent: 353; arguments refused by type: 682
proof against the reference ref_reverse_each/2:
    proved for every input of the declared types:
      unfold reverse_each_el/2 (one clause, not recursive)
      reverse_each/2 = ref_reverse_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 109. sort each sublist

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_sort_each([], []).
ref_sort_each([A|B], [C|D]) :-
    msort(A, C),
    ref_sort_each(B, D).

?- show_synth(sort_each, [[[2,1],[3]]-[[1,2],[3]],[[0,5,1]]-[[0,1,5]],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[2,1],[3]] -> [[1,2],[3]]
  [[0,5,1]] -> [[0,1,5]]
  [] -> []
hypothesis tree:
    sort_each: map: each element by the sub-predicate
      sort_each_el: expression msort(x)
program:
    sort_each([], []).
    sort_each([A|B], [C|D]) :-
        sort_each_el(A, C),
        sort_each(B, D).
    sort_each_el(A, B) :-
        msort(A, B).
candidates built: 543; dropped as observationally equivalent: 354; arguments refused by type: 692
proof against the reference ref_sort_each/2:
    proved for every input of the declared types:
      unfold sort_each_el/2 (one clause, not recursive)
      sort_each/2 = ref_sort_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 110. minimum and maximum of each sublist (map of a template)

*Category:* `io_synth/hierarchy`

**Input**

```prolog
% reference program
ref_minmax_each([], []).
ref_minmax_each([A|B], [C-D|E]) :-
    min_list(A, C),
    max_list(A, D),
    ref_minmax_each(B, E).

?- show_synth(minmax_each, [[[3,1],[5]]-[1-3,5-5],[[0,2,1]]-[0-2],[]-[]], [], nested).
```

**Output**

```text
examples:
  [[3,1],[5]] -> [1-3,5-5]
  [[0,2,1]] -> [0-2]
  [] -> []
hypothesis tree:
    minmax_each: map: each element by the sub-predicate
      minmax_each_el: template A-B from anti-unification of the outputs
        minmax_each_el_1: expression min_list(x)
        minmax_each_el_2: expression max_list(x)
program:
    minmax_each([], []).
    minmax_each([A|B], [C|D]) :-
        minmax_each_el(A, C),
        minmax_each(B, D).
    minmax_each_el(A, B-C) :-
        minmax_each_el_1(A, B),
        minmax_each_el_2(A, C).
    minmax_each_el_1(A, B) :-
        min_list(A, B).
    minmax_each_el_2(A, B) :-
        max_list(A, B).
candidates built: 1410; dropped as observationally equivalent: 905; arguments refused by type: 1686
proof against the reference ref_minmax_each/2:
    proved for every input of the declared types:
      unfold minmax_each_el/2 (one clause, not recursive)
      unfold minmax_each_el_1/2 (one clause, not recursive)
      unfold minmax_each_el_2/2 (one clause, not recursive)
      minmax_each/2 = ref_minmax_each/2 by induction on argument 1
both run on every input of the pool: equal_on(463)
```

## 111. one list, two examples, size 2

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-list(int)], [[x=[1,3,5]],[x=[5,3,2]]], 2).
```

**Output**

```text
without observational equivalence: 35 expressions kept (40 built)
with observational equivalence:    15 expressions kept (40 built)
```

## 112. one list, two examples, size 3

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-list(int)], [[x=[1,3,5]],[x=[5,3,2]]], 3).
```

**Output**

```text
without observational equivalence: 312 expressions kept (332 built)
with observational equivalence:    63 expressions kept (164 built)
```

## 113. one list, two examples, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-list(int)], [[x=[1,3,5]],[x=[5,3,2]]], 4).
```

**Output**

```text
without observational equivalence: 3125 expressions kept (3195 built)
with observational equivalence:    217 expressions kept (765 built)
```

## 114. one list, one example, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-list(int)], [[x=[1,2]]], 4).
```

**Output**

```text
without observational equivalence: 3120 expressions kept (3195 built)
with observational equivalence:    50 expressions kept (298 built)
```

## 115. one list, three examples, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-list(int)], [[x=[1,2]],[x=[3]],[x=[]]], 4).
```

**Output**

```text
without observational equivalence: 3120 expressions kept (3195 built)
with observational equivalence:    185 expressions kept (616 built)
```

## 116. one integer, size 2

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int], [[x=1],[x=2],[x=3]], 2).
```

**Output**

```text
without observational equivalence: 33 expressions kept (38 built)
with observational equivalence:    13 expressions kept (38 built)
```

## 117. one integer, size 3

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int], [[x=1],[x=2],[x=3]], 3).
```

**Output**

```text
without observational equivalence: 306 expressions kept (326 built)
with observational equivalence:    49 expressions kept (160 built)
```

## 118. one integer, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int], [[x=1],[x=2],[x=3]], 4).
```

**Output**

```text
without observational equivalence: 3292 expressions kept (3362 built)
with observational equivalence:    164 expressions kept (732 built)
```

## 119. one integer on five values, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int], [[x= -1],[x=0],[x=1],[x=2],[x=3]], 4).
```

**Output**

```text
without observational equivalence: 3292 expressions kept (3362 built)
with observational equivalence:    251 expressions kept (851 built)
```

## 120. fold combiner, three probe pairs, size 3

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([r-int,x-int], [[r=0,x=1],[r=1,x=2],[r=2,x=3]], 3).
```

**Output**

```text
without observational equivalence: 415 expressions kept (435 built)
with observational equivalence:    68 expressions kept (245 built)
```

## 121. fold combiner, three probe pairs, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([r-int,x-int], [[r=0,x=1],[r=1,x=2],[r=2,x=3]], 4).
```

**Output**

```text
without observational equivalence: 4794 expressions kept (4864 built)
with observational equivalence:    238 expressions kept (1218 built)
```

## 122. fold combiner, four probe pairs, size 5

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([r-int,x-int], [[r=0,x=1],[r=1,x=2],[r=2,x=3],[r=5,x=0]], 5).
```

**Output**

```text
without observational equivalence: 60493 expressions kept (60776 built)
with observational equivalence:    1980 expressions kept (8605 built)
```

## 123. element and its list, size 3

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int,l-list(int)], [[x=1,l=[1,2]],[x=2,l=[1,2]]], 3).
```

**Output**

```text
without observational equivalence: 412 expressions kept (432 built)
with observational equivalence:    49 expressions kept (198 built)
```

## 124. element and its list, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([x-int,l-list(int)], [[x=1,l=[1,2]],[x=2,l=[1,2]],[x=5,l=[5]]], 4).
```

**Output**

```text
without observational equivalence: 4455 expressions kept (4530 built)
with observational equivalence:    340 expressions kept (1222 built)
```

## 125. list fold combiner, size 4

*Category:* `io_synth/reductions`

**Input**

```prolog
?- show_stats([r-list(int),x-int], [[r=[],x=1],[r=[2],x=3]], 4).
```

**Output**

```text
without observational equivalence: 4383 expressions kept (4488 built)
with observational equivalence:    154 expressions kept (792 built)
```

## 126. sum of squares of the even elements, seed 1

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_sq_evens(A, B) :-
    evens(A, C),
    squares(C, D),
    sum_list(D, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sum_sq_evens, [[1,2,3,4]-20,[2]-4,[1,3]-0,[6,1]-36,[]-0], 1).
```

**Output**

```text
examples:
  [1,2,3,4] -> 20
  [2] -> 4
  [1,3] -> 0
  [6,1] -> 36
  [] -> 0
    sum_sq_evens: genetic algorithm, generation 26: filter((x mod 2) < 1) then map((x*x)) then sum_list
program:
    sum_sq_evens(A, B) :-
        sum_sq_evens_s1(A, C),
        sum_sq_evens_s2(C, D),
        sum_sq_evens_s3(D, B).
    sum_sq_evens_s1([], []).
    sum_sq_evens_s1([A|B], C) :-
        (   sum_sq_evens_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_sq_evens_s1(B, D).
    sum_sq_evens_s1_test(A) :-
        A mod 2<1.
    sum_sq_evens_s2([], []).
    sum_sq_evens_s2([A|B], [C|D]) :-
        sum_sq_evens_s2_el(A, C),
        sum_sq_evens_s2(B, D).
    sum_sq_evens_s2_el(A, B) :-
        B is A*A.
    sum_sq_evens_s3(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_sq_evens/2:
    proved for every input of the declared types:
      unfold sum_sq_evens_s1_test/1 (one clause, not recursive)
      unfold sum_sq_evens_s2_el/2 (one clause, not recursive)
      unfold sum_sq_evens_s3/2 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      sum_sq_evens_s1/2 = evens/2 by induction on argument 1
      sum_sq_evens_s2/2 = squares/2 by induction on argument 1
      sum_sq_evens/2 = ref_sum_sq_evens/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 127. sum of squares of the even elements, seed 2

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_sq_evens(A, B) :-
    evens(A, C),
    squares(C, D),
    sum_list(D, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sum_sq_evens, [[1,2,3,4]-20,[2]-4,[1,3]-0,[6,1]-36,[]-0], 2).
```

**Output**

```text
examples:
  [1,2,3,4] -> 20
  [2] -> 4
  [1,3] -> 0
  [6,1] -> 36
  [] -> 0
    sum_sq_evens: genetic algorithm, generation 65: map((x*x)) then filter((x mod 2) < 1) then sum_list
program:
    sum_sq_evens(A, B) :-
        sum_sq_evens_s1(A, C),
        sum_sq_evens_s2(C, D),
        sum_sq_evens_s3(D, B).
    sum_sq_evens_s1([], []).
    sum_sq_evens_s1([A|B], [C|D]) :-
        sum_sq_evens_s1_el(A, C),
        sum_sq_evens_s1(B, D).
    sum_sq_evens_s1_el(A, B) :-
        B is A*A.
    sum_sq_evens_s2([], []).
    sum_sq_evens_s2([A|B], C) :-
        (   sum_sq_evens_s2_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_sq_evens_s2(B, D).
    sum_sq_evens_s2_test(A) :-
        A mod 2<1.
    sum_sq_evens_s3(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_sq_evens/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 128. sum of squares of the even elements, seed 3

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_sq_evens(A, B) :-
    evens(A, C),
    squares(C, D),
    sum_list(D, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sum_sq_evens, [[1,2,3,4]-20,[2]-4,[1,3]-0,[6,1]-36,[]-0], 3).
```

**Output**

```text
examples:
  [1,2,3,4] -> 20
  [2] -> 4
  [1,3] -> 0
  [6,1] -> 36
  [] -> 0
    sum_sq_evens: genetic algorithm, generation 9: map((x*x)) then filter((x mod 2) < 1) then sum_list
program:
    sum_sq_evens(A, B) :-
        sum_sq_evens_s1(A, C),
        sum_sq_evens_s2(C, D),
        sum_sq_evens_s3(D, B).
    sum_sq_evens_s1([], []).
    sum_sq_evens_s1([A|B], [C|D]) :-
        sum_sq_evens_s1_el(A, C),
        sum_sq_evens_s1(B, D).
    sum_sq_evens_s1_el(A, B) :-
        B is A*A.
    sum_sq_evens_s2([], []).
    sum_sq_evens_s2([A|B], C) :-
        (   sum_sq_evens_s2_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_sq_evens_s2(B, D).
    sum_sq_evens_s2_test(A) :-
        A mod 2<1.
    sum_sq_evens_s3(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_sq_evens/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 129. sum of squares of the even elements, seed 4

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_sq_evens(A, B) :-
    evens(A, C),
    squares(C, D),
    sum_list(D, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sum_sq_evens, [[1,2,3,4]-20,[2]-4,[1,3]-0,[6,1]-36,[]-0], 4).
```

**Output**

```text
examples:
  [1,2,3,4] -> 20
  [2] -> 4
  [1,3] -> 0
  [6,1] -> 36
  [] -> 0
    sum_sq_evens: genetic algorithm, generation 26: filter((x mod 2) < 1) then map((x*x)) then sum_list
program:
    sum_sq_evens(A, B) :-
        sum_sq_evens_s1(A, C),
        sum_sq_evens_s2(C, D),
        sum_sq_evens_s3(D, B).
    sum_sq_evens_s1([], []).
    sum_sq_evens_s1([A|B], C) :-
        (   sum_sq_evens_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_sq_evens_s1(B, D).
    sum_sq_evens_s1_test(A) :-
        A mod 2<1.
    sum_sq_evens_s2([], []).
    sum_sq_evens_s2([A|B], [C|D]) :-
        sum_sq_evens_s2_el(A, C),
        sum_sq_evens_s2(B, D).
    sum_sq_evens_s2_el(A, B) :-
        B is A*A.
    sum_sq_evens_s3(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_sq_evens/2:
    proved for every input of the declared types:
      unfold sum_sq_evens_s1_test/1 (one clause, not recursive)
      unfold sum_sq_evens_s2_el/2 (one clause, not recursive)
      unfold sum_sq_evens_s3/2 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      sum_sq_evens_s1/2 = evens/2 by induction on argument 1
      sum_sq_evens_s2/2 = squares/2 by induction on argument 1
      sum_sq_evens/2 = ref_sum_sq_evens/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 130. sum of squares of the even elements, seed 5

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_sq_evens(A, B) :-
    evens(A, C),
    squares(C, D),
    sum_list(D, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sum_sq_evens, [[1,2,3,4]-20,[2]-4,[1,3]-0,[6,1]-36,[]-0], 5).
```

**Output**

```text
examples:
  [1,2,3,4] -> 20
  [2] -> 4
  [1,3] -> 0
  [6,1] -> 36
  [] -> 0
    sum_sq_evens: genetic algorithm, generation 33: filter((x mod 2) < 1) then map((x*x)) then sum_list
program:
    sum_sq_evens(A, B) :-
        sum_sq_evens_s1(A, C),
        sum_sq_evens_s2(C, D),
        sum_sq_evens_s3(D, B).
    sum_sq_evens_s1([], []).
    sum_sq_evens_s1([A|B], C) :-
        (   sum_sq_evens_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_sq_evens_s1(B, D).
    sum_sq_evens_s1_test(A) :-
        A mod 2<1.
    sum_sq_evens_s2([], []).
    sum_sq_evens_s2([A|B], [C|D]) :-
        sum_sq_evens_s2_el(A, C),
        sum_sq_evens_s2(B, D).
    sum_sq_evens_s2_el(A, B) :-
        B is A*A.
    sum_sq_evens_s3(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_sq_evens/2:
    proved for every input of the declared types:
      unfold sum_sq_evens_s1_test/1 (one clause, not recursive)
      unfold sum_sq_evens_s2_el/2 (one clause, not recursive)
      unfold sum_sq_evens_s3/2 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      sum_sq_evens_s1/2 = evens/2 by induction on argument 1
      sum_sq_evens_s2/2 = squares/2 by induction on argument 1
      sum_sq_evens/2 = ref_sum_sq_evens/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 131. number of positive elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_count_positives(A, B) :-
    pos(A, C),
    length(C, B).
pos([], []).
pos([A|B], C) :-
    (   A>0
    ->  C=[A|D]
    ;   C=D
    ),
    pos(B, D).

?- show_ga(count_positives, [[1,-2,3]-2,[0]-0,[4,5,-1,6]-3,[]-0], 1).
```

**Output**

```text
examples:
  [1,-2,3] -> 2
  [0] -> 0
  [4,5,-1,6] -> 3
  [] -> 0
    count_positives: genetic algorithm, generation 3: filter(x > 0) then length
program:
    count_positives(A, B) :-
        count_positives_s1(A, C),
        count_positives_s2(C, B).
    count_positives_s1([], []).
    count_positives_s1([A|B], C) :-
        (   count_positives_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        count_positives_s1(B, D).
    count_positives_s1_test(A) :-
        A>0.
    count_positives_s2(A, B) :-
        length(A, B).
proof against the reference ref_count_positives/2:
    proved for every input of the declared types:
      unfold count_positives_s1_test/1 (one clause, not recursive)
      unfold count_positives_s2/2 (one clause, not recursive)
      count_positives_s1/2 = pos/2 by induction on argument 1
      count_positives/2 = ref_count_positives/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 132. sum of the doubled odd elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_odd_doubles(A, B) :-
    odds(A, C),
    doubles(C, D),
    sum_list(D, B).
odds([], []).
odds([A|B], C) :-
    (   A mod 2=:=1
    ->  C=[A|D]
    ;   C=D
    ),
    odds(B, D).
doubles([], []).
doubles([A|B], [C|D]) :-
    C is 2*A,
    doubles(B, D).

?- show_ga(sum_odd_doubles, [[1,2,3]-8,[4]-0,[5,7]-24,[]-0], 1).
```

**Output**

```text
examples:
  [1,2,3] -> 8
  [4] -> 0
  [5,7] -> 24
  [] -> 0
    sum_odd_doubles: genetic algorithm, generation 16: filter((x mod 2) =:= 1) then sum_list then (2*x)
program:
    sum_odd_doubles(A, B) :-
        sum_odd_doubles_s1(A, C),
        sum_odd_doubles_s2(C, D),
        sum_odd_doubles_s3(D, B).
    sum_odd_doubles_s1([], []).
    sum_odd_doubles_s1([A|B], C) :-
        (   sum_odd_doubles_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_odd_doubles_s1(B, D).
    sum_odd_doubles_s1_test(A) :-
        A mod 2=:=1.
    sum_odd_doubles_s2(A, B) :-
        sum_list(A, B).
    sum_odd_doubles_s3(A, B) :-
        B is 2*A.
proof against the reference ref_sum_odd_doubles/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 133. largest square

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_max_square(A, B) :-
    squares(A, C),
    max_list(C, B).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(max_square, [[1,-3,2]-9,[2]-4,[0,1]-1], 1).
```

**Output**

```text
examples:
  [1,-3,2] -> 9
  [2] -> 4
  [0,1] -> 1
    max_square: genetic algorithm, generation 37: map((abs(x))) then max_list then (x*x)
program:
    max_square(A, B) :-
        max_square_s1(A, C),
        max_square_s2(C, D),
        max_square_s3(D, B).
    max_square_s1([], []).
    max_square_s1([A|B], [C|D]) :-
        max_square_s1_el(A, C),
        max_square_s1(B, D).
    max_square_s1_el(A, B) :-
        B is abs(A).
    max_square_s2(A, B) :-
        max_list(A, B).
    max_square_s3(A, B) :-
        B is A*A.
proof against the reference ref_max_square/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 134. number of even elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_count_evens(A, B) :-
    evens(A, C),
    length(C, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).

?- show_ga(count_evens, [[1,2,4]-2,[3]-0,[6,8,1,0]-3,[]-0,[3,5]-0,[-1,2]-1], 1).
```

**Output**

```text
examples:
  [1,2,4] -> 2
  [3] -> 0
  [6,8,1,0] -> 3
  [] -> 0
  [3,5] -> 0
  [-1,2] -> 1
    count_evens: genetic algorithm, generation 17: filter((x mod 2) < 1) then length
program:
    count_evens(A, B) :-
        count_evens_s1(A, C),
        count_evens_s2(C, B).
    count_evens_s1([], []).
    count_evens_s1([A|B], C) :-
        (   count_evens_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        count_evens_s1(B, D).
    count_evens_s1_test(A) :-
        A mod 2<1.
    count_evens_s2(A, B) :-
        length(A, B).
proof against the reference ref_count_evens/2:
    proved for every input of the declared types:
      unfold count_evens_s1_test/1 (one clause, not recursive)
      unfold count_evens_s2/2 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      count_evens_s1/2 = evens/2 by induction on argument 1
      count_evens/2 = ref_count_evens/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 135. squares in ascending order

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sorted_squares(A, B) :-
    squares(A, C),
    msort(C, B).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(sorted_squares, [[3,-1,2]-[1,4,9],[-2,0]-[0,4],[]-[]], 1).
```

**Output**

```text
examples:
  [3,-1,2] -> [1,4,9]
  [-2,0] -> [0,4]
  [] -> []
    sorted_squares: genetic algorithm, generation 2: map((x*x)) then msort
program:
    sorted_squares(A, B) :-
        sorted_squares_s1(A, C),
        sorted_squares_s2(C, B).
    sorted_squares_s1([], []).
    sorted_squares_s1([A|B], [C|D]) :-
        sorted_squares_s1_el(A, C),
        sorted_squares_s1(B, D).
    sorted_squares_s1_el(A, B) :-
        B is A*A.
    sorted_squares_s2(A, B) :-
        msort(A, B).
proof against the reference ref_sorted_squares/2:
    proved for every input of the declared types:
      unfold sorted_squares_s1_el/2 (one clause, not recursive)
      unfold sorted_squares_s2/2 (one clause, not recursive)
      sorted_squares_s1/2 = squares/2 by induction on argument 1
      sorted_squares/2 = ref_sorted_squares/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 136. the even elements in reverse order

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_reversed_evens(A, B) :-
    evens(A, C),
    reverse(C, B).
evens([], []).
evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    evens(B, D).

?- show_ga(reversed_evens, [[1,2,3,4]-[4,2],[6,8]-[8,6],[5]-[]], 1).
```

**Output**

```text
examples:
  [1,2,3,4] -> [4,2]
  [6,8] -> [8,6]
  [5] -> []
    reversed_evens: genetic algorithm, generation 2: filter((x mod 2) < 1) then reverse
program:
    reversed_evens(A, B) :-
        reversed_evens_s1(A, C),
        reversed_evens_s2(C, B).
    reversed_evens_s1([], []).
    reversed_evens_s1([A|B], C) :-
        (   reversed_evens_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        reversed_evens_s1(B, D).
    reversed_evens_s1_test(A) :-
        A mod 2<1.
    reversed_evens_s2(A, B) :-
        reverse(A, B).
proof against the reference ref_reversed_evens/2:
    proved for every input of the declared types:
      unfold reversed_evens_s1_test/1 (one clause, not recursive)
      unfold reversed_evens_s2/2 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      reversed_evens_s1/2 = evens/2 by induction on argument 1
      reversed_evens/2 = ref_reversed_evens/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 137. sum after adding one to each element

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_incremented(A, B) :-
    incs(A, C),
    sum_list(C, B).
incs([], []).
incs([A|B], [C|D]) :-
    C is A+1,
    incs(B, D).

?- show_ga(sum_incremented, [[1,2,3]-9,[0]-1,[]-0,[5,5]-12,[2]-3], 1).
```

**Output**

```text
examples:
  [1,2,3] -> 9
  [0] -> 1
  [] -> 0
  [5,5] -> 12
  [2] -> 3
    sum_incremented: genetic algorithm, generation 41: map((x+1)) then sum_list
program:
    sum_incremented(A, B) :-
        sum_incremented_s1(A, C),
        sum_incremented_s2(C, B).
    sum_incremented_s1([], []).
    sum_incremented_s1([A|B], [C|D]) :-
        sum_incremented_s1_el(A, C),
        sum_incremented_s1(B, D).
    sum_incremented_s1_el(A, B) :-
        B is A+1.
    sum_incremented_s2(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_incremented/2:
    proved for every input of the declared types:
      unfold sum_incremented_s1_el/2 (one clause, not recursive)
      unfold sum_incremented_s2/2 (one clause, not recursive)
      sum_incremented_s1/2 = incs/2 by induction on argument 1
      sum_incremented/2 = ref_sum_incremented/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 138. smallest doubled element

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_min_doubled(A, B) :-
    doubles(A, C),
    min_list(C, B).
doubles([], []).
doubles([A|B], [C|D]) :-
    C is 2*A,
    doubles(B, D).

?- show_ga(min_doubled, [[3,1,2]-2,[5]-10,[4,-1]- -2,[2,0,3]-0,[-2,1]- -4], 1).
```

**Output**

```text
examples:
  [3,1,2] -> 2
  [5] -> 10
  [4,-1] -> -2
  [2,0,3] -> 0
  [-2,1] -> -4
    min_doubled: genetic algorithm, generation 26: map((2*x)) then min_list
program:
    min_doubled(A, B) :-
        min_doubled_s1(A, C),
        min_doubled_s2(C, B).
    min_doubled_s1([], []).
    min_doubled_s1([A|B], [C|D]) :-
        min_doubled_s1_el(A, C),
        min_doubled_s1(B, D).
    min_doubled_s1_el(A, B) :-
        B is 2*A.
    min_doubled_s2(A, B) :-
        min_list(A, B).
proof against the reference ref_min_doubled/2:
    proved for every input of the declared types:
      unfold min_doubled_s1_el/2 (one clause, not recursive)
      unfold min_doubled_s2/2 (one clause, not recursive)
      min_doubled_s1/2 = doubles/2 by induction on argument 1
      min_doubled/2 = ref_min_doubled/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 139. sum of the positive elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_positives(A, B) :-
    pos(A, C),
    sum_list(C, B).
pos([], []).
pos([A|B], C) :-
    (   A>0
    ->  C=[A|D]
    ;   C=D
    ),
    pos(B, D).

?- show_ga(sum_positives, [[1,-2,3]-4,[-5]-0,[2,2,-1]-4,[]-0], 1).
```

**Output**

```text
examples:
  [1,-2,3] -> 4
  [-5] -> 0
  [2,2,-1] -> 4
  [] -> 0
    sum_positives: genetic algorithm, generation 12: filter(x > 0) then sum_list
program:
    sum_positives(A, B) :-
        sum_positives_s1(A, C),
        sum_positives_s2(C, B).
    sum_positives_s1([], []).
    sum_positives_s1([A|B], C) :-
        (   sum_positives_s1_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        sum_positives_s1(B, D).
    sum_positives_s1_test(A) :-
        A>0.
    sum_positives_s2(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_positives/2:
    proved for every input of the declared types:
      unfold sum_positives_s1_test/1 (one clause, not recursive)
      unfold sum_positives_s2/2 (one clause, not recursive)
      sum_positives_s1/2 = pos/2 by induction on argument 1
      sum_positives/2 = ref_sum_positives/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 140. last element after sorting

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_largest_sorted(A, B) :-
    msort(A, C),
    last(C, B).

?- show_ga(largest_sorted, [[3,1,2]-3,[5,9,4]-9,[7]-7], 1).
```

**Output**

```text
examples:
  [3,1,2] -> 3
  [5,9,4] -> 9
  [7] -> 7
    largest_sorted: genetic algorithm, generation 0: max_list
program:
    largest_sorted(A, B) :-
        largest_sorted_s1(A, B).
    largest_sorted_s1(A, B) :-
        max_list(A, B).
proof against the reference ref_largest_sorted/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 141. first element after reversing

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_first_reversed(A, B) :-
    reverse(A, [B|_]).

?- show_ga(first_reversed, [[3,1,2]-2,[5,9,4]-4,[7]-7], 1).
```

**Output**

```text
examples:
  [3,1,2] -> 2
  [5,9,4] -> 4
  [7] -> 7
    first_reversed: genetic algorithm, generation 6: last
program:
    first_reversed(A, B) :-
        first_reversed_s1(A, B).
    first_reversed_s1(A, B) :-
        last(A, B).
proof against the reference ref_first_reversed/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 142. squares of the odd elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_squares_of_odds(A, B) :-
    odds(A, C),
    squares(C, B).
odds([], []).
odds([A|B], C) :-
    (   A mod 2=:=1
    ->  C=[A|D]
    ;   C=D
    ),
    odds(B, D).
squares([], []).
squares([A|B], [C|D]) :-
    C is A*A,
    squares(B, D).

?- show_ga(squares_of_odds, [[1,2,3]-[1,9],[4,5]-[25],[2]-[]], 1).
```

**Output**

```text
examples:
  [1,2,3] -> [1,9]
  [4,5] -> [25]
  [2] -> []
    squares_of_odds: genetic algorithm, generation 0: map((x*x)) then filter((x mod 2) =:= 1)
program:
    squares_of_odds(A, B) :-
        squares_of_odds_s1(A, C),
        squares_of_odds_s2(C, B).
    squares_of_odds_s1([], []).
    squares_of_odds_s1([A|B], [C|D]) :-
        squares_of_odds_s1_el(A, C),
        squares_of_odds_s1(B, D).
    squares_of_odds_s1_el(A, B) :-
        B is A*A.
    squares_of_odds_s2([], []).
    squares_of_odds_s2([A|B], C) :-
        (   squares_of_odds_s2_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        squares_of_odds_s2(B, D).
    squares_of_odds_s2_test(A) :-
        A mod 2=:=1.
proof against the reference ref_squares_of_odds/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 143. number of distinct elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_distinct_count(A, B) :-
    sort(A, C),
    length(C, B).

?- show_ga(distinct_count, [[3,1,3]-2,[5,5,5]-1,[1,2]-2,[]-0], 1).
```

**Output**

```text
examples:
  [3,1,3] -> 2
  [5,5,5] -> 1
  [1,2] -> 2
  [] -> 0
    distinct_count: genetic algorithm, generation 2: sort then length
program:
    distinct_count(A, B) :-
        distinct_count_s1(A, C),
        distinct_count_s2(C, B).
    distinct_count_s1(A, B) :-
        sort(A, B).
    distinct_count_s2(A, B) :-
        length(A, B).
proof against the reference ref_distinct_count/2:
    proved for every input of the declared types:
      unfold distinct_count_s1/2 (one clause, not recursive)
      unfold distinct_count_s2/2 (one clause, not recursive)
      distinct_count/2 = ref_distinct_count/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 144. sum of the halved elements

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_sum_halves(A, B) :-
    halves(A, C),
    sum_list(C, B).
halves([], []).
halves([A|B], [C|D]) :-
    C is A//2,
    halves(B, D).

?- show_ga(sum_halves, [[4,5,6]-7,[1]-0,[9,9]-8,[]-0], 1).
```

**Output**

```text
examples:
  [4,5,6] -> 7
  [1] -> 0
  [9,9] -> 8
  [] -> 0
    sum_halves: genetic algorithm, generation 58: map((x//2)) then sum_list
program:
    sum_halves(A, B) :-
        sum_halves_s1(A, C),
        sum_halves_s2(C, B).
    sum_halves_s1([], []).
    sum_halves_s1([A|B], [C|D]) :-
        sum_halves_s1_el(A, C),
        sum_halves_s1(B, D).
    sum_halves_s1_el(A, B) :-
        B is A//2.
    sum_halves_s2(A, B) :-
        sum_list(A, B).
proof against the reference ref_sum_halves/2:
    proved for every input of the declared types:
      unfold sum_halves_s1_el/2 (one clause, not recursive)
      unfold sum_halves_s2/2 (one clause, not recursive)
      sum_halves_s1/2 = halves/2 by induction on argument 1
      sum_halves/2 = ref_sum_halves/2 clause by clause
both run on every input of the pool: equal_on(1555)
```

## 145. twice the sum

*Category:* `io_synth/genetic`

**Input**

```prolog
% reference program
ref_double_sum(A, B) :-
    sum_list(A, C),
    B is 2*C.

?- show_ga(double_sum, [[1,2,3]-12,[5]-10,[]-0], 1).
```

**Output**

```text
examples:
  [1,2,3] -> 12
  [5] -> 10
  [] -> 0
    double_sum: genetic algorithm, generation 3: map((2*x)) then sum_list
program:
    double_sum(A, B) :-
        double_sum_s1(A, C),
        double_sum_s2(C, B).
    double_sum_s1([], []).
    double_sum_s1([A|B], [C|D]) :-
        double_sum_s1_el(A, C),
        double_sum_s1(B, D).
    double_sum_s1_el(A, B) :-
        B is 2*A.
    double_sum_s2(A, B) :-
        sum_list(A, B).
proof against the reference ref_double_sum/2:
    not proved
both run on every input of the pool: equal_on(1555)
```

## 146. drop the minimum from each sublist, from the notes' single example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_dropmin_each([], []).
ref_dropmin_each([A|B], [C|D]) :-
    drop_min(A, C),
    ref_dropmin_each(B, D).
drop_min([], []).
drop_min([A|B], C) :-
    min_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_active(dropmin_each, nested, [initial([[[1,3,5],[5,3,2]]])]).
```

**Output**

```text
pool: 463 inputs; the oracle runs the reference program
query: distinguish([[3]]-[[]],candidates(4))
rounds: 2; examples used: 2; final check: equal_on(463)
program:
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
        ->  D=[A|E]
        ;   D=E
        ),
        dropmin_each_el_sel(B, C, E).
    dropmin_each_el_test(A, B) :-
        A=\=B.
proof against the reference ref_dropmin_each/2:
    proved for every input of the declared types:
      unfold dropmin_each_el_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmin_each_el_sel/3 = del_eq/3 by induction on argument 1
      dropmin_each_el/2 = drop_min/2 clause by clause
      dropmin_each/2 = ref_dropmin_each/2 by induction on argument 1
```

## 147. drop the minimum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_dropmin([], []).
ref_dropmin([A|B], C) :-
    min_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_active(dropmin, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([]-[],candidates(3))
query: counter_example([-2]-[])
query: counter_example([2]-[])
rounds: 4; examples used: 4; final check: equal_on(259)
program:
    dropmin([], []).
    dropmin([A|B], C) :-
        min_list([A|B], D),
        dropmin_sel([A|B], D, C).
    dropmin_sel([], _, []).
    dropmin_sel([A|B], C, D) :-
        (   dropmin_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        dropmin_sel(B, C, E).
    dropmin_test(A, B) :-
        A=\=B.
proof against the reference ref_dropmin/2:
    proved for every input of the declared types:
      unfold dropmin_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmin_sel/3 = del_eq/3 by induction on argument 1
      dropmin/2 = ref_dropmin/2 clause by clause
```

## 148. drop the maximum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_dropmax([], []).
ref_dropmax([A|B], C) :-
    max_list([A|B], D),
    del_eq([A|B], D, C).
del_eq([], _, []).
del_eq([A|B], C, D) :-
    (   A==C
    ->  D=E
    ;   D=[A|E]
    ),
    del_eq(B, C, E).

?- show_active(dropmax, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2,-2]-[],candidates(4))
query: distinguish([1]-[],candidates(2))
rounds: 3; examples used: 3; final check: equal_on(259)
program:
    dropmax([], []).
    dropmax([A|B], C) :-
        max_list([A|B], D),
        dropmax_sel([A|B], D, C).
    dropmax_sel([], _, []).
    dropmax_sel([A|B], C, D) :-
        (   dropmax_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        dropmax_sel(B, C, E).
    dropmax_test(A, B) :-
        A<B.
proof against the reference ref_dropmax/2:
    proved for every input of the declared types:
      unfold dropmax_test/2 (one clause, not recursive)
      at the call, every element of argument 1 is at most argument 2 (library fact about max_list/2), and the tail keeps it
      tests compared on integers that satisfy the invariant
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      dropmax_sel/3 = del_eq/3 by induction on argument 1, for inputs where every element of argument 1 is at most argument 2
      dropmax/2 = ref_dropmax/2 clause by clause
```

## 149. keep the even elements, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_evens([], []).
ref_evens([A|B], C) :-
    (   A mod 2=:=0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_evens(B, D).

?- show_active(evens, small, [initial([[1,2,3,4]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([]-[],candidates(2))
rounds: 2; examples used: 2; final check: equal_on(259)
program:
    evens([], []).
    evens([A|B], C) :-
        (   evens_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        evens(B, D).
    evens_test(A) :-
        A mod 2<1.
proof against the reference ref_evens/2:
    proved for every input of the declared types:
      unfold evens_test/1 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      evens/2 = ref_evens/2 by induction on argument 1
```

## 150. keep the positive elements, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_positives([], []).
ref_positives([A|B], C) :-
    (   A>0
    ->  C=[A|D]
    ;   C=D
    ),
    ref_positives(B, D).

?- show_active(positives, small, [initial([[1,-2,3]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([]-[],candidates(3))
rounds: 2; examples used: 2; final check: equal_on(259)
program:
    positives([], []).
    positives([A|B], C) :-
        (   positives_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        positives(B, D).
    positives_test(A) :-
        A>0.
proof against the reference ref_positives/2:
    proved for every input of the declared types:
      unfold positives_test/1 (one clause, not recursive)
      positives/2 = ref_positives/2 by induction on argument 1
```

## 151. double each element, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_double([], []).
ref_double([A|B], [C|D]) :-
    C is A*2,
    ref_double(B, D).

?- show_active(double, small, [initial([[1,2,3]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-1,-2]-[-2,-4],candidates(3))
query: distinguish([-2,-1,-2]-[-4,-2,-4],candidates(2))
rounds: 3; examples used: 3; final check: equal_on(259)
program:
    double([], []).
    double([A|B], [C|D]) :-
        double_el(A, C),
        double(B, D).
    double_el(A, B) :-
        B is 2*A.
proof against the reference ref_double/2:
    proved for every input of the declared types:
      unfold double_el/2 (one clause, not recursive)
      arithmetic compared as polynomials
      double/2 = ref_double/2 by induction on argument 1
```

## 152. square each element, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_square([], []).
ref_square([A|B], [C|D]) :-
    C is A*A,
    ref_square(B, D).

?- show_active(square, small, [initial([[2,3]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2,-1]-[4,1],candidates(3))
query: distinguish([-2,-2,-1]-[4,4,1],candidates(3))
rounds: 3; examples used: 3; final check: equal_on(259)
program:
    square([], []).
    square([A|B], [C|D]) :-
        square_el(A, C),
        square(B, D).
    square_el(A, B) :-
        B is A*A.
proof against the reference ref_square/2:
    proved for every input of the declared types:
      unfold square_el/2 (one clause, not recursive)
      square/2 = ref_square/2 by induction on argument 1
```

## 153. add one to each element, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_inc([], []).
ref_inc([A|B], [C|D]) :-
    C is A+1,
    ref_inc(B, D).

?- show_active(inc, small, [initial([[1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-1,-2]-[0,-1],candidates(3))
query: distinguish([-2,-2,-1]-[-1,-1,0],candidates(3))
query: distinguish([-2,-2,-2]-[-1,-1,-1],candidates(3))
query: distinguish([-2,-1,-2]-[-1,0,-1],candidates(2))
rounds: 5; examples used: 5; final check: equal_on(259)
program:
    inc([], []).
    inc([A|B], [C|D]) :-
        inc_el(A, C),
        inc(B, D).
    inc_el(A, B) :-
        B is A+1.
proof against the reference ref_inc/2:
    proved for every input of the declared types:
      unfold inc_el/2 (one clause, not recursive)
      inc/2 = ref_inc/2 by induction on argument 1
```

## 154. subtract the minimum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_submin([], []).
ref_submin([A|B], C) :-
    min_list([A|B], D),
    minus([A|B], D, C).
minus([], _, []).
minus([A|B], C, [D|E]) :-
    D is A-C,
    minus(B, C, E).

?- show_active(submin, small, [initial([[3,5,4]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([]-[],candidates(2))
query: counter_example([-2]-[0])
rounds: 3; examples used: 3; final check: equal_on(259)
program:
    submin([], []).
    submin([A|B], C) :-
        min_list([A|B], D),
        submin_each([A|B], D, C).
    submin_each([], _, []).
    submin_each([A|B], C, [D|E]) :-
        submin_el(A, C, D),
        submin_each(B, C, E).
    submin_el(A, B, C) :-
        C is A-B.
proof against the reference ref_submin/2:
    proved for every input of the declared types:
      unfold submin_el/3 (one clause, not recursive)
      submin_each/3 = minus/3 by induction on argument 1
      submin/2 = ref_submin/2 clause by clause
```

## 155. minimum and maximum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_minmax(A, B-C) :-
    min_list(A, B),
    max_list(A, C).

?- show_active(minmax, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: counter_example([-2]-(-2- -2))
query: distinguish([2,3]-(2-3),candidates(4))
rounds: 3; examples used: 3; final check: equal_on(258)
program:
    minmax(A, B-C) :-
        minmax_1(A, B),
        minmax_2(A, C).
    minmax_1(A, B) :-
        min_list(A, B).
    minmax_2(A, B) :-
        max_list(A, B).
proof against the reference ref_minmax/2:
    proved for every input of the declared types:
      unfold minmax_1/2 (one clause, not recursive)
      unfold minmax_2/2 (one clause, not recursive)
      minmax/2 = ref_minmax/2 clause by clause
```

## 156. first and last element, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_first_last([A|B], A-C) :-
    last([A|B], C).

?- show_active(first_last, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: counter_example([-2]-(-2- -2))
query: distinguish([-2,-1]-(-2- -1),candidates(4))
query: distinguish([-2,-2]-(-2- -2),candidates(4))
query: distinguish([-2,1]-(-2-1),candidates(4))
query: distinguish([2,-2]-(2- -2),candidates(4))
rounds: 6; examples used: 6; final check: equal_on(258)
program:
    first_last(A, B-C) :-
        first_last_1(A, B),
        first_last_2(A, C).
    first_last_1(A, B) :-
        A=[B|_].
    first_last_2(A, B) :-
        last(A, B).
proof against the reference ref_first_last/2:
    proved for every input of the declared types:
      unfold first_last_1/2 (one clause, not recursive)
      unfold first_last_2/2 (one clause, not recursive)
      first_last/2 = ref_first_last/2 clause by clause
```

## 157. sort, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_sorted(A, B) :-
    msort(A, B).

?- show_active(sorted, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2,-1]-[-2,-1],candidates(4))
query: distinguish([-2,-2]-[-2,-2],candidates(2))
query: distinguish([-2,-2,-2]-[-2,-2,-2],candidates(2))
rounds: 4; examples used: 4; final check: equal_on(259)
program:
    sorted(A, B) :-
        msort(A, B).
proof against the reference ref_sorted/2:
    proved for every input of the declared types:
      sorted/2 = ref_sorted/2 clause by clause
```

## 158. reverse, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_reversed(A, B) :-
    reverse(A, B).

?- show_active(reversed, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2,-1,-2]-[-2,-1,-2],candidates(3))
rounds: 2; examples used: 2; final check: equal_on(259)
program:
    reversed(A, B) :-
        reverse(A, B).
proof against the reference ref_reversed/2:
    proved for every input of the declared types:
      reversed/2 = ref_reversed/2 clause by clause
```

## 159. length, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_count(A, B) :-
    length(A, B).

?- show_active(count, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2]-1,candidates(4))
query: distinguish([-2,-2]-2,candidates(3))
query: distinguish([-1]-1,candidates(2))
rounds: 4; examples used: 4; final check: equal_on(259)
program:
    count(A, B) :-
        length(A, B).
proof against the reference ref_count/2:
    proved for every input of the declared types:
      count/2 = ref_count/2 clause by clause
```

## 160. sum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_total(A, B) :-
    sum_list(A, B).

?- show_active(total, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2]- -2,candidates(4))
query: distinguish([-2,-2]- -4,candidates(3))
query: distinguish([-2,-1]- -3,candidates(3))
rounds: 4; examples used: 4; final check: equal_on(259)
program:
    total(A, B) :-
        sum_list(A, B).
proof against the reference ref_total/2:
    proved for every input of the declared types:
      total/2 = ref_total/2 clause by clause
```

## 161. keep only the maximum, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_keep_max([], []).
ref_keep_max([A|B], C) :-
    max_list([A|B], D),
    keep_eq([A|B], D, C).
keep_eq([], _, []).
keep_eq([A|B], C, D) :-
    (   A==C
    ->  D=[A|E]
    ;   D=E
    ),
    keep_eq(B, C, E).

?- show_active(keep_max, small, [initial([[3,1,2]])]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([-2]-[-2],candidates(4))
query: distinguish([0,0]-[0,0],candidates(4))
query: distinguish([1]-[1],candidates(2))
rounds: 4; examples used: 4; final check: equal_on(259)
program:
    keep_max([], []).
    keep_max([A|B], C) :-
        max_list([A|B], D),
        keep_max_sel([A|B], D, C).
    keep_max_sel([], _, []).
    keep_max_sel([A|B], C, D) :-
        (   keep_max_test(A, C)
        ->  D=[A|E]
        ;   D=E
        ),
        keep_max_sel(B, C, E).
    keep_max_test(A, B) :-
        A=:=B.
proof against the reference ref_keep_max/2:
    proved for every input of the declared types:
      unfold keep_max_test/2 (one clause, not recursive)
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      keep_max_sel/3 = keep_eq/3 by induction on argument 1
      keep_max/2 = ref_keep_max/2 clause by clause
```

## 162. add one to every element of a list of lists, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_inc_all([], []).
ref_inc_all([A|B], [C|D]) :-
    inc_row(A, C),
    ref_inc_all(B, D).
inc_row([], []).
inc_row([A|B], [C|D]) :-
    C is A+1,
    inc_row(B, D).

?- show_active(inc_all, nested, [initial([[[1,2],[3]]])]).
```

**Output**

```text
pool: 463 inputs; the oracle runs the reference program
query: distinguish([[1,0]]-[[2,1]],candidates(3))
rounds: 2; examples used: 2; final check: equal_on(463)
program:
    inc_all([], []).
    inc_all([A|B], [C|D]) :-
        inc_all_el(A, C),
        inc_all(B, D).
    inc_all_el([], []).
    inc_all_el([A|B], [C|D]) :-
        inc_all_el_el(A, C),
        inc_all_el(B, D).
    inc_all_el_el(A, B) :-
        B is A+1.
proof against the reference ref_inc_all/2:
    proved for every input of the declared types:
      unfold inc_all_el_el/2 (one clause, not recursive)
      inc_all_el/2 = inc_row/2 by induction on argument 1
      inc_all/2 = ref_inc_all/2 by induction on argument 1
```

## 163. keep the even elements of each sublist, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_evens_each([], []).
ref_evens_each([A|B], [C|D]) :-
    evens_row(A, C),
    ref_evens_each(B, D).
evens_row([], []).
evens_row([A|B], C) :-
    (   0=:=A mod 2
    ->  C=[A|D]
    ;   C=D
    ),
    evens_row(B, D).

?- show_active(evens_each, nested, [initial([[[1,2],[3,4]]])]).
```

**Output**

```text
pool: 463 inputs; the oracle runs the reference program
query: distinguish([[2,0]]-[[2,0]],candidates(4))
rounds: 2; examples used: 2; final check: equal_on(463)
program:
    evens_each([], []).
    evens_each([A|B], [C|D]) :-
        evens_each_el(A, C),
        evens_each(B, D).
    evens_each_el([], []).
    evens_each_el([A|B], C) :-
        (   evens_each_el_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        evens_each_el(B, D).
    evens_each_el_test(A) :-
        A mod 2<1.
proof against the reference ref_evens_each/2:
    proved for every input of the declared types:
      unfold evens_each_el_test/1 (one clause, not recursive)
      tests on E mod K compared on every residue
      tests compared in normal form
      evens_each_el/2 = evens_row/2 by induction on argument 1
      evens_each/2 = ref_evens_each/2 by induction on argument 1
```

## 164. sum of each sublist, from one example

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_sums_each([], []).
ref_sums_each([A|B], [C|D]) :-
    sum_list(A, C),
    ref_sums_each(B, D).

?- show_active(sums_each, nested, [initial([[[1,2],[3]]])]).
```

**Output**

```text
pool: 463 inputs; the oracle runs the reference program
query: distinguish([[]]-[0],candidates(3))
query: distinguish([[0,1]]-[1],candidates(3))
query: distinguish([[0,2]]-[2],candidates(3))
query: distinguish([[0]]-[0],candidates(3))
query: distinguish([[],[1]]-[0,1],candidates(2))
query: distinguish([[1],[]]-[1,0],candidates(2))
rounds: 7; examples used: 7; final check: equal_on(463)
program:
    sums_each([], []).
    sums_each([A|B], [C|D]) :-
        sums_each_el(A, C),
        sums_each(B, D).
    sums_each_el(A, B) :-
        sum_list(A, B).
proof against the reference ref_sums_each/2:
    proved for every input of the declared types:
      unfold sums_each_el/2 (one clause, not recursive)
      sums_each/2 = ref_sums_each/2 by induction on argument 1
```

## 165. keep the elements greater than one, from the first two pool inputs

*Category:* `io_synth/active`

**Input**

```prolog
% reference program (the oracle)
ref_above_one([], []).
ref_above_one([A|B], C) :-
    (   A>1
    ->  C=[A|D]
    ;   C=D
    ),
    ref_above_one(B, D).

?- show_active(above_one, small, [initial(2)]).
```

**Output**

```text
pool: 259 inputs; the oracle runs the reference program
query: distinguish([0]-[],candidates(3))
query: distinguish([1]-[],candidates(3))
query: distinguish([2]-[2],candidates(3))
rounds: 4; examples used: 5; final check: equal_on(259)
program:
    above_one([], []).
    above_one([A|B], C) :-
        (   above_one_test(A)
        ->  C=[A|D]
        ;   C=D
        ),
        above_one(B, D).
    above_one_test(A) :-
        A>1.
proof against the reference ref_above_one/2:
    proved for every input of the declared types:
      unfold above_one_test/1 (one clause, not recursive)
      above_one/2 = ref_above_one/2 by induction on argument 1
```

## 166. 2*X and X+X: proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is X+X, e(Xs,Ys))], e, [list(int), any]).
```

**Output**

```text
proved for every input of the declared types:
      arithmetic compared as polynomials
      d/2 = e/2 by induction on argument 1
```

## 167. 2*X and 2*X+1: not proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([d([],[]), (d([X|Xs],[Y|Ys]) :- Y is 2*X, d(Xs,Ys))], d, [e([],[]), (e([X|Xs],[Y|Ys]) :- Y is 2*X+1, e(Xs,Ys))], e, [list(int), any]).
```

**Output**

```text
not proved
```

## 168. msort and sort are different library calls: not proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([(s(L, R) :- msort(L, R))], s, [(t(L, R) :- sort(L, R))], t, [list(int), any]).
```

**Output**

```text
not proved
```

## 169. X > 1 and X >= 2 on integers: proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([f([],[]), (f([X|Xs],R) :- (X > 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X >= 2 -> R=[X|R1] ; R=R1), g(Xs,R1))], g, [list(int), any]).
```

**Output**

```text
proved for every input of the declared types:
      tests compared in normal form
      f/2 = g/2 by induction on argument 1
```

## 170. residues and a flipped if-then-else: proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([f([],[]), (f([X|Xs],R) :- (X mod 2 < 1 -> R=[X|R1] ; R=R1), f(Xs,R1))], f, [g([],[]), (g([X|Xs],R) :- (X mod 2 =:= 1 -> R=R1 ; R=[X|R1]), g(Xs,R1))], g, [list(int), any]).
```

**Output**

```text
proved for every input of the declared types:
      tests on E mod K compared on every residue
      tests compared in normal form
      if-then-else with the test negated and the branches swapped
      f/2 = g/2 by induction on argument 1
```

## 171. == on integers read as =:=: proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([f([],_,[]), (f([X|Xs],M,R) :- (X =\= M -> R=[X|R1] ; R=R1), f(Xs,M,R1))], f, [g([],_,[]), (g([X|Xs],M,R) :- (X == M -> R=R1 ; R=[X|R1]), g(Xs,M,R1))], g, [list(int), int, any]).
```

**Output**

```text
proved for every input of the declared types:
      tests compared in normal form
      == and \== on integers read as =:= and =\=
      if-then-else with the test negated and the branches swapped
      f/3 = g/3 by induction on argument 1
```

## 172. == on terms of unknown type is not =:=: not proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([f([],_,[]), (f([X|Xs],M,R) :- (X =\= M -> R=[X|R1] ; R=R1), f(Xs,M,R1))], f, [g([],_,[]), (g([X|Xs],M,R) :- (X == M -> R=R1 ; R=[X|R1]), g(Xs,M,R1))], g, [list(any), any, any]).
```

**Output**

```text
not proved
```

## 173. a recursive call that is not on the tail cannot use the induction hypothesis: not proved

*Category:* `io_synth/checks-proof`

**Input**

```prolog
?- show_equal([c([],0), (c([_|Xs],N) :- c(Xs,M), N is M+1)], c, [d([],0), (d([X|Xs],N) :- d([X|Xs],M), N is M+1)], d, [list(int), any]).
```

**Output**

```text
not proved
```

## 174. the first example not reproduced

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([q(X, Y) :- Y is X + 1], q, [1-2, 2-4]).
```

**Output**

```text
differs(2,3,4)
```

## 175. every example reproduced

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([q(X, Y) :- Y is X + 1], q, [1-2, 2-3]).
```

**Output**

```text
ok
```

## 176. runaway recursion stops at the inference limit

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([(loop(X, Y) :- loop(X, Y))], loop, [1-1]).
```

**Output**

```text
differs(1,err,1)
```

## 177. a call that fails

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([f(a, 1)], f, [a-1, b-2]).
```

**Output**

```text
differs(b,err,2)
```

## 178. head of the empty list fails

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([(h(L, X) :- L = [X|_])], h, [[1,2]-1, []-0]).
```

**Output**

```text
differs([],err,0)
```

## 179. an exception counts as no answer

*Category:* `io_synth/checks-run_all`

**Input**

```prolog
?- show_run_all([(t(X, Y) :- Y is 10 // X)], t, [2-5, 0-0]).
```

**Output**

```text
differs(0,err,0)
```

## 180. append becomes app, and app's definition is added

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([r([], []), (r([X|Xs], R) :- r(Xs, R1), append(R1, [X], R))], r).
```

**Output**

```text
specification for fold.pl:
    r([], []).
    r([A|B], C) :-
        r(B, D),
        app(D, [A], C).
    app([], A, A).
    app([A|B], C, [A|D]) :-
        app(B, C, D).
```

## 181. a sum specification is kept as it is

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([s([], 0), (s([X|Xs], S) :- s(Xs, S0), S is S0 + X)], s).
```

**Output**

```text
specification for fold.pl:
    s([], 0).
    s([A|B], C) :-
        s(B, D),
        C is D+A.
```

## 182. a library call is refused

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([(m(L, M) :- min_list(L, M))], m).
```

**Output**

```text
not a fold.pl specification: it calls a library predicate
```

## 183. if-then-else is refused

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([e([], []), (e([X|Xs], R) :- (X > 0 -> R = [X|R1] ; R = R1), e(Xs, R1))], e).
```

**Output**

```text
not a fold.pl specification: it calls a library predicate
```

## 184. a length specification

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([l([], 0), (l([_|Xs], N) :- l(Xs, N0), N is N0 + 1)], l).
```

**Output**

```text
specification for fold.pl:
    l([], 0).
    l([_|A], B) :-
        l(A, C),
        B is C+1.
```

## 185. flatten: append becomes app

*Category:* `io_synth/checks-fold_spec`

**Input**

```prolog
?- show_fold_spec([f([], []), (f([X|Xs], R) :- f(Xs, R1), append(X, R1, R))], f).
```

**Output**

```text
specification for fold.pl:
    f([], []).
    f([A|B], C) :-
        f(B, D),
        app(A, D, C).
    app([], A, A).
    app([A|B], C, [A|D]) :-
        app(B, C, D).
```

## 186. sum

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sum([], 0).
ref_sum([A|B], C) :-
    ref_sum(B, D),
    C is A+D.

?- show_to_algorithm(sum, [[1,2,3]-6,[4]-4,[]-0,[2,5]-7], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 6
  [4] -> 4
  [] -> 0
  [2,5] -> 7
program found:
    sum([], 0).
    sum([A|B], C) :-
        sum(B, D),
        C is D+A.
proof against the reference ref_sum/2:
    proved for every input of the declared types:
      sum/2 = ref_sum/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sum([],0).
    sum([A|B],C) :- sum_acc(B,C,A).
    sum_acc([],A,B) :- A is 0+B.
    sum_acc([A|B],C,D) :- E is A+D, sum_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 187. length

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_len([], 0).
ref_len([_|A], B) :-
    ref_len(A, C),
    B is C+1.

?- show_to_algorithm(len, [[1,2,3]-3,[4]-1,[]-0,[5,6]-2], [len], [in(list(any)),out], 7).
```

**Output**

```text
examples:
  [1,2,3] -> 3
  [4] -> 1
  [] -> 0
  [5,6] -> 2
program found:
    len([], 0).
    len([_|A], B) :-
        len(A, C),
        B is C+1.
proof against the reference ref_len/2:
    proved for every input of the declared types:
      len/2 = ref_len/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    len([],0).
    len([A|B],C) :- len_acc(B,C,1).
    len_acc([],A,B) :- A is 0+B.
    len_acc([A|B],C,D) :- E is 1+D, len_acc(B,C,E).
total: yes; specification functional: yes; typed answers: yes
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(255)
```

## 188. naive reverse

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_rev([], []).
ref_rev([A|B], C) :-
    ref_rev(B, D),
    append(D, [A], C).

?- show_to_algorithm(rev, [[1,2,3]-[3,2,1],[4]-[4],[]-[],[2,5]-[5,2]], [rev], [in(list(any)),out], 7).
```

**Output**

```text
examples:
  [1,2,3] -> [3,2,1]
  [4] -> [4]
  [] -> []
  [2,5] -> [5,2]
program found:
    rev([], []).
    rev([A|B], C) :-
        rev(B, D),
        append(D, [A], C).
proof against the reference ref_rev/2:
    proved for every input of the declared types:
      rev/2 = ref_rev/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [app_assoc]):
    rev([],[]).
    rev([A|B],C) :- rev_acc(B,[A],C).
    rev_acc([],A,A).
    rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D).
total: yes; specification functional: yes; typed answers: yes
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(255)
```

## 189. sum of squares

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sumsq([], 0).
ref_sumsq([A|B], C) :-
    ref_sumsq(B, D),
    C is A*A+D.

?- show_to_algorithm(sumsq, [[1,2,3]-14,[4]-16,[]-0,[2,5]-29], [], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 14
  [4] -> 16
  [] -> 0
  [2,5] -> 29
program found:
    sumsq([], 0).
    sumsq([A|B], C) :-
        sumsq(B, D),
        C is D+A*A.
proof against the reference ref_sumsq/2:
    proved for every input of the declared types:
      arithmetic compared as polynomials
      sumsq/2 = ref_sumsq/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sumsq([],0).
    sumsq([A|B],C) :- D is A*A, sumsq_acc(B,C,D).
    sumsq_acc([],A,B) :- A is 0+B.
    sumsq_acc([A|B],C,D) :- E is A*A+D, sumsq_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 190. sum of doubles

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sumdbl([], 0).
ref_sumdbl([A|B], C) :-
    ref_sumdbl(B, D),
    C is D+A+A.

?- show_to_algorithm(sumdbl, [[1,2,3]-12,[4]-8,[]-0,[2,5]-14], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 12
  [4] -> 8
  [] -> 0
  [2,5] -> 14
program found:
    sumdbl([], 0).
    sumdbl([A|B], C) :-
        sumdbl(B, D),
        C is D+2*A.
proof against the reference ref_sumdbl/2:
    proved for every input of the declared types:
      arithmetic compared as polynomials
      sumdbl/2 = ref_sumdbl/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sumdbl([],0).
    sumdbl([A|B],C) :- D is 2*A, sumdbl_acc(B,C,D).
    sumdbl_acc([],A,B) :- A is 0+B.
    sumdbl_acc([A|B],C,D) :- E is 2*A+D, sumdbl_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 191. product

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_prod([], 1).
ref_prod([A|B], C) :-
    ref_prod(B, D),
    C is D*A.

?- show_to_algorithm(prod, [[1,2,3]-6,[4]-4,[]-1,[2,5]-10], [], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 6
  [4] -> 4
  [] -> 1
  [2,5] -> 10
program found:
    prod([], 1).
    prod([A|B], C) :-
        prod(B, D),
        C is D*A.
proof against the reference ref_prod/2:
    proved for every input of the declared types:
      prod/2 = ref_prod/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [times_assoc]):
    prod([],1).
    prod([A|B],C) :- prod_acc(B,C,A).
    prod_acc([],A,B) :- A is 1*B.
    prod_acc([A|B],C,D) :- E is A*D, prod_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 192. count the odd elements

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_cnt_odd([], 0).
ref_cnt_odd([A|B], C) :-
    ref_cnt_odd(B, D),
    C is A mod 2+D.

?- show_to_algorithm(cnt_odd, [[1,2,3]-2,[4]-0,[]-0,[5,7,9]-3,[2,4,1]-1], [len], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 2
  [4] -> 0
  [] -> 0
  [5,7,9] -> 3
  [2,4,1] -> 1
program found:
    cnt_odd([], 0).
    cnt_odd([A|B], C) :-
        cnt_odd(B, D),
        C is D+A mod 2.
proof against the reference ref_cnt_odd/2:
    proved for every input of the declared types:
      arithmetic compared as polynomials
      cnt_odd/2 = ref_cnt_odd/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    cnt_odd([],0).
    cnt_odd([A|B],C) :- D is A mod 2, cnt_odd_acc(B,C,D).
    cnt_odd_acc([],A,B) :- A is 0+B.
    cnt_odd_acc([A|B],C,D) :- E is A mod 2+D, cnt_odd_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 193. flatten a list of lists

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_flat2([], []).
ref_flat2([A|B], C) :-
    ref_flat2(B, D),
    append(A, D, C).

?- show_to_algorithm(flat2, [[[1,2],[3]]-[1,2,3],[[4]]-[4],[]-[],[[],[5]]-[5]], [], [in(list(list(any))),out], 3).
```

**Output**

```text
examples:
  [[1,2],[3]] -> [1,2,3]
  [[4]] -> [4]
  [] -> []
  [[],[5]] -> [5]
program found:
    flat2([], []).
    flat2([A|B], C) :-
        flat2(B, D),
        append(A, D, C).
proof against the reference ref_flat2/2:
    proved for every input of the declared types:
      flat2/2 = ref_flat2/2 by induction on argument 1
fold.pl derives, by fuse (lemmas []):
    flat2([],[]).
    flat2([A|B],C) :- flat2_fuse(A,B,C).
    flat2_fuse([],A,B) :- flat2(A,B).
    flat2_fuse([A|B],C,[A|D]) :- flat2_fuse(B,C,D).
total: yes; specification functional: yes; typed answers: yes
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(3616)
```

## 194. twice the length

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_len_plus([], 0).
ref_len_plus([_|A], B) :-
    ref_len_plus(A, C),
    B is C+2.

?- show_to_algorithm(len_plus, [[1,2,3]-6,[4]-2,[]-0,[5,6]-4], [len], [in(list(any)),out], 7).
```

**Output**

```text
examples:
  [1,2,3] -> 6
  [4] -> 2
  [] -> 0
  [5,6] -> 4
program found:
    len_plus([], 0).
    len_plus([_|A], B) :-
        len_plus(A, C),
        B is C+1+1.
proof against the reference ref_len_plus/2:
    proved for every input of the declared types:
      arithmetic compared as polynomials
      len_plus/2 = ref_len_plus/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    len_plus([],0).
    len_plus([A|B],C) :- D is 1+1, len_plus_acc(B,C,D).
    len_plus_acc([],A,B) :- A is 0+B.
    len_plus_acc([A|B],C,D) :- E is 1+1+D, len_plus_acc(B,C,E).
total: yes; specification functional: yes; typed answers: yes
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(255)
```

## 195. sum of incremented elements

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sum_inc([], 0).
ref_sum_inc([A|B], C) :-
    ref_sum_inc(B, D),
    C is D+A+1.

?- show_to_algorithm(sum_inc, [[1,2,3]-9,[4]-5,[]-0,[2,5]-9], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 9
  [4] -> 5
  [] -> 0
  [2,5] -> 9
program found:
    sum_inc([], 0).
    sum_inc([A|B], C) :-
        sum_inc(B, D),
        C is D+A+1.
proof against the reference ref_sum_inc/2:
    proved for every input of the declared types:
      sum_inc/2 = ref_sum_inc/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sum_inc([],0).
    sum_inc([A|B],C) :- D is A+1, sum_inc_acc(B,C,D).
    sum_inc_acc([],A,B) :- A is 0+B.
    sum_inc_acc([A|B],C,D) :- E is A+1+D, sum_inc_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 196. negated sum

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sum_neg([], 0).
ref_sum_neg([A|B], C) :-
    ref_sum_neg(B, D),
    C is D-A.

?- show_to_algorithm(sum_neg, [[1,2,3]- -6,[4]- -4,[]-0,[2,5]- -7], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> -6
  [4] -> -4
  [] -> 0
  [2,5] -> -7
program found:
    sum_neg([], 0).
    sum_neg([A|B], C) :-
        sum_neg(B, D),
        C is D-A.
proof against the reference ref_sum_neg/2:
    proved for every input of the declared types:
      sum_neg/2 = ref_sum_neg/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sum_neg([],0).
    sum_neg([A|B],C) :- D is -A, sum_neg_acc(B,C,D).
    sum_neg_acc([],A,B) :- A is 0+B.
    sum_neg_acc([A|B],C,D) :- E is -A+D, sum_neg_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 197. length of integer lists

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_cnt_pos([], 0).
ref_cnt_pos([_|A], B) :-
    ref_cnt_pos(A, C),
    B is C+1.

?- show_to_algorithm(cnt_pos, [[1,2,3]-3,[4]-1,[]-0,[2,5]-2], [len], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,2,3] -> 3
  [4] -> 1
  [] -> 0
  [2,5] -> 2
program found:
    cnt_pos([], 0).
    cnt_pos([_|A], B) :-
        cnt_pos(A, C),
        B is C+1.
proof against the reference ref_cnt_pos/2:
    proved for every input of the declared types:
      cnt_pos/2 = ref_cnt_pos/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    cnt_pos([],0).
    cnt_pos([A|B],C) :- cnt_pos_acc(B,C,1).
    cnt_pos_acc([],A,B) :- A is 0+B.
    cnt_pos_acc([A|B],C,D) :- E is 1+D, cnt_pos_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 198. sum of absolute values

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sum_abs([], 0).
ref_sum_abs([A|B], C) :-
    ref_sum_abs(B, D),
    C is D+abs(A).

?- show_to_algorithm(sum_abs, [[1,-2,3]-6,[4]-4,[]-0,[-2,5]-7], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,-2,3] -> 6
  [4] -> 4
  [] -> 0
  [-2,5] -> 7
program found:
    sum_abs([], 0).
    sum_abs([A|B], C) :-
        sum_abs(B, D),
        C is D+abs(A).
proof against the reference ref_sum_abs/2:
    proved for every input of the declared types:
      sum_abs/2 = ref_sum_abs/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sum_abs([],0).
    sum_abs([A|B],C) :- D is abs(A), sum_abs_acc(B,C,D).
    sum_abs_acc([],A,B) :- A is 0+B.
    sum_abs_acc([A|B],C,D) :- E is abs(A)+D, sum_abs_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 199. sum of halved elements

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_sum_halves_fold([], 0).
ref_sum_halves_fold([A|B], C) :-
    ref_sum_halves_fold(B, D),
    C is D+A//2.

?- show_to_algorithm(sum_halves_fold, [[4,5,6]-7,[1]-0,[]-0,[9,9]-8], [sum], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [4,5,6] -> 7
  [1] -> 0
  [] -> 0
  [9,9] -> 8
program found:
    sum_halves_fold([], 0).
    sum_halves_fold([A|B], C) :-
        sum_halves_fold(B, D),
        C is D+A//2.
proof against the reference ref_sum_halves_fold/2:
    proved for every input of the declared types:
      sum_halves_fold/2 = ref_sum_halves_fold/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [plus_assoc]):
    sum_halves_fold([],0).
    sum_halves_fold([A|B],C) :- D is A//2, sum_halves_fold_acc(B,C,D).
    sum_halves_fold_acc([],A,B) :- A is 0+B.
    sum_halves_fold_acc([A|B],C,D) :- E is A//2+D, sum_halves_fold_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

## 200. maximum of non-negative integers

*Category:* `io_synth/to-algorithm`

**Input**

```prolog
% reference program
ref_maxf([], 0).
ref_maxf([A|B], C) :-
    ref_maxf(B, D),
    C is max(D, A).

?- show_to_algorithm(maxf, [[1,3,2]-3,[4]-4,[2,5]-5,[0,1]-1,[]-0], [maxl,msort,sort,last], [in(list(int)),out], 4).
```

**Output**

```text
examples:
  [1,3,2] -> 3
  [4] -> 4
  [2,5] -> 5
  [0,1] -> 1
  [] -> 0
program found:
    maxf([], 0).
    maxf([A|B], C) :-
        maxf(B, D),
        C is max(D, A).
proof against the reference ref_maxf/2:
    proved for every input of the declared types:
      maxf/2 = ref_maxf/2 by induction on argument 1
fold.pl derives, by accumulate (lemmas [max_assoc]):
    maxf([],0).
    maxf([A|B],C) :- maxf_acc(B,C,A).
    maxf_acc([],A,B) :- A is max(0,B).
    maxf_acc([A|B],C,D) :- E is max(A,D), maxf_acc(B,C,E).
total: yes; specification functional: yes; typed answers: no
so the derived program equals the specification on every input of the declared types
bounded check: equal_on(341)
```

