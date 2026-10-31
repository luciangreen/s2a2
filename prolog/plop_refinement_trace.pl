% Shows how PLOp's merge condition is learned: covering finds no condition (no negatives),
% the prover finds counter-example inputs, and refinement adds functional_in_first_argument.
% Run: cd prolog && swipl -q -g go -t halt plop_refinement_trace.pl
:- use_module(s2a2).
:- use_module(axioms).
:- use_module(instances).
go :- axioms(plop, Ax),
  findall(pair(B, A, T), ( inst(plop, train, _, Cs, T), program_from_clauses(Cs, B), apply_algorithm(Ax, B, T, A, _) ), Pairs),
  maplist(s2a2:pair_derivation, Pairs, Derivs),
  forall(member(Op, [unfold, merge]),
    ( s2a2:positives(Op, Derivs, Pairs, Pos), s2a2:negatives(Op, Derivs, Pairs, Neg),
      s2a2:cover(Pos, Neg, CS), length(Pos,NP), length(Neg,NN),
      format("~w: ~w positives, ~w negatives, covering conditions ~w~n", [Op, NP, NN, CS]),
      forall(member(C, CS), ( s2a2:refine_rule(Derivs, Pairs, rule(Op, C), R), format("  refined: ~w~n", [R]) )) )),
  forall(( member(D, Derivs), nth1(K, Derivs, D), nth1(K, Pairs, pair(_,_,T)), member(step(I, S), D), s2a2:op_name(I, merge),
           s2a2:apply_op(I, S, S1, T), s2a2:counterexample(S, S1, T, CE) ), format("  counter-example input: ~w~n", [CE])),
  halt.
