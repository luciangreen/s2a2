#!/usr/bin/env bash
# Run each family in its own process with a time limit; logs and results in results/.
cd "$(dirname "$0")/prolog"
mkdir -p ../results
for f in ${FAMS:-algebraplop detlog piglog2 dup_clause dup_literal subsumed_clause implied_clause dup_then_subsumed pid loop2 starlog plop}; do
  RESULTS=../results/$f.pl FAMILIES=$f timeout ${LIMIT:-1500} swipl -q -g "consult(experiment),main,halt" -t halt > ../results/$f.log 2>&1
  echo "$f exit $?"
done
echo ALLDONE
