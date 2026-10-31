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

## proof/types (`types.pl`)

The eighth MNN item uses proofs to find that one type is the same as, contained in, or related to another, because variables tie argument positions (slots) together. A type is the set of values at a slot `P/N:I`. Three sound proof rules give inclusions that hold for every input:

- **flow**: `P/N:I ⊆ B` when P is defined by rules only and in each clause the head variable at I also stands at B (or at a rule-defined slot already contained in B; recursion is handled by induction on derivation height). `reach(X,Y) :- edge(X,Y). reach(X,Y) :- edge(X,Z), reach(Z,Y).` proves `reach:1 ⊆ edge:1`.
- **cover**: a projection clause `person(X) :- parent(X,_)` proves `parent:1 ⊆ person:1`.
- **chain**: the transitive closure of the two, e.g. `reach:1 ⊆ edge:1 ⊆ node:1`.

From these come **same type** (inclusion both ways: `reach:1 = edge:1`), **related slots** (union-find over shared variables, `X \= Y` and comparisons), **refinement templates** (`num:1 --[X>0]--> pos:1`), **conversion templates** (`pos:1 --[Y is 1+2*X]--> val:2`) and **dimension checks** (`F is M*A` gives kg·m·s⁻² for force; `F is M+A` is refuted). Templates are memoised by clause shape (names and variables abstracted), so a program with the same clause shapes reuses them. `check_inclusion/6` confirms any inclusion on every input over a small domain, or returns a counter-example input.

The optimisation it supports: a unary guard `t(V)` is deleted when V also stands at a slot proved to be contained in t's type (`implied_guard/4`; the S2A2 feature `type_implied_by_related_variable`). Only unary guards are deleted, because membership of each slot separately does not prove a tuple. `types_tests.pl` has 17 tests, including a semantic check of every inclusion the rules infer.

## Spec to algorithm: fold and eureka definitions (`fold.pl`)

The other operators only make a program smaller. Deriving a new algorithm from a naive specification sometimes needs the opposite first: define a new predicate (a **eureka** definition), unfold it, rewrite it with a **lemma**, then **fold** the result back into a call to the new predicate. This is the unfold/fold method of Burstall and Darlington (1977), with the correctness conditions of Tamaki and Sato (1984). The specification is a program that is obviously correct but slow. The result is a faster program, proved to give the same answers.

**Result: six specifications derived, each starting from an empty lemma database, each proved and measured** (`results/fold.txt` lists every step):

| Specification | Strategy | Lemma found and used | Derived program | Proof | Cost of the specification → derived |
| --- | --- | --- | --- | --- | --- |
| `app3` (append three lists) | deforest | none | one pass | least model preserved (Tamaki–Sato) | 771 → 514 steps (lists of 256) |
| naive reverse | accumulate | `app_assoc`, proved | `rev_acc(T,[H|A],R)` | same least model | 33,409 → 513 steps (256) |
| tree flatten | accumulate | `app_assoc`, proved | `flat_acc` threads the list through the tree | same least model | 33,409 → 513 steps (left comb of 256) |
| sum of a list | accumulate | `plus_assoc`, integer axiom | tail-recursive `sum_acc` | equal on integer lists | 257 → 2 pending goals (256) |
| length | accumulate | `plus_assoc`, integer axiom | tail-recursive `len_acc` | same least model | 257 → 2 pending goals (256) |
| Fibonacci on naturals | tuple | none | `fib_tup(N,F(N+1),F(N))` | same least model | 32,836 → 39 steps (n = 20) |

### The rules

| Rule | What it does | Condition checked |
| --- | --- | --- |
| define | adds `d(V1..Vn) :- G1, …, Gk` for a new name `d` | `d` is new |
| unfold | replaces a clause by all its resolvents on one user literal | none (always sound) |
| fold | replaces an instance of a definition's body by its head | the definition's local variables map to distinct variables used nowhere else; a clause from a definition was unfolded first |
| lemma | replaces one side of a lemma by the other | the lemma is in the database, and the same local-variable condition |
| merge | unifies two calls of one predicate with identical first arguments | none for soundness (an instance of a clause); equality then rests on functionality |
| normalise | unfolds a literal whose case argument is a constructor and that matches at most one clause; evaluates `is/2` and comparisons on ground arguments | none |

### Three eureka strategies

