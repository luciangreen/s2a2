# S2A in mnns compared with S2A2

There are three programs called S2A:

| | Where | Learns from | Produces |
| --- | --- | --- | --- |
| S2A | `Philosophy/s2a` | strings | rearrangements of strings (the S2A that S2A2's README calls "S2A", under "Why a new S2A") |
| `s2a/4` | mnns, `prolog/s2a/s2a.pl` (391 lines, Stage 8 "in progress") | input/output examples | one clause: a projection or an integer polynomial |
| S2A2 | this repository | pairs of programs (`s2a2.pl`), specifications (`fold.pl`), input/output examples (`io_synth.pl`) | optimisation algorithms, faster programs, and hierarchies of predicates, with proofs |

This note compares the mnns `s2a/4` (checked at mnns commit `81aafd7`) with S2A2's `io_synth.pl`, the part that does the same job: a program from input/output examples.

## What mnns `s2a/4` does

`s2a(Name, Spec, Options, Result)` takes examples `[[input,[['A',In]]],[output,[['B',Out]]]]` and tries, in this order:

1. **Input address.** A unique position in the input whose subterm equals the output in every example. For example, `box(red,[5,6]) → [5,6]` gives `projection(box(_, A), A)`.
2. **Integer affine, quadratic and cubic** formulas, solved exactly from the examples. For example, `1→5, 2→7, 4→11` gives `B is 2*A+3`.
3. **A table** of the examples, only with `allow_table(true)`.

Otherwise it returns `no_algorithm(Reason)`, or `ambiguous(Candidates)` when several addresses fit. The result is an `mnn_program/5` in the mnns IR, with `proof([])`. The trace says how many examples it reproduces, but no proof is made. Its own documentation says it does not yet infer recursive list algorithms such as reverse (requirement R4.1.2).

## Run on the same tasks

`docs/compare_mnns_s2a.pl` runs both on 12 tasks, then runs each program on held-out inputs that neither saw:

| task | mnns s2a/4 | held out | S2A2 io_synth | held out |
| --- | --- | --- | --- | --- |
| projection | s2a_input_address | yes | projection | yes |
| swap_pair | no_algorithm(no_generalization_candidate) | - | expression | yes |
| affine | s2a_affine | yes | expression | yes |
| quadratic | s2a_quadratic | yes | expression | yes |
| cubic | s2a_cubic | yes | polynomial | yes |
| reverse | no_algorithm(no_generalization_candidate) | - | expression | yes |
| double_each | no_algorithm(no_generalization_candidate) | - | map | yes |
| evens | no_algorithm(no_generalization_candidate) | - | filter | yes |
| sum | no_algorithm(no_generalization_candidate) | - | expression | yes |
| minmax | no_algorithm(no_generalization_candidate) | - | template | yes |
| dropmin_each | no_algorithm(no_generalization_candidate) | - | map | yes |
| inc_all | no_algorithm(no_generalization_candidate) | - | map | yes |

mnns `s2a/4` solves 4 of the 12 and S2A2 solves all 12. Every program that either one returns passes its held-out inputs.

- **Methods taken from mnns.** S2A2 at first solved 10, because it had no way to take an argument out of a compound term and its expressions stop at size 4 (so not a cubic). It now has mnns's two methods as hypotheses of its own:
  - **projection:** a unique address whose subterm equals the output, giving `projection(box(_, A), A)`;
  - **polynomial:** degree 1 to 3, solved exactly with integer coefficients, giving `cubic(A, B) :- B is A*A*A+1`.

  Both are tried after a single expression, so list tasks are solved as before. Both are proved by `io_proof.pl` against a reference.
- **S2A2 only:** everything with lists or recursion.
  - For the swap of a pair, S2A2 finds `reverse/2`.
  - The [README's S2A2 results](../README.md) give hierarchies such as drop-the-minimum-per-sublist, each proved equal to a reference program.
- **Both:** affine and quadratic. mnns's programs keep zero terms (`B is 1*A*A+0*A+1`); S2A2's are simplified (`B is A*A+1`, `B is 2*(A+1)+1`).

## Differences

| | mnns `s2a/4` | S2A2 `io_synth.pl` |
| --- | --- | --- |
| Hypotheses | address projection; integer polynomials of degree 1 to 3 | typed expressions; the same projection and polynomials; map, filter (plain, or using the whole list), templates by anti-unification, foldr; genetic pipelines |
| Recursion and lists | none | yes, including invented helper predicates, maps inside maps and filters inside maps |
| Compound-term projection | yes | yes (the same method) |
| Arithmetic | exact solving for degree ≤ 3 | enumeration up to size 4, then the same exact solving for degree ≤ 3 |
| Several answers fit | `ambiguous(Candidates)` | smallest first; `active_synth/6` asks an oracle about a distinguishing input |
| Proof | `proof([])`: the examples are reproduced; nothing else is proved | `io_proof.pl` proves the program equal to a reference program for every input of the declared types; `fold.pl` proves faster versions equal |
| Table fallback | with `allow_table(true)` | none |
| Output | mnns IR (`mnn_program/5`), ready for the mnns pipeline | plain Prolog clauses |
| After synthesis | the mnns pipeline (Detlog, PLOp, …) | `fold.pl` derives faster programs (accumulators, tupling, fusion) |

## What follows

- **They were complementary; S2A2 now covers both.** mnns's address projection and exact polynomial solving are now hypotheses of `io_synth`. S2A2's structural search, proofs and optimisation cover the recursive list programs that mnns's own requirement R4.1.2 asks for and does not yet meet.
- **mnns can call S2A2.** mnns's `prolog/s2a/s2a2_bridge.pl` (`mnn_s2a2:s2a2/4`) takes an mnns spec and runs mnns's own `s2a/4` first. When that returns `no_algorithm`, it calls S2A2's `io_synth` and returns the program in mnns's `mnn_program/5` IR. Given a reference program, it adds an mnns `induction_equivalence` proof, which mnns's checker re-proves with its own copy of `io_proof.pl`. The same module runs S2A2's `learn/2`, `apply_algorithm/5` and `fold.pl` on mnns programs. This is item 5 of S2A2's Work remaining; mnns's `docs/s2a2.md` keeps its status.
- **Bugs found by this comparison.** Running these tasks found two bugs in `io_synth.pl`, both now fixed and tested:
  - A task named like a library predicate (`reverse`) emitted `reverse(A,B) :- reverse(A,B)`. Library calls are now module-qualified when they clash.
  - The genetic algorithm hung when no gene accepts the input type (`box(...)`). It now fails at once, and its emitted program is checked on every example before it is returned.

To reproduce, run this from the S2A2 root, with mnns cloned next to it:

```sh
MNNS=../mnns swipl -q -g main -t halt docs/compare_mnns_s2a.pl
```
