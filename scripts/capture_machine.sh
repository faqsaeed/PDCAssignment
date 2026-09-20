#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/results/machine"
mkdir -p "$OUT"

lscpu | head -25 | tee "$OUT/lscpu.txt"
grep MemTotal /proc/meminfo | tee "$OUT/memory.txt"
gcc --version | head -1 | tee "$OUT/gcc.txt"
uname -a | tee "$OUT/kernel.txt"
ispc --version | tee "$OUT/ispc.txt"
grep -o avx2 /proc/cpuinfo | head -1 | tee "$OUT/avx2.txt"

if command -v cpupower >/dev/null 2>&1; then
  cpupower frequency-info > "$OUT/cpupower.txt" 2>&1 || true
fi

if command -v dmidecode >/dev/null 2>&1; then
  sudo dmidecode --type memory > "$OUT/dmidecode-memory.txt" 2>&1 || true
fi

echo "Machine information saved under results/machine/."
