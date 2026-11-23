# Measurements and reproduction

## Pinned upstream comparison

The checkout was POT's default branch `master` at `367355d757223e39989e384b7a93d0537b1547ea`, reporting `ot.__version__ == "0.9.8.dev"`. The NumPy branch in `sinkhorn_knopp` computes the Gibbs kernel and a row-preconditioned kernel, alternates the two scale updates, checks numerical safety, and tests the column marginal L2 residual at zero-based iterations 0, 10, 20, … . The numerical rollback, budget exhaustion, warm starts, multi-target branch and logging semantics all matter for an upstream design. [Pinned solver and return statements](https://github.com/PythonOT/POT/blob/367355d757223e39989e384b7a93d0537b1547ea/ot/bregman/_sinkhorn.py#L608-L687) · [Benchmark fixtures](https://github.com/PythonOT/POT/blob/367355d757223e39989e384b7a93d0537b1547ea/benchmarks/sinkhorn_knopp.py)

This experiment compares the unmodified Python function at that revision with a temporary copy of its source patched only for an opt-in post-row test. It retains the original kernel, row/column update order, backend operations and numerical safety checks. The extra test computes the L1 column residual after the row update; it checks the materialized output before returning. The sampler runs 31 shuffled repetitions for each method on one BLAS thread. Input generation, imports, warmups, reference solves and accuracy checks are outside timing. Kernel construction, any range scan, probes and the full returned dense array are inside. Each row's times are medians; per-run samples and interquartile ranges are provided. No library-wide throughput figure follows from four small-to-medium fixtures.

| Mode | When it probes (zero-based iteration modulo 10) | Success criterion |
|---|---|---|
| stock | 0 | POT's default marginal L2 criterion, `stopThr=1e-7` |
| count-extra | 0, 4, 7, 9 | Same marginal target and plan target `2.5e-8`, using multiplier $S-1$ |
| geometry-cadence10 | 0 | Both targets using $C_S=\min\{S-1,(1+h/l)/2\}$ |
| geometry-extra | 0, 4, 7, 9 | Both targets using $C_S$ |

The two modes labelled `-extra` have identical schedules, checks, kernel scanning and output formation. Their only change is the multiplier. The two *geometry* modes isolate the sampling schedule. Against stock, both the stopping contract and the implementation change. The private benchmark switches in the patch are included to make these comparisons reproducible. The full estimator can be unhelpful for a broad range of kernel entries, since then $C_S=S-1$. Extra checks cost reductions. A local speedup depends on saved matrix-vector multiplications outweighing those reductions.

The two upstream fixtures use the original `setup(50)` and `setup(500)`, with shapes 12×50 and 125×500, regularization 1 and uniform marginals. Their empirical reference is stock POT run to a tighter marginal tolerance of `1e-14`. Two 64×128 fixtures use the same one-dimensional sites and a planted optimal scaling at regularization 0.25 and 0.02. On those problems both requested marginals come from the planted table. The reference is constructed independently of iteration. All these computations use float64. The check against the numerical reference allows $2\times10^{-12}$ for the comparison and does not supply an interval certificate.

Each entry is **updates / median ms**. All four stock-versus-opt-in comparisons in this run took longer with the added accuracy target. At the same two tolerances, the warm planted example isolates the tighter factor (10 to 8 updates) and the more frequent probes (11 to 8).

| Fixture | Stock | Count + extra | Geometry every 10 | Geometry + extra |
|---|---:|---:|---:|---:|
| upstream-50 | 21 / 0.581 | 20 / 0.697 | 21 / 0.590 | 20 / 0.638 |
| upstream-500 | 11 / 1.284 | 15 / 1.900 | 21 / 2.033 | 15 / 1.995 |
| planted-0.25 | 11 / 0.460 | 10 / 0.562 | 11 / 0.591 | 8 / 0.511 |
| planted-0.02 | 51 / 2.032 | 70 / 3.160 | 71 / 2.759 | 70 / 3.083 |

The cold planted example gives a reason for a separate tolerance. Stock's measured row and column L2 errors were $1.77\times10^{-17}$ and $6.47\times10^{-9}$ at its 51st update, while the observed plan TV was $6.14\times10^{-8}$. The opt-in run reached the plan target $2.5\times10^{-8}$ after 70 updates, with estimate $2.20\times10^{-8}$ and observed TV $3.12\times10^{-10}$. This contrasts two acceptance criteria; stock satisfied its own requested contract.

[Complete results](head-run/summary.csv) · [All timing samples](head-run/trials.csv) · [Runtime and BLAS details](head-run/environment.json) · [Local diff](postrow-review.patch) · [Comparison script](reproduce.py)

### Run the small checks

For the shortest independent illustration, run `python minimal_example.py` with NumPy installed. It checks the pre- and post-update formulas against a planted scaling at the same iterate. On our run the seventh update had post-row estimate $1.5149137\times10^{-8}$, pre-row estimate $4.4905567\times10^{-8}$ and observed plan TV $3.705024\times10^{-9}$.

To reproduce the pinned upstream comparison, use Python 3.12, Git, a C++ compiler with OpenMP, and a fresh virtual environment. Commands below start in this directory. The dependency checkout includes the Eigen submodule required by POT. The script verifies the commit and solver blob, checks its installed source against the checkout, and applies the diff only in a temporary directory.

~~~sh
git clone https://github.com/PythonOT/POT.git POT
git -C POT checkout --detach 367355d757223e39989e384b7a93d0537b1547ea
git -C POT submodule update --init --recursive
python -m venv .venv
. .venv/bin/activate
python -m pip install numpy==2.3.5 scipy==1.17.0 threadpoolctl
CC=gcc CXX=g++ python -m pip install ./POT
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
    python reproduce.py POT fresh-results --repeats 31
