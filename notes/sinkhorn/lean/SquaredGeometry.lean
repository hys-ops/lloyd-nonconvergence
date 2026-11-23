import GibbsStop

open Finset Real
noncomputable section
namespace ScalingAudit
variable {I J D : Type} [Fintype D]

def sqCost (x : I → D → ℝ) (y : J → D → ℝ) (i : I) (j : J) :=
  (∑ h,(x i h-y j h)^2)/2

theorem sq_cost_swap (x : I → D → ℝ) (y : J → D → ℝ) (i l : I) (j m : J) :
    sqCost x y i m + sqCost x y l j - sqCost x y i j - sqCost x y l m =
    ∑ h, (x i h-x l h)*(y j h-y m h) := by
  unfold sqCost
  rw [←add_div,←sub_div,←sub_div,div_eq_iff (by norm_num : (2:ℝ)≠0),sum_mul]
  simp only [←sum_add_distrib,←sum_sub_distrib]
  exact sum_congr rfl fun _ _ => by ring

/-- The implemented coordinate-width bound on the Gibbs odds ratio.
The widths can be obtained in linear time without constructing the pair table. -/
theorem squared_box_cross (x : I → D → ℝ) (y : J → D → ℝ) (dx dy : D → ℝ)
    (bx : ∀ i l h, |x i h-x l h| ≤ dx h) (by' : ∀ j m h, |y j h-y m h| ≤ dy h)
    (ε : ℝ) (he : 0 < ε) :
    Cross (gibbs (sqCost x y) ε) (exp ((∑ h,dx h*dy h)/(2*ε))) := by
  intro i l j m
  have upper := Finset.sum_le_sum (s:=univ) (fun h _ =>
    (le_abs_self ((x i h-x l h)*(y j h-y m h))).trans
      ((abs_mul _ _).le.trans (mul_le_mul (bx i l h) (by' j m h)
        (abs_nonneg _) ((abs_nonneg _).trans (bx i l h)))))
  rw [←sq_cost_swap] at upper
  unfold gibbs
  rw [pow_two,←exp_add,←exp_add,←exp_add,←exp_add,exp_le_exp]
  have pos : 0 < 2*ε := by linarith
  field_simp [he.ne']
  linarith only [upper]
end ScalingAudit
