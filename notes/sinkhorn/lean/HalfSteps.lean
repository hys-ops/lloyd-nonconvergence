import ScalingCuts

open Finset
noncomputable section
namespace ScalingAudit
variable {I J : Type*} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

def Cross (P : Table I J) (t : ℝ) :=
  ∀ i l j k, P i j * P l k ≤ t^2 * (P l j * P i k)
def rate (t : ℝ) := (t-1)/(t+1)
def geom (t : ℝ) := (t+1)/2
def fixRow (P Q : Table I J) : Table I J :=
  fun i j => (row Q i / row P i) * P i j

omit [Fintype I] [Nonempty I] in
theorem row_pos {P : Table I J} (h : Positive P) (i : I) : 0 < row P i :=
  sum_pos (fun j _ => h i j) univ_nonempty

omit [Nonempty I] [Nonempty J] in
theorem gap_tr (P Q : Table I J) : gap (tr P) (tr Q) = gap P Q := by
  exact sum_comm

omit [Nonempty I] [Nonempty J] in
theorem gap_triangle (P M Q : Table I J) : gap P Q ≤ gap P M + gap M Q := by
  unfold gap
  simp only [←sum_add_distrib]
  exact sum_le_sum fun i _ => sum_le_sum fun j _ => by
    rw [show Q i j - P i j = (M i j-P i j)+(Q i j-M i j) by ring]
    exact abs_add_le _ _

omit [Nonempty I] [Nonempty J] in
theorem err_nonneg (P Q : Table I J) : 0 ≤ err P Q :=
  sum_nonneg fun _ _ => abs_nonneg _

omit [Nonempty I] in
/-- All invariants and both residual identities for one actual normalized update.
After transpose it is again a problem with exact column masses. -/
theorem half_step (P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    let F := fixRow P Q
    Positive (tr F) ∧ (Related P Q → Related (tr F) (tr Q)) ∧ SameCols (tr F) (tr Q) ∧
    Cross (tr F) t ∧ gap P F = err P Q ∧ err (tr F) (tr Q) ≤ rate t * err P Q := by
  let A i j := (row P i)⁻¹ * P i j
  let d i := row Q i - row P i
  have pp := row_pos hp
  have qp := row_pos hq
  have An i j : 0 ≤ A i j := mul_nonneg (inv_pos.mpr (pp i)).le (hp i j).le
  have sums i : ∑ j, A i j = 1 := by
    simp only [A, ←mul_sum]; exact inv_mul_cancel₀ (pp i).ne'
  have dz : ∑ i, d i = 0 := by
    simp only [d, row, sum_sub_distrib]
    rw [sum_comm (f:=fun i j => Q i j),sum_comm (f:=fun i j => P i j)]
    exact sub_eq_zero.mpr (sum_congr rfl (fun j _ => (cols j).symm))
  have eq i j : fixRow P Q i j - P i j = d i * A i j := by
    dsimp [fixRow, d, A]; field_simp [(pp i).ne']
  have hrows i : ∑ j, fixRow P Q i j = row Q i := by
    simp only [fixRow, ←mul_sum]
    exact div_mul_cancel₀ _ (pp i).ne'
  refine ⟨fun j i => mul_pos (div_pos (qp i) (pp i)) (hp i j),
    ?_, fun i => hrows i, ?_, ?_, ?_⟩
  · rintro ⟨a,b,ha,hb,rep⟩
    refine ⟨b, fun i => a i / (row Q i / row P i), hb,
      fun i => div_pos (ha i) (div_pos (qp i) (pp i)), ?_⟩
    intro j i
    dsimp [tr,fixRow]
    rw [rep]; field_simp [(pp i).ne',(qp i).ne']
  · intro j k i l
    have scaled := ManyRows.diagonal_cross P (fun i => row Q i / row P i) (fun _ => 1) t
      (fun i => (div_pos (qp i) (pp i)).le) (by simp) hc i l j k
    simp only [mul_one] at scaled
    change fixRow P Q i j * fixRow P Q l k ≤ t^2 * (fixRow P Q i k * fixRow P Q l j)
    unfold fixRow
    linarith only [scaled]
  · simpa only [gap,eq,err,d] using ManyRows.correction_size A An sums d
  · have contract := ManyRows.scaled_kernel_contraction P (fun i => (row P i)⁻¹) (fun _ => 1)
      (fun i j => (hp i j).le) (fun i => (inv_pos.mpr (pp i)).le) (by simp)
      (by simpa only [mul_one] using sums) t ht hc d dz
    have opposite j : row (tr Q) j - row (tr (fixRow P Q)) j = -(∑ i, d i*A i j) := by
      rw [←cols j]
      simp only [row, tr, ←sum_sub_distrib, ←eq, ←sum_neg_distrib, neg_sub]
    simpa only [err,opposite,abs_neg,rate,mul_one,d,A] using contract
end ScalingAudit
