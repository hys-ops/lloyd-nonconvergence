# Sequential estimation of multivariate ranks

[Complete written proof (PDF)](sequential-multivariate-ranks-proof.pdf)

How much does not knowing the correct predictive law change the multivariate rank of the **same observation**? Over a worst-case list of $M$ candidate path laws, the cumulative expected squared error over $T$ observations is of order $\min(T,\log M)$. Within a fixed smooth one-parameter family, the worst-case order is $\log(1+T)$ even for observations that are i.i.d. conditional on the parameter.

## A one-observation bound

Let the reference law $\rho$ have a full-dimensional log-concave density $w$ in a ball of radius $R$, centered at zero. Observation laws have densities on a common compact set. Let $S_p$ be the quadratic optimal map from $p(y)\,dy$ to $\rho$, with bounded representatives chosen in the reference ball. Conditional rank maps can be taken jointly measurable: the unique optimal plan varies Borel measurably by compactness and stability, and the map can be recovered as the limit of conditional means on dyadic cells. The loss is evaluated at the same observation under both maps, not at the same reference point.

$$
\int p|S_p-S_q|^2
\le 16R^2\int(\sqrt p-\sqrt q)^2
\le 16R^2\,\mathrm{KL}(p\Vert q).
$$

Write $r=\sqrt p$, $s=\sqrt q$, $U=S_p$, $V=S_q$, and $M_0=(U+V)/2$. On the common positive-density set, [McCann, Corollary 4.3, Theorem 4.4 and Remark 4.5](https://www.math.toronto.edu/~mccann/papers/advances.pdf#page=22) give the nonsmooth change of variables for these convex gradients. Log-concavity of $w$ and concavity of log determinant give $w(M_0)\det DM_0\ge rs$ there, using Aleksandrov Hessians. Since $M_0$ is itself a convex gradient, the same change of variables gives $(M_0)_\#(rs\,dy)\le\rho$. There is no contribution off the overlap.

Test the domination with $R^2-|x|^2$ on the reference ball and use $U_\#(p\,dy)=V_\#(q\,dy)=\rho$. For $X=\|rU-sV\|_2$ and $B=R\|r-s\|_2$, expansion gives
$$
X^2\le B^2+\tfrac12\int rs|U-V|^2\le B^2+\tfrac12(X+B)^2.
$$
The second inequality uses $\sqrt{rs}\le(r+s)/2$ and $(r+s)(U-V)/2=rU-sV-(r-s)M_0$. Thus $(X-3B)(X+B)\le0$, and $\|r(U-V)\|_2\le X+B\le4B$. Integrating $-\log u\ge2(1-\sqrt u)$ gives the KL comparison. When the KL divergence is finite the rank under $q$ is unambiguous $p$-almost everywhere.

## Sequential upper bounds

Under a candidate path law $Q$, predict with its next conditional density $q_t$ and output $S_{q_t}(Y_t)$ once $Y_t$ arrives. If $p_t$ is the true conditional density under $P$, the one-observation bound and the chain rule give
$$
\sum_{t=1}^T\mathbb E_P |S_{p_t}(Y_t)-S_{q_t}(Y_t)|^2
\le16R^2\,\mathrm{KL}(P^{1:T}\Vert Q^{1:T}).
$$
This allows dependent observations. Taking the [Bayesian mixture](https://arxiv.org/abs/cs/0301014) of candidate path laws $P_j$ with weights $\pi_j>0$ bounds the right side by $16R^2\min_j\{\mathrm{KL}(P^{1:T}\Vert P_j^{1:T})+\log(1/\pi_j)\}$. In the correctly specified case, uniform weights and the trivial per-step bound give $\min(4R^2T,16R^2\log M)$. Mix the densities, not the maps.

For i.i.d. models $P_\theta$, suppose $\mathrm{KL}(P_\theta\Vert P_\eta)\le C\|\theta-\eta\|^2$ locally and the prior gives mass at least $ca^k$ to each radius-$a$ parameter neighborhood for sufficiently small $a$. Restrict the Bayesian mixture to this neighborhood and use Jensen's inequality to bound its path divergence by $-\log(ca^k)+TCa^2$. Set $a=T^{-1/2}$ to obtain the upper bound $16R^2[C+\log(1/c)+(k/2)\log T]$; use uniform hypotheses for a uniform bound. This applies the classical [parametric log-loss calculation](https://doi.org/10.1109/18.54897) to rank loss.

## Matching examples on a square

Take uniform reference on $D=[0,1]^2$, $z=(x,y)$, and
$$
v(z)=\pi^{-2}\nabla[\cos(\pi x)\cos(\pi y)],\qquad S_\theta(z)=z+\theta v(z),\quad |\theta|\le1/2.
$$
The Hessian eigenvalues of its potential are $1-\theta c_\pm$, where $c_\pm=\cos(\pi(x\pm y))$. The map is strictly monotone and its normal component is fixed on each face, so it maps the square into itself. For an interior target point, minimizing the potential minus the corresponding linear form gives an interior minimum (the inward derivative is negative on an incident face), hence surjectivity on the interior. The rank map therefore transports the density $p_\theta=(1-\theta c_+)(1-\theta c_-)\ge1/4$ to the uniform law. Direct integration gives $\int_D|v|^2=1/(2\pi^2)$.

**Finite list.** Set $\ell=\min(T,\lfloor\log_2 M\rfloor)$. Take all $2^\ell$ paths of independent observations with parameters $b_t/2$, $b_t\in\{-1,1\}$, for the first $\ell$ observations and parameter zero thereafter. Under the uniform prior on paths, the current sign is independent of the past and the current observation updates its probabilities in proportion to $p_\pm=p_{\pm1/2}$. Its expected conditional rank variance at each such date is
$$
\tfrac14\int_D |v(z)|^2\frac{2p_+(z)p_-(z)}{p_+(z)+p_-(z)}\,dz
\ \ge\ \frac1{32\pi^2}.
$$
The inequality uses the lower bound on both densities. Summing and taking the worst candidate proves a lower bound $\ell/(32\pi^2)$ for any estimator, even one using the current observation. This is an example of a hard list, not a lower bound for every list.

**Fixed i.i.d. family.** Draw $\theta$ once with prior density $2\cos^2(\pi\theta)$ on $[-1/2,1/2]$, and sample from $p_\theta$ at every date. Conditional on $n$ past observations, replacing the current density in the risk integral by $1/4$ lower bounds the risk of any estimator by the posterior variance of $\theta$ divided by $8\pi^2$. Indeed, after this replacement the pointwise optimal estimator at $z$ is $z+\mathbb E[\theta\mid\text{past}]v(z)$. The prior Fisher information is $4\pi^2$ and $|\partial_\theta\log p_\theta|\le4$. Integration by parts against the joint density of $\theta$ and the past, followed by Cauchy–Schwarz, gives expected posterior variance at least $(4\pi^2+16n)^{-1}$. The boundary term vanishes since the prior is zero at both ends; this is the scalar [van Trees bound](https://dspace.library.uu.nl/handle/1874/1190). Consequently worst-case cumulative risk is at least
$$
\frac1{8\pi^2}\sum_{n=0}^{T-1}\frac1{4\pi^2+16n}
\ge\frac1{128\pi^2}\log(1+4T/\pi^2).
$$
An independent upper check in this example is to estimate $\theta$ by the clipped sample mean of $-2\cos(\pi X)\cos(\pi Y)$ on the past. Its expectation before clipping is $\theta$ by direct integration and its mean squared error after clipping is at most $4/n$. Since $|v|\le1/\pi$, the cumulative upper bound is $O(\log(1+T))$.

## Lean verification

Lean derives static quadratic optimal transport and midpoint domination, and proves the same-observation rank bound with constant $16R^2$, including vanishing densities and the extended-real KL consequence. It verifies the cumulative bounds for absolutely continuous finite path laws, including the true finite mixture and misspecification bound. `SequentialRanks.worst_square_catalog_minimax` proves the matching worst-list rates for the same risk over measurable deterministic policies that see the past and current observation; the lower bound is for a constructed hard list, not every list. `SequentialRanks.square_iid_minimax_log` gives both bounds for the same fixed i.i.d. family and risk. The formal proof also verifies the joint measurability of conditional rank representatives and the stated parametric upper bound under its local KL and prior-mass assumptions.

The archived Lean 4.34.1 run records a clean build and kernel replay of 122 proof modules across both projects; the audited declarations use only `propext`, `Classical.choice` and `Quot.sound`. The natural-language statements and their correspondence to the formal definitions remain open to independent review.

[Download the Lean sources, archived logs, and replay instructions](sg-ranks-lean-replay.zip). Extract the ZIP into a fresh directory and run `bash verify.sh` from that directory.

## Relation to the endpoint tool

The [Brenier endpoint-moment tool](brenier-endpoint-moment-tool.md) suggested this application and gives another route to the one-observation bound. The proof here needs only the classical convex-gradient change of variables and a midpoint calculation. It does not replace the more general endpoint comparison, in particular at singular destinations. These are expected-loss results, not runtime or realized-path guarantees. This AI-assisted research note makes no priority claim and has not undergone independent human review.
