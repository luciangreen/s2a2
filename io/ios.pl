% 200 inputs and outputs, from real runs: io(N, Predicate, Inputs, Output).
io(1,synth,[sum,[[]-0,[1,4,7,-3]-9,[8,-2]-6,[9,-1,2]-10]],[hypothesis(expression(f(sum,[v(x)]))),program(["sum(A, B) :-","sum_list(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[21,3])]).
io(2,signals,[double,[[]-[],[-1]-[-2],[5,8,-2]-[10,16,-4],[6,9,-1,2]-[12,18,-2,4]]],[in_type(list(int)),out_type(list(int)),length_preserved,empty_case([]),depth_preserved]).
io(3,prove_equal,[filter,1],[first(["d([], [])","d([A|B], C):-(A>0->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=0->C=[A|D];C=D), e(B, D)"]),not_proved]).
io(4,equivalent,[extra_base,[a-b]],refuted(input([edge(a,a),edge(b,a)]),only_in_a([reach(b,b)]),only_in_b([]))).
io(5,apply_axioms,[dup_literal,compound_last],[steps(1),optimised(["a(c1, d1)","a(c2, d2)","b(c1, e1)","b(c3, e3)","q(A):-b(A, B), a(A, C)","r(A, B):-a(A, B)"]),proof(proved(syntactic))]).
io(6,learn_apply,[drop,[col-colour-q-[blue,green,red],big-size-s-[s2,s3]],[a-b]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(a, b)"]),proof(refuted(only_in_a([conn(a,a),conn(a,b),conn(b,a),conn(b,b)]),only_in_b([])))]).
io(7,derive,[rev,all],[strategy(accumulate),lemmas([app_assoc]),program(["rev([],[]).","rev([A|B],C) :- rev_acc(B,[A],C).","rev_acc([],A,A).","rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(8,synth,[len,[[]-0,[-3,0,3,6]-4,[3]-1,[9,-1,2]-3]],[hypothesis(expression(f(len,[v(x)]))),program(["len(A, B) :-","length(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[6,3])]).
io(9,signals,[add_k,[[]-[],[-1]-[2],[0,3]-[3,6],[6,9,-1,2]-[9,12,2,5]]],[in_type(list(int)),out_type(list(int)),length_preserved,empty_case([]),depth_preserved]).
io(10,prove_equal,[map,2],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(11,equivalent,[none,[b-c]],proved(syntactic([]))).
io(12,apply_axioms,[dup_then_subsumed,grandparent_last],[steps(2),optimised(["parent(ann, bob)","parent(ann, dee)","parent(bob, cy)","parent(dee, eli)","grandparent(A, B):-parent(A, C), parent(C, B)"]),proof(proved(syntactic))]).
io(13,learn_apply,[keep,[col-colour-q-[blue]],[b-c]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(b, c)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(14,derive,[flat2,all],[strategy(fuse),lemmas([]),program(["flat2([],[]).","flat2([A|B],C) :- flat2_fuse(A,B,C).","flat2_fuse([],A,B) :- flat2(A,B).","flat2_fuse([A|B],C,[A|D]) :- flat2_fuse(B,C,D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(15,synth,[maximum,[[]-none,[-3,0,3,6]-6,[3]-3,[4,7]-7]],false).
io(16,signals,[evens,[[]-[],[0,3]-[0],[1,4,7]-[4],[8]-[8]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(17,prove_equal,[filter,3],[first(["d([], [])","d([A|B], C):-(A>2->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=3->C=[A|D];C=D), e(B, D)"]),proved(steps(2))]).
io(18,equivalent,[dup_clause,[c-a]],proved(syntactic([dup_clause((reach(A,B):-[edge(A,B)]))]))).
io(19,apply_axioms,[pid,loop_clause_first],[steps(2),optimised(["road(a, b)","road(b, c)","road(c, d)","trip(A, B):-road(A, B)","trip(A, B):-road(A, C), trip(C, B)"]),proof(proved(exhaustive))]).
io(20,learn_apply,[keep,[col-colour-q-[blue,green],big-size-s-[s2]],[c-d]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(c, d)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(21,derive,[fib,[accumulate]],no_derivation).
io(22,synth,[sort,[[]-[],[-1]-[-1],[4,7]-[4,7],[5,8,-2]-[-2,5,8]]],error(permission_error(modify,static_procedure,sort/2))).
io(23,signals,[positives,[[1,4,7]-[1,4,7],[2,5,8,-2]-[2,5,8],[8]-[8],[9,-1]-[9]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(24,prove_equal,[map,4],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(25,equivalent,[dup_literal,[a-c]],proved(syntactic([dup_literal((reach(A,B):-[edge(A,B),edge(A,B)]))]))).
io(26,apply_axioms,[plop,extra_goal],[steps(4),optimised(["good(v1)","shown(red)","fin(s1, v1)","fin(s2, v2)","lab(v1, red)","lab(v2, green)","sub(a, s1)","sub(b, s2)","exp(A, B):-sub(A, C), fin(C, B)","row1(A, B):-exp(A, B), good(B)","row2(A, B):-exp(A, C), lab(C, B)","report(A, B):-sub(A, C), fin(C, D), good(D), sub(A, E), fin(E, F), lab(F, B), shown(B)"]),proof(proved(exhaustive))]).
io(27,learn_apply,[keep,[col-colour-q-[blue]],[a-c]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, c)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(28,derive,[sum,[fuse]],no_derivation).
io(29,synth,[dedup,[[-1]-[-1],[0,3]-[0,3],[5,8,-2]-[-2,5,8],[6,9,-1,2]-[-1,2,6,9]]],[hypothesis(expression(f(msort,[v(x)]))),program(["dedup(A, B) :-","msort(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[-4,0,7]])]).
io(30,signals,[reverse,[[]-[],[-3,0,3]-[3,0,-3],[2,5,8,-2]-[-2,8,5,2],[9,-1]-[-1,9]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,empty_case([]),depth_preserved]).
io(31,prove_equal,[filter,5],[first(["d([], [])","d([A|B], C):-(A>4->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>4->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(32,equivalent,[subsumed,[b-a]],proved(syntactic([subsumed((reach(A,B):-[edge(A,B),edge(B,C)]),by((reach(D,E):-[edge(D,E)])))]))).
io(33,apply_axioms,[detlog,at_most],[steps(1),optimised(["score(10)","score(50)","score(90)","low(A):-score(A), A=<50","grade(A, fail):-low(A)","grade(A, pass):-score(A), A>50"]),proof(proved(exhaustive))]).
io(34,learn_apply,[drop,[col-colour-q-[green],big-size-s-[s3]],[d-a]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(d, a)"]),proof(refuted(only_in_a([conn(a,a),conn(a,d),conn(d,a),conn(d,d)]),only_in_b([])))]).
io(35,derive,[len,[tuple]],no_derivation).
io(36,synth,[double,[[]-[],[0,3]-[0,6],[6,9,-1]-[12,18,-2],[7]-[14]]],[hypothesis(map),program(["double([], []).","double([A|B], [C|D]) :-","double_el(A, C),","double(B, D).","double_el(A, B) :-","B is 2*A."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[2,4,6,8,10,12],[-8,0,14]])]).
io(37,signals,[sum,[[]-0,[-2,1,4]-3,[3]-3,[4,7,-3,0]-8]],[in_type(list(int)),out_type(int),aggregate_of_list,empty_case(0)]).
io(38,prove_equal,[map,6],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(39,equivalent,[flipped,[a-b,b-a,b-c,c-a]],refuted(input([edge(a,a),edge(a,b),edge(a,c),edge(b,a),edge(b,b),edge(b,c),edge(c,c)]),only_in_a([reach(c,a),reach(c,b)]),only_in_b([]))).
io(40,apply_axioms,[proof_types,chain_through_recursion],[steps(1),optimised(["edge(a, b)","edge(b, c)","edge(c, a)","node(A):-edge(A, B)","node(A):-edge(B, A)","reach(A, B):-edge(A, B)","reach(A, B):-edge(A, C), reach(C, B)","start(A):-reach(A, B)"]),proof(proved(exhaustive))]).
io(41,learn_apply,[keep,[col-colour-q-[red]],[d-a]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(d, a)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(42,derive,[sumsq,[accumulate]],[strategy(accumulate),lemmas([plus_assoc]),program(["sumsq([],0).","sumsq([A|B],C) :- D is A*A, sumsq_acc(B,C,D).","sumsq_acc([],A,B) :- A is 0+B.","sumsq_acc([A|B],C,D) :- sumsq_acc(B,C,E), E is A*A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(43,synth,[add_k,[[1,4,7]-[4,7,10],[2]-[5],[7,-3,0,3]-[10,0,3,6],[8,-2]-[11,1]]],[hypothesis(map),program(["add_k([], []).","add_k([A|B], [C|D]) :-","add_k_el(A, C),","add_k(B, D).","add_k_el(A, B) :-","B is A+1+1+1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[4,5,6,7,8,9],[-1,3,10]])]).
io(44,signals,[len,[[]-0,[-2]-1,[-1,2,5,8]-4,[4,7]-2]],[in_type(list(int)),out_type(int),aggregate_of_list,empty_case(0)]).
io(45,prove_equal,[filter,7],[first(["d([], [])","d([A|B], C):-(A>2->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(\\+A=<2->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(46,equivalent,[dup_literal,[a-b,b-c,c-a]],proved(syntactic([dup_literal((reach(A,B):-[edge(A,B),edge(A,B)]))]))).
io(47,apply_axioms,[dup_literal,grandparent_last],[steps(1),optimised(["parent(ann, bob)","parent(ann, dee)","parent(bob, cy)","parent(dee, eli)","grandparent(A, B):-parent(C, B), parent(A, C)"]),proof(proved(syntactic))]).
io(48,learn_apply,[keep,[col-colour-q-[blue,green,red],big-size-s-[s1,s2]],[a-b,a-c,b-c,c-d]],error(time_limit_exceeded)).
io(49,derive,[len,[fuse]],no_derivation).
io(50,synth,[evens,[[]-[],[2,5,8,-2]-[2,8,-2],[3,6]-[6],[9,-1,2]-[2]]],[hypothesis(filter(plain,cmp(<,f(mod2,[v(x)]),c(1)))),program(["evens([], []).","evens([A|B], C) :-","(   evens_test(A)","->  C=[A|D]",";   C=D","),","evens(B, D).","evens_test(A) :-","A mod 2<1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[2,4,6],[-4,0]])]).
io(51,signals,[maximum,[[]-none,[-1,2]-2,[5,8,-2]-8,[6]-6]],[in_type(list(int)),out_type(any),empty_case(none)]).
io(52,prove_equal,[map,8],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(53,equivalent,[subsumed,[b-c,c-a]],proved(syntactic([subsumed((reach(A,B):-[edge(A,B),edge(B,C)]),by((reach(D,E):-[edge(D,E)])))]))).
io(54,apply_axioms,[subsumed_clause,path3_last],[steps(1),optimised(["link(a, b)","link(b, c)","link(c, a)","link(c, d)","node(A):-link(A, B)","path(A, B):-link(A, B)","path(A, B):-link(A, C), path(C, B)"]),proof(proved(syntactic))]).
io(55,learn_apply,[keep,[col-colour-q-[red]],[a-c,b-c,c-d]],error(time_limit_exceeded)).
io(56,derive,[sumsq,[tuple]],no_derivation).
io(57,synth,[positives,[[]-[],[-3,0,3,6]-[3,6],[4,7,-3]-[4,7],[9]-[9]]],[hypothesis(filter(plain,cmp(>,v(x),c(0)))),program(["positives([], []).","positives([A|B], C) :-","(   positives_test(A)","->  C=[A|D]",";   C=D","),","positives(B, D).","positives_test(A) :-","A>0."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[7]])]).
io(58,signals,[sort,[[0,3,6]-[0,3,6],[1]-[1],[6,9,-1,2]-[-1,2,6,9],[7,-3]-[-3,7]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,depth_preserved]).
io(59,prove_equal,[filter,9],[first(["d([], [])","d([A|B], C):-(A>4->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=5->C=[A|D];C=D), e(B, D)"]),proved(steps(2))]).
io(60,equivalent,[flipped,[c-a]],refuted(input([edge(a,a),edge(a,c),edge(c,c)]),only_in_a([reach(c,a)]),only_in_b([]))).
io(61,apply_axioms,[pid,no_loop_clause],[steps(1),optimised(["link(a, b)","link(b, c)","reach(A, B):-link(A, B)","reach(A, B):-link(A, C), reach(C, B)"]),proof(proved(exhaustive))]).
io(62,learn_apply,[drop,[col-colour-q-[blue,green],big-size-s-[s3]],[a-c,c-d]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(a, c)","edge(c, d)"]),proof(refuted(only_in_a([conn(a,a),conn(a,c),conn(a,d),conn(c,a),conn(c,c),conn(c,d),conn(d,a),conn(d,c),conn(d,d)]),only_in_b([])))]).
io(63,derive,[rev,all],[strategy(accumulate),lemmas([app_assoc]),program(["rev([],[]).","rev([A|B],C) :- rev_acc(B,[A],C).","rev_acc([],A,A).","rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(64,synth,[reverse,[[]-[],[-3,0]-[0,-3],[4]-[4],[5,8,-2,1]-[1,-2,8,5]]],[hypothesis(expression(f(rev,[v(x)]))),program(["reverse(A, B) :-","lists:reverse(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[6,5,4,3,2,1],[7,0,-4]])]).
io(65,signals,[dedup,[[]-[],[1,4,7,-3]-[-3,1,4,7],[2,5]-[2,5],[8,-2,1]-[-2,1,8]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,empty_case([]),depth_preserved]).
io(66,prove_equal,[map,10],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(67,equivalent,[extra_base,[a-b,a-c,b-a,b-c]],refuted(input([edge(a,a),edge(a,b),edge(a,c),edge(b,b),edge(c,b)]),only_in_a([reach(c,c)]),only_in_b([]))).
io(68,apply_axioms,[starlog,chain4],[steps(6),optimised(["f(a, b)","g(b, c)","h(c, d)","k(d, e)","r(A, B):-f(A, C), g(C, D), h(D, E), k(E, B)"]),proof(proved(exhaustive))]).
io(69,learn_apply,[drop,[col-colour-q-[blue,green,red]],[a-c]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(col,[A]),[l(q,[A])]),lr(l(col,[B]),[l(colour,[B])]))),[template_matches])])),optimised(["edge(a, c)"]),proof(refuted(only_in_a([conn(a,a),conn(a,c),conn(c,a),conn(c,c)]),only_in_b([])))]).
io(70,derive,[flat2,all],[strategy(fuse),lemmas([]),program(["flat2([],[]).","flat2([A|B],C) :- flat2_fuse(A,B,C).","flat2_fuse([],A,B) :- flat2(A,B).","flat2_fuse([A|B],C,[A|D]) :- flat2_fuse(B,C,D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(71,synth,[maximum,[[-2,1]-1,[-1,2]-2,[5,8]-8,[6,9]-9]],[hypothesis(expression(f(maxl,[v(x)]))),program(["maximum(A, B) :-","max_list(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[6,7])]).
io(72,signals,[positives,[[2,5]-[2,5],[3,6]-[3,6],[8,-2]-[8],[9,-1]-[9]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(73,prove_equal,[filter,11],[first(["d([], [])","d([A|B], C):-(A>2->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=2->C=[A|D];C=D), e(B, D)"]),not_proved]).
io(74,equivalent,[none,[a-b,a-c,c-a]],proved(syntactic([]))).
io(75,apply_axioms,[algebraplop,decreasing],[steps(0),optimised(["d(0)","d(1)","d(2)","d(3)","w(0, 10)","w(A, B):-d(A), A>0, C is A-1, w(C, D), B is D-2","from(A, B):-w(B, A)"]),proof(proved(syntactic))]).
io(76,learn_apply,[keep,[col-colour-q-[blue],big-size-s-[s1,s2,s3]],[a-b,a-c,c-d,d-a]],error(time_limit_exceeded)).
io(77,derive,[fib,[tuple]],[strategy(tuple),lemmas([]),program(["fib(0,0).","fib(s(0),1).","fib(s(s(A)),B) :- fib_tup(A,C,D), B is C+D.","fib_tup(0,1,0).","fib_tup(s(A),B,C) :- fib_tup(A,C,D), B is C+D."]),total(yes),functional(yes),typed_answers(yes)]).
io(78,synth,[sort,[[-1,2,5]-[-1,2,5],[0,3,6]-[0,3,6],[6,9,-1]-[-1,6,9],[7,-3,0]-[-3,0,7]]],error(permission_error(modify,static_procedure,sort/2))).
io(79,signals,[reverse,[[-3,0,3]-[3,0,-3],[3,6,9]-[9,6,3],[4,7,-3]-[-3,7,4],[9,-1,2]-[2,-1,9]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,depth_preserved]).
io(80,prove_equal,[map,12],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(81,equivalent,[dup_clause,[b-a,b-c]],proved(syntactic([dup_clause((reach(A,B):-[edge(A,B)]))]))).
io(82,apply_axioms,[proof_types,sibling_two_guards],[steps(2),optimised(["parent(ann, bob)","parent(ann, cy)","parent(bob, dee)","person(A):-parent(A, B)","person(A):-parent(B, A)","sib(A, B):-parent(C, A), parent(C, B), A\\=B"]),proof(proved(exhaustive))]).
io(83,learn_apply,[keep,[col-colour-q-[blue,green]],[a-c,b-c,d-a]],error(time_limit_exceeded)).
io(84,derive,[sum,all],[strategy(accumulate),lemmas([plus_assoc]),program(["sum([],0).","sum([A|B],C) :- sum_acc(B,C,A).","sum_acc([],A,B) :- A is 0+B.","sum_acc([A|B],C,D) :- sum_acc(B,C,E), E is A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(85,synth,[dedup,[[0,3,6,9]-[0,3,6,9],[1,4,7,-3]-[-3,1,4,7],[7,-3,0,3]-[-3,0,3,7],[8,-2,1,4]-[-2,1,4,8]]],[hypothesis(expression(f(msort,[v(x)]))),program(["dedup(A, B) :-","msort(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[-4,0,7]])]).
io(86,signals,[sum,[[-3,0,3,6]-6,[-2,1,4,7]-10,[4,7,-3,0]-8,[5,8,-2,1]-12]],[in_type(list(int)),out_type(int),aggregate_of_list]).
io(87,prove_equal,[filter,13],[first(["d([], [])","d([A|B], C):-(A>4->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(\\+A=<4->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(88,equivalent,[extra_base,[a-b]],refuted(input([edge(a,a),edge(b,a)]),only_in_a([reach(b,b)]),only_in_b([]))).
io(89,apply_axioms,[dup_clause,path3_last],[steps(1),optimised(["link(a, b)","link(b, c)","link(c, a)","link(c, d)","node(A):-link(A, B)","path(A, B):-link(A, C), path(C, B)","path(A, B):-link(A, B)"]),proof(proved(syntactic))]).
io(90,learn_apply,[keep,[col-colour-q-[blue],big-size-s-[s2]],[a-b,c-d]],error(time_limit_exceeded)).
io(91,derive,[fib,all],[strategy(tuple),lemmas([]),program(["fib(0,0).","fib(s(0),1).","fib(s(s(A)),B) :- fib_tup(A,C,D), B is C+D.","fib_tup(0,1,0).","fib_tup(s(A),B,C) :- fib_tup(A,C,D), B is C+D."]),total(yes),functional(yes),typed_answers(yes)]).
io(92,synth,[double,[[]-[]]],[hypothesis(constant([])),program(["double(_, [])."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[],[]])]).
io(93,signals,[len,[[]-0]],[in_type(list(A)),out_type(int),aggregate_of_list,nested_input,empty_case(0)]).
io(94,prove_equal,[map,14],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(95,equivalent,[none,[a-b,a-c,b-c,c-a]],proved(syntactic([]))).
io(96,apply_axioms,[subsumed_clause,sibling_last],[steps(1),optimised(["parent(ann, bob)","parent(ann, cy)","parent(bob, dee)","sibling(A, B):-parent(C, A), parent(C, B), A\\=B"]),proof(proved(syntactic))]).
io(97,learn_apply,[drop,[col-colour-q-[green]],[b-c]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(col,[A]),[l(q,[A])]),lr(l(col,[B]),[l(colour,[B])]))),[template_matches])])),optimised(["edge(b, c)"]),proof(refuted(only_in_a([conn(b,b),conn(b,c),conn(c,b),conn(c,c)]),only_in_b([])))]).
io(98,derive,[sum,[accumulate]],[strategy(accumulate),lemmas([plus_assoc]),program(["sum([],0).","sum([A|B],C) :- sum_acc(B,C,A).","sum_acc([],A,B) :- A is 0+B.","sum_acc([A|B],C,D) :- sum_acc(B,C,E), E is A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(99,synth,[add_k,[[-3]-[0],[0]-[3],[2]-[5],[5]-[8]]],[hypothesis(map),program(["add_k([], []).","add_k([A|B], [C|D]) :-","add_k_el(A, C),","add_k(B, D).","add_k_el(A, B) :-","B is A+1+1+1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[4,5,6,7,8,9],[-1,3,10]])]).
io(100,signals,[maximum,[[-2]- -2,[1]-1,[6]-6,[9]-9]],[in_type(list(int)),out_type(int),aggregate_of_list]).
io(101,prove_equal,[filter,15],[first(["d([], [])","d([A|B], C):-(A>1->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>1->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(102,equivalent,[dup_clause,[b-a,b-c,c-a]],proved(syntactic([dup_clause((reach(A,B):-[edge(A,B)]))]))).
io(103,apply_axioms,[dup_then_subsumed,path3_last],[steps(2),optimised(["link(a, b)","link(b, c)","link(c, a)","link(c, d)","node(A):-link(A, B)","path(A, B):-link(A, C), path(C, B)","path(A, B):-link(A, B)"]),proof(proved(syntactic))]).
io(104,learn_apply,[keep,[col-colour-q-[red],big-size-s-[s1]],[a-c,b-c,c-d,d-a]],error(time_limit_exceeded)).
io(105,derive,[len,[fuse]],no_derivation).
io(106,synth,[evens,[[-2,2,6]-[-2,2,6],[1]-[],[3,7,-2,2]-[-2,2],[6,-3]-[6]]],[hypothesis(filter(plain,cmp(<,f(mod2,[v(x)]),c(1)))),program(["evens([], []).","evens([A|B], C) :-","(   evens_test(A)","->  C=[A|D]",";   C=D","),","evens(B, D).","evens_test(A) :-","A mod 2<1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[2,4,6],[-4,0]])]).
io(107,signals,[sort,[[]-[],[-3,1,5]-[-3,1,5],[-1]-[-1],[2,6,-3,1]-[-3,1,2,6]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,empty_case([]),depth_preserved]).
io(108,prove_equal,[map,16],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(109,equivalent,[dup_literal,[a-b,c-a]],proved(syntactic([dup_literal((reach(A,B):-[edge(A,B),edge(A,B)]))]))).
io(110,apply_axioms,[loop2,two_callers],[steps(2),optimised(["colour(blue)","colour(red)","q(A):-colour(A)","col(A):-colour(A)","paint(A):-colour(A)"]),proof(proved(exhaustive))]).
io(111,learn_apply,[keep,[col-colour-q-[blue,green,red]],[a-b,a-c,c-d]],error(time_limit_exceeded)).
io(112,derive,[sumsq,all],[strategy(accumulate),lemmas([plus_assoc]),program(["sumsq([],0).","sumsq([A|B],C) :- D is A*A, sumsq_acc(B,C,D).","sumsq_acc([],A,B) :- A is 0+B.","sumsq_acc([A|B],C,D) :- sumsq_acc(B,C,E), E is A*A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(113,synth,[positives,[[]-[],[-1,3,7,-2]-[3,7],[2,6]-[2,6],[7,-2,2]-[7,2]]],[hypothesis(filter(plain,cmp(>,v(x),c(0)))),program(["positives([], []).","positives([A|B], C) :-","(   positives_test(A)","->  C=[A|D]",";   C=D","),","positives(B, D).","positives_test(A) :-","A>0."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[7]])]).
io(114,signals,[dedup,[[]-[],[-2,2,6,-3]-[-3,-2,2,6],[0,4]-[0,4],[8]-[8]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,empty_case([]),depth_preserved]).
io(115,prove_equal,[filter,17],[first(["d([], [])","d([A|B], C):-(A>4->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=4->C=[A|D];C=D), e(B, D)"]),not_proved]).
io(116,equivalent,[subsumed,[a-c]],proved(syntactic([subsumed((reach(A,B):-[edge(A,B),edge(B,C)]),by((reach(D,E):-[edge(D,E)])))]))).
io(117,apply_axioms,[algebraplop,base3_step5],[steps(0),optimised(["n(0)","n(1)","n(2)","n(3)","t(0, 3)","t(A, B):-n(A), A>0, C is A-1, t(C, D), B is D+5","inv(A, B):-t(B, A)"]),proof(proved(syntactic))]).
io(118,learn_apply,[keep,[col-colour-q-[red],big-size-s-[s1,s2,s3]],[a-c,b-c]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, c)","edge(b, c)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(512)))]).
io(119,derive,[rev,[accumulate]],[strategy(accumulate),lemmas([app_assoc]),program(["rev([],[]).","rev([A|B],C) :- rev_acc(B,[A],C).","rev_acc([],A,A).","rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(120,synth,[reverse,[[]-[],[3,7,-2]-[-2,7,3],[5]-[5],[8,-1,3,7]-[7,3,-1,8]]],[hypothesis(expression(f(rev,[v(x)]))),program(["reverse(A, B) :-","lists:reverse(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[6,5,4,3,2,1],[7,0,-4]])]).
io(121,signals,[double,[[]-[],[1,5,9]-[2,10,18],[4]-[8],[9,0]-[18,0]]],[in_type(list(int)),out_type(list(int)),length_preserved,empty_case([]),depth_preserved]).
io(122,prove_equal,[map,18],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(123,equivalent,[flipped,[a-b,a-c,b-a,c-a]],refuted(input([edge(a,a),edge(a,b),edge(a,c),edge(b,a),edge(b,b),edge(b,c),edge(c,c)]),only_in_a([reach(c,a),reach(c,b)]),only_in_b([]))).
io(124,apply_axioms,[piglog2,group_of_three],[steps(2),optimised(["d(y1)","g(x2)","src(s1)","a(s1, x1)","b(x1, x2)","c(s1, y1)","ok(A):-src(A), inv_1(A), inv_2(A)","inv_1(A):-a(A, B), b(B, C), g(C)","inv_2(A):-c(A, B), d(B)"]),proof(proved(exhaustive))]).
io(125,learn_apply,[drop,[col-colour-q-[blue,green]],[d-a]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(col,[A]),[l(q,[A])]),lr(l(col,[B]),[l(colour,[B])]))),[template_matches])])),optimised(["edge(d, a)"]),proof(refuted(only_in_a([conn(a,a),conn(a,d),conn(d,a),conn(d,d)]),only_in_b([])))]).
io(126,derive,[flat2,[fuse]],[strategy(fuse),lemmas([]),program(["flat2([],[]).","flat2([A|B],C) :- flat2_fuse(A,B,C).","flat2_fuse([],A,B) :- flat2(A,B).","flat2_fuse([A|B],C,[A|D]) :- flat2_fuse(B,C,D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(127,synth,[sum,[[]-0,[1]-1,[4,8,-1,3]-14,[6,-3]-3]],[hypothesis(expression(f(sum,[v(x)]))),program(["sum(A, B) :-","sum_list(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[21,3])]).
io(128,signals,[add_k,[[-3,1,5]-[0,4,8],[0]-[3],[2,6,-3,1]-[5,9,0,4],[5,9]-[8,12]]],[in_type(list(int)),out_type(list(int)),length_preserved,depth_preserved]).
io(129,prove_equal,[filter,19],[first(["d([], [])","d([A|B], C):-(A>1->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=2->C=[A|D];C=D), e(B, D)"]),proved(steps(2))]).
io(130,equivalent,[dup_literal,[a-b,a-c,b-c]],proved(syntactic([dup_literal((reach(A,B):-[edge(A,B),edge(A,B)]))]))).
io(131,apply_axioms,[dup_clause,sibling_last],[steps(1),optimised(["parent(ann, bob)","parent(ann, cy)","parent(bob, dee)","sibling(A, B):-parent(C, A), parent(C, B), A\\=B"]),proof(proved(syntactic))]).
io(132,learn_apply,[drop,[col-colour-q-[blue,green,red],big-size-s-[s2,s3]],[a-b,a-c,b-c,d-a]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(a, b)","edge(a, c)","edge(b, c)","edge(d, a)"]),proof(refuted(only_in_a([conn(a,a),conn(a,b),conn(a,c),conn(a,d),conn(b,a),conn(b,b),conn(b,c),conn(b,d),conn(c,a),conn(c,b),conn(c,c),conn(c,d),conn(d,a),conn(d,b),conn(d,c),conn(d,d)]),only_in_b([])))]).
io(133,derive,[rev,[tuple]],no_derivation).
io(134,synth,[len,[[]-0,[-3]-1,[2,6]-2,[7,-2,2]-3]],[hypothesis(expression(f(len,[v(x)]))),program(["len(A, B) :-","length(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[6,3])]).
io(135,signals,[evens,[[]-[],[-2,2,6,-3]-[-2,2,6],[1,5]-[],[6,-3,1]-[6]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(136,prove_equal,[map,20],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(137,equivalent,[subsumed,[b-a,b-c]],proved(syntactic([subsumed((reach(A,B):-[edge(A,B),edge(B,C)]),by((reach(D,E):-[edge(D,E)])))]))).
io(138,apply_axioms,[dup_literal,path3_last],[steps(1),optimised(["link(a, b)","link(b, c)","link(c, a)","link(c, d)","node(A):-link(A, B)","path(A, B):-link(A, B)","path(A, B):-link(A, C), path(C, B)"]),proof(proved(syntactic))]).
io(139,learn_apply,[keep,[col-colour-q-[blue]],[b-c,c-d,d-a]],error(time_limit_exceeded)).
io(140,derive,[flat2,all],[strategy(fuse),lemmas([]),program(["flat2([],[]).","flat2([A|B],C) :- flat2_fuse(A,B,C).","flat2_fuse([],A,B) :- flat2(A,B).","flat2_fuse([A|B],C,[A|D]) :- flat2_fuse(B,C,D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(141,synth,[dedup,[[]-[],[-2,2]-[-2,2],[3,7,-2,2]-[-2,2,3,7],[8]-[8]]],[hypothesis(expression(f(msort,[v(x)]))),program(["dedup(A, B) :-","msort(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[-4,0,7]])]).
io(142,signals,[len,[[]-0,[-1,3,7]-3,[2,6,-3,1]-4,[7]-1]],[in_type(list(int)),out_type(int),aggregate_of_list,empty_case(0)]).
io(143,prove_equal,[filter,21],[first(["d([], [])","d([A|B], C):-(A>4->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>4->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(144,equivalent,[flipped,[b-c]],refuted(input([edge(b,b),edge(b,c),edge(c,c)]),only_in_a([reach(c,b)]),only_in_b([]))).
io(145,apply_axioms,[dup_then_subsumed,sibling_last],[steps(2),optimised(["parent(ann, bob)","parent(ann, cy)","parent(bob, dee)","sibling(A, B):-parent(C, A), parent(C, B), A\\=B"]),proof(proved(syntactic))]).
io(146,learn_apply,[keep,[col-colour-q-[blue,green],big-size-s-[s2]],[a-b,b-c]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, b)","edge(b, c)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(512)))]).
io(147,derive,[fib,[fuse]],no_derivation).
io(148,synth,[double,[[]-[],[-1,3,7]-[-2,6,14],[7]-[14],[9,0]-[18,0]]],[hypothesis(map),program(["double([], []).","double([A|B], [C|D]) :-","double_el(A, C),","double(B, D).","double_el(A, B) :-","B is 2*A."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[2,4,6,8,10,12],[-8,0,14]])]).
io(149,signals,[maximum,[[]-none,[0,4,8,-1]-8,[5]-5,[8,-1]-8]],[in_type(list(int)),out_type(any),empty_case(none)]).
io(150,prove_equal,[map,22],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(151,equivalent,[extra_base,[a-b,b-a,b-c,c-a]],refuted(input([edge(a,a),edge(a,b),edge(a,c),edge(b,b),edge(c,b)]),only_in_a([reach(c,c)]),only_in_b([]))).
io(152,apply_axioms,[loop2,arity2],[steps(1),optimised(["edge(a, b)","edge(b, c)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive))]).
io(153,learn_apply,[keep,[col-colour-q-[blue]],[c-d]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(c, d)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(154,derive,[sum,[tuple]],no_derivation).
io(155,synth,[add_k,[[-3,1,5]-[0,4,8],[0,4,8,-1]-[3,7,11,2],[5]-[8],[8,-1]-[11,2]]],[hypothesis(map),program(["add_k([], []).","add_k([A|B], [C|D]) :-","add_k_el(A, C),","add_k(B, D).","add_k_el(A, B) :-","B is A+1+1+1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[4,5,6,7,8,9],[-1,3,10]])]).
io(156,signals,[sort,[[]-[],[4]-[4],[6,-3]-[-3,6],[9,0,4]-[0,4,9]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,empty_case([]),depth_preserved]).
io(157,prove_equal,[filter,23],[first(["d([], [])","d([A|B], C):-(A>1->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(\\+A=<1->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(158,equivalent,[none,[a-c,b-c,c-a]],proved(syntactic([]))).
io(159,apply_axioms,[plop,three_rows],[steps(6),optimised(["good(v1)","fin(s1, v1)","fin(s2, v2)","lab(v1, red)","lab(v2, green)","size(v1, big)","sub(a, s1)","sub(b, s2)","exp(A, B):-sub(A, C), fin(C, B)","row1(A, B):-exp(A, B), good(B)","row2(A, B):-exp(A, C), lab(C, B)","row3(A, B):-exp(A, C), size(C, B)","report(A, B, C):-sub(A, D), fin(D, E), good(E), sub(A, F), fin(F, G), lab(G, B), sub(A, H), fin(H, I), size(I, C)"]),proof(proved(exhaustive))]).
io(160,learn_apply,[drop,[col-colour-q-[green],big-size-s-[s3]],[a-b,a-c,b-c,c-d]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(a, b)","edge(a, c)","edge(b, c)","edge(c, d)"]),proof(refuted(only_in_a([conn(a,a),conn(a,b),conn(a,c),conn(a,d),conn(b,a),conn(b,b),conn(b,c),conn(b,d),conn(c,a),conn(c,b),conn(c,c),conn(c,d),conn(d,a),conn(d,b),conn(d,c),conn(d,d)]),only_in_b([])))]).
io(161,derive,[len,all],[strategy(accumulate),lemmas([plus_assoc]),program(["len([],0).","len([A|B],C) :- len_acc(B,C,1).","len_acc([],A,B) :- A is 0+B.","len_acc([A|B],C,D) :- len_acc(B,C,E), E is 1+D."]),total(yes),functional(yes),typed_answers(yes)]).
io(162,synth,[evens,[[]-[],[-2,2,6,-3]-[-2,2,6],[6,-3]-[6],[9,0,4]-[0,4]]],[hypothesis(filter(plain,cmp(<,f(mod2,[v(x)]),c(1)))),program(["evens([], []).","evens([A|B], C) :-","(   evens_test(A)","->  C=[A|D]",";   C=D","),","evens(B, D).","evens_test(A) :-","A mod 2<1."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[2,4,6],[-4,0]])]).
io(163,signals,[dedup,[[-3,1,5,9]-[-3,1,5,9],[2]-[2],[5,9]-[5,9],[7,-2,2]-[-2,2,7]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,depth_preserved]).
io(164,prove_equal,[map,24],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(165,equivalent,[dup_clause,[a-c,b-a]],proved(syntactic([dup_clause((reach(A,B):-[edge(A,B)]))]))).
io(166,apply_axioms,[detlog,extra_goal],[steps(1),optimised(["even(2)","num(1)","num(2)","num(5)","small(A):-num(A), A<3","kind(A, small):-small(A)","kind(A, large):-num(A), A>=3, A>0"]),proof(proved(exhaustive))]).
io(167,learn_apply,[keep,[col-colour-q-[red]],[a-c,c-d,d-a]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, c)","edge(c, d)","edge(d, a)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(512)))]).
io(168,derive,[sumsq,all],[strategy(accumulate),lemmas([plus_assoc]),program(["sumsq([],0).","sumsq([A|B],C) :- D is A*A, sumsq_acc(B,C,D).","sumsq_acc([],A,B) :- A is 0+B.","sumsq_acc([A|B],C,D) :- sumsq_acc(B,C,E), E is A*A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(169,synth,[positives,[[]-[],[-3,1,5,9]-[1,5,9],[2]-[2],[7,-2,2]-[7,2]]],[hypothesis(filter(plain,cmp(>,v(x),c(0)))),program(["positives([], []).","positives([A|B], C) :-","(   positives_test(A)","->  C=[A|D]",";   C=D","),","positives(B, D).","positives_test(A) :-","A>0."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[1,2,3,4,5,6],[7]])]).
io(170,signals,[double,[[]-[],[3,7]-[6,14],[6,-3,1]-[12,-6,2],[8,-1,3,7]-[16,-2,6,14]]],[in_type(list(int)),out_type(list(int)),length_preserved,empty_case([]),depth_preserved]).
io(171,prove_equal,[filter,25],[first(["d([], [])","d([A|B], C):-(A>3->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=4->C=[A|D];C=D), e(B, D)"]),proved(steps(2))]).
io(172,equivalent,[extra_base,[a-b]],refuted(input([edge(a,a),edge(b,a)]),only_in_a([reach(b,b)]),only_in_b([]))).
io(173,apply_axioms,[proof_types,guard_implied_by_guard],[steps(2),optimised(["parent(ann, bob)","parent(bob, cy)","person(A):-parent(A, B)","human(A):-person(A)","elder(A):-parent(A, B), parent(B, C)"]),proof(proved(exhaustive))]).
io(174,learn_apply,[keep,[col-colour-q-[blue,green,red],big-size-s-[s1,s2]],[a-b,d-a]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, b)","edge(d, a)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(512)))]).
io(175,derive,[len,[accumulate]],[strategy(accumulate),lemmas([plus_assoc]),program(["len([],0).","len([A|B],C) :- len_acc(B,C,1).","len_acc([],A,B) :- A is 0+B.","len_acc([A|B],C,D) :- len_acc(B,C,E), E is 1+D."]),total(yes),functional(yes),typed_answers(yes)]).
io(176,synth,[reverse,[[]-[],[-2,2,6,-3]-[-3,6,2,-2],[0,4,8]-[8,4,0],[3,7]-[7,3]]],[hypothesis(expression(f(rev,[v(x)]))),program(["reverse(A, B) :-","lists:reverse(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[[6,5,4,3,2,1],[7,0,-4]])]).
io(177,signals,[add_k,[[]-[],[-1,3,7]-[2,6,10],[4]-[7],[9,0,4,8]-[12,3,7,11]]],[in_type(list(int)),out_type(list(int)),length_preserved,empty_case([]),depth_preserved]).
io(178,prove_equal,[map,26],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is A+A, e(B, D)"]),proved(steps(2))]).
io(179,equivalent,[none,[a-b]],proved(syntactic([]))).
io(180,apply_axioms,[dup_literal,sibling_last],[steps(1),optimised(["parent(ann, bob)","parent(ann, cy)","parent(bob, dee)","sibling(A, B):-parent(C, B), A\\=B, parent(C, A)"]),proof(proved(syntactic))]).
io(181,learn_apply,[keep,[col-colour-q-[red]],[a-b]],[algorithm(algorithm([rule(unfold,[])])),optimised(["edge(a, b)","e(A, B):-edge(A, B)","conn(A, B):-edge(A, B)"]),proof(proved(exhaustive(16)))]).
io(182,derive,[sumsq,all],[strategy(accumulate),lemmas([plus_assoc]),program(["sumsq([],0).","sumsq([A|B],C) :- D is A*A, sumsq_acc(B,C,D).","sumsq_acc([],A,B) :- A is 0+B.","sumsq_acc([A|B],C,D) :- sumsq_acc(B,C,E), E is A*A+D."]),total(yes),functional(yes),typed_answers(no)]).
io(183,synth,[sum,[[]-0,[0,5,-3]-2,[3]-3,[6,-2,3,8]-15]],[hypothesis(expression(f(sum,[v(x)]))),program(["sum(A, B) :-","sum_list(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[21,3])]).
io(184,signals,[evens,[[]-[],[-2,3]-[-2],[5]-[],[8,0,5,-3]-[8,0]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(185,prove_equal,[filter,27],[first(["d([], [])","d([A|B], C):-(A>1->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(A>=1->C=[A|D];C=D), e(B, D)"]),not_proved]).
io(186,equivalent,[dup_clause,[b-c]],proved(syntactic([dup_clause((reach(A,B):-[edge(A,B)]))]))).
io(187,apply_axioms,[implied_clause,path3_last],[steps(0),optimised(["link(a, b)","link(b, c)","link(c, a)","link(c, d)","node(A):-link(A, B)","path(A, B):-link(A, B)","path(A, B):-link(A, C), path(C, B)","path(A, B):-link(A, C), link(C, B)"]),proof(proved(syntactic))]).
io(188,learn_apply,[drop,[col-colour-q-[blue,green],big-size-s-[s3]],[b-c]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(A,[B]),[l(C,[B])]),lr(l(A,[D]),[l(E,[D])]))),[template_matches])])),optimised(["edge(b, c)"]),proof(refuted(only_in_a([conn(b,b),conn(b,c),conn(c,b),conn(c,c)]),only_in_b([])))]).
io(189,derive,[rev,all],[strategy(accumulate),lemmas([app_assoc]),program(["rev([],[]).","rev([A|B],C) :- rev_acc(B,[A],C).","rev_acc([],A,A).","rev_acc([A|B],C,D) :- rev_acc(B,[A|C],D)."]),total(yes),functional(yes),typed_answers(yes)]).
io(190,synth,[len,[[]-0,[-2]-1,[1,6,-2,3]-4,[4,9]-2]],[hypothesis(expression(f(len,[v(x)]))),program(["len(A, B) :-","length(A, B)."]),runs_on([[1,2,3,4,5,6],[-4,0,7]],[6,3])]).
io(191,signals,[positives,[[]-[],[-1,4,9]-[4,9],[2]-[2],[6,-2]-[6]]],[in_type(list(int)),out_type(list(int)),subsequence,drops_elements]).
io(192,prove_equal,[map,28],[first(["d([], [])","d([A|B], [C|D]):-C is 2*A, d(B, D)"]),second(["e([], [])","e([A|B], [C|D]):-C is 3*A, e(B, D)"]),not_proved]).
io(193,equivalent,[dup_literal,[c-a]],proved(syntactic([dup_literal((reach(A,B):-[edge(A,B),edge(A,B)]))]))).
io(194,apply_axioms,[pid,extra_rule],[steps(2),optimised(["arc(a, b)","arc(b, c)","arc(c, a)","node(A):-arc(A, B)","conn(A, B):-arc(A, B)","conn(A, B):-arc(A, C), conn(C, B)"]),proof(proved(exhaustive))]).
io(195,learn_apply,[drop,[col-colour-q-[blue,green,red]],[c-d]],[algorithm(algorithm([rule(del_clause,[]),rule(replace(tmpl(lr(l(col,[A]),[l(q,[A])]),lr(l(col,[B]),[l(colour,[B])]))),[template_matches])])),optimised(["edge(c, d)"]),proof(refuted(only_in_a([conn(c,c),conn(c,d),conn(d,c),conn(d,d)]),only_in_b([])))]).
io(196,derive,[flat2,[accumulate]],no_derivation).
io(197,synth,[maximum,[[]-none,[-1,4]-4,[5,-3,2]-5,[8]-8]],false).
io(198,signals,[reverse,[[-3]-[-3],[0,5,-3,2]-[2,-3,5,0],[3,8]-[8,3],[7,-1,4]-[4,-1,7]]],[in_type(list(int)),out_type(list(int)),length_preserved,permutation,depth_preserved]).
io(199,prove_equal,[filter,29],[first(["d([], [])","d([A|B], C):-(A>3->C=[A|D];C=D), d(B, D)"]),second(["e([], [])","e([A|B], C):-(\\+A=<3->C=[A|D];C=D), e(B, D)"]),proved(steps(1))]).
io(200,equivalent,[subsumed,[a-c]],proved(syntactic([subsumed((reach(A,B):-[edge(A,B),edge(B,C)]),by((reach(D,E):-[edge(D,E)])))]))).
