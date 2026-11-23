import RuntimeBounds

open Finset Real
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

def gibbs (M : Table I J) (ε : ℝ) : Table I J := fun i j => exp (-(M i j)/ε)
def entropicCost (M Z : Table I J) (ε : ℝ) :=
  ∑ i, ∑ j, (Z i j * M i j + ε * Z i j * (log (Z i j) - 1))

omit [Nonempty I] [Nonempty J] in
theorem cost_identity (M Z : Table I J) (ε : ℝ) (he : 0 < ε) :
    entropicCost M Z ε = ε * objective (gibbs M ε) Z := by
  simp only [entropicCost, objective, gibbs, log_exp, mul_sum]
  apply sum_congr rfl; intro i _
  apply sum_congr rfl; intro j _
  field_simp [he.ne']; ring

/-- For any finite real cost and positive temperature, the optimum exists, is unique
against all feasible plans, and the two stopping formulas bound its plan error.
lo and hi are attained at kernel entries, not additional input hypotheses. -/
theorem gibbs_stopping (M P : Table I J) (ε : ℝ) (he : 0 < ε)
    (p : I → ℝ) (w : J → ℝ) (hp : ∀ i, 0 < p i) (hw : ∀ j, 0 < w j)
    (sp : ∑ i, p i = 1) (sw : ∑ j, w j = 1)
    (scale : Related (gibbs M ε) P) (col : row (tr P) = w) :
    let K := gibbs M ε
    ∃ (Q : Table I J) (a b : I × J), Positive Q ∧ Related K Q ∧ feasible Q p w ∧
      (∀ i j, K a.1 a.2 ≤ K i j ∧ K i j ≤ K b.1 b.2) ∧
      (∀ Z, feasible Z p w → entropicCost M Q ε ≤ entropicCost M Z ε ∧
        (entropicCost M Z ε = entropicCost M Q ε ↔ Z = Q)) ∧
      (let t := K b.1 b.2 / K a.1 a.2
       let e := err P Q / 2
       gap P Q/2 ≤ factor I t * e ∧
       gap (fixRow P Q) Q/2 ≤ min (1+factor I t) (factor J t*rate t) * e) := by
  let K := gibbs M ε
  have hk : Positive K := fun _ _ => exp_pos _
  obtain ⟨a,_,low⟩ := univ.exists_min_image (fun u : I × J => K u.1 u.2) univ_nonempty
  obtain ⟨b,_,high⟩ := univ.exists_max_image (fun u : I × J => K u.1 u.2) univ_nonempty
  have box i j := And.intro (low (i,j) (mem_univ _)) (high (i,j) (mem_univ _))
  obtain ⟨Q,hq,rq,fq,opt⟩ := optimal_scaling K p w hp hw sp sw _ _ (hk a.1 a.2) box
  have pp : Positive P := by
    obtain ⟨l,r,lp,rp,rep⟩ := scale
    exact fun i j => (rep i j) ▸ mul_pos (mul_pos (lp i) (hk _ _)) (rp j)
  refine ⟨Q,a,b,hq,rq,fq,box, ?_, two_stops K P Q pp hq scale rq
    (fun j => congrFun (col.trans fq.2.2.symm) j) _ _ (hk a.1 a.2) box⟩
  intro Z fz
  simp only [cost_identity M _ ε he, mul_le_mul_iff_right₀ he, mul_right_inj' he.ne']
  exact opt Z fz
end ScalingAudit