- **deforest**: a conjunctive definition such as `app3(X,Y,Z,R) :- app(X,Y,W), app(W,Z,R)` is unfolded on its induction variable and folded back. The intermediate list `W` disappears.
- **accumulate**: a recursive call whose result is consumed afterwards gets a definition that generalises the consumer's other arguments into an accumulator. Inside `is/2`, the generalisation works on subterms. `rev(T,RT), app(RT,[H],R)` gives `rev_acc(T,A,R) :- rev(T,RT), app(RT,A,R)`, and `sum(T,S1), S is S1+H` gives `sum_acc(T,S,A) :- sum(T,S1), S is S1+A`. The step clause must end as a tail call: the definition's outputs go straight into the new call and are never computed afterwards. This rejects `sum_acc(T,S,A) :- sum_acc(T,E,H), S is E+A`, which is correct but no better.
- **tuple**: two recursive calls on related arguments, `fib(s(N),F1), fib(N,F2)`, get one definition that computes both: `fib_tup(N,F1,F2)`. Unfolding on the larger argument and merging the repeated call `fib(s(M),_)` lets it fold into one recursive call, which makes it linear.

### Types beyond lists

Types are declared by their constructors (`set_types/1`). The defaults are `list(E)`, `tree(E)` (`leaf | node(tree(E),E,tree(E))`) and `nat` (`0 | s(nat)`), plus `int`, `num` and `any`. Every check works from the declarations:

- **coverage** uses a pattern matrix, so nested patterns work: `fib(0,_)`, `fib(s(0),_)`, `fib(s(s(N)),_)` covers `nat`, but leaving out `s(0)` is caught.
- **structural recursion**: every recursive call takes a proper subterm at one fixed argument.
- **argument types** of calls and outputs are inferred, so `B is C+D` is known to be on integers when `C` and `D` come from `fib_tup`.

### The lemma database and lemma discovery

A lemma about user predicates is admitted only after `prove_lemma/3` proves it. Both sides are deforested on the same induction variable, and the two derived programs must be the same up to the predicate name. Associativity of append passes. Integer arithmetic facts (associativity of `+` and `*`) are axioms of the integers. They are used only where their variables are integers, and `verify/5` reports whether every `is/2` in the result is on integers.

When a strategy gets stuck, `discover_lemmas/4` looks at the stuck clauses and conjectures lemmas:

- associativity, when a predicate chains with itself through a private variable (`app(RT,[H],X), app(X,A,R)`);
- commutativity of the same predicate;
- the integer axiom for an operator that chains in `is/2`.

It proves or refutes each conjecture and retries with the good ones. For reverse it proves `app_assoc` and refutes `app_comm` with `[a]`, `[b]`. **No lemma is written by hand in any of the six derivations.**

### Why each result is correct

- **deforest without lemmas or merges.** Only unfold and fold are used, so the least model is preserved exactly (Tamaki–Sato).
- **Otherwise.** Every step keeps every clause true in the specification's least model, so every answer of the result is an answer of the specification (soundness). `verify/5` then checks three things:
  - `total`: the result answers every input of the declared types;
  - `functional`: the specification has at most one answer per input;
  - `slot_type`: the specification answers only inputs of those types.

  The first two give equal answers on every typed input. With the third as well, the **least models are equal**, so the programs agree in **every mode**, not just the one checked. They give the same correct answers, though which queries terminate can differ.
- **Sum.** Summing is equal on integer lists only. The specification also sums lists of floats, where associativity does not hold exactly, and the third check rightly fails.
- **Body order.** `verify/5` returns the result with each body ordered so that inputs are bound. The order of a conjunction does not change the least model.
- **Bounded check.** `bounded_equal/7` independently compares the programs on every input up to a size: 255 lists, 723 trees, 341 integer lists, 17 naturals. A second mode, with both arguments given, agrees on every pair tried.

### Learning which strategy to try

`features/3` describes a specification, for example "result used after the recursive call" or "calls on related arguments". `learn_strategies/2` learns, by sequential covering, when each strategy succeeds. From all six:

- deforest when `conjunctive`;
- accumulate when `result_used_after_call ∧ ¬calls_on_related_arguments`;
- tuple when `calls_on_related_arguments`.

Left out one at a time, the learned order needs 9 attempts in total against 12 for the fixed order. It loses one attempt on `app3`, because no other example is conjunctive, and cannot place `fib` first, because no other example uses tupling.

### What is still open

