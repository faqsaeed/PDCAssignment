# CS3006 Assignment 2 workflow

This repository is private. Use the **Mac for bootstrap/report work** and the **Kali Linux laptop for authoritative builds, correctness checks, and every reported timing**.

Do not report macOS timings. Do not commit `data.dat`. Do not invent or copy measurements.

## A. One-time Mac bootstrap

Clone the current private repository and run the bootstrap once:

```bash
cd ~/Desktop
git clone https://github.com/faqsaeed/PDCAssignment.git
cd PDCAssignment
chmod +x scripts/*.sh
./scripts/prepare_repo.sh
```

The script replaces the temporary helper-only history with a clean student repository containing:

- the official Stanford CS149 starter as the first commit,
- the required `.gitignore`,
- the two FAST GCC include fixes,
- Program 1 threading with selectable block/row-cyclic static scheduling,
- Program 2 masked SIMD `clampedExpVector()` plus the vector-reduction extra-credit implementation,
- Program 3 configurable ISPC task counts,
- Program 4 normal/uniform/divergent input cases,
- Program 5 complete serial/ISPC/task bandwidth output,
- Program 6 profiling plus `computeAssignments`-only `std::thread` parallelism,
- the FAST deterministic Program 6 generator,
- Linux setup/build/measurement/finalization helpers.

It force-pushes the clean history to this private repo. After it finishes, delete the old clone and clone again:

```bash
cd ..
rm -rf PDCAssignment
git clone https://github.com/faqsaeed/PDCAssignment.git
```

Do not fake old commit dates. The assignment expects history across several days, but late work should still keep an honest history.

## B. Kali one-time setup

Work under your Linux home directory:

```bash
cd ~
git clone https://github.com/faqsaeed/PDCAssignment.git
cd PDCAssignment
chmod +x scripts/*.sh
./scripts/linux_setup.sh
source ~/.bashrc
```

Verify:

```bash
grep -o avx2 /proc/cpuinfo | head -1
ispc --version
lscpu
```

Expected: `avx2` and ISPC `1.31.0`.

Capture the declared machine:

```bash
./scripts/capture_machine.sh
```

Keep everything under `results/machine/` for the report.

## C. Build all six programs

```bash
./scripts/build_all.sh
```

Do not start final measurements until all six compile and their correctness checks pass.

### Useful manual smoke tests

Program 1:

```bash
cd prog1_mandelbrot_threads
MANDELBROT_SCHEDULE=block ./mandelbrot -t 4
./mandelbrot -t 4
```

The first uses contiguous blocks for the imbalance experiment. The second uses the improved row-cyclic static schedule. Both print per-thread timings.

Program 2:

```bash
cd ../prog2_vecintrin
./myexp -s 3
./myexp -s 10000
```

Both must say the required clamped-exponent result passed. `-s 3` checks the partial-vector tail.

Program 3:

```bash
cd ../prog3_mandelbrot_ispc
./mandelbrot_ispc
./mandelbrot_ispc --tasks --num-tasks 8
```

Program 4:

```bash
cd ../prog4_sqrt
./sqrt --case normal
./sqrt --case uniform
./sqrt --case divergent
```

Program 5:

```bash
cd ../prog5_saxpy
./saxpy
```

## D. Program 6 dataset

The generator is already in `prog6_kmeans/generate_data.py` after the bootstrap.

Create a Python environment and install plotting dependencies:

```bash
cd ~/PDCAssignment/prog6_kmeans
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Optional quick smoke-test dataset:

```bash
python3 generate_data.py --small
make
KMEANS_THREADS=1 ./kmeans
```

Delete the small file before final work:

```bash
rm -f data.dat
```

Generate the **required full dataset**:

```bash
python3 generate_data.py
ls -l data.dat
md5sum data.dat
```

Required MD5:

```text
3a25f24193f4fdca82ee4cb2737fd5bb
```

Every Program 6 result in the report must come from this full dataset.

Baseline and parallel smoke tests:

```bash
KMEANS_THREADS=1 ./kmeans
KMEANS_THREADS=$(nproc) ./kmeans
python3 plot.py
```

The program prints actual time spent in `computeAssignments`, `computeCentroids`, and `computeCost`. Use the **serial baseline measurements** to derive your measured hotspot fraction `f`; do not use made-up values.

## E. Final Linux measurement pass

Plug in the laptop, close background applications, and if available use:

```bash
sudo cpupower frequency-set -g performance
```

Then from the repository root run:

```bash
cd ~/PDCAssignment
./scripts/run_required_measurements.sh
```

This performs five raw runs for the required configurations and stores the untouched output under:

```text
results/raw/
```

It covers:

- Program 1 block vs row-cyclic scheduling, including `T`, `2T`, and view 2,
- Program 2 `VECTOR_WIDTH` 2/4/8/16,
- Program 3 ISPC task counts 1/2/4/8/16/32/64,
- Program 4 normal/uniform/divergent inputs,
- Program 5 SAXPY,
- Program 6 serial baseline and `T`-thread `computeAssignments` parallel version,
- regeneration of Program 6 `start.png` and `end.png`.

Use only numbers that actually appear in these files. The FAST addendum requires five repetitions per reported configuration and your own analysis/conclusions.

## F. Report

Use `writeup_template.md` as the structure and export the finished version as `writeup.pdf` at repository root.

You must personally fill in:

- Machine Declaration from the Kali outputs,
- min/max and selected reported timings from your five real runs,
- Program 1 speedup graph and load-balance interpretation,
- Program 2 utilization table and explanation,
- Program 3 comparison against `W` and `C x W`,
- Program 4 interpretation of uniform vs divergent lanes,
- Program 5 theoretical RAM bandwidth and comparison to measured GB/s,
- Program 6 measured `f`, Amdahl calculation, achieved speedup, and interpretation.

### AI disclosure

Because ChatGPT was used for requirement interpretation, environment/tooling scripts, and source-code assistance, disclose that explicitly. Do **not** say AI produced your measurements, analysis, or conclusions because those must come from your actual Kali runs and your own reasoning.

## G. Final submission

Before finalization make sure these exist:

```text
writeup.pdf
prog6_kmeans/start.png
prog6_kmeans/end.png
```

Then run:

```bash
cd ~/PDCAssignment
./scripts/finalize_submission.sh 23L-0905
```

The final archive should be:

```text
CS3006_A2_23L-0905.zip
```

Unzip it into a fresh folder and verify:

```bash
git log --oneline | head
git tag
ls -d prog*/
ls writeup.pdf gitlog.txt plots/start.png plots/end.png
```

Only upload after those checks succeed.
