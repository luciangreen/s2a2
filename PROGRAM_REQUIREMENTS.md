# S2A2: program requirements

## Purpose

Learn an optimisation algorithm (a list of rewrite rules with conditions) from two pairs of (unoptimised, optimised) Prolog programs. Then apply it to programs of other shapes, lengths, names and arities, and prove every result equal to the original.

## Functional requirements

| Id | Requirement | Status |
| --- | --- | --- |
| R1 | Represent a program as terms (facts + rules), not strings, so names, strings and variables are structure | done |
| R2 | Match programs up to variable names, body order, clause order and invented predicate names | done (`same_program/3`) |
| R3 | Nine operators: delete clause, delete literal, unfold, merge, extract group, closed form, complement guard, invert formula, replace by template | done |
| R4 | Handle shared-variable bodies such as `a(C,D), b(C,E)`, not only `a, b` | done (`compound` instances) |
| R5 | Find a derivation from each training pair by iterative deepening | done (`derive/5`) |
| R6 | Learn each operator's conditions from positives and negatives by sequential covering (disjunctions allowed) | done (`learn/2`) |
| R7 | Learn replacement templates by anti-unification, with predicate names as variables | done |
| R8 | Refine conditions with prover counter-examples | done (`refine_rule`) |
| R9 | Apply the algorithm until nothing changes | done (`apply_algorithm/5`) |
| R10 | Reference optimisers written before learning ("axioms") to compare against | done (`axioms.pl`) |
| R11 | Prove each test result equal to its original (syntactic, or every subset of the facts) | done (`experiment.pl`) |
| R12 | MNN speed-up: a logistic unit, trained leave-one-family-out, orders the search candidates; results unchanged | done (`train_mnn/2`, `speedup.pl`) |
| R13 | S2GN coverage fix: the grammar always parses every input it was learned from | done (`s2gn_cover.pl`) |
| R14 | Time limits on every least-model and equivalence call so recursive programs cannot hang learning | done |
| R15 | proof/types: prove type inclusions, same types and related types from shared variables; templates; dimensions; memo | done (`types.pl`, 17 tests) |
| R16 | Delete a type guard that a related variable proves (feature `type_implied_by_related_variable`) | done (`proof_types` family, 4/4) |
| R17 | Spec to algorithm: unfold, fold and eureka definitions, with the Tamaki–Sato fold condition checked on every step | done (`fold.pl`) |
| R18 | A lemma database that admits a lemma only after proving it (both sides deforested to the same program) | done (`prove_lemma/3`; associativity of append proved, commutativity refused) |
| R19 | Prove a derived program equal to its specification on every ground input: soundness of each step, plus totality of the result, functionality of the specification and list-typed answers | done (`total/3`, `functional/3`, `list_slot/3`); naive reverse → accumulator reverse proved |
| R20 | An independent bounded check that compares two programs on every input up to a size and returns a counter-example | done (`bounded_equal/7`) |
| R21 | Data types beyond lists: declared constructors, pattern-matrix coverage, structural recursion on any argument, inferred argument types | done (`set_types/1`; trees and naturals) |
| R22 | Arithmetic: `is/2` and comparisons in programs, integer axioms used only on integers | done (sum and length with accumulators) |
| R23 | More than one eureka strategy | done: deforest, accumulate (with the tail-call condition), tuple (with merge), fuse |
| R24 | Lemma discovery: conjecture lemmas from stuck clauses, prove or refute them, retry | done (`discover_lemmas/4`; every example starts from an empty database) |
| R25 | Learn which strategy to try first | done (`learn_strategies/2`, leave-one-out: 9 attempts against 12) |
| R26 | Equality in every mode, not only the one checked | done where the specification answers only typed inputs (`slot_type/4`: equal least models) |
| R27 | 200 input/output pairs produced by running the code | done (`io_pairs/`) |
| R28 | Find nested and hierarchical predicates from input/output examples, inventing helper predicates | done (`io_synth.pl`: map, filter, template, foldr, context hoisting) |
| R29 | Reduce brute-force induction: structural signals, top-down propagation, observational equivalence, types, anti-unification | done (217 of 3,125 expressions kept over a list, size 4) |
| R30 | A genetic algorithm for pipelines that top-down propagation cannot split | done (`ga_synth/5`; sum of squares of evens with each of seeds 1-20, in 3 to 103 generations) |
| R31 | Active learning with an oracle: distinguishing inputs and counter-examples | done (`active_synth/6`; drop-minimum from one example and one query) |
| R32 | Hand a synthesised program to spec to algorithm | done (`to_fold_spec/3`; sum, length and reverse from examples to accumulator programs, proved) |
| R33 | Prove each program found from examples equal to a reference program for every input of the declared types | done (`io_proof.pl`: unfolding, induction on lists, lemmas, polynomial arithmetic, test normal forms, residues; 70/70 hierarchies, 20/20 active, 15/15 to-algorithm, 12/20 genetic proved) |
| R34 | Accumulate for `S is S1 + f(H)`, and sums not written as `S1 + Rest` | done (`fold.pl` evaluates the start value of the accumulator and reorders sums; `max_assoc` axiom; 14 of 15 to-algorithm derivations proved) |
| R35 | Derive flatten of a list of lists | done (`fuse` strategy: the recursive call and its consumer become one predicate; `total/3` handles the two-predicate cycle with a lexicographic measure; all 15 to-algorithm derivations proved) |
| R36 | Prove "drop the maximum" against the natural reference (`X == M` removed) | done (`io_proof.pl` invariant from `max_list/2`: under `X =< M`, `X < M` holds exactly when `X =\= M`) |
| R37 | mnns's input-address projection and exact integer polynomials (degree 1 to 3) in `io_synth` | done (12 of 12 shared tasks with mnns `s2a/4`, all passing held-out inputs) |

