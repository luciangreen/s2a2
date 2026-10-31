/*  s2gn_cover.pl -- make an S2GN grammar cover every input it was learned from.

    S2GN (Philosophy/s2g/normalise.pl: strings_to_grammar_words/2) can return a grammar
    that does not parse one of its own inputs. Example (found in this study):
        ["n1,l2,s1", "n1,l2", "n1,n1,l2,s1", "s1,n1,l2"]
    gives a1 -> a2 l2 s1 | s1 n1 l2 | n1 l2 s1, which does not parse "n1,l2": the trailing
    s1 is optional in the data but required in the grammar.

    strings_to_grammar_covering(+Strings, -Grammar, -Added) runs S2GN, checks every input
    with check_grammar/2, and adds each input it misses as an alternative of the start
    symbol, so the result always covers 100% of the inputs. Added lists those strings.
    Load after Philosophy/s2g/strings_to_grammar.pl (which includes normalise.pl). */

strings_to_grammar_covering(L, G, Added) :-
    strings_to_symbols(L, L1, Lw),
    strings_to_grammar(L1, G5),
    decode_grammar(G5, G0),
    findall(W, ( member(W, Lw), \+ catch(check_grammar([W], G0), _, fail) ), Missed),
    G0 = [[Start, Arrow, _]|_],
    findall([Start, Arrow, Items],
            ( member(W, Missed), term_string(T, W), maplist([X, [X]]>>true, T, Items) ), Extra),
    append(G0, Extra, G),
    Added = Missed.
