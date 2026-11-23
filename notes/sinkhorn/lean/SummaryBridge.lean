import PlanCertificate

open Finset
noncomputable section
namespace ScalingAudit

/-- Tensor interpolation by ordered composition. The local certificate is for
the original f in each coordinate; stability propagates the remaining errors. -/
structure Axis (X : Type*) where
  op : X → X
  stability : ℝ
  localError : ℝ
def tensorApply {X : Type*} (axes : List (Axis X)) (f : X) :=
  axes.foldr (fun a g => a.op g) f
def tensorError {X : Type*} : List (Axis X) → ℝ
  | [] => 0
  | a :: rest => a.localError + a.stability * tensorError rest

theorem tensor_bound {X : Type*} [PseudoMetricSpace X] (f : X) (axes : List (Axis X))
    (cert : ∀ a ∈ axes, 0 ≤ a.stability ∧ dist f (a.op f) ≤ a.localError ∧
      ∀ g, dist (a.op f) (a.op g) ≤ a.stability * dist f g) :
    dist f (tensorApply axes f) ≤ tensorError axes := by
  induction axes with
  | nil => simp [tensorApply,tensorError]
  | cons a rest ih =>
    obtain ⟨hn,hf,hop⟩ := cert a (by simp)
    exact (dist_triangle f (a.op f) (a.op (tensorApply rest f))).trans
      (add_le_add hf ((hop _).trans (mul_le_mul_of_nonneg_left (ih (fun q h => cert q (by simp [h]))) hn)))

variable {I J : Type} [Fintype I] [Fintype J]

/-- Event-level local error propagated to a signed summary marginal.
No sign constraint on the reconstructed rows or the summary nodes is required. -/
theorem summary_tv (qhat q : I → ℝ) (f : I → J → ℝ) (w E : J → ℝ)
    (hw : ∀ j, 0 ≤ w j) (total : ∑ i, qhat i = ∑ i, q i)
    (repr : ∀ i, qhat i-q i = ∑ j,w j * f i j)
    (events : ∀ (S : Finset I) j, (∑ i ∈ S, f i j) ≤ E j) :
    (∑ i, |qhat i-q i|)/2 ≤ ∑ j,w j * E j := by
  classical
  let d i := qhat i-q i
  let S := univ.filter fun i => 0 ≤ d i
  have mass : ∑ i,d i = 0 := by simp only [d,sum_sub_distrib,total,sub_self]
  have l1 : (∑ i,|d i|) = 2 * ∑ i ∈ S, d i := by
    rw [←S.sum_add_sum_compl (fun i => |d i|)]
    have pos := sum_congr (s₁:=S) rfl (fun i hi => abs_of_nonneg (mem_filter.mp hi).2)
    have neg := sum_congr (s₁:=Sᶜ) rfl (fun i hi => abs_of_nonpos (le_of_not_ge
      fun w => (mem_compl.mp hi) (mem_filter.mpr ⟨mem_univ _,w⟩)))
    rw [pos,neg,sum_neg_distrib]; linarith [S.sum_add_sum_compl d]
  have bound : (∑ i ∈ S,d i) ≤ ∑ j,w j*E j := by
    simp only [d,repr]; rw [sum_comm]
    exact sum_le_sum fun j _ => (by rw [←mul_sum]; exact mul_le_mul_of_nonneg_left (events S j) (hw j))
  change (∑ i,|d i|)/2 ≤ _
  linarith

/-- Combination with the actual finite-plan certificate. α may be the tensor
or a joint mixed-error budget supplied by the interpolation stage. -/
theorem summary_plan [Nonempty I] [Nonempty J] (P Q : Table I J) (hp : Positive P)
    (hq : Positive Q) (rel : Related P Q) (cols : SameCols P Q) (t : ℝ) (ht : 1 ≤ t)
    (hc : Cross P t) (qhat : I → ℝ) (α : ℝ) (proxy : (∑ i,|qhat i-row P i|)/2 ≤ α) :
    gap P Q/2 ≤ factor I t * ((∑ i,|row Q i-qhat i|)/2+α) := by
  have tri : err P Q ≤ (∑ i,|row Q i-qhat i|)+(∑ i,|qhat i-row P i|) := by
    rw [←sum_add_distrib]
    exact sum_le_sum fun i _ => by
      rw [show row Q i-row P i = row Q i-qhat i+(qhat i-row P i) by ring]
      exact abs_add_le _ _
  have fp : 0 ≤ factor I t := le_min (Nat.cast_nonneg _) (by unfold geom; linarith)
  have approx : err P Q ≤ (∑ i,|row Q i-qhat i|)+2*α := by linarith
  linarith only [(plan_certificate P Q hp hq rel cols t ht hc).trans (mul_le_mul_of_nonneg_left approx fp)]
end ScalingAudit
