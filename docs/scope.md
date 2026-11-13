# Does S2A2 find algorithms from first principles?

No. S2A2 cannot find non-hardwired algorithms from first principles in the open-ended sense of general program synthesis or inductive logic programming.

## What is hardwired

S2A2 operates inside a fixed, deliberately restricted vocabulary.

**Optimisation / rewrite stage (`s2a2.pl` + `fold.pl`)**

- A fixed set of nine operators: delete clause, delete literal, unfold, merge, extract group, closed-form, complement guard, invert formula, replace-by-template.
- A fixed set of eureka strategies: deforest, accumulate (with a tail-call condition), tuple (with merge), and fuse.
- Lemma discovery is limited to a few hard-coded schemes (associativity, commutativity, a handful of integer axioms). It conjectures only those patterns and proves/refutes them; it does not invent arbitrary lemmas.

**I/O synthesis stage (`io_synth.pl`)**

- A small, fixed library of combinators: map, filter (plain or with context), template (via anti-unification), foldr, scalar expressions, and a few aggregates (`sum_list`, `min_list`, `max_list`, etc.).
- Structural signals that assume list-processing shapes (length-preserving, subsequence, nested, per-sublist, output template, etc.).
- Top-down propagation that decomposes only along those combinators.
- A genetic algorithm that searches sequences of the same hardwired genes, not arbitrary clause structures.
- Observational equivalence, types, and anti-unification further prune inside that closed set.

Everything the system invents (helper predicates, accumulator definitions, fused predicates, etc.) is assembled from these pre-defined pieces.

## What "from first principles" would require

True first-principles discovery would mean:

- Searching an open hypothesis space of arbitrary definite clauses (or a richer language),
- Inventing new predicates and recursive structure without a fixed set of combinators or rewrite operators,
- Using only positive/negative examples + background knowledge, without hard-coded strategies for accumulation, deforestation, etc.

That is closer to what systems such as Popper, Aleph/Progol-style ILP, or modern neural/symbolic program synthesizers attempt. S2A2 deliberately does not do this; its design goal is the opposite: heavy pruning and specialised operators so that the search stays tractable and every result can be proved correct.

## What S2A2 can do well

Within its hardwired fragment it is effective:

- It invents hierarchies of helpers (map of filter, nested maps, genetic pipelines of filter → map → aggregate).
- It can turn a naïve recursive specification synthesised from I/O into a more efficient algorithm (accumulator, fused predicate, etc.) and prove the transformation.
- The conditions on the operators are learned from examples rather than written by hand, and a prover filters unsafe rewrites.

But the algorithms themselves are compositions of the built-in operators and combinators, not discoveries of entirely new algorithmic ideas.

## Explicit limitations noted by the author

The "Work remaining" ([`PROGRAM_REQUIREMENTS.md`](../PROGRAM_REQUIREMENTS.md)) and "What is still open" ([`README.md`](../README.md)) sections list exactly the missing generality:

- Small library of components,
- Genetic search only over straight-line pipelines,
- Limited lemma conjecture schemes,
- No algebraic laws over whole lists,
- Predicates restricted to one input / one output,
- No open-ended clause invention.

**Summary:** S2A2 is a powerful specialised synthesis + optimisation system that stays inside a carefully engineered set of operators and combinators. It does not perform open-ended, first-principles algorithm discovery.
