#!/usr/bin/env python3
"""
generate_data.py -- Generates data.dat for CS3006 Assignment 2, Program 6 (K-Means).

FAST-NUCES CS3006 (Parallel and Distributed Computing), Fall 2026.
Instructor: Dr. Abdul Qadeer.

This replaces the ~800 MB data.dat that the Stanford handout tells you to fetch
from their AFS filesystem. The generator is deterministic.
"""

import argparse
import os
import struct
import numpy as np

DEFAULT_M = 1_000_000
DEFAULT_N = 100
DEFAULT_K = 3
DEFAULT_EPSILON = 0.1
DEFAULT_OUTPUT = "data.dat"
SEED = 7
CHUNK = 100_000


def generate(M: int, N: int, K: int, epsilon: float,
             output: str, verbose: bool = True) -> None:
    rng = np.random.default_rng(SEED)
    header_bytes = 4 + 4 + 4 + 8
    total_bytes = header_bytes + M * N * 8 + K * N * 8 + M * 4
    if verbose:
        print(f"Generating {M:,} points x {N} dims, K={K} clusters -> {output}")
        print(f"Expected file size: {total_bytes / 1024**2:.1f} MB")

    centres = rng.uniform(0.0, 1.0, size=(K, N))
    labels = rng.integers(0, K, size=M)

    data = np.empty((M, N), dtype=np.float64)
    for start in range(0, M, CHUNK):
        end = min(start + CHUNK, M)
        noise = rng.standard_normal(size=(end - start, N)) * 3.0
        data[start:end] = centres[labels[start:end]] + noise
        if verbose:
            print(f"  points: {end:>10,} / {M:,}  ({end / M * 100:3.0f}%)", end="\r")
    if verbose:
        print()

    centroids = np.empty((K, N), dtype=np.float64)
    centroids[0] = rng.uniform(0.0, 1.0, size=N)
    for k in range(1, K):
        centroids[k] = centroids[0] + (rng.uniform(0.0, 1.0, size=N) - 0.5) * 0.1

    if verbose:
        print("  computing initial assignments ...")
    assignments = np.empty(M, dtype=np.int32)
    for start in range(0, M, CHUNK):
        end = min(start + CHUNK, M)
        block = data[start:end]
        d2 = ((block[:, np.newaxis, :] - centroids[np.newaxis, :, :]) ** 2).sum(axis=2)
        assignments[start:end] = np.argmin(d2, axis=1)

    if verbose:
        print(f"  writing {output} ...")
    with open(output, "wb") as f:
        f.write(struct.pack("i", M))
        f.write(struct.pack("i", N))
        f.write(struct.pack("i", K))
        f.write(struct.pack("d", epsilon))
        f.write(data.tobytes())
        f.write(centroids.tobytes())
        f.write(assignments.tobytes())

    if verbose:
        actual = os.path.getsize(output)
        print(f"Done. File: {output}  ({actual / 1024**2:.1f} MB)")
        print(f"Header written: M={M}, N={N}, K={K}, epsilon={epsilon}")
        if actual != total_bytes:
            print(f"WARNING: expected {total_bytes} bytes, got {actual}.")


def main():
    parser = argparse.ArgumentParser(description="Generate data.dat for CS3006 asst2 prog6_kmeans")
    parser.add_argument("--M", type=int, default=DEFAULT_M)
    parser.add_argument("--N", type=int, default=DEFAULT_N)
    parser.add_argument("--K", type=int, default=DEFAULT_K)
    parser.add_argument("--epsilon", type=float, default=DEFAULT_EPSILON)
    parser.add_argument("--output", type=str, default=DEFAULT_OUTPUT)
    parser.add_argument("--small", action="store_true")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()
    if args.small:
        args.M = 10_000
    generate(args.M, args.N, args.K, args.epsilon, args.output, not args.quiet)


if __name__ == "__main__":
    main()
