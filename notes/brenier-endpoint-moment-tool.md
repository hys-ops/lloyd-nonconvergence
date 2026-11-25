# The Brenier endpoint-moment tool

The [technical note (PDF)](../Brenier_Endpoint_Moment_Tool.pdf) extracts a finite comparison of raw cell moments from the midpoint coupling in [Section 4 of the source preprint](https://github.com/openai/math/blob/4eaee87548250b2682affda7d05d947c05554bae/preprints/Sharp-One-Third-Stability-of-Brenier-Maps-September-25-2026/build/source/sections/moments.tex#L8-L32). Under uniform volume on a compact convex body, the estimate compares two collections of power cells at the same sites, including cells that vanish at one endpoint. It replaces the differentiated cell-mass calculation in an alternate proof of the same one-third stability theorem.

[Read the full 14-page alternate proof (PDF)](../Brenier_One_Third_Stability_Alternate_Proof.pdf). This AI-assisted revision proves the same theorem as the 18-page source preprint; §4 gives the replacement for the differentiated cell-mass argument. The main upper bound, with the manuscript’s explicit constant, and the sharpness of the exponent are now verified in Lean 4.33.1.

## Lean verification

[Source and reproduction scripts](../files/brenier-14p-lean-433-reproduction.zip) · [Verification log](../files/brenier-14p-lean-433-verification.log)

The verification follows the alternate proof: it checks the endpoint-moment estimate and the exact finite-support potential bound, then uses them to obtain the 1/3 stability estimate for arbitrary probability measures supported on a compact target set. It retains the sum of the coordinate projection volumes in the printed constant. It also checks the original three-atom sharpness conclusion and the exact squared map distance for that example.

The separate W₁ remark and the literature discussion are outside the formalization.

## Which results use the estimate?

```mermaid
flowchart TD
  P["Original Brenier midpoint coupling"] --> E["Finite endpoint-moment estimate"]
  E --> A["Alternate one-third stability proof"]
  E --> S["Horizontal estimate → semi-geostrophic overlap bound"]
  E -.->|suggests the application| R["Sequential ranks: direct McCann argument"]
  E -.->|motivates the directional moment viewpoint| L["Exact Lloyd orbit"]
  E -.->|motivates the residual viewpoint| K["Sinkhorn: separate finite-kernel proof"]
```

Solid arrows mean that the argument uses the estimate; dotted arrows are motivation. [Community submission #87](https://github.com/mathcommunity/oai-math-revised/issues/87) records the comparison and its downstream uses.

## What the idea led to

| Note | What is proved | Role of the tool |
| --- | --- | --- |
| [Velocity comparison for semi-geostrophic vortex patches](semigeostrophic-vortex-patches.md) | For the stated patch class, conserved horizontal impulse controls the velocity error on the overlap with a circular rearrangement. | The horizontal endpoint estimate turns density control from rearrangement into velocity control. |
| [Sequential multivariate rank estimation](sequential-multivariate-ranks.md) | A prediction-to-rank error bound, with examples matching the growth rates of the upper bounds. | The endpoint estimate suggested the application. The shorter proof in the note uses McCann's change of variables directly. |
| [Nonconvergence of two-site Lloyd iteration](../README.md#where-the-proof-came-from) | An exact two-site orbit need not converge in dimension three or higher. | The first-moment viewpoint motivated a directional identity; the exact orbit proof does not use the finite bound. |
| [Full-plan error bounds for Sinkhorn](sinkhorn/README.md) | Bounds the entire returned entropic transport plan from an intermediate marginal residual; gives two stopping probes. | The shared residual-measure viewpoint motivated the new finite-kernel proof; the earlier Brenier theorem is not a premise. |

The follow-ups make no priority claim. They should not be read as further improvements to the original one-third stability theorem.
