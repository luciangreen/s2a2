# S2A2: Spec to Algorithm 2

S2A2 learns an **optimisation algorithm** from a few pairs of (unoptimised program, optimised program), then applies it to programs it has never seen, of any length and shape. A prover checks every result.

It is the last step of the Manual Neuronets pipeline (Prolog → pl2ann network → input recovered from the network's output → code learned from that input and output → **the optimisation that turns the original into the learned code**).

## Why a new S2A

S2A and S2GN (`Philosophy/s2g/normalise.pl`) learn from strings. A program then has to be flattened into a string, and that causes three problems we measured:

1. **Fixed shape.** A pattern learned on two-clause programs does not fire on a three-clause program, or on one whose clauses have different body lengths. With S2A, 0 of 16 rewrites carried over to programs of a different shape.
2. **No new pieces.** S2A can only rearrange items already in the input. It can't write `edge(X,Z), path(Z,Y)` from `path(X,Z), edge(Z,Y)`, a formula, or a new predicate.
3. **Optional items.** S2GN's grammars can leave out a case they were learned from. For example, from `["n1,l2,s1", "n1,l2", …]` it requires the trailing `s1`. `s2gn_cover.pl` fixes the coverage, but a grammar still says what programs look like, not how to rewrite them.

S2A2 works on Prolog **terms**:

- **Names and variables are matched as structure, not words.** Only plain data words would need S2GN-style symbols. Predicate names can themselves be generalised: a learned template can say "for any predicates P and E".
- **Position-free.** A program is a set of rules plus a set of facts, so every rewrite is local to the clauses it touches. The rest of the program is an optional segment of any length, including empty.
- **Operators plus conditions.** A rewrite is one of nine operators, each with conditions learned from the examples:
  - delete a clause or a literal;
  - unfold a call;
  - merge two calls;
  - replace a clause by a learned template;
  - extract an independent group of goals into a new predicate;
  - replace a recurrence by its formula;
  - replace a negated guard by its complement;
  - invert a formula.
- **Applied until nothing changes.** The algorithm keeps applying its rules, so chains of any length are handled.

## How it learns

1. **Derivations.** For each training pair, iterative deepening finds a sequence of operator steps from the unoptimised program to the optimised one. Matching ignores variable names, body order, clause order and the names of invented predicates.
2. **Positives and negatives.** Each step taken is a positive instance of its operator. Each other instance of the same operator that was possible in the same state, and would not have led to the target, is a negative.
3. **Conditions.** For each operator, sequential covering picks the smallest conjunction of features that holds for the positives and for no negative. If no single conjunction covers every positive, it keeps several (a disjunction).
4. **Templates.** A replaced clause becomes a template by anti-unification (Plotkin's least general generalisation) over all pairs, with predicate names generalised too.
5. **Prover-guided refinement.** Each learned rule is replayed on its training steps, and the prover checks every rewrite on all inputs built from the program's input predicates, not just the facts given. If it finds a counter-example input, the features that disappear on that input are added as conditions. This is how S2A2 learns that PLOp may merge two calls only when the predicate is functional, although every training example happened to be functional.

## MNN speed-up

`train_mnn/2` trains a small network: one logistic unit over the operator and its cheap features, with the weights stored as Prolog facts (`mnn_weight/2`). It learns from earlier derivations and only **orders** the candidates in the search. Every candidate is still tried, so results are unchanged and only the number of nodes expanded changes. `speedup.pl` measures this leave-one-family-out.

## Results

`./run_families.sh` learns each of the 12 families from its two training pairs, applies the learned algorithm to the test programs, and proves each result. `./check_results.sh` then requires every test to be exact and proved.

| Family | Learned algorithm | Same rule list as the axioms | Tests exact and proved |
| --- | --- | --- | --- |
| duplicate clause | del_clause when duplicate_of_another_clause | yes | 5/5 |
| duplicate literal | del_lit when repeats_another_literal | yes | 4/4 |
| subsumed clause | del_clause when subsumed_by_other_clause | yes | 4/4 |
| implied clause | del_clause when implied_by_the_other_clauses | yes | 1/1 |
| duplicate then subsumed | both of the above, in order | yes | 5/5 |
| PID | del_clause when calls_itself_unchanged; template `P(X,Y) :- P(X,Z), E(Z,Y)` → `P(X,Y) :- E(X,Z), P(Z,Y)` | yes | 3/3 |
| loop2 | unfold | conditions not forced | 3/3 |
| Starlog | unfold; del_clause when defines_unused_non_target | conditions not forced | 3/3 |
| PLOp | unfold when caller_is_a_target; merge when functional_in_first_argument | yes | 3/3 |
| AlgebraPLOp | closed_form when affine_recurrence; invert_formula | conditions not forced | 3/3 (proved with the index type fixed) |
| Detlog | complement_guard | conditions not forced | 3/3 |
| Piglog2 | extract | conditions not forced | 3/3 |

**Total: 40 of 40 tests exact (same output as the axioms) and proved.**

- "Conditions not forced" means no training step had a negative, so no condition was needed to separate them. The operator only fires where it is sound, so the output still equals the axioms' output.
- AlgebraPLOp's closed form is proved with the index facts held fixed. With a gap in the index (for example, n(2) missing) the recurrence stops but the formula does not, and the prover reports that counter-example.

MNN speed-up (search nodes to find each pair's derivation, trained leave-one-family-out, `results/speedup.txt`): **4,802,587 nodes in fixed order, 2,453,579 in MNN order (2.0x fewer), with the same answers.** The largest gains are Detlog (9.2x), Piglog2 (4.9x), loop2 and AlgebraPLOp (3.2x) and Starlog (2.8x). On the three smallest searches (under 30 nodes) it is slightly slower.

Time limits nest correctly: `limited/2` catches only its own limit, so an enclosing limit is never swallowed. Without this, AlgebraPLOp's search ran past its limit for over 40 minutes. With it, the search takes 315 nodes.

`calc/calc_check.py` checks the worked calculations quoted in the report (15/15). `calc/flies.lp` is the hand-written clingo inversion example.

## Files

| File | Contents |
| --- | --- |
| `prolog/s2a2.pl` | representation, operators, features, derivation search, learning, refinement, MNN |
| `prolog/axioms.pl` | the reference optimisers, written before learning ("optimise the algorithm at the start") |
| `prolog/instances.pl` | 12 families × (2 training + 1 to 7 test) unoptimised programs |
| `prolog/experiment.pl` | learn, apply to tests, compare with the axioms, prove |
| `prolog/speedup.pl` | search nodes with and without the MNN ordering |
| `prolog/prover.pl` | the prover (shared with renn_pipeline) |
| `prolog/s2gn_cover.pl` | the S2GN coverage fix |

## Run

```
cd prolog
swipl -q -g "consult(experiment),main,halt" -t halt          # all families
FAMILIES=pid,plop swipl -q -g "consult(experiment),main,halt" -t halt
swipl -q -g "consult(speedup),main,halt" -t halt
```

Requires SWI-Prolog 9 or later.
