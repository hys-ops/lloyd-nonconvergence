# A full-plan stopping rule for Sinkhorn

**Result.** For a finite positive Gibbs kernel, an intermediate marginal residual bounds the distance from the **whole** current transport plan to the entropic optimum. The implementation uses the bound to test for an early exit and, on wide problems, can avoid one transpose matrix–vector product on that exit.

$$
\operatorname{TV}(\pi,\pi_*)\le \min\left\{k-1,\frac{1+\exp(\Delta/2)}2\right\}\operatorname{TV}(q,p).
$$

Here the columns of the current plan already match their target, $q,p$ are its current and target row masses, and $\Delta$ is the log cross-ratio diameter of the shared kernel. The one-row case has zero error. [Read the complete proof](Sinkhorn_plan_error_proof.md), including the return path in the implementation.

Here $k$ is the number of rows in the table. The bound assumes a finite positive kernel, positive marginal weights, and the same kernel for both tables in exact real arithmetic. The Lean endpoint `ScalingAudit.certified_exit` certifies the two added early-exit rules, not the stock POT exit or rounding behavior in float64. [The theorem and proof (PDF)](Sinkhorn_plan_error_proof.pdf) · [Written and Lean statement correspondence](Sinkhorn_plan_error_proof.md#written-versions-and-lean-correspondence).

## Residual Sinkhorn 0.3.0 preview

The proposed POT integration speeds up supported classic dense NumPy Sinkhorn calls without requiring new arguments or a tighter accuracy target. Its latest change extends that acceleration to **ordinary warm starts**, including calls that request the scaling log for the next frame. This is a research preview, not a released POT feature. The standalone wheels below are unchanged.

- **Default calls.** The candidate brings the 0.2.0 adapter's marginal-only acceleration and automatic fixed-cost caching to supported POT calls. It does not form a second, row-scaled Gibbs kernel and reuses matrix-vector products. Cache reuse checks the full cost array. A supported unseeded call can return between regular checkpoints using an auxiliary bound and a check of the returned marginals; at regular checkpoints it does not have to meet that auxiliary bound.
- **Warm starts.** In addition to the usual checks at updates 1, 11, 21, and so on, the solver checks the existing marginal tolerance after updates 2, 3 and 4. An early return checks both marginals on the returned matrix. With `log=True`, it includes the terminal error and scaling vectors. This is useful in repeated solves such as point-cloud registration, where a previous solution can be a good initial guess. No full-plan accuracy target is added.
- **Optional whole-plan accuracy.** Callers can separately pass `plan_tol` to request a TV tolerance on the entire transport matrix, measured against the optimum of the same entropically regularized problem. This mode checks both marginal residuals and a float64 TV estimate. It reports failure if it cannot honor an explicit request. The estimate uses bounds proved in exact arithmetic; it is not a floating-point interval certificate. The implementation shares residual work with a capped direct bound, can save a transpose product via a pre-row check on wide inputs, and only runs the directional estimate when residual progress suggests it could help.
- **Scope.** The accelerated route is for supported positive, single-target-histogram dense NumPy float64 problems. Ordinary unsupported requests, other backends, and unseeded calls that ask for logging use the existing solver. The cost-only `sinkhorn2` interface, the standalone `prepare(...)` API, and the grid and compressed-output experiments are outside this integration. Standalone 0.2.1 was a Windows import fix, not a solver change.

### Warm-start registration at the same marginal tolerance

These are the eight registration settings in which 0.2.0 had previously timed slower than stock. All methods used the same starting data and iteration budgets, requested `stopThr=1e-7` and did not request `plan_tol`. Each closed-loop run generated its own subsequent poses and initial guesses. The terminal-window runs instead shared the same inputs and initial guesses. Figures are median elapsed milliseconds over 48 order-balanced rounds on one pinned CPU core and one BLAS thread.

| Setting | Stock POT | Adapter 0.2.0 | Candidate 0.3.0 |
|---|---:|---:|---:|
| Bunny, 192 points, reg 0.08, 56 frames | 33.66 | 34.00 | 22.34 |
| Bunny, 192 points, reg 0.24, 56 frames | 26.17 | 26.36 | 17.13 |
| Bunny, 512 points, reg 0.08, 56 frames | 152.35 | 152.97 | 113.22 |
| Two-lobe cloud, 384 points, reg 0.08, 56 frames | 61.06 | 60.93 | 50.88 |
| Two-lobe cloud, 384 points, reg 0.24, 56 frames | 53.81 | 54.24 | 47.25 |
| Bunny, 192 points, reg 0.08, final 8 frames | 3.02 | 3.03 | 1.86 |
| Bunny, 192 points, reg 0.24, final 8 frames | 1.85 | 1.85 | 1.83 |
| Bunny, 512 points, reg 0.24, final 8 frames | 13.39 | 13.39 | 10.96 |

Seven of eight settings had paired timing intervals favoring the candidate over stock. The five 56-frame runs took **12–35% less time** than stock. For the 192-point terminal window at regularization 0.08, updates fell **58→13**, and elapsed time fell **3.02→1.86 ms**. Changing only the check schedule in the same implementation took **2.33→1.88 ms**. The 192-point terminal window at 0.24 already finished in one update per frame and showed no clear improvement.

Both marginal errors met `1e-7` in all 304 returned candidate plans. Earlier exits can increase full-plan TV error even when they meet the same marginal tolerance: at one frame of the 512-point 0.08 run the observed TV error against each solver's tighter numerical reference was about `3.55e-8` for stock and `1.43e-6` for the candidate. The largest observed change in the final rotation matrix across the five live jobs was `3.46e-7` in Frobenius norm. Those are measured examples, not a guarantee for other inputs.

### Other default-call benchmarks

These 160 settings were remeasured at the same requested marginal accuracy and iteration budgets, again without `plan_tol`. Times are sums of setting-level medians in milliseconds over 12 order-balanced rounds, one pinned CPU core and one BLAS thread. The comparison uses the stock classic POT solver and the original 0.2.0 adapter.

| Workload | Calls | Stock POT | Adapter 0.2.0 | Candidate 0.3.0 |
|---|---:|---:|---:|---:|
| Original 27 dense settings | 27 | 105.06 | 61.52 | 62.32 |
| Eight independent reproduction inputs, cold cache | 8 | 27.51 | 10.92 | 10.65 |
| Same eight inputs, warm cache | 8 | 26.75 | 9.28 | 9.26 |
| Four basic fixtures | 4 | 2.13 | 1.01 | 1.03 |
| 84 planted-plan fixtures | 84 | 67.21 | 29.91 | 29.92 |
| 900 MNIST pairs × three regularizations | 2700 | 1,584.69 | 833.53 | 830.81 |
| 625 MNIST pairs × three regularizations | 1875 | 1,091.99 | 583.87 | 578.82 |
| RGB palette, full dense plans | 64 | 989.55 | 623.15 | 614.51 |
| Fixed cost matrices | 36 | 65.08 | 41.99 | 42.42 |
| Cost reuse, copies and changes | 147 | 273.06 | 186.65 | 188.80 |
| graspologic graph alignment | 400 | 779.07 | 696.03 | 693.28 |
| Bunny 512, final 8 frames, reg 0.08 | 8 | 12.23 | 11.86 | 9.89 |
| Bunny 512, 56 frames, reg 0.24 | 56 | 114.90 | 115.22 | 84.70 |

All 5,417 candidate calls in this additional replay met the requested marginal tolerance. Outside the two registration rows, the 5,353 returned plans matched 0.2.0 byte for byte. Most of the speedup in those rows was already present in 0.2.0. The graph replay preserved all 209 final row-wise matches against stock. Of the 19 settings that initially ran more than 5% slower than 0.2.0, none remained over that threshold after a targeted 30-round retest.

**Where the candidate can be slower.** In a separate synthetic warm-start test, stock already finished in one update at 8×8 and 32×128. The candidate added about 23 microseconds per cold call (29.9→53.1 µs and 46.0→68.9 µs). On those same sizes, when the initial guess was farther away and stock ran 11 updates, the candidate was about 1.7× as fast. A separate unsafe-kernel fixture that immediately returned with a numerical warning took 70.2→88.4 µs with the same result and warning. These tests do not support a universal speedup.

The native Linux suite recorded **1,585 passed, 170 skipped and 4 expected failures**. See [POT issue #934](https://github.com/PythonOT/POT/issues/934) for the original proposal and [@xihaian251's independent reproduction](https://github.com/xihaian251/sinkhorn-reproduction/releases/tag/v1.0.0) for two earlier implementation optimizations under the standard POT stopping rule. The timings above are our measurements of this candidate, not independent timings. Earlier benchmarks below refer to their stated versions and output requirements.

## Why I look inside long proofs

Long AI-generated proofs can contain useful arguments buried in repeated calculations. I look for those steps, pull them out into explicitly stated tools, and see whether the tools shorten a proof or unlock a different problem. A useful result should be short enough for a reader to understand the idea, with the complete argument and verification available to check. Here, a way to track what a partial input can still change eventually helped decide whether an optimal-transport iteration needed to continue.

## From a residual response to a stopping rule

1. **The starting material.** The [Brenier stability manuscript](https://github.com/openai/math/tree/4eaee87548250b2682affda7d05d947c05554bae/preprints/Sharp-One-Third-Stability-of-Brenier-Maps-September-25-2026) uses midpoints of paired transport cells. The [endpoint-moment comparison](https://github.com/hys-ops/lloyd-nonconvergence/blob/main/notes/brenier-endpoint-moment-tool.md) replaced a longer sensitivity argument for cell moments with a direct comparison. Developing this comparison exposed a common residual measure: one piece of displaced mass simultaneously constrains the errors seen in different directions.
2. **The question that transferred.** Can a single residual describe where Sinkhorn's marginal error goes and how different outputs respond? In the two-source case, the same moved mass changes the two conditional means. For many sources, moving mass $m$ from row $i$ to row $\ell$ changes the column distribution by $m(P_\ell-P_i)$, where $P_i$ is that row's conditional destination distribution. This is the bridge used in the finite entropic proof. The earlier Brenier theorem motivated the construction; it is not a premise of the stopping theorem.
3. **From output estimates to the full plan.** Early work bounded barycentric and conditional outputs. The dense-plan result uses paired row responses and cross-ratio bounds to control the first correction; applying the same reasoning to successive row and column corrections gives a convergent geometric sum. A cheaper global coefficient makes the test usable inside the solver.
4. **From theorem to implementation.** The prototype tests the residual after the column update on wide problems or after the row update otherwise; both paths return the row-corrected full plan. It reuses matrix products and can reuse the fixed kernel across calls. The dense prototype neither compresses the returned matrix nor invokes the separate interpolation experiments.

```mermaid
flowchart LR
  S["Brenier stability proof: midpoint cell comparison"] --> T["Extract a common residual measure"]
  T -. "methodological inspiration" .-> R["Transport: a moved mass m changes columns by m(Pℓ−Pᵢ)"]
  R --> C["Cross-ratios bound each correction"]
  C --> F["Sum the remaining corrections to bound the full plan"]
  F --> D["Two optional early exits"]
  D --> B["Matched-budget experiment and NumPy prototype"]
```

## What was measured

| Comparison | Result | Meaning |
|---|---|---|
| 900 MNIST pairs, with [Cuturi 2013, §5](https://papers.neurips.cc/paper_files/paper/2013/file/af21d0c97db2e27e13572cbf59eb343d-Paper.pdf) as application precedent (different test protocol), same separable-grid implementation, TV budget 0.001, no interpolation | $\varepsilon=0.24$: 3,211 → 2,178 total iterations; 73.61 → 66.62 ms including coefficient preparation | Isolates the geometry-aware coefficient against the row-count certificate |
| Same comparison at two other regularizations | 0.12: 4,317 → 3,229; 0.02: 19,762 in either mode | The bound need not help at low regularization |
| 0.1.0 vs POT 0.9.7, 27 CPU cases, one thread, full dense output; 11 alternated timings | median 1.83×; maximum output-to-output TV below $4.63\times10^{-12}$ | Combined implementation; same runtime argument, not the same mathematical certificate |
| 0.1.0, early exits on vs off | median 1.10× in 11 cases where the new rule fired; 0.98× across all 27 | Effect of the early exit in the dense implementation |

The [pinned default-branch comparison](EVIDENCE.md) illustrates a different contract. On a planted 64×128 problem, stock POT met the marginal target in 51 updates at observed plan TV 6.14e-8. Asking also for a plan TV target of 2.5e-8 took 70 updates; observed error was 3.12e-10. On the four tested fixtures this experimental path was slower than stock in median wall time. The run uses default-branch Python sources and 0.9.7 native modules, not a complete build of the development branch.

## When the difference is larger

| Workload | Measured or proved change | Output and comparison |
|---|---|---|
| Two fixed sources, truncated Gaussian example; comparison bound from [Kassraie et al., Proposition 4](https://arxiv.org/abs/2406.05061) | Squared barycentric-error bound 1.2 → 0.000400 → 0.000166; observed error about 0.000083 | Three bounds on the same example, not a runtime ratio. In a separate run, the two-mean test first certified RMS 0.01 at state 16, versus 17 using KL alone. |
| RGB photo to 32 palettes per photo ([sample-image source](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_sample_image.html)) | 0.678 → 0.400 s (1.70×); 0.425 → 0.313 s (1.36×), preparation included | Barycentric colors and costs vs the fastest previous tested approach; enabling the joint RGB information alone reduced time 19% and 18% against the same new code without it, and reduced computation sites 33% and 43%. The maximum observed full-plan TV in a separate original-data check was 0.000111 against a tolerance of 0.001. |
| 524,288 irregular targets, 32 repeated queries | 2.770 → 0.746 s (3.7×), preparation included | Barycenters and costs vs the fastest tested baseline. In separate output-matched timings on the same moving-source workload, returning the implicit plan as scaling factors took 2.211 → 0.563 s (3.93×); returning every coupling entry took 2.211 → 2.249 s. |
| Dense adapter, all 900 MNIST pairs | 2.15×, 1.55× and 1.99× against POT 0.9.7 at 0.02, 0.12 and 0.24; 1.51 → 0.70 s at 0.02 | Full dense plans, consumed to compute costs; this is not the same-solver stopping-rule comparison. |
| [graspologic SeedlessProcrustes](https://graspologic-org.github.io/graspologic/latest/reference/reference/align.html) on [Eichler et al.'s data](https://www.nature.com/articles/nature23455) | 1.103 → 0.994 s over five paired timings; each of 209 row-wise best matches agrees with the baseline | Complete local alignment using our embeddings of the bundled data and [Agterberg et al.’s method, Algorithm 1](https://arxiv.org/abs/2012.09828), not a reproduction of the biological study or evidence of upstream adoption. |
| Fixed 640×768 cost matrix, 12 solves | 98.1 ms without cross-call reuse → 90.1 ms automatic → 79.5 ms explicit preparation | Separate 0.2.0 cache experiment. In the downstream graph workload kernel builds went 400 → 140, but the six timing pairs were split 3–3. |
| Synthetic 16,384-source grid, 128 solves | 228.9 → 106.1 ms including prep vs ordinary grid Sinkhorn; single call 1.94 → 55.3 ms | Separate interpolation path; new stopping only without interpolation took 153.3 ms for 128. |
| One correspondence step on the [Stanford Bunny](https://graphics.stanford.edu/data/3Dscanrep/) ([Turk and Levoy, 1994](https://doi.org/10.1145/192161.192241)), 3,485 points on each side | 151 → 132 ms changing only the stopping rule; updates 5 → 3 at 0.24 | An experiment on this public mesh, not reproduction of the scan acquisition paper or a timing of complete registration. |

The earlier general-purpose RGB prototype was slower than its strongest baseline (0.651 → 3.059 s for the observable workload). The later RGB-specific joint summary is the version behind the two-photo gains above. The RGB and irregular-target experiments use a separate reusable target-summary implementation. They are not timing claims for the dense POT proposal.

## Experiment provenance

- **MNIST:** [Cuturi 2013, §5](https://papers.neurips.cc/paper_files/paper/2013/file/af21d0c97db2e27e13572cbf59eb343d-Paper.pdf) used grayscale ink as mass for handwritten-digit classification on a 20×20 support; our measurements use 28×28 images, half squared Euclidean cost, and the same 30×30 pairs in two different timing protocols. The separable-grid baseline is related to [Solomon et al., Algorithm 1](https://doi.org/10.1145/2766963). The source subset and timing files are documented in the archives.
- **Two sources:** Our own truncated Gaussian fixture supplies the numbers; [Kassraie et al., §3.2, Proposition 4](https://arxiv.org/abs/2406.05061) supplies the comparison bound, not a reused experiment. The related $2/\kappa$ coefficient in [Kolesnikov, §4, Eq. (16)](https://arxiv.org/abs/1007.1103) concerns unregularized maps. No large wall-clock speedup was measured for the two-source fixture.
- **POT development snapshot:** We reused two exact upstream benchmark fixtures (`setup(50)`, `setup(500)`); the two planted 64×128 examples were designed here. See [the pinned benchmark code](https://github.com/PythonOT/POT/blob/367355d757223e39989e384b7a93d0537b1547ea/benchmarks/sinkhorn_knopp.py) and [our result CSV](head-run/summary.csv).
- **Other measurements:** On the released dense adapter, the four RGB settings had median speedup 1.536× and the three Bunny settings 1.374× against stock POT 0.9.7, a separate comparison from the RGB summary and the one-step Bunny results. The early interpolation prototype was slower for complete Bunny registration (0.892 → 5.199 s). In the 64-row pair example with the same residual TV 0.001, global vs pair-aware bounds were 0.01188 vs 0.001295, with observed plan TV 0.001009; the extra benefit vanished for a move between opposite endpoints. See the archived `release1_times.csv` and `many_rows/results/paired.csv`.

## Read and reproduce

### Residual Sinkhorn 0.2.1 (Windows import fix)

[Download the 0.2.1 wheel](downloads/residual_sinkhorn-0.2.1-py3-none-any.whl). If the `ctypes` lookup raises `TypeError` at import, the adapter now uses the existing NumPy comparison. The solver and stopping rules are unchanged. Focused import and cache tests passed on Windows (Python 3.12) and Linux with NumPy; they did not exercise delegation to POT. The full comparison on Windows with Python 3.13 and a native macOS run have not been independently repeated.

```sh
python -m pip install ./residual_sinkhorn-0.2.1-py3-none-any.whl
```

The import and requirements are unchanged (see below). SHA-256: `2dd71e8c65e771e7b0414110b40b6713b893b07d9168d02e7105ad3d175c05a1`

### Original 0.2.0 wheel for reproduction

The original 0.2.0 wheel and its checksum below are unchanged. Version 0.2.1 is not a new benchmark; benchmark versions remain as recorded in [the evidence notes](EVIDENCE.md).

[Download the original Residual Sinkhorn 0.2.0 wheel](downloads/residual_sinkhorn-0.2.0-py3-none-any.whl). Requires Python 3.10+, NumPy 1.24+, and POT 0.9.7 or 0.9.7.post1. This is a separate adapter; it does not modify POT.

```sh
python -m pip install ./residual_sinkhorn-0.2.0-py3-none-any.whl
```

```python
from residual_sinkhorn import sinkhorn

plan = sinkhorn(a, b, M, reg)
```

SHA-256: `d7099ea4dbad90242bf7318e2235c18cad579e43d3312faa8bfc76e78c854759`

- [Measured comparisons and scripts](EVIDENCE.md).
- [Benchmark measurements, sources, and reproduction scope](EVIDENCE.md). No third-party datasets are redistributed here.

- [Complete written proof](Sinkhorn_plan_error_proof.md). Consult the Lean table there for exactly what was checked.
- The ManyRows benchmark is shipped separately from the dense NumPy prototype. Its archived `many_rows/results/digits.csv` and `many_rows/results/grid_time.csv` are the matched grid evidence; `many_rows/reproduce.sh` rebuilds the experiments from the archived inputs.
- The dense comparison is archived separately in the 0.1.0 source bundle. Its `evaluation/reproduce.sh` sets thread counts and reruns the POT comparison; `evaluation/release1_times.csv` and `evaluation/release1_accuracy.csv` contain the one-thread results.
- In the [Lean source directory](lean), run `lake exe cache get` and `bash verify.sh` after installing Lean 4.34.1. Start with `CertifiedExit.lean`, `Audit.lean` and the audit README. The proof concerns exact arithmetic, not NumPy rounding or the default POT exit. The public replay below covers the synthetic example, the pinned POT comparison and the formal proof; historical CSVs are supplied as recorded measurements.

The contraction ingredients connect to standard work on the Hilbert metric and Sinkhorn. No historical priority claim is made. The proof and benchmarks describe a research prototype, not a feature already shipped by POT.
