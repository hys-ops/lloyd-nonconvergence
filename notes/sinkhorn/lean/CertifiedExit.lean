import DenseChecks

open Finset Real
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

/-- The default dense iteration starts at the uniform row scaling. -/
def rowIter (K : Table I J) (p : I → ℝ) (w : J → ℝ) : ℕ → I → ℝ
  | 0 => fun _ => 1/(Fintype.card I : ℝ)
  | n+1 => rowUpdate K (columnUpdate K (rowIter K p w n) w) p

theorem rowIter_pos (K : Table I J) (p : I → ℝ) (w : J → ℝ) (hk : Positive K)
    (hp : ∀ i, 0 < p i) (hw : ∀ j, 0 < w j) (n : ℕ) : ∀ i, 0 < rowIter K p w n i := by
  induction n with
  | zero => exact fun _ => div_pos one_pos (Nat.cast_pos.mpr Fintype.card_pos)
  | succ n ih =>
    have v j : 0 < columnUpdate K (rowIter K p w n) w j :=
      div_pos (hw j) (sum_pos (fun i _ => mul_pos (ih i) (hk i j)) univ_nonempty)
    exact fun i => div_pos (hp i) (sum_pos (fun j _ => mul_pos (hk i j) (v j)) univ_nonempty)

/-- End-to-end exact-real statement for the two optional early exits, at any
iteration from the package's uniform initialization. The marginals, cost,
temperature and scanned bounds are inputs. The unique minimizer is a conclusion. -/
theorem certified_exit (M : Table I J) (ε : ℝ) (hε : 0 < ε) (p : I → ℝ) (w : J → ℝ)
    (hp : ∀ i, 0 < p i) (hw : ∀ j, 0 < w j) (sp : ∑ i,p i = 1) (sw : ∑ j,w j = 1)
    (twoCols : 1 < Fintype.card J) (lo hi : ℝ) (hl : 0 < lo)
    (box : ∀ i j, lo ≤ gibbs M ε i j ∧ gibbs M ε i j ≤ hi) (tol : ℝ) :
    let K := gibbs M ε
    let t := hi/lo
    let c := factor J t
    let d := min (1+factor I t) (c*rate t)
    ∃ Q : Table I J, feasible Q p w ∧
      (∀ Z, feasible Z p w → entropicCost M Q ε ≤ entropicCost M Z ε ∧
        (entropicCost M Z ε = entropicCost M Q ε ↔ Z = Q)) ∧
      ∀ n, let u := rowIter K p w n
           let v := columnUpdate K u w
           let a := rowUpdate K v p
           let before := (∑ i, |u i * rowProduct K v i - p i|)/2
           let after := (∑ j, |v j * colProduct K a j - w j|)/2
           (before < (tol/4)/max d (1/(10:ℝ)^300) ∨ after < (tol/4)/c) →
           gap (plan K a v) Q / 2 < tol/4 := by
  let K := gibbs M ε
  let t := hi/lo
  obtain ⟨Q,hq,rq,fq,opt⟩ := optimal_scaling K p w hp hw sp sw lo hi hl box
  refine ⟨Q,fq,?_,?_⟩
  · intro Z fz
    simp only [cost_identity M _ ε hε,mul_le_mul_iff_right₀ hε,mul_right_inj' hε.ne']
    exact opt Z fz
  · intro n
    let u := rowIter K p w n
    have h := dense_checks K Q hq rq u (rowIter_pos K p w (fun i j => hl.trans_le (box i j).1)
      hp hw n) lo hi hl box
    dsimp only at h ⊢
    rw [fq.2.1,fq.2.2] at h
    have ht : 1 ≤ t := by
      obtain ⟨i⟩ := ‹Nonempty I›; obtain ⟨j⟩ := ‹Nonempty J›
      exact (one_le_div hl).2 ((box i j).1.trans (box i j).2)
    have cp : 0 < cap J := Nat.cast_pos.mpr (Nat.sub_pos_of_lt twoCols)
    have gp : 0 < geom t := by dsimp [geom]; linarith
    rintro (pre | post)
    · apply early_budget h.1 (div_nonneg (sum_nonneg fun _ _ => abs_nonneg _) (by norm_num))
        (le_max_left _ _) _ pre
      exact lt_of_lt_of_le (by positivity : 0 < 1/(10:ℝ)^300) (le_max_right _ _)
    · exact early_budget h.2 (div_nonneg (sum_nonneg fun _ _ => abs_nonneg _) (by norm_num))
        le_rfl (lt_min cp gp) post
end ScalingAudit
