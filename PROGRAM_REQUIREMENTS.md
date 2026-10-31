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

## Results (`results/`)

All 13 families (44 tests): every test result equals the axioms' result. Every result is proved equal to the original, except AlgebraPLOp. Its closed form is proved only with the index type held fixed: a gap in the index facts gives a counter-example, which is reported.

## Work remaining

1. **Index-domain condition for closed forms.** `closed_form` is correct only when the index facts have no gaps. Add a `contiguous_index_domain` feature, or emit a guarded closed form.
2. **Conditions the data never forces.** When no training step has a negative, the learner keeps no condition (`unfold when []`). This is safe, because the operator only fires where it is sound, but it differs from the axioms. More varied training pairs, or prover-generated near-miss pairs, would force the conditions.
3. **Bigger programs.** Iterative deepening is limited to depth 8. Use the MNN ordering with beam search for longer derivations.
4. **Plain data words.** Data words (not names) inside strings still need S2GN symbols. Connect `s2gn_cover.pl` for string arguments.
5. **Replace s2a in mnns.** Write an adapter so the mnns repository can call `learn/2` and `apply_algorithm/5` instead of the address/affine finder.
6. **More operators.** Loop fusion and accumulator introduction now exist as the `deforest` and `accumulate` strategies of `fold.pl`, for list recursion. Still to do: tupling (e.g. linear Fibonacci), trees and other data types, and arithmetic lemmas (sum with an accumulator needs associativity of `+`).
8. **Learn the fold strategy.** The eureka step is a fixed heuristic (generalise the constants after the recursive call). S2A2's learner should learn when to define, which lemma to apply and where to fold from derivations, as it learns the other operators' conditions.
9. **Lemma discovery.** The database holds lemmas someone wrote down. Proposing candidate lemmas (from the goals left over when a fold fails) and proving them automatically would let the database grow by itself.
7. **Richer types.** proof/types proves inclusion of single slots. Tuple types (two slots together), negated types (`\+ t(X)`), and inclusions that depend on facts rather than holding for every input are not yet proved. Dimensions need unit declarations; inferring units from data is open.
