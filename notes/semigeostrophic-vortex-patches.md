# Velocity stability on the overlap of semi-geostrophic vortex patches

**Theorem.** Let the physical reference measure be uniform on a bounded convex body in $\mathbb R^3$, invariant under rotations about the vertical axis, with horizontal radius $R_h$. Let $p_t=\rho\,\mathbf 1_{E_t}$ be a renormalized probability-density solution of the incompressible semi-geostrophic equation in geostrophic coordinates, with constant patch density $\rho>0$ and uniformly finite second moments on bounded time intervals. Assume the initial vertical support lies in an interval of length $\ell$.

At each height, replace the horizontal slice of $E_0$ by the centered disk of the same area. Call the resulting set $B$ and put $q=\rho\,\mathbf 1_B$. This reference patch is stationary. The perturbation $E_t$ may be asymmetric. Define the initial horizontal impulse excess by

$$
\mathcal I_0=\int_{\mathbb R^3}|y_h|^2(p_0-q)\,dy.
$$

Then, for almost every time $t$ on the interval of the solution,

$$
\boxed{\displaystyle
\rho\int_{E_t\cap B}|u_{p_t}(y)-u_q(y)|^2\,dy
\;\le\;4R_h^2\sqrt{\pi\rho\,\ell\,\mathcal I_0}.}
$$

The integral compares velocities at the same geostrophic positions, weighted by the mass shared by the two patches.

**Proof.** Let $S_f$ be the quadratic optimal map from $f\,dy$ to the physical reference measure. The velocity is $u_f(y)=J(y-S_f(y))$, where $J(a,b,c)=(-b,a,0)$. Rotational and reflection symmetry, together with uniqueness, make $S_{q,h}$ radial, so $u_q$ is tangent to the reference circles. For $p=p_t$, rotating the physical endpoint of its optimal coupling preserves admissibility. Differentiating its maximal correlation at rotation angle zero gives $\int y_h\cdot(JS_p)_h\,p\,dy=0$. Testing the transport equation with $|y_h|^2$, by truncation, therefore shows that the impulse excess stays equal to $\mathcal I_0$.

Renormalization and zero vertical velocity preserve patch area at each height $z$, almost everywhere. Write $E=E_t(z)$, $D=B(z)$, and $\delta(z)=|E\setminus D|=|D\setminus E|$. The least impulse cost of exchanging area $\delta$ is attained by the two annuli immediately inside and outside the disk boundary. Each contributes $\delta^2/(2\pi)$. Hence $\mathcal I_0\ge(\rho/\pi)\int\delta(z)^2\,dz$, and Cauchy–Schwarz gives

$$
\|p-q\|_1=2\rho\int\delta(z)\,dz
\le 2\sqrt{\pi\rho\,\ell\,\mathcal I_0}.
$$

**The Brenier estimate enters at this last step.** Its horizontal endpoint form is

$$
\int\frac{|pS_{p,h}-qS_{q,h}|^2}{p+q}\,dy
\le R_h^2\int\frac{(p-q)^2}{p+q}\,dy,
$$

with $0/0=0$. For equal-density patches the right-hand integral is exactly $\|p-q\|_1$. On the overlap the left-hand integrand is exactly $\rho|u_p-u_q|^2/2$. Restricting the integral to that overlap and inserting the preceding density bound proves the theorem.

**Sources and verification.** The disk comparison is the planar angular-impulse estimate of [Sideris and Vega, Lemma 2](https://web.math.ucsb.edu/~sideris/pdffiles/sideris-vega.pdf), applied slice by slice. [Choi and Lim](https://arxiv.org/abs/2103.11724) develop the related rearrangement method for radially decreasing Euler vorticities.

The transport input comes from the project’s [finite Brenier cell-moment estimate](https://github.com/hys-ops/lloyd-nonconvergence/blob/5f851ccb85e28bf658f311c5a92f1f9a28df8597/Brenier_Endpoint_Moment_Tool.pdf). For the density form, quantize both destination laws on common finite grids converging in the second-moment metric. Conditional Jensen bounds the discrete triangular discrimination by its original value. Stability of the optimal plans, together with bounded source coordinates, identifies the limit of the vector moment measures. The squared weighted density norm is lower semicontinuous by its dual formula $\sup_{a\in C_c}(2\int a\cdot dB-\int |a|^2\,dm)$, where $B$ is the difference of the two vector moment measures and $m$ is the sum of the two destination laws. Reciprocal vertical rescaling of physical and geostrophic coordinates preserves optimality and yields the horizontal radius $R_h$.

**Lean verification.** `Vortex.sg_public_patch` proves the overlap velocity bound, with the displayed constant, from a given renormalized probability patch solution and the stated reference-body and moment hypotheses. It derives the weak patch equation and time representatives from the renormalized equation with initial data, proves stationarity of the circular reference, and derives the continuum horizontal endpoint estimate from the finite-cell estimate. `Vortex.two_dates_from_probability_dynamics` gives a common full-measure time set for the two-time weak equation and all test functions. The formulation makes the patch mass, measurability and moment assumptions explicit and uses an almost-everywhere optimal transport map to define the given solution's velocity. It does not prove existence of the evolving patch solution.

The archived Lean 4.34.1 run records a clean build and kernel replay of 122 proof modules across both projects; the audited declarations use only `propext`, `Classical.choice` and `Quot.sound`.

This AI-assisted note makes no priority claim and has not undergone independent human review. See also the [Brenier tool page](brenier-endpoint-moment-tool.md).
