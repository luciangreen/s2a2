# Dictionary of algorithms

| File | Written by | Contents |
| --- | --- | --- |
| `dictionary.pl` | `prolog/harvest.pl` | 477 `entry(Id, Info, Clauses)` terms harvested from the non-LLM Prolog code of 82 of the author's public repositories, plus `alt(Id, AltId, Info, Clauses)`: other definitions with the same behaviour |
| `generated.pl` | `prolog/dict_gen.pl` | invented and joined entries (`uses(Ids)` names the entries they call), and `lemma(Kind, Ids, Status)` with Status `proved(Steps)`, `tested(N)` or `refuted(Input)` |

`Info` holds `source(Repo, File, Name/Arity)`, or `invented(Scheme, Ids)` or `joined(How, Ids)`. It also holds `in(Type)`, `out(Type)`, `size(S)` and, for harvested entries, `also(Sources)`: the other places the same behaviour was found.

Regenerate:

```
cd prolog
swipl harvest.pl -- ../dictionary/dictionary.pl ~/repos/*   # needs the repositories cloned
swipl dict_gen.pl
```

Use:

```prolog
?- use_module(dict), load_dictionary(['../dictionary/dictionary.pl', '../dictionary/generated.pl']),
   dict_synth(f, [[1,2]-5, [3]-9, []-0], P, R).
```
