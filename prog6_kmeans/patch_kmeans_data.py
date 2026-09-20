#!/usr/bin/env python3
"""Repair a macOS-generated Program 6 data.dat to match the required checksum.

Usage:
    python3 patch_kmeans_data.py expected_assignments.bin

The script is intentionally conservative. It first verifies that the first
800,002,420 bytes of data.dat match the required dataset prefix. Only then does
it replace the final 4,000,000-byte initial-assignment block, and finally it
verifies the complete required MD5 checksum.
"""

import hashlib
from pathlib import Path
import sys

DATA = Path("data.dat")
ASSIGN = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("expected_assignments.bin")
PREFIX_LEN = 800_002_420
EXPECTED_SIZE = 804_002_420
EXPECTED_PREFIX_MD5 = "8ecc561e507139dbbea6b195796fbbdd"
EXPECTED_FULL_MD5 = "3a25f24193f4fdca82ee4cb2737fd5bb"
EXPECTED_ASSIGNMENT_SIZE = 4_000_000


def md5_range(path: Path, limit=None) -> str:
    h = hashlib.md5()
    remaining = limit
    with path.open("rb") as f:
        while True:
            chunk_size = 16 * 1024 * 1024
            if remaining is not None:
                if remaining <= 0:
                    break
                chunk_size = min(chunk_size, remaining)
            block = f.read(chunk_size)
            if not block:
                break
            h.update(block)
            if remaining is not None:
                remaining -= len(block)
    return h.hexdigest()


def main() -> None:
    if not DATA.exists():
        raise SystemExit("data.dat not found in the current directory.")

    size = DATA.stat().st_size
    if size != EXPECTED_SIZE:
        raise SystemExit(
            f"Wrong data.dat size: {size} bytes (expected {EXPECTED_SIZE})."
        )

    if not ASSIGN.exists():
        raise SystemExit(
            f"Assignment block not found: {ASSIGN}. Place expected_assignments.bin "
            "in prog6_kmeans or pass its path as the first argument."
        )

    assignment_size = ASSIGN.stat().st_size
    if assignment_size != EXPECTED_ASSIGNMENT_SIZE:
        raise SystemExit(
            f"Wrong assignment block size: {assignment_size} bytes "
            f"(expected {EXPECTED_ASSIGNMENT_SIZE})."
        )

    prefix_md5 = md5_range(DATA, PREFIX_LEN)
    print("Prefix MD5:", prefix_md5)
    if prefix_md5 != EXPECTED_PREFIX_MD5:
        raise SystemExit(
            "Prefix differs from the required dataset. Refusing to modify data.dat."
        )

    with DATA.open("r+b") as f, ASSIGN.open("rb") as assignments:
        f.seek(PREFIX_LEN)
        f.write(assignments.read())

    full_md5 = md5_range(DATA)
    print("Full MD5:", full_md5)
    if full_md5 != EXPECTED_FULL_MD5:
        raise SystemExit(
            "Patched data.dat still does not match the required checksum."
        )

    print("Success: data.dat matches the required FAST checksum.")


if __name__ == "__main__":
    main()
