#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="$ROOT/results/raw"
RUN5="$ROOT/scripts/run_five.sh"
mkdir -p "$RAW"

T="$(nproc)"
DOUBLE_T=$((2*T))

echo "Hardware threads T=$T"
echo "Raw outputs will be written under $RAW"

# Program 1 -----------------------------------------------------------------
cd "$ROOT/prog1_mandelbrot_threads"
make clean >/dev/null && make
for n in 1 2 4 "$T" "$DOUBLE_T"; do
  if [ "$n" -le 32 ]; then
    MANDELBROT_SCHEDULE=block "$RUN5" "$RAW/p1_block_t${n}.txt" ./mandelbrot -t "$n"
    "$RUN5" "$RAW/p1_cyclic_t${n}.txt" ./mandelbrot -t "$n"
  fi
done
MANDELBROT_SCHEDULE=block "$RUN5" "$RAW/p1_block_view2_t${T}.txt" ./mandelbrot -t "$T" --view 2
"$RUN5" "$RAW/p1_cyclic_view2_t${T}.txt" ./mandelbrot -t "$T" --view 2

# Program 2 -----------------------------------------------------------------
cd "$ROOT/prog2_vecintrin"
cp CS149intrin.h "$RAW/CS149intrin.h.backup"
restore_p2() { cp "$RAW/CS149intrin.h.backup" CS149intrin.h; }
trap restore_p2 EXIT
for width in 2 4 8 16; do
  sed -E -i "s/^#define VECTOR_WIDTH [0-9]+/#define VECTOR_WIDTH $width/" CS149intrin.h
  make clean >/dev/null && make
  "$RUN5" "$RAW/p2_width${width}.txt" ./myexp -s 10000
done
restore_p2
trap - EXIT
rm -f "$RAW/CS149intrin.h.backup"
make clean >/dev/null && make

# Program 3 -----------------------------------------------------------------
cd "$ROOT/prog3_mandelbrot_ispc"
make clean >/dev/null && make
"$RUN5" "$RAW/p3_ispc.txt" ./mandelbrot_ispc
for tasks in 1 2 4 8 16 32 64; do
  "$RUN5" "$RAW/p3_tasks${tasks}.txt" ./mandelbrot_ispc --tasks --num-tasks "$tasks"
done

# Program 4 -----------------------------------------------------------------
cd "$ROOT/prog4_sqrt"
make clean >/dev/null && make
for case_name in normal uniform divergent; do
  "$RUN5" "$RAW/p4_${case_name}.txt" ./sqrt --case "$case_name"
done

# Program 5 -----------------------------------------------------------------
cd "$ROOT/prog5_saxpy"
make clean >/dev/null && make
"$RUN5" "$RAW/p5_saxpy.txt" ./saxpy

# Program 6 -----------------------------------------------------------------
cd "$ROOT/prog6_kmeans"
if [ ! -f data.dat ]; then
  echo "ERROR: prog6_kmeans/data.dat is missing."
  echo "Run: cd prog6_kmeans && python3 generate_data.py && md5sum data.dat"
  exit 1
fi
EXPECTED="3a25f24193f4fdca82ee4cb2737fd5bb"
ACTUAL="$(md5sum data.dat | awk '{print $1}')"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "ERROR: Program 6 checksum mismatch: $ACTUAL"
  exit 1
fi
make clean >/dev/null && make
KMEANS_THREADS=1 "$RUN5" "$RAW/p6_serial_baseline.txt" env KMEANS_THREADS=1 ./kmeans
KMEANS_THREADS="$T" "$RUN5" "$RAW/p6_parallel_t${T}.txt" env KMEANS_THREADS="$T" ./kmeans

# Regenerate final plots using the last correct full-data run.
python3 plot.py

echo
echo "Measurement sweep complete."
echo "Do not invent missing numbers. Use only values in $RAW in your write-up."
echo "Program 6 plots should now be in prog6_kmeans/start.png and end.png."
