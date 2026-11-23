import PlanCertificate

open Finset
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

/-- The joint residual law, with an approximate signed row marginal. pairT i l
bounds only this pair's odds ratios; no sign condition is imposed on qhat. -/
theorem paired_certificate (P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (rel : Related P Q) (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t)
    (qhat : I → ℝ) (α : ℝ) (uncertain : (∑ i, |qhat i-row P i|)/2 ≤ α)
    (mass : ∑ i, qhat i = ∑ i, row P i) (m pairT : I → I → ℝ)
    (hm : ∀ i l, 0 ≤ m i l)
    (flow : ∀ i, row Q i-qhat i = (∑ l,m i l)-(∑ l,m l i))
    (pt : ∀ i l, 1 ≤ pairT i l)
    (pc : ∀ i l j k, P i j * P l k ≤ (pairT i l)^2 * (P l j * P i k)) :
    let e := (∑ i, |row Q i-qhat i|)/2
    let pair := ∑ i, ∑ l, m i l * rate (pairT i l)
    gap P Q/2 ≤ min (factor I t * (e+α)) (e+α+geom t*(pair+rate t*α)) := by
  let A i j := (row P i)⁻¹ * P i j
  let d i := row Q i - qhat i
  let u i := qhat i - row P i
  let pair := ∑ i, ∑ l, m i l * rate (pairT i l)
  have pp := row_pos hp
  have norm i : ∑ j, A i j = 1 := by
    simp only [A,←mul_sum]; exact inv_mul_cancel₀ (pp i).ne'
  have pw i l : (∑ j, |A i j-A l j|) ≤ 2*rate (pairT i l) := by
    apply ManyRows.abs_sum_bound _ _ (fun j => mul_nonneg (inv_pos.mpr (pp l)).le (hp l j).le)
      (norm i) (norm l) _ (pt i l)
    intro j k
    have bound := mul_le_mul_of_nonneg_left (pc i l j k)
      (mul_nonneg (inv_pos.mpr (pp i)).le (inv_pos.mpr (pp l)).le)
    dsimp [A]; linarith only [bound]
  have transfer (j) : (∑ i,d i*A i j) = ∑ i, ∑ l, m i l*(A i j-A l j) := by
    simp only [d,flow,sub_mul,mul_sub,sum_sub_distrib,sum_mul]
    congr 1
    rw [sum_comm (f:=fun i l => m l i*A i j)]
  have known := ManyRows.paired_transfer A m (fun i l => rate (pairT i l)) hm pw
  simp only [←transfer] at known
  have zero : ∑ i,u i = 0 := by simp only [u,sum_sub_distrib,mass,sub_self]
  have unknown := ManyRows.scaled_kernel_contraction P (fun i => (row P i)⁻¹) (fun _ => 1)
    (fun i j => (hp i j).le) (fun i => (inv_pos.mpr (pp i)).le) (by simp)
    (by simpa only [mul_one] using norm) t ht hc u zero
  simp only [mul_one] at unknown
  have rr := (rate_range ht).1
  have eu : (∑ i, |u i|) ≤ 2*α := by change (∑ i, |u i|)/2 ≤ α at uncertain; linarith
  have un : (∑ j, |∑ i, u i*A i j|) ≤ rate t*(2*α) := unknown.trans (mul_le_mul_of_nonneg_left eu rr)
  have decomp i : row Q i-row P i = d i+u i := by dsimp [d,u]; ring
  have errbound : err P Q ≤ (∑ i, |d i|)+2*α := by
    calc
      _ ≤ ∑ i,(|d i|+|u i|) := sum_le_sum fun i _ => (decomp i) ▸ abs_add_le _ _
      _ ≤ _ := by rw [sum_add_distrib]; exact add_le_add_right eu _
  let F := fixRow P Q
  have delta i j : F i j - P i j = (d i+u i)*A i j := by
    rw [←decomp]; dsimp [F,fixRow,A]; field_simp [(pp i).ne']
  have op j : row (tr F) j-row (tr Q) j = (∑ i, d i*A i j)+(∑ i, u i*A i j) := by
    rw [←cols j]
    simp only [row,tr,←sum_add_distrib,←add_mul,←delta,sum_sub_distrib]
  have eb : err (tr F) (tr Q) ≤ 2*(pair+rate t*α) := by
    calc
      _ ≤ ∑ j,(|∑ i,d i*A i j|+|∑ i,u i*A i j|) := by
        apply sum_le_sum; intro j _
        rw [abs_sub_comm,op]; exact abs_add_le _ _
      _ ≤ _ := by rw [sum_add_distrib]; dsimp [pair]; linarith only [known,un]
  obtain ⟨h1,r1,c1,x1,mov,_⟩ := half_step P Q hp hq cols t ht hc
  have next := plan_certificate (tr F) (tr Q) h1 (fun j i => hq i j) (r1 rel) c1 t ht x1
  rw [gap_tr] at next
  have base := plan_certificate P Q hp hq rel cols t ht hc
  have ge : 0 ≤ geom t := by dsimp [geom]; linarith
  have fp : 0 ≤ factor I t := le_min (Nat.cast_nonneg _) ge
  have next' := next.trans ((mul_le_mul_of_nonneg_right (min_le_right _ _) (err_nonneg _ _)).trans
    (mul_le_mul_of_nonneg_left eb ge))
  have tri := gap_triangle P F Q
  rw [show gap P F = err P Q from mov] at tri
  apply le_min
  · change gap P Q / 2 ≤ factor I t * ((∑ i,|d i|)/2+α)
    linarith only [base.trans (mul_le_mul_of_nonneg_left errbound fp)]
  · change gap P Q / 2 ≤ (∑ i,|d i|)/2+α+geom t*(pair+rate t*α)
    linarith only [tri,errbound,next']
end ScalingAudit
