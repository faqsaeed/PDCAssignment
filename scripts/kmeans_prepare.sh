#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDIR="$ROOT/prog6_kmeans"
GENERATOR="${1:-}"
MODE="${2:-small}"

if [ ! -d "$KDIR" ]; then
  echo "prog6_kmeans is missing. Run scripts/prepare_repo.sh on your Mac first." >&2
  exit 1
fi

if [ -n "$GENERATOR" ]; then
  cp "$GENERATOR" "$KDIR/generate_data.py"
fi

if [ ! -f "$KDIR/generate_data.py" ]; then
  echo "FAST generate_data.py is not present." >&2
  echo "Pass its local path as the first argument, e.g.:" >&2
  echo "  $0 ~/Downloads/generate_data.py small" >&2
  exit 1
fi

cd "$KDIR"
python3 -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip
pip install 'numpy>=1.19.5' 'matplotlib>=3.8' 'scikit-learn>=1.1.2'

case "$MODE" in
  small)
    python3 generate_data.py --M 100000 --output data_small.dat
    cp data_small.dat data.dat
    echo "Small debugging dataset installed as data.dat. DO NOT use it for reported timings."
    ;;
  full)
    rm -f data.dat
    python3 generate_data.py
    echo "Checking required full dataset..."
    SIZE="$(stat -c %s data.dat)"
    HASH="$(md5sum data.dat | awk '{print $1}')"
    echo "size=$SIZE"
    echo "md5=$HASH"
    [ "$SIZE" = "804002420" ] || { echo "ERROR: unexpected data.dat size" >&2; exit 2; }
    [ "$HASH" = "3a25f24193f4fdca82ee4cb2737fd5bb" ] || { echo "ERROR: checksum mismatch" >&2; exit 3; }
    echo "Full Program 6 dataset verified."
    ;;
  *)
    echo "Mode must be 'small' or 'full'." >&2
    exit 1
    ;;
esac
