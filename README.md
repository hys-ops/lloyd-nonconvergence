# Nonconvergence of two-site population Lloyd iteration

For every dimension $n\geq3$, a smooth, centrally symmetric, positively curved body can be chosen arbitrarily close to the Euclidean ball in any prescribed finite differentiability norm, yet the exact two-site population Lloyd iteration for its uniform law need not converge. One antipodal start yields an orbit whose unordered pairs accumulate at one common radius on **every** equatorial axis. All these limit configurations are stationary. Ordinary and optimal equal-mass updates give the same orbit.

$$
\operatorname{Clust}
= \big\{\{\pm c(w,0)\}:w\in S^{n-2}\big\}
\cong \mathbb{RP}^{n-2},
\qquad c>0.
$$

The paper also gives examples with a smooth isotropic strongly log-concave Gaussian perturbation and a smooth compactly supported log-concave density. For centrally symmetric absolutely continuous planar laws with finite first moment and a twice continuously differentiable angular moment, the ordinary iteration converges from every nonzero antipodal start.

## The proof idea

For an even law, set $H(u)=\mathbb E|u\cdot X|$. The next positive site at direction $u$ is $H(u)u+\nabla_S H(u)$. To steer it to the next unit direction $v$ with $u\cdot v>0$, prescribe

$$
\nabla_S\log H(u)=\frac{v}{u\cdot v}-u.
$$

The construction chooses a sequence approaching every equatorial direction, prescribes these gradients along it, and realizes the potential as the angular moment of a probability law.

## Where the question came from

A midpoint coupling in [the OpenAI Brenier preprint, Section 4](https://github.com/openai/math/blob/4eaee87548250b2682affda7d05d947c05554bae/preprints/Sharp-One-Third-Stability-of-Brenier-Maps-September-25-2026/build/source/sections/moments.tex#L8-L32) led to a finite comparison of two power-cell partitions and a descent certificate for one inexact Lloyd step. That certificate **motivated** the question about exact long-run dynamics; the nonconvergence proof does not use the finite inequality. It starts from the separate exact centroid identity above. The research diagram marks that difference with solid lines for mathematical dependence and a dashed line for motivation. This record does not assert historical priority.

## Files

- [Preprint PDF](Lloyd_preprint.pdf): the complete argument, its scope, and literature comparison.
- [Research-path diagram](Lloyd_Research_Path.html): the development from transport comparison to the exact-orbit theorem. Download and open locally if GitHub shows the HTML source.
- [Lean reproduction packet](Lloyd_Lean_Reproduction.zip): local source, pinned toolchain and dependencies, verification scripts and archived logs. Start with the README inside it. The central declaration is `LloydNDVerified.projective_lloyd`. It verifies the mathematical existence statement by a related formal construction, not the manuscript’s literature assessments.
- [SHA-256 inventory](SHA256SUMS): digests for these exact files.

Lean and mathlib and the other upstream dependencies listed in the packet’s `lean/lake-manifest.json` are fetched separately, remain subject to their own upstream licenses and notices, and are not redistributed here.
