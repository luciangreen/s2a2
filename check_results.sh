#!/usr/bin/env bash
# Fails unless every test line in results/*.log has exact=true and a proof that is
# proved(...) or proved_if_types_fixed(...).
cd "$(dirname "$0")/results"
bad=$(grep -h "exact=" *.log | grep -v -E "exact=true .*proof=proved" || true)
n=$(grep -h "exact=" *.log | wc -l)
if [ -n "$bad" ] || [ "$n" -eq 0 ]; then echo "FAILED:"; echo "$bad"; exit 1; fi
echo "$n of $n tests: exact and proved"