## Results (`results/`)

All 13 families (44 tests): every test result equals the axioms' result. Every result is proved equal to the original, except AlgebraPLOp. Its closed form is proved only with the index type held fixed: a gap in the index facts gives a counter-example, which is reported.

## Work remaining

1. **Index-domain condition for closed forms.** `closed_form` is correct only when the index facts have no gaps. Add a `contiguous_index_domain` feature, or emit a guarded closed form.
2. **Conditions the data never forces.** When no training step has a negative, the learner keeps no condition (`unfold when []`). This is safe, because the operator only fires where it is sound, but it differs from the axioms. More varied training pairs, or prover-generated near-miss pairs, would force the conditions.
3. **Bigger programs.** Iterative deepening is limited to depth 8. Use the MNN ordering with beam search for longer derivations.
4. **Plain data words.** Data words (not names) inside strings still need S2GN symbols. Connect `s2gn_cover.pl` for string arguments.
5. **Replace s2a in mnns.** For specs, mnns's `s2a2_bridge.pl` now calls `io_synth` when its own `s2a/4` finds nothing, and `io_synth` has mnns's projection and exact polynomial fitting (`docs/mnns_s2a_vs_s2a2.md`: on 12 shared tasks mnns `s2a/4` solves 4, `io_synth` 12). mnns also calls `learn/2`, `apply_algorithm/5` and `fold.pl` (`s2a2_learn/3`, `s2a2_apply/5`, `s2a2_derive/4`), and a program proved equal to a reference carries an mnns `induction_equivalence` proof that mnns's own checker re-proves. The optimisation results carry `edb_equivalence` and `fold_derivation` proofs too; mnns's checker repeats all three kinds with its own copies of `io_proof.pl`, `prover.pl` and `fold.pl`, which must be kept in step with this repository.
6. **More operators.** Loop fusion, accumulators and tupling now exist as strategies of `fold.pl`. Still open: strategies that need other kinds of lemma (distributivity) or new data structures.
7. **Richer types.** proof/types proves inclusion of single slots. Tuple types (two slots together), negated types (`\+ t(X)`), and inclusions that depend on facts rather than holding for every input are not yet proved. Dimensions need unit declarations; inferring units from data is open.
8. **More training examples for the strategy learner.** Six examples are few; a held-out case with no similar training example falls back to the fixed order.
9. **More conjecture schemes.** Discovery conjectures associativity, commutativity and the integer axioms. Distributivity and identities are not yet conjectured.
10. **Termination in every mode.** Equal least models give the same answers in every mode; whether a query terminates in a given mode is not checked.
11. **io_synth coverage.** Algebraic laws over whole lists for the prover (map and filter commuting, sums of maps) and facts about library predicates; more components, predicates with several inputs, distinguishing inputs from a solver rather than a pool, a check of which predicate in a hierarchy acts first, and genetic search over trees rather than straight-line pipelines.
12. **Open-ended clause invention.** Every program is built from fixed operators, strategies and combinators (`docs/scope.md`). Search over arbitrary definite clauses, from positive and negative examples and background knowledge, as in Popper or Aleph, is not done.
