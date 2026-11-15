# S2A2 Workbench (web app)

`index.html` runs S2A2 in the browser. The Prolog files in `../prolog` and `../dictionary` load into SWI-Prolog compiled to WebAssembly ([swipl-wasm](https://github.com/SWI-Prolog/npm-swipl-wasm) 8.2.6, SWI-Prolog 10.1.20), running in a Web Worker. Nothing is sent to a server.

| Page | What it runs |
| --- | --- |
| Learn an optimisation | `s2a2.pl`: learn each family from its two training pairs, apply to the tests, compare with the axioms, prove |
| Specification to algorithm | `fold.pl`: eureka strategies, lemma discovery, totality, bounded check |
| Program from examples | `io_synth.pl`: nested predicates from input/output, the hand-over to `fold.pl`, a proof against a reference, active learning |
| Dictionary of algorithms | `dict.pl`: synthesis from examples (positive and negative) or from code; browse, run, lemmas |
| Prove two programs equal | `io_proof.pl`, with a counter-example from the probe inputs when the proof fails |
| Types from proofs | `types.pl` |
| MNN speed-up | `results/speedup.txt`, and one family measured live |
| Committed results | the files in `../results` |

Each page calls one predicate of `prolog/web.pl`. In the browser there are no alarms, so `web.pl` replaces `call_with_time_limit` by an inference limit (50 million inferences a second). That makes the results deterministic, and they match the committed CI logs.

## Run it

Serve the repository root over HTTP, then open `/webapp/`:

```
python3 -m http.server 8000      # from the repository root
# open http://localhost:8000/webapp/
```

The page looks for `swipl-bundle.js` beside it first, then loads the pinned bundle from jsDelivr or from SWI-Prolog's GitHub Pages. To work offline, copy `index.js` from `https://swi-prolog.github.io/npm-swipl-wasm/8/2/6/` to `webapp/swipl-bundle.js`.

## Test

```
cd prolog && S2A2_WEB_SHIM=1 swipl -q -g main -t 'halt(1)' web_tests.pl
```
