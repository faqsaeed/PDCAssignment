#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y build-essential git wget python3 python3-pip python3-venv zip dmidecode linux-cpupower

if ! grep -qw avx2 /proc/cpuinfo; then
  echo "ERROR: AVX2 was not detected. Do not use this machine for the AVX2 assignment path." >&2
  exit 2
fi

echo "AVX2 detected."

cd "$HOME"
if ! command -v ispc >/dev/null 2>&1 || ! ispc --version 2>/dev/null | grep -q '1.31.0'; then
  wget -c https://github.com/ispc/ispc/releases/download/v1.31.0/ispc-v1.31.0-linux.tar.gz
  tar -xzf ispc-v1.31.0-linux.tar.gz
  if ! grep -Fq 'ispc-v1.31.0-linux/bin' "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:$HOME/ispc-v1.31.0-linux/bin' >> "$HOME/.bashrc"
  fi
  export PATH="$PATH:$HOME/ispc-v1.31.0-linux/bin"
fi

ispc --version

echo
echo "Linux prerequisites are installed. Open a new shell or run:"
echo '  source ~/.bashrc'
