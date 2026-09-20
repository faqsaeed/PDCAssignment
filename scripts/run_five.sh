#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <output-file> <command> [args...]" >&2
  echo "Example: $0 results/raw/p1_t4.txt ./mandelbrot -t 4" >&2
  exit 1
fi

OUT="$1"
shift
mkdir -p "$(dirname "$OUT")"

{
  echo "# date: $(date --iso-8601=seconds)"
  echo "# host: $(hostname)"
  printf '# command:'
  printf ' %q' "$@"
  echo
  echo

  for run in 1 2 3 4 5; do
    echo "===== RUN $run ====="
    "$@"
    echo
  done
} | tee "$OUT"

echo "Saved five raw runs to $OUT"
