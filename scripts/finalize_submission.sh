#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <roll-number>" >&2
  echo "Example: $0 23L-0905" >&2
  exit 1
fi

ROLL="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[ -f writeup.pdf ] || { echo "ERROR: writeup.pdf is missing from repository root." >&2; exit 2; }
[ -f prog6_kmeans/start.png ] || { echo "ERROR: prog6_kmeans/start.png is missing." >&2; exit 3; }
[ -f prog6_kmeans/end.png ] || { echo "ERROR: prog6_kmeans/end.png is missing." >&2; exit 3; }

mkdir -p plots
cp prog6_kmeans/start.png prog6_kmeans/end.png plots/

for d in \
  prog1_mandelbrot_threads \
  prog2_vecintrin \
  prog3_mandelbrot_ispc \
  prog4_sqrt \
  prog5_saxpy \
  prog6_kmeans
do
  (cd "$d" && make clean) || true
done

rm -f prog*/*.ppm prog*/*.log prog*/*.dat
rm -rf prog6_kmeans/venv prog*/__pycache__
rm -rf results/raw/*
mkdir -p results/raw
touch results/raw/.gitkeep

git add -A
if ! git diff --cached --quiet; then
  git commit -m "Final submission"
fi

# Ensure the tag points at the final committed source/plots/write-up state.
if git rev-parse submission >/dev/null 2>&1; then
  git tag -d submission >/dev/null
fi
git tag -a submission -m "CS3006 Assignment 2 final submission"

# The addendum asks for this file in the archive; it need not be committed.
git log --oneline --stat > gitlog.txt

cd "$(dirname "$ROOT")"
NAME="CS3006_A2_${ROLL}.zip"
rm -f "$NAME"
zip -r "$NAME" "$(basename "$ROOT")" >/dev/null

echo "Created: $(pwd)/$NAME"
ls -lh "$NAME"
echo "Repository size:"
du -sh "$ROOT"

echo
echo "Verify the archive in a fresh directory before uploading."
