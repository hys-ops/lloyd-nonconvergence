import Alternation
import EntropicPlan

open Finset Filter Real
open scoped Topology
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

omit [Fintype I] [Fintype J] [Nonempty I] [Nonempty J] in
theorem box_cross (K : Table I J) (lo hi : ℝ) (hl : 0 < lo)
    (bounds : ∀ i j, lo ≤ K i j ∧ K i j ≤ hi) : Cross K (hi/lo) := by
  intro i l j m
  have hp i j := hl.trans_le (bounds i j).1
  have hn := (hp i j).le.trans (bounds i j).2
  calc
    _ ≤ hi*hi := mul_le_mul (bounds i j).2 (bounds l m).2 (hp l m).le hn
    _ = (hi/lo)^2*(lo*lo) := by field_simp
    _ ≤ _ := mul_le_mul_of_nonneg_left (mul_le_mul (bounds l j).1 (bounds i m).1 hl.le (hp l j).le) (sq_nonneg _)

omit [Fintype I] [Fintype J] [Nonempty I] [Nonempty J] in
theorem scaled_cross (K P : Table I J) (t : ℝ) (hc : Cross K t) (rel : Related K P) :
    Cross P t := by
  obtain ⟨a,b,ha,hb,rep⟩ := rel
  intro i l j m
  simp only [rep]
  exact (ManyRows.diagonal_cross K a b t (fun i => (ha i).le) (fun j => (hb j).le) hc i l j m).trans_eq
    (mul_assoc _ _ _)

omit [Nonempty I] in
theorem guard_factor (lo hi : ℝ) (hl : 0 < lo) :
    (if hi ≥ (2*cap I-1)*lo then cap I else (1+hi/lo)/2) = factor I (hi/lo) := by
  unfold factor geom
  split_ifs with h
  · rw [min_eq_left]
    have := (le_div_iff₀ hl).2 h
    linarith
  · rw [min_eq_right]
    · ring
    · have := (div_lt_iff₀ hl).2 (lt_of_not_ge h)
      linarith

theorem reciprocal_rate (lo hi : ℝ) (hl : 0 < lo) (hh : 0 < hi) :
    (1-lo/hi)/(1+lo/hi) = rate (hi/lo) := by
  unfold rate
  have p : hi+lo ≠ 0 := by linarith
  have q : lo+hi ≠ 0 := by linarith
  field_simp

/-- Existence of a positive scaling, attainment of the prescribed probability
margins, and unique global optimality, including nonnegative competitors. -/
theorem optimal_scaling (K : Table I J) (p : I → ℝ) (w : J → ℝ)
    (hp : ∀ i, 0 < p i) (hw : ∀ j, 0 < w j) (sp : ∑ i, p i = 1) (sw : ∑ j,w j = 1)
    (lo hi : ℝ) (hl : 0 < lo) (bounds : ∀ i j, lo ≤ K i j ∧ K i j ≤ hi) :
    ∃ Q : Table I J, Positive Q ∧ Related K Q ∧ feasible Q p w ∧
      ∀ Z, feasible Z p w → objective K Q ≤ objective K Z ∧ (objective K Z = objective K Q ↔ Z = Q) := by
  have hk : Positive K := fun i j => hl.trans_le (bounds i j).1
  let D : Table I J := fun i j => p i*w j
  have dp : Positive D := fun i j => mul_pos (hp i) (hw j)
  have dr i : row D i = p i := by simp [D,row,←mul_sum,sw]
  have dc j : row (tr D) j = w j := by simp [D,row,tr,←sum_mul,sp]
  let P : Table I J := fun i j => K i j * (w j / row (tr K) j)
  have zp j := row_pos (P:=tr K) (fun j i => hk i j) j
  have bpos j := div_pos (hw j) (zp j)
  have pp : Positive P := fun i j => mul_pos (hk i j) (bpos j)
  have kr : Related K P := ⟨fun _ => 1, _, fun _ => one_pos, bpos, by simp [P]⟩
  have col : SameCols P D := by
    intro j
    rw [dc]; simp only [row,tr,P,←sum_mul]
    change row (tr K) j * (w j / row (tr K) j) = w j
    field_simp [(zp j).ne']
  obtain ⟨i⟩ := ‹Nonempty I›
  obtain ⟨j⟩ := ‹Nonempty J›
  have ht := (one_le_div hl).2 ((bounds i j).1.trans (bounds i j).2)
  obtain ⟨Q,qp,pq,qc,qr,_⟩ := alternating_limit P D pp dp col _ ht
    (scaled_cross K P _ (box_cross K lo hi hl bounds) kr)
  have rows : row Q = p := qr.trans (funext dr)
  have cols : row (tr Q) = w := funext fun j => (qc j).trans (dc j)
  refine ⟨Q,qp,related_trans kr pq,⟨fun i j => (qp i j).le,rows,cols⟩, ?_⟩
  intro Z hz
  exact unique_minimum K Q Z hk qp (related_trans kr pq) (rows ▸ cols ▸ hz)

/-- Fast path's two different residual locations. The first certificate applies to P
and the second to the table returned after its next row update. -/
theorem two_stops (K P Q : Table I J) (hp : Positive P) (hq : Positive Q)
    (rp : Related K P) (rq : Related K Q) (cols : SameCols P Q)
    (lo hi : ℝ) (hl : 0 < lo) (bounds : ∀ i j, lo ≤ K i j ∧ K i j ≤ hi) :
    let t := hi/lo
    let e := err P Q/2
    gap P Q/2 ≤ factor I t * e ∧
    gap (fixRow P Q) Q/2 ≤ min (1+factor I t) (factor J t*rate t) * e := by
  obtain ⟨i⟩ := ‹Nonempty I›
  obtain ⟨j⟩ := ‹Nonempty J›
  have ht := (one_le_div hl).2 ((bounds i j).1.trans (bounds i j).2)
  have h := scaled_cross K P _ (box_cross K lo hi hl bounds) rp
  have rel := related_trans (related_symm rp) rq
  constructor
  · linarith only [plan_certificate P Q hp hq rel cols _ ht h]
  · linarith only [returned_plan P Q hp hq rel cols _ ht h]

/-- The implementation's strict budget comparison also works with a positive floor
on the multiplier in the denominator (the wide branch uses 1e-300). -/
theorem early_budget {E e c d tol : ℝ} (certificate : E ≤ c*e) (he : 0 ≤ e)
    (envelope : c ≤ d) (hd : 0 < d) (stop : e < (tol/4)/d) : E < tol/4 :=
  certificate.trans_lt ((mul_le_mul_of_nonneg_right envelope he).trans_lt
    (by simpa [mul_comm] using (lt_div_iff₀ hd).mp stop))

end ScalingAudit
