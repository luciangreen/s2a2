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

The other operators only make a program smaller. Deriving a new algorithm from a naive specification sometimes needs the opposite first: define a new predicate (a **eureka** definition), unfold it, rewrite it with a **lemma**, then **fold** the result back into a call to the new predicate. This is the unfold/fold method of Burstall and Darlington (1977), with the correctness conditions of Tamaki and Sato (1984). The specification is a program that is obviously correct but slow; the result is a faster program proved to give exactly the same answers.

The rules, each with the side condition that makes it sound:

| Rule | What it does | Condition checked |
| --- | --- | --- |
| define | adds `d(V1..Vn) :- G1, …, Gk` for a new name `d` | `d` is new |
| unfold | replaces a clause by all its resolvents on one body literal | none (always sound) |
| fold | replaces an instance of a definition's body by its head | the definition's local variables map to distinct variables used nowhere else in the clause; a clause from a definition must have been unfolded first |
| lemma | replaces one side of a lemma by the other | the lemma is in the database (so it is proved), and the same local-variable condition |
| normalise | unfolds a literal whose case argument is already `[]` or `[_|_]` and that matches at most one clause | none |

Two strategies search for the steps by iterative deepening:

- **deforest** a conjunctive definition such as `app3(X,Y,Z,R) :- app(X,Y,W), app(W,Z,R)`: unfold on the induction variable, normalise, fold. The intermediate list `W` disappears.
- **accumulate** a recursive clause that works after its recursive call, such as `rev([H|T],R) :- rev(T,RT), app(RT,[H],R)`: the eureka definition generalises the constants after the call (`[H]` becomes an accumulator `A`), giving `rev_acc(T,A,R) :- rev(T,RT), app(RT,A,R)`. It is unfolded, rewritten with lemmas from the database, and folded; then the original clause is folded with it.

### The lemma database

A lemma is admitted only after `prove_lemma/3` proves it. Both sides become predicates over their shared variables, both are deforested on the same induction variable, and the two derived programs must be the same up to the predicate name. Unfold/fold preserves the least model, so the two sides then denote the same relation. Associativity of append, `app(X,Y,W), app(W,Z,R) ⇔ app(Y,Z,V), app(X,V,R)`, is proved this way (both sides become `l([],Y,Z,R) :- app(Y,Z,R). l([H|T],Y,Z,[H|R]) :- l(T,Y,Z,R).`). The false "lemma" `app(X,Y,R) ⇔ app(Y,X,R)` is not proved, and the bounded check refutes it with `X=[a], Y=[b]`.

### Result: naive reverse to accumulator reverse

```
specification                              derived
rev([],[]).                                rev([],[]).
rev([H|T],R) :- rev(T,RT), app(RT,[H],R).  rev([H|T],R) :- rev_acc(T,[H],R).
                                           rev_acc([],A,A).
                                           rev_acc([H|T],A,R) :- rev_acc(T,[H|A],R).
```

The derivation (`results/fold.txt` lists every clause):

1. eureka: `rev_acc(T,A,R) :- rev(T,RT), app(RT,A,R)`;
2. unfold `rev`: `rev_acc([],A,A)` (after normalising `app([],A,R)`) and `rev_acc([H|T],A,R) :- rev(T,RT), app(RT,[H],X), app(X,A,R)`;
3. lemma `assoc`, then normalise `app([H],A,V)`: `rev_acc([H|T],A,R) :- rev(T,RT), app(RT,[H|A],R)`;
4. fold with the eureka definition: `rev_acc([H|T],A,R) :- rev_acc(T,[H|A],R)`;
5. fold the specification's own clause: `rev([H|T],R) :- rev_acc(T,[H],R)`.

**Proof that it is correct for every ground first argument.** Every step keeps every clause true in the least model of the specification plus the definition, so every answer of the derived program is an answer of the specification (soundness). The checker then shows three things: the derived `rev(+list,-)` answers every list input (case analysis on `[]` and `[_|_]`, structural recursion on the tail, mode-correct calls); the specification has at most one answer for each input (non-overlapping heads, functional calls); and the specification answers only list inputs. So both have exactly the same answer on every ground input. The bounded check agrees on all 255 lists of length up to 7 over `{a,b}`.

**Speed.** Resolution steps for `rev(L,R)`:

| Length of L | naive | derived |
| --- | --- | --- |
| 8 | 45 | 9 |
| 16 | 153 | 17 |
| 32 | 561 | 33 |
| 64 | 2,145 | 65 |
| 128 | 8,385 | 129 |

Quadratic, (n+1)(n+2)/2, becomes linear, n+1.

**The database is what makes it possible.** With an empty lemma database the search finds no derivation: the step clause can only be folded into `rev_acc(T,[H],X), app(X,A,R)`, which is still quadratic. With the proved associativity lemma it finds the five steps above. `app3` needs no lemma: deforestation alone turns two passes into one (123 steps to 82 for two lists of 40).

### Limits

- Lists only: totality is checked for case analysis on `[]` and `[_|_]`. Trees and other types need their constructors declared.
- Pure programs without builtins, so no arithmetic lemmas yet (summing with an accumulator needs associativity of `+`).
- The eureka step is one fixed heuristic, and the lemmas are written by hand; S2A2 does not yet learn either. Tupling (linear Fibonacci) is not covered.
- Equality is proved in the mode the checks use (`rev(+list,-)`), on ground inputs.

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
| `prolog/fold.pl` | spec to algorithm: unfold, fold, eureka definitions, lemmas, totality and functionality checks, bounded check |
| `prolog/fold_tests.pl` | 16 tests of the side conditions that keep fold sound |
| `prolog/fold_examples.pl` | lemma proofs, app3 deforestation, naive reverse to accumulator reverse (writes `results/fold.txt`) |
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

Requires SWI-Prolog 9 or later.
