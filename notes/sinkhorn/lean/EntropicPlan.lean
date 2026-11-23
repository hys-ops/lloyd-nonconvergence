import ScalingLimits
import Mathlib.InformationTheory.KullbackLeibler.KLFun

open Finset Real InformationTheory
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J]

def objective (K P : Table I J) := ∑ i, ∑ j, (P i j * (log (P i j) - log (K i j)) - P i j)

def feasible (P : Table I J) (p : I → ℝ) (w : J → ℝ) :=
  (∀ i j, 0 ≤ P i j) ∧ row P = p ∧ row (tr P) = w

private theorem scalar_kl (z q : ℝ) (hz : 0 ≤ z) (hq : 0 < q) :
    q * klFun (z/q) = z * (log z - log q) - z + q := by
  rcases eq_or_lt_of_le hz with h|h
  · simp [←h, klFun_zero]
  · rw [klFun_apply,log_div h.ne' hq.ne']; field_simp; ring

/-- Exact objective gap even when a competing feasible plan has zero entries. -/
theorem objective_gap (K Q Z : Table I J) (hk : Positive K) (hq : Positive Q)
    (scale : Related K Q) (hz : feasible Z (row Q) (row (tr Q))) :
    objective K Z - objective K Q = ∑ i, ∑ j, Q i j * klFun (Z i j / Q i j) := by
  obtain ⟨a,b,ha,hb,e⟩ := scale
  have dual i j : log (Q i j) - log (K i j) = log (a i) + log (b j) := by
    rw [e,log_mul (mul_pos (ha i) (hk i j)).ne' (hb j).ne', log_mul (ha i).ne' (hk i j).ne']; ring
  have zrow i : (∑ j,(Z i j - Q i j)) = 0 := by
    rw [sum_sub_distrib]; exact sub_eq_zero.mpr (congrFun hz.2.1 i)
  have zcol j : (∑ i,(Z i j - Q i j)) = 0 := by
    rw [sum_sub_distrib]; exact sub_eq_zero.mpr (congrFun hz.2.2 j)
  have cancel : (∑ i, ∑ j, (Z i j-Q i j)*(log (a i)+log (b j))) = 0 := by
    simp only [mul_add,sum_add_distrib]
    have h (i) : (∑ j, (Z i j - Q i j) * log (a i)) = 0 := by rw [←sum_mul,zrow,zero_mul]
    simp only [h,sum_const_zero,zero_add]
    rw [sum_comm]; simp_rw [←sum_mul,zcol,zero_mul]; exact sum_const_zero
  have cell (i j) :
      (Z i j*(log (Z i j)-log (K i j))-Z i j) - (Q i j*(log (Q i j)-log (K i j))-Q i j) =
      Q i j*klFun (Z i j/Q i j) + (Z i j-Q i j)*(log (a i)+log (b j)) := by
    rw [scalar_kl _ _ (hz.1 i j) (hq i j),←dual]; ring
  unfold objective
  simp only [←sum_sub_distrib,cell,sum_add_distrib,cancel,add_zero]

/-- The positive scaling uniquely minimizes the normalized entropic objective. -/
theorem unique_minimum (K Q Z : Table I J) (hk : Positive K) (hq : Positive Q)
    (scale : Related K Q) (hz : feasible Z (row Q) (row (tr Q))) :
    objective K Q ≤ objective K Z ∧ (objective K Z = objective K Q ↔ Z = Q) := by
  let c i j := Q i j * klFun (Z i j / Q i j)
  have h i j : 0 ≤ c i j := mul_nonneg (hq i j).le (klFun_nonneg (div_nonneg (hz.1 i j) (hq i j).le))
  have eq := objective_gap K Q Z hk hq scale hz
  change _ = ∑ i, ∑ j, c i j at eq
  refine ⟨sub_nonneg.mp (eq ▸ sum_nonneg fun i _ => sum_nonneg fun j _ => h i j), ?_⟩
  constructor
  · intro same
    have zero : (∑ i,∑ j,c i j) = 0 := by linarith
    funext i j
    have hi := (sum_eq_zero_iff_of_nonneg (s:=univ) (fun k _ => sum_nonneg fun j _ => h k j)).mp zero i (mem_univ i)
    have hj := (sum_eq_zero_iff_of_nonneg (s:=univ) (fun j _ => h i j)).mp hi j (mem_univ j)
    have one := (klFun_eq_zero_iff (div_nonneg (hz.1 i j) (hq i j).le)).mp
      ((mul_eq_zero.mp hj).resolve_left (hq i j).ne')
    exact (div_eq_one_iff_eq (hq i j).ne').mp one
  · rintro rfl; rfl
end ScalingAudit
