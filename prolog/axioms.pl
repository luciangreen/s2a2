/*  axioms.pl -- the reference optimisers, written by hand BEFORE any learning.

    "Optimise the algorithm at the start": each MNN rule is written down here as an
    ordered list of (operator, conditions). Applied to an original program it gives the
    reference optimised program. The learner never sees these lists, only (original,
    reference) pairs; the test is whether the algorithm it learns gives the same output
    as these axioms on programs it has not seen, and whether the prover accepts both. */
:- module(axioms, [axioms/2]).

axioms(dup_clause,        algorithm([rule(del_clause, [duplicate_of_another_clause])])).
axioms(dup_literal,       algorithm([rule(del_lit, [repeats_another_literal])])).
axioms(subsumed_clause,   algorithm([rule(del_clause, [subsumed_by_other_clause])])).
axioms(implied_clause,    algorithm([rule(del_clause, [implied_by_the_other_clauses])])).
axioms(dup_then_subsumed, algorithm([rule(del_clause, [duplicate_of_another_clause]),
                                     rule(del_clause, [subsumed_by_other_clause])])).
% Prolog Inductive Debugger: drop the no-progress clause; recurse after the progress step
axioms(pid, algorithm([rule(del_clause, [calls_itself_unchanged]),
                       rule(replace(tmpl(lr(l(P, [X, Y]), [l(P, [X, Z]), l(E, [Z, Y])]),
                                         lr(l(P, [X, Y]), [l(E, [X, Z]), l(P, [Z, Y])]))),
                            [template_matches])])).
% loop2 (splice): a caller calls the generator directly instead of through a wrapper
axioms(loop2, algorithm([rule(unfold, [callee_is_a_wrapper, caller_is_a_target])])).
% Starlog: nest single-use intermediates into the target, then drop them
axioms(starlog, algorithm([rule(unfold, [callee_called_once, caller_is_a_target]),
                           rule(del_clause, [defines_unused_non_target])])).
% PLOp: unfold helpers into the target, then compute a functional call once
axioms(plop, algorithm([rule(unfold, [caller_is_a_target]),
                        rule(merge, [functional_in_first_argument])])).
% AlgebraPLOp: a recurrence becomes its closed form; a lookup through it becomes the inverse
axioms(algebraplop, algorithm([rule(closed_form, [affine_recurrence]),
                               rule(invert_formula, [affine_formula_call])])).
% Detlog: the cut's "otherwise" (here \+ guard) becomes the complementary test
axioms(detlog, algorithm([rule(complement_guard, [negated_single_guard])])).
% Piglog2: independent groups of goals become separate predicates (can run concurrently)
axioms(piglog2, algorithm([rule(extract, [independent_group])])).
% proof/types: a type guard is deleted when a related variable proves it (types.pl)
axioms(proof_types, algorithm([rule(del_lit, [type_implied_by_related_variable])])).
