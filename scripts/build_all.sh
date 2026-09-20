#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for d in \
  prog1_mandelbrot_threads \
  prog2_vecintrin \
  prog3_mandelbrot_ispc \
  prog4_sqrt \
  prog5_saxpy \
  prog6_kmeans
do
  echo "===== $d ====="
  (cd "$ROOT/$d" && make clean && make)
done

echo "All six programs built successfully."
