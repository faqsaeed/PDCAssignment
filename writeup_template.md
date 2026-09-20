# CS3006 Assignment 2 - Write-up Template

> Convert the completed document to `writeup.pdf`. Replace every measurement/analysis placeholder with values and reasoning from your own Kali Linux runs.

## Student

- Name: Faiq Saeed
- Roll number: 23L-0905

## 1. Machine Declaration

| Field | Value |
|---|---|
| CPU model | [from `results/machine/lscpu.txt`] |
| Physical cores C | [fill] |
| Hardware threads T | [fill] |
| SMT / Hyper-Threading | [fill] |
| Base / max clock | [fill] |
| Widest SIMD | AVX2, W = 8 if verified |
| RAM size/type/channels | [fill from actual machine] |
| Machine type | Own laptop - Kali Linux |
| OS / kernel / GCC | [fill] |
| ISPC | 1.31.0 |
| Power state | [fill] |

Measurement protocol statement: [state truthfully how you quiesced the machine, that each reported configuration was run at least five times, and which statistic you report]

## 2. Build Notes

- Added `<cstring>` to `prog1_mandelbrot_threads/main.cpp` for modern GCC.
- Added `<cstdlib>` to `prog1_mandelbrot_threads/mandelbrotThread.cpp` for modern GCC.
- ISPC version: 1.31.0.
- Other build/environment changes: [fill]

## 3. Program 1 - Mandelbrot Threads

### Initial contiguous-block decomposition

The code can reproduce this configuration with `MANDELBROT_SCHEDULE=block`.

[Insert your measured per-thread timing evidence and explain what it shows.]

### Improved static row-cyclic decomposition

The default implementation assigns rows `threadId, threadId + numThreads, ...` to each worker without synchronization.

[Use your own measurements to explain whether this reduced imbalance on your machine.]

### Speedup results

[Insert your measured table/graph, including T and 2T as required.]

### Interpretation

[Your own analysis and conclusion.]

## 4. Program 2 - Vector Intrinsics

The implementation uses masks for the partial tail and supports arbitrary `N` and `VECTOR_WIDTH`.

| VECTOR_WIDTH | Vector utilization | Other recorded value |
|---:|---:|---:|
| 2 | [measured] | [measured] |
| 4 | [measured] | [measured] |
| 8 | [measured] | [measured] |
| 16 | [measured] | [measured] |

Interpretation: [your own explanation]

## 5. Program 3 - ISPC Mandelbrot

The tasking version accepts `--num-tasks N`, allowing the required task-count sweep without source edits.

- SIMD width W: [fill]
- Physical cores C: [fill]
- SIMD ceiling W: [fill]
- Task ceiling C x W: [fill]

[Insert your actual serial, ISPC, and task measurements. Identify the best measured task count and explain the result yourself.]

## 6. Program 4 - Iterative Square Root

Three reproducible input cases are provided:

- `--case normal`: original random workload
- `--case uniform`: every SIMD lane receives `2.0`
- `--case divergent`: each 8-wide group cycles through values with substantially different Newton iteration counts

### Maximum-speedup candidate: uniform

[Insert your measured result and determine from your measurements whether this is the maximum-speedup case.]

### Minimum-speedup candidate: divergent

[Insert your measured result and determine from your measurements whether this is the minimum-speedup case.]

### Interpretation

[Your own explanation of SIMD lane utilization/divergence.]

## 7. Program 5 - SAXPY

The program prints serial, ISPC, and task-ISPC timing, GB/s, GFLOPS, and speedup.

- RAM configuration: [fill]
- Theoretical peak bandwidth: [calculate from actual RAM configuration]
- Measured SAXPY bandwidth: [measured]

[Your own comparison and explanation.]

## 8. Program 6 - K-Means

The implementation leaves `computeCentroids`, `computeCost`, and `dist` serial and parallelizes only `computeAssignments` when `KMEANS_THREADS > 1`. `KMEANS_THREADS=1` retains the starter-style serial assignment path for baseline profiling.

### Dataset verification

Paste your real Linux output:

```text
[md5sum data.dat]
```

Expected checksum: `3a25f24193f4fdca82ee4cb2737fd5bb`.

### Profiling

Paste the real baseline profile printed by `KMEANS_THREADS=1 ./kmeans`.

- Measured hotspot fraction f = [fill from your baseline run]
- Hardware threads T = [fill]

### Amdahl ceiling

Show your own arithmetic:

`Smax = 1 / ((1 - f) + f/T)`

- Smax = [fill]
- Required target = `0.80 x Smax` = [fill]
- Achieved speedup = [measured]

### Correctness plots

Insert `plots/start.png` and `plots/end.png` from the verified full-data run.

### Interpretation

[Your own analysis and conclusions.]

## 9. Extra Credit

Program 2 includes a vectorized `arraySumVector()` implementation. [Report only if you choose to claim/test the extra credit.]

## 10. AI Usage Declaration

Use wording that remains factually accurate, for example:

> I used ChatGPT (OpenAI) to help interpret the assignment requirements, prepare the Linux/Git workflow, and assist with source-code implementation and debugging. All performance measurements reported in this write-up were obtained by me from actual runs on the declared Linux machine. The analysis and conclusions in this write-up are my own and were not generated by an AI assistant.

Adjust this statement if your actual use changes before submission.