~~~

**Recorded run and low-memory reproduction.** The compiler was killed while building the separate BSP C++ solver in this environment. The recorded run used all tracked Python modules from the pinned POT revision with the Linux POT 0.9.7 wheel supplying native modules for package import. The measured dense Sinkhorn iterations and their benchmark setup are the pinned Python/NumPy path. No BSP routine participates. This is a default-branch source comparison, not a successful clean wheel build of all of upstream POT. The pinned source and benchmark file were cross-checked. To use the recorded route on Linux x86_64, execute the following instead of building the native extensions, in the environment with the numeric dependencies above. [Loader](run_source_snapshot.py) · [Native-module provenance](head-run/source-mode.json)
    
~~~sh
python -m pip install --only-binary=:all: "POT==0.9.7"
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
    python run_source_snapshot.py POT source-results --repeats 31
~~~

## Previously measured release and grid results

These numbers come from earlier experiments. We recomputed their summaries from the archived CSVs. The relevant historical result tables are included below alongside the synthetic and pinned upstream replay instructions. [Recomputed output](evidence/archive-summary.txt)

| Question | Matched data and result |
|---|---|
| What did replacing the entire dense CPU implementation buy on POT 0.9.7? | Adapter 0.1.0, one BLAS thread, `stopThr=1e-9`, input cost ready, full plan returned. 27 settings, each method run 11 times with shuffled order. Median of the 27 ratios of per-case medians, stock time/adapter time, **1.826896×**. All 27 ratios exceeded one on that run. Maximum TV difference to the stock output was $4.623\times10^{-12}$ or less. |
| What did the additional exit alone buy in that adapter? | Same float64 implementation with that exit disabled versus enabled. Median ratio disabled/enabled **1.0988359×** on the 11 settings where it triggered and **0.9784931×** over all 27. A ratio below one means enabling the extra probes was slower at the median. Computation reuse and memory operations contribute to the full-replacement result. |
| What did tightening the multiplier alone do to a different, uncompressed solver? | 30×30 MNIST pairs, identical separable grid kernel, initialization and accuracy budget on each pair. Threshold at most plan TV 0.001 with the same per-pair tightening for the cost observable. 7 repeats per rule and temperature; each loop returns the transport cost. At 0.24, 3,211 → 2,178 total updates and **73.60737 → 66.62483 ms**. Both figures use `many_rows/results/grid_time.csv`. At 0.12, 4,317 → 3,229 updates and **102.57400 → 104.23943 ms**. At 0.02, 19,762 → 19,762 and **407.29369 → 441.46322 ms**. Geometry preparation is in the time measured by this loop. |

The release settings cover MNIST, RGB, bunny scans, random clouds and general cost matrices, with several temperatures or inputs per family. They are 27 configurations of five families. A tighter numerical reference could differ from a stock-checkpoint return by about $2.05\times10^{-8}$ in plan TV, even when stock and the adapter agreed closely with each other. The separable grid study compares two plan-error multipliers in another solver. Neither historical comparison estimates the gain of applying our proposed patch to all of current POT.

The adapter's next version, 0.2.0, added cross-call kernel reuse. With a fixed 640×768 cost and 12 different marginal pairs, prior one-thread, nine-repeat medians were 98.098 ms for 0.1.0, 90.087 ms for automatic reuse and 79.529 ms for explicit preparation including setup. On a fruit-fly alignment, 400 → 140 kernel builds gave identical returned final plans; six paired end-to-end runs split three wins apiece. Medians were 1.021 and 1.000 s. This is a separate comparison and cache behavior is outside the proposed initial feature. [Cache timing CSV](evidence/cache-timing.csv)

### Historical measurements and data provenance

- [Dense timings](evidence/release1_times.csv), [accuracy checks](evidence/release1_accuracy.csv), and [900-pair dense timings](evidence/mnist_batch.csv) are the recorded release measurements.
- [MNIST grid timing](evidence/mnist-grid-time.csv) and [row-pair comparison](evidence/paired.csv) are the recorded geometry and residual-position tests. The digit problem follows the application in [Cuturi 2013, §5](https://papers.neurips.cc/paper_files/paper/2013/file/af21d0c97db2e27e13572cbf59eb343d-Paper.pdf), not its SVM protocol. The grid solver uses separable kernel evaluation in the spirit of [Solomon et al., Algorithm 1](https://doi.org/10.1145/2766963).
- [RGB timings](evidence/rgb-timing.csv) and [reference checks](evidence/rgb-reference.csv) use [scikit-learn's sample photographs](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_sample_image.html). [Graspologic timings](evidence/graspologic-results.csv) used its published SeedlessProcrustes implementation (see [Agterberg et al., Algorithm 1](https://arxiv.org/abs/2012.09828)) with the [Eichler et al. dataset](https://www.nature.com/articles/nature23455). The neural matching statistic compares the two solvers, not biological ground truth.
- Bunny measurements refer to the [Stanford Bunny mesh](https://graphics.stanford.edu/data/3Dscanrep/) from [Turk and Levoy](https://doi.org/10.1145/192161.192241), not the original reconstruction protocol.
- These result files do not contain third-party input datasets. The public runnable replay covers the synthetic example and pinned POT cases; the historical application figures are supplied as measured evidence.
- The [POT license](evidence/POT-LICENSE.txt) accompanies the experimental patch. The patch is a reproduction artifact, not an upstream PR.

### Formal verification

In the [Lean source directory](lean), use the pinned toolchain and run `lake exe cache get` then `bash verify.sh`. The archived clean-build and axiom logs cover 40 declarations; the mathematical result models exact real arithmetic, not float64.