- **More strategies and lemmas.** Lemma discovery conjectures only associativity and commutativity. Strategies that need other lemmas, for example distributivity, or a new data type such as an accumulator pair, need more conjecture schemes.
- **Termination in every mode.** Equal least models give the same answers in every mode. Whether a query terminates is a separate question, and it is not checked.
- **Arithmetic beyond integers.** The integer axioms are not valid for floats, so results that use them are stated for integer inputs.
- **More training examples.** Six examples are few for learning; held-out cases with no similar training example fall back to the fixed order.

## MNN speed-up

`train_mnn/2` trains a small network: one logistic unit over the operator and its cheap features, with the weights stored as Prolog facts (`mnn_weight/2`). It learns from earlier derivations and only **orders** the candidates in the search. Every candidate is still tried, so results are unchanged and only the number of nodes expanded changes. `speedup.pl` measures this leave-one-family-out.

## Results

`./run_families.sh` learns each of the 13 families from its two training pairs, applies the learned algorithm to the test programs, and proves each result. `./check_results.sh` then requires every test to be exact and proved.

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
| proof/types | del_lit when type_implied_by_related_variable | yes | 4/4 |

**Total: 44 of 44 tests exact (same output as the axioms) and proved.**

- "Conditions not forced" means no training step had a negative, so no condition was needed to separate them. The operator only fires where it is sound, so the output still equals the axioms' output.
- AlgebraPLOp's closed form is proved with the index facts held fixed. With a gap in the index (for example, n(2) missing) the recurrence stops but the formula does not, and the prover reports that counter-example.

MNN speed-up (search nodes to find each pair's derivation, trained leave-one-family-out, `results/speedup.txt`; nodes counted for solved pairs only): **364,029 nodes in fixed order, 99,561 in MNN order (3.7x fewer), with the same answers.** The largest gains are Detlog (9.2x), PLOp (8.2x), Piglog2 (4.9x), loop2 and AlgebraPLOp (3.2x) and Starlog (2.8x). It is slower on proof/types (0.56x) and on three of the four searches under 30 nodes. One PLOp pair is not solved within 2 minutes in either order; it is left out of the counts, because an unsolved pair's count measures the machine's speed, not the search.

Time limits nest correctly: `limited/2` catches only its own limit, so an enclosing limit is never swallowed. Without this, AlgebraPLOp's search ran past its limit for over 40 minutes. With it, the search takes 315 nodes.

`calc/calc_check.pl` checks the worked calculations quoted in the report (15/15; run `swipl calc/calc_check.pl`, which exits 1 if any check fails). `calc/flies.lp` is the hand-written clingo inversion example.

## Files

| File | Contents |
| --- | --- |
| `prolog/s2a2.pl` | representation, operators, features, derivation search, learning, refinement, MNN |
| `prolog/types.pl` | proof/types: type inclusions, same and related types, templates, dimensions, implied guards |
| `prolog/types_tests.pl` | 17 tests for proof/types |
| `prolog/fold.pl` | spec to algorithm: types, unfold/fold/lemma/merge, three eureka strategies, lemma discovery, totality, functionality and answer types, bounded check, strategy learning |
| `prolog/fold_tests.pl` | 30 tests of the side conditions that keep fold sound |
| `prolog/fold_examples.pl` | the lemma database, six derivations, a second mode, strategy learning (writes `results/fold.txt`) |
| `prolog/axioms.pl` | the reference optimisers, written before learning ("optimise the algorithm at the start") |
| `prolog/instances.pl` | 13 families × (2 training + 1 to 5 test) unoptimised programs |
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
swipl -q -g main -t 'halt(1)' fold_examples.pl                  # spec to algorithm
swipl -q -g main -t 'halt(1)' fold_tests.pl
```

## October 2026 Research

* [algebraplop](https://github.com/luciangreen/algebraplop)
[ann2pl](https://github.com/luciangreen/ann2pl)
[anns2a](https://github.com/luciangreen/anns2a)
[detlog](https://github.com/luciangreen/detlog)
[loop2](https://github.com/luciangreen/loop2)
[mnns](https://github.com/luciangreen/mnns)
[Philosophy](https://github.com/luciangreen/Philosophy)
[piglog2](https://github.com/luciangreen/piglog2)
[pl2ann](https://github.com/luciangreen/pl2ann)
[plop](https://github.com/luciangreen/plop)
[Prolog_Inductive_Debugger](https://github.com/luciangreen/Prolog_Inductive_Debugger)
[renn-inverse](https://github.com/luciangreen/renn-inverse)
[renn](https://github.com/luciangreen/renn)
[s2a2](https://github.com/luciangreen/s2a2)
[Starlog](https://github.com/luciangreen/Starlog)


Requires SWI-Prolog 9 or later.
