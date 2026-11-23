import HalfSteps

open Filter
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

theorem rate_range {t : ℝ} (ht : 1 ≤ t) : 0 ≤ rate t ∧ rate t < 1 := by
  have h : 0 < t+1 := by linarith
  exact ⟨div_nonneg (sub_nonneg.mpr ht) h.le, (div_lt_one h).2 (by linarith)⟩

private theorem geom_identity {t : ℝ} (ht : 1 ≤ t) : 1 + geom t * rate t = geom t := by
  have h : t+1 ≠ 0 := by linarith
  unfold geom rate; field_simp [h]; ring

/-- No convergence or successive-step hypotheses: the count estimate controls
the finite tail, and the half-step can be applied in both orientations. -/
private theorem after_n (n : ℕ) (P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (rel : Related P Q) (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    gap P Q ≤ (geom t + (cap I + cap J)*(rate t)^n) * err P Q := by
  induction n generalizing I J with
  | zero =>
    apply (count_certificate P Q hp rel cols).trans
    apply mul_le_mul_of_nonneg_right _ (err_nonneg _ _)
    have c : 0 ≤ cap J := Nat.cast_nonneg _
    simp only [pow_zero, mul_one, geom]; linarith
  | succ n ih =>
    let F := fixRow P Q
    obtain ⟨hpos,hrel,hcols,hcross,hmove,herr⟩ := half_step P Q hp hq cols t ht hc
    have bound := ih (tr F) (tr Q) hpos (fun j i => hq i j) (hrel rel) hcols hcross
    rw [gap_tr,add_comm (cap J) (cap I)] at bound
    have r := (rate_range ht).1
    have g : 0 ≤ geom t := by unfold geom; linarith
    have c : 0 ≤ cap I + cap J := add_nonneg (Nat.cast_nonneg _) (Nat.cast_nonneg _)
    have coeff := add_nonneg g (mul_nonneg c (pow_nonneg r n))
    calc
      gap P Q ≤ gap P F + gap F Q := gap_triangle _ _ _
      _ ≤ err P Q + (geom t + (cap I + cap J)*rate t^n)*(rate t*err P Q) := by
        rw [show gap P F = err P Q from hmove]
        exact add_le_add_right (bound.trans (mul_le_mul_of_nonneg_left herr coeff)) _
      _ = _ := by
        rw [pow_succ]
        linear_combination (err P Q) * (geom_identity ht)

def factor (I : Type) [Fintype I] (t : ℝ) := min (cap I) (geom t)

/-- Complete finite many-row TV inequality, for any two positive scalings
with common column masses. Both sides are twice the TV quantities. -/
theorem plan_certificate (P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (rel : Related P Q) (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    gap P Q ≤ factor I t * err P Q := by
  have r := rate_range ht
  have lim := (((tendsto_pow_atTop_nhds_zero_of_lt_one r.1 r.2).const_mul
    (cap I+cap J)).const_add (geom t)).mul_const (err P Q)
  have bound := le_of_tendsto_of_tendsto tendsto_const_nhds lim
    (Eventually.of_forall fun n => after_n n P Q hp hq rel cols t ht hc)
  simp only [mul_zero,add_zero] at bound
  rw [factor,min_mul_of_nonneg _ _ (err_nonneg _ _)]
  exact le_min (count_certificate P Q hp rel cols) bound

theorem returned_plan (P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (rel : Related P Q) (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    gap (fixRow P Q) Q ≤ min (1 + factor I t) (factor J t * rate t) * err P Q := by
  let F := fixRow P Q
  obtain ⟨hp',hr',hc',hx',hm,he⟩ := half_step P Q hp hq cols t ht hc
  have h := plan_certificate (tr F) (tr Q) hp' (fun j i => hq i j) (hr' rel) hc' t ht hx'
  rw [gap_tr] at h
  have fpos : 0 ≤ factor J t := le_min (Nat.cast_nonneg _) (by dsimp [geom]; linarith)
  have rev : gap F P = gap P F := by simp only [gap,abs_sub_comm (P _ _) (F _ _)]
  rw [min_mul_of_nonneg _ _ (err_nonneg _ _)]
  apply le_min
  · have v := gap_triangle F P Q
    rw [rev,show gap P F = err P Q from hm] at v
    rw [add_mul,one_mul]
    exact v.trans (add_le_add_right (plan_certificate P Q hp hq rel cols t ht hc) _)
  · exact (h.trans (mul_le_mul_of_nonneg_left he fpos)).trans_eq (mul_assoc _ _ _).symm
end ScalingAudit
