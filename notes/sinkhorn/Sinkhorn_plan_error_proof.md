# How much can a Sinkhorn marginal error move the whole transport plan?

[Complete written proof (PDF)](Sinkhorn_plan_error_proof.pdf)

A Sinkhorn half-step exactly matches one margin in real arithmetic. The other margin is cheap to inspect. How far can the entire current table still be from the entropic optimum? This note answers that question for a finite positive kernel. It gives two stopping tests for the same returned table, including a test that can be performed before its last scaling. Every quantity in a stopping test is available without computing the optimum.

## Where the question came from

Our working practice is to read a long AI-assisted proof for an intermediate argument that can stand on its own, verify or shorten that argument, and try it on a different problem. Here the starting point was a comparison of first moments of transport cells in section 4 of a Brenier stability proof. A midpoint measure accounts for part of the source distribution. Bounding the complement immediately by its total mass gives a scalar estimate. Keeping the complementary measure makes the same residual pay for all the directional errors together. For example, in the cell-moment problem a single submeasure of mass half the triangular discrimination dominates a matrix of affine-observable errors. [Original cell argument](https://github.com/openai/math/blob/4eaee87548250b2682affda7d05d947c05554bae/preprints/Sharp-One-Third-Stability-of-Brenier-Maps-September-25-2026/build/source/sections/moments.tex#L8-L32) · [Open research notes on the cell-moment approach](https://github.com/hys-ops/lloyd-nonconvergence#where-the-proof-came-from)

We first asked what marginal error could certify about a Sinkhorn transport **map**. One result used input KL divergence and a strongly log-concave target to control rowwise squared transport error, hence also error of conditional means. Binary Gaussian examples identified how much a scalar KL budget alone could certify. A separate implementation summarized a fixed target for queries with changing source weights or positions. In RGB, the three channels of a particular color jointly determine interpolation error. The revised summary used their joint offsets and the source palette's pairwise geometry. Both summary solvers were built and measured.

The obstruction at many source sites was a factor proportional to their count. Looking at **where** the residual mass moves led to the finite-plan estimate below. Nearby rows can induce very similar conditional destination laws. Correcting mass between them creates only the difference of those laws in the opposite margin. We used the resulting bound both to permit coarser summaries and to stop ordinary uncompressed Sinkhorn. The 0.1.0 dense adapter combines the second use with fewer repeated dense operations. The 0.2.0 adapter adds cross-call reuse. It returns dense plans and uses a precomputed global coefficient. The RGB interpolation engine and the optional row-pair refinement are separate experimental paths.

These are historical connections. The proof below starts with a positive finite matrix. Its hypotheses do not require Euclidean sites, log-concavity, a Gaussian limit, a transport-cell comparison or interpolation. Matrix scaling, cross-ratio geometry, total-variation contraction of a stochastic kernel and the entropy minimization identity have established histories. We give the details to identify which comparisons apply to the actual iterate and which quantities a solver can use. [Sinkhorn and Knopp](https://doi.org/10.2140/pjm.1967.21.343) · [Cohen and Fausti on Hilbert distance and total variation](https://arxiv.org/abs/2309.02413)

For historical sources, see the [Brenier tool page](../brenier-endpoint-moment-tool.md) and [experiment notes](EVIDENCE.md).

## Finite-plan theorem and stopping rules

Let $I,J$ be nonempty finite sets of sizes $R,S$. Let $p_i,w_j>0$ sum to one on each side. Let $K_{ij}>0$ and let a *scaling* mean $P_{ij}=a_iK_{ij}b_j$ with strictly positive factors. For a matrix or vector, write $\|D\|_{\rm TV}=\frac12\sum|D|$ and $\operatorname{TV}(P,Q)=\|P-Q\|_{\rm TV}$. Write $r(P),c(P)$ for its row and column sums. Suppose $t\ge1$ bounds the kernel cross ratios by
$$
K_{ij}K_{\ell m}\ \le\ t^2K_{im}K_{\ell j}\quad(i,\ell\in I,\ j,m\in J).
$$
Set $\rho=(t-1)/(t+1)$, $G=1/(1-\rho)=(1+t)/2$, and $C_k=\min\{k-1,G\}$. One inexpensive choice is $t=h/l$ for any $0<l\le K_{ij}\le h$. The smallest permissible $t$ is the square root of the maximum cross ratio.

**Theorem.** There is a unique scaling $Q$ with margins $p,w$. For $K_{ij}=\exp(-M_{ij}/\varepsilon)$ with finite real costs and $\varepsilon>0$, this is the unique minimizer of the entropically regularized cost over all nonnegative tables with these margins. For any scaling $P$ with $c(P)=w$,
$$
\operatorname{TV}(P,Q)\le C_R\|r(P)-p\|_{\rm TV}. \tag{1}
$$
Transposing gives the column-residual estimate $C_S\|c(F)-w\|_{\rm TV}$ for a row-exact scaling $F$. With one row the exact column margin determines the whole table. The symmetric observation handles one column.

**The table actually returned.** Given a positive row factor $u$, set
$$
v=w/(K^\top u),\qquad P_{ij}=u_iK_{ij}v_j,\qquad
a=p/(Kv),\qquad F_{ij}=a_iK_{ij}v_j.
$$
All divisions and $\odot$ below are componentwise. Define
$$
e_0=\tfrac12\|u\odot(Kv)-p\|_1,\qquad
e_1=\tfrac12\|v\odot(K^\top a)-w\|_1,\qquad
d=\min\{1+C_R,C_S\rho\}.
$$
The assumption that both tables scale the same kernel matters. Two arbitrary tables can have identical margins and different entries. The same returned $F$ satisfies both bounds
$$
\operatorname{TV}(F,Q)\le d\,e_0,\qquad
\operatorname{TV}(F,Q)\le C_S e_1. \tag{2}
$$
The first uses the residual **before** changing $u$ to $a$. In the second, the residual belongs to the row-exact table **after** the change. For any positive target $\delta$, strict inequality in either test implies plan TV strictly below $\delta$.

## Proof

### 1. Cross ratios control a pair of conditional rows

Multiplying by positive row and column factors cancels in every cross ratio. The same property holds for transposes and for the conditional rows obtained by normalizing each row. Let $A,B$ be any two such probability rows. For an event $H\subseteq J$ put $x=A(H)$ and $y=B(H)$. Summing $A_jB_m\le t^2 B_j A_m$ over $j\in H,m\notin H$ gives $x(1-y)\le t^2y(1-x)$. The denominator $1+(t^2-1)y$ is positive, so
$$
x-y\le \frac{(t^2-1)y(1-y)}{1+(t^2-1)y}\le\frac{t-1}{t+1}.
$$
For the second inequality, multiplying by $(t+1)(1+(t^2-1)y)$ leaves the nonnegative difference $(t-1)((t+1)y-1)^2$. Taking $H=\{j:A_j>B_j\}$ proves $\|A-B\|_{\rm TV}\le\rho$, since the positive and negative parts of $A-B$ have equal mass. For the range-based choice $t=h/l$, the numerator of a cross ratio is at most $h^2$ and its denominator at least $l^2$. The maximum is at least one because a repeated row produces cross ratio one.

### 2. One half-step propagates a signed residual

Let $P$ have columns $w$, row sums $q$, and conditional rows $A_{ij}=P_{ij}/q_i$. Set $s_i=p_i-q_i$ and $e=\|s\|_{\rm TV}$. Replacing row $i$ by $p_iA_{ij}$ gives $F$. Entrywise $F-P=s_iA_{ij}$, so $\|F-P\|_{\rm TV}=e$. Its new column error is $c(F)-w=\sum_i s_i A_i$.

The positive and negative parts of $s$ both have mass $e$. When $e=0$ the error vanishes. Otherwise $m_{i\ell}=s_i^+s_\ell^-/e$ pairs the two parts. More generally any nonnegative pairing with these margins works. Then
$$
\sum_i s_i A_i=\sum_{i,\ell}m_{i\ell}(A_i-A_\ell),\qquad
\|c(F)-w\|_{\rm TV}\le\sum_{i,\ell}m_{i\ell}\|A_i-A_\ell\|_{\rm TV}
\le \rho e. \tag{3}
$$
Row correction preserves positivity and the diagonal-scaling form. The column half-step obeys the same identities by transposition. The pairing in (3) is why a known distribution of residual mass can beat a bound that uses only $e$.

### 3. Existence, convergence and identification of the optimum

Start by column-normalizing $K$ to $w$ and alternately fit $p$ and $w$ by exact positive factors. If the first row residual has TV $e$, (3) shows inductively that the TV movement at half-step $n$, counting from zero, is at most $e\rho^n$. The sum is finite, including at $\rho=0$. The tables therefore converge in finite-dimensional TV to a nonnegative table $L$. Row-exact and column-exact subsequences have the same limit. It has both required margins.

For each table $T$ in the sequence,
$$
T_{ij}T_{\ell m}K_{im}K_{\ell j}=T_{im}T_{\ell j}K_{ij}K_{\ell m}.
$$
This polynomial identity survives passage to the limit. If $L_{ij}=0$, positivity of its row and column margins gives $m,\ell$ with $L_{im}>0$ and $L_{\ell j}>0$. The right side of the identity would be positive and the left zero. Thus $L>0$. Fix one row $i_0$ and one column $j_0$. The identity gives $L_{ij}=a_iK_{ij}b_j$ with
$$
a_i=L_{i j_0}/K_{i j_0},\qquad
b_j=\frac{L_{i_0j}K_{i_0j_0}}{K_{i_0j}L_{i_0j_0}}.
$$
This also works if we start from any positive column-exact scaling of $K$.

For any feasible table $Z$, define $H_K(Z)=\sum_{ij}[Z_{ij}\log(Z_{ij}/K_{ij})-Z_{ij}]$, interpreting $0\log0=0$. For a feasible positive scaling $Q$, $\log(Q_{ij}/K_{ij})=\log a_i+\log b_j$. Its pairing with $Z-Q$ is zero by the two marginal identities. Expanding yields
$$
H_K(Z)-H_K(Q)=\sum_{ij}Q_{ij}\phi(Z_{ij}/Q_{ij}),\qquad
\phi(x)=x\log x-x+1.
$$
Here $\phi(0)=1$; for $x>0$ its derivative is $\log x$, so its unique minimum is zero at one. Equality holds exactly when $Z=Q$. Applying this to $L$ proves uniqueness of the feasible scaling and its global optimality. For Gibbs $K$, $\varepsilon H_K(Z)=\sum Z_{ij}M_{ij}+\varepsilon\sum Z_{ij}(\log Z_{ij}-1)$. The convention in POT omits the linear term, which is a constant on feasible unit-mass tables. Thus the minimizers agree.

Starting now from the given $P$, the iteration converges to this same $Q$. The geometric sum from its first correction bounds $\operatorname{TV}(P,Q)$ by $Ge$.

### 4. A second bound counts common row cuts

Since $P,Q$ scale the same positive $K$, write $Q_{ij}=\alpha_iP_{ij}\beta_j$ with positive factors. Permute the rows in decreasing order of $\alpha_i$, breaking ties consistently across columns. For fixed $j$, $z_{ij}=Q_{ij}-P_{ij}$ has the sign of $\alpha_i-1/\beta_j$. Its positive entries precede its negative entries and $\sum_i z_{ij}=0$. Every prefix sum $H_{sj}=\sum_{i=1}^s z_{ij}$ is nonnegative. The largest prefix equals the sum of all positive entries. When the column differs, one of the $R-1$ proper prefixes realizes that maximum.

It follows that the column's contribution $\frac12\sum_i|z_{ij}|$ is at most $\sum_{s=1}^{R-1} H_{sj}$, also when the column is unchanged. Summing over columns gives
$$
\operatorname{TV}(P,Q)\le\sum_{s=1}^{R-1}\sum_{i=1}^s (p_i-q_i)\le(R-1)e .
$$
Each subset sum of a zero-total residual is at most its total positive mass $e$. Combining with the geometric estimate proves (1). The Lean proof uses upper sets in the same common row-weight order and handles ties directly.

### 5. From the observed residual to the returned table

The old table $P$ has exact columns; the returned table $F$ has exact rows. Equation (1) and $\operatorname{TV}(F,P)=e_0$ give $\operatorname{TV}(F,Q)\le(1+C_R)e_0$ by the triangle inequality. Applying (1) to $F^\top,Q^\top$ gives $\operatorname{TV}(F,Q)\le C_S e_1$. Equation (3) gives $e_1\le\rho e_0$. Taking the smaller bound proves (2). Uniform initialization of $u$ is positive, and the two division updates preserve positivity by finite sums of positive terms. Therefore the comparison applies at every iterate of the implemented recurrence.

In the adapter, $\delta=\mathrm{stopThr}/4$. As $S\ge2$, $C_S>0$. Testing $e_1<\delta/C_S$ is equivalent to $C_S e_1<\delta$. The wide branch tests $e_0<\delta/\max(d,10^{-300})$. Multiplying by $d\ge0$ gives $d e_0<\delta$ whenever $\delta>0$, including $d=0$. This proves the advertised strict conclusion at successful extra exits in exact arithmetic.

### 6. Refinement when the residual distribution is available

Suppose we have a signed approximate marginal $\widehat q$ of total mass one, with $\|\widehat q-q\|_{\rm TV}\le\alpha$. Put $e=\|p-\widehat q\|_{\rm TV}$. Pair the positive and negative parts of $p-\widehat q$ using $m_{i\ell}$. Let $\rho_{i\ell}$ bound the TV between these specific conditional rows, obtainable from section 1 using only that row pair's cross ratios. The signed residual $p-q$ is the sum of $p-\widehat q$ and $\widehat q-q$. Applying the pair-specific estimate to the first and (3)'s global contraction to the second bounds the first opposite residual by $\sum m_{i\ell}\rho_{i\ell}+\rho\alpha$. The first table movement costs at most $e+\alpha$. The remaining movements cost at most $G$ times the first opposite residual by section 3. Equation (1) also applies directly with row error at most $e+\alpha$. Consequently
$$
\operatorname{TV}(P,Q)\le\min\left\{C_R(e+\alpha),\
 e+\alpha+G\left(\sum_{i,\ell}m_{i\ell}\rho_{i\ell}+\rho\alpha\right)\right\}.
$$
This is the distribution-sensitive variant used in a separate experiment. The dense package computes (2) without forming a residual pairing.

For squared Euclidean cost $M_{ij}=\|x_i-y_j\|^2/2$, expanding the four squares shows that the logarithm of $K_{ij}K_{\ell m}/(K_{im}K_{\ell j})$ is $(x_i-x_\ell)\cdot(y_j-y_m)/\varepsilon$. Bounding each coordinate difference by its width gives $\Delta=\sum_k{\rm width}_k(x){\rm width}_k(y)/\varepsilon$ as an upper bound on that logarithm. Hence $t=\exp(\Delta/2)$ is valid. Holding domain and temperature fixed keeps this geometric upper bound fixed while point counts increase. Arbitrary finite cost matrices in the installed adapter use the range of $K$ instead.

## Algorithms and floating-point scope

**The local-install adapter 0.2.0.** The following is the success path for a single eligible dense CPU float64 problem. It shows which table each probe certifies. The ordinary checkpoint and iteration-limit branches implement a different success or return policy.

~~~
K, C_cols, d, first_product = obtain_kernel(M, reg)
u = uniform(R)
col_product = first_product                   # K^T u
for k = 0, ..., numItermax-1:
    v = w / col_product
    kv = K v
    ordinary = (k mod 10 == 0)
    probe = (k mod 10 in {4,7,9}) and (next ordinary k < numItermax)
    wide = (S >= 4 R)
    accept = wide and probe and TV(u * kv - p) < (stopThr/4) / max(d, 10^-300)
    u = p / kv
    if not accept:
        col_product = K^T u
        if ordinary: accept = L2(v * col_product - w) < stopThr
        if probe and not wide: accept = TV(v * col_product - w) < (stopThr/4) / C_cols
    if accept:
        form F = diag(u) K diag(v)
        check both materialized L2 margin errors < stopThr
        on a non-wide extra exit also recheck its post-row plan-TV test on F
        if checks pass: return F
        otherwise: delegate to POT
~~~

Here TV of a residual vector means half its entrywise absolute sum and * in the pseudocode means pointwise multiplication of two vectors. Supported fast calls have ordinary NumPy float64 inputs, a C-contiguous cost, positive finite regularization, one strictly positive marginal per side with sums close to one, at least two rows and columns, no log, verbose mode, additional keywords or warm start, an iteration budget of at least 11, and $10^{-13}\le\mathrm{stopThr}<1$. The adapter checks a safe numerical range for $K$. Unsupported calls and applicable numerical failures delegate to POT 0.9.7 or 0.9.7.post1. Finite iteration exhaustion can return the last plan with POT-style warning. An ordinary checkpoint or exhaustion can return a plan whose full-plan TV exceeds the quarter budget.

**Repeated calls.** The automatic cache retains at most one entry per thread within its size budget. Cost shape, regularization and three sampled costs screen candidates. On admission it builds from a fresh cost snapshot. A later hit requires a full cost comparison and matching regularization; a failed full comparison triggers a cooldown. It reuses the kernel, the initial product, and the two coefficients. Marginals and termination conditions are supplied anew. An explicit `prepare(M, reg)` takes the snapshot immediately. The proof of cache equivalence is induction on a call trace: an empty entry is valid; constructing or replacing an entry stores the value of the deterministic builder at its saved key; a hit returns that value only at the same key; skipping, clearing and invalidating preserve the invariant. This proves equivalence to cold computation in the value model, assuming stable input values during each call.

**Proposed POT review experiment.** Its single post-row check uses $C_S e_1$ and an explicit plan-TV target. Every successful opt-in return must pass both the plan test and the existing marginal criterion, including at ordinary checkpoints. Its strict success policy differs from the adapter's extra-probe policy. The local patch leaves the historical solver and installation intact. Timings, the alternate check schedules and the prototype's failure behavior are documented in [the comparison and reproduction notes](EVIDENCE.md).

**At machine precision.** BLAS, exponentiation, rounding of residual reductions, input mass checks and mutable NumPy arrays are outside the real-arithmetic theorem. An inexpensive float64 number evaluating the bound is an estimate. A numerically tighter reference plan checks experimental agreement; neither it nor a second reduction supplies an outward-rounded error bound. The prototype uses explicit failure on an unmet opt-in budget. A production guarantee about floating-point output would require validated bounds for kernel evaluation, scalings, residuals and deviations from exactly matched margins.

## What changed in experiments

With the same separable grid solver, input pairs and plan budget on 900 MNIST comparisons, the geometry-based rule at regularization 0.24 reduced updates from 3,211 to 2,178 and median wall time from 73.61 to 66.62 ms. At 0.02, both rules took 19,762 updates. In a separate dense benchmark, switching the whole dense CPU implementation to the earlier POT-compatible adapter gave a median 1.826896× speedup over POT 0.9.7. In the matched code comparison, turning on the extra exits gave 1.0988359× on the 11 triggered configurations and 0.9784931× over all 27. The pinned default-branch prototype tests a stricter policy that always requires the requested plan estimate. It was slower than stock on the four measured fixtures. [Tables, conditions, command lines and raw data](EVIDENCE.md)

## Written versions and Lean correspondence

The earlier many-row research note gives the finite-kernel estimate, a short argument and the pairwise extension. Its original `ManyRows.limit_certificate` takes convergence, step bounds and contraction as inputs. The **0.2.0 Lean audit** supplies the actual updates, the count bound, the limiting scaling and its optimality, and both probes. This page gives a self-contained written proof of the finite-plan theorem and its use in dense early stopping. The historical map, Gaussian, and interpolation results each have separate assumptions and proofs.

| Step above | Module and declarations in the frozen audit |
|---|---|
| Cross ratios and row events | `ManyRows.lean`, `odds_gap`, `subset_gap`, `abs_sum_bound`, `diagonal_cross`. `RuntimeBounds.lean`, `box_cross` and `scaled_cross`. |
| Transfer and exact half-step movement | `ManyRows.lean`, `paired_transfer`, `residual_contraction`, `scaled_kernel_contraction` and `correction_size`. `HalfSteps.lean`, `half_step`. |
| Alternating convergence and feasible positive scaling | `Alternation.lean`, `alternating_limit`. `ScalingLimits.lean`, `closed_scalings`. `RuntimeBounds.lean`, `optimal_scaling`. |
| Unique entropic optimum including competitors with zeros | `EntropicPlan.lean`, `objective_gap` and `unique_minimum`. `GibbsStop.lean`, `cost_identity` and `gibbs_stopping`. |
| Ordered cuts and global finite-plan bound | `ScalingCuts.lean`, `ordered_cut_bound` and `count_certificate`. `PlanCertificate.lean`, `plan_certificate`. The formal proof uses the count bound for a finite tail and then sends its geometric factor to zero. The written proof sums the same half-step bounds to the identified limit. |
| Pair-specific residual and squared geometry | `PairedCertificate.lean`, `paired_certificate`. `SquaredGeometry.lean`, `sq_cost_swap` and `squared_box_cross`. |
| Returned iterate, factors and strict threshold | `PlanCertificate.lean`, `returned_plan`. `RuntimeBounds.lean`, `guard_factor`, `reciprocal_rate`, `two_stops` and `early_budget`. `DenseChecks.lean`, `dense_checks`. `CertifiedExit.lean`, `rowIter_pos` and `certified_exit`. |
| Cache value model | `CacheReuse.lean`, `dispatch_sound` and `trace_sound`. `CachedKernel.lean`, `kernel_trace`. |
| Earlier interpolation interface | `SummaryBridge.lean`, `tensor_bound`, `summary_tv` and `summary_plan`. These consume local approximation bounds. The RGB mixed Newton/Cauchy remainder, one-dimensional Chebyshev error constants, all floating-point operations and all Python execution paths have no end-to-end Lean claim here. |

The existing clean-build and axiom logs accompany the [frozen proof sources](lean). The build used Lean 4.34.1 and mathlib `d13f23b723b8a846827a245b89c10fc7d3f11612`. It audited 40 public declarations including supporting lemmas, reusing the previously checked ManyRows source. Its axiom union is `propext`, `Classical.choice` and `Quot.sound`. See [the performance evidence and scope](EVIDENCE.md) for the separate numerical comparisons.
