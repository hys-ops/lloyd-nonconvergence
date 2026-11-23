import GibbsStop

open Finset
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

def colProduct (K : Table I J) (u : I → ℝ) (j : J) := ∑ i, u i * K i j
def rowProduct (K : Table I J) (v : J → ℝ) (i : I) := ∑ j, K i j * v j
def plan (K : Table I J) (u : I → ℝ) (v : J → ℝ) : Table I J := fun i j => u i*K i j*v j
def columnUpdate (K : Table I J) (u : I → ℝ) (w : J → ℝ) (j : J) := w j / colProduct K u j
def rowUpdate (K : Table I J) (v : J → ℝ) (p : I → ℝ) (i : I) := p i / rowProduct K v i

omit [Fintype I] [Nonempty I] [Nonempty J] in
theorem plan_rows (K : Table I J) (u : I → ℝ) (v : J → ℝ) (i : I) :
    row (plan K u v) i = u i * rowProduct K v i := by simp [row,plan,rowProduct,mul_assoc,←mul_sum]
omit [Fintype J] [Nonempty I] [Nonempty J] in
theorem plan_cols (K : Table I J) (u : I → ℝ) (v : J → ℝ) (j : J) :
    row (tr (plan K u v)) j = v j * colProduct K u j := by simp [row,tr,plan,colProduct,←sum_mul,mul_comm (v j)]

/-- Exact products used by both early checks in _dense. Both conclusions concern
the same returned row-normalized plan. Q may be obtained from optimal_scaling. -/
theorem dense_checks (K Q : Table I J) (hq : Positive Q) (rq : Related K Q)
    (u : I → ℝ) (hu : ∀ i, 0 < u i) (lo hi : ℝ) (hl : 0 < lo)
    (bounds : ∀ i j, lo ≤ K i j ∧ K i j ≤ hi) :
    let p := row Q
    let w := row (tr Q)
    let v := columnUpdate K u w
    let newU := rowUpdate K v p
    let out := plan K newU v
    let t := hi/lo
    let before := (∑ i, |u i * rowProduct K v i - p i|)/2
    let after := (∑ j, |v j * colProduct K newU j - w j|)/2
    gap out Q/2 ≤ min (1+factor I t) (factor J t*rate t) * before ∧
    gap out Q/2 ≤ factor J t * after := by
  let p := row Q
  let w := row (tr Q)
  let v := columnUpdate K u w
  let a := rowUpdate K v p
  let P := plan K u v
  let F := plan K a v
  have hk : Positive K := fun i j => hl.trans_le (bounds i j).1
  have colp j : 0 < colProduct K u j := sum_pos (fun i _ => mul_pos (hu i) (hk i j)) univ_nonempty
  have vp j : 0 < v j := div_pos (row_pos (P:=tr Q) (fun j i => hq i j) j) (colp j)
  have rowp i : 0 < rowProduct K v i := sum_pos (fun j _ => mul_pos (hk i j) (vp j)) univ_nonempty
  have ap i : 0 < a i := div_pos (row_pos hq i) (rowp i)
  have pp : Positive P := fun i j => mul_pos (mul_pos (hu i) (hk i j)) (vp j)
  have cols : SameCols P Q := fun j => by
    rw [show row (tr P) j = v j * colProduct K u j from plan_cols _ _ _ _]
    exact div_mul_cancel₀ _ (colp j).ne'
  have scale : Related K P := ⟨u,v,hu,vp,fun _ _ => rfl⟩
  have h := (two_stops K P Q pp hq scale rq cols lo hi hl bounds).2
  have eq : fixRow P Q = F := by
    funext i j
    dsimp only [fixRow,F,P]
    rw [plan_rows]; dsimp [plan,a,rowUpdate,p]
    field_simp [(hu i).ne',(rowp i).ne']
  rw [eq] at h
  constructor
  · simpa only [err,P,plan_rows,abs_sub_comm (row Q _) (u _ * rowProduct K v _)] using h
  · have crossT : Cross (tr K) (hi/lo) := box_cross (tr K) lo hi hl (fun j i => bounds i j)
    have scaleF : Related (tr K) (tr F) := ⟨v,a,vp,ap,fun j i => by dsimp [tr,F,plan]; ring⟩
    have scaleQ : Related (tr K) (tr Q) := by
      obtain ⟨s,b,sp,bp,e⟩ := rq
      exact ⟨b,s,bp,sp,fun j i => by dsimp [tr]; rw [e]; ring⟩
    have exactRows : SameCols (tr F) (tr Q) := fun i => by
      change row (plan K a v) i = p i
      rw [plan_rows]; exact div_mul_cancel₀ _ (rowp i).ne'
    obtain ⟨i⟩ := ‹Nonempty I›; obtain ⟨j⟩ := ‹Nonempty J›
    have ht := (one_le_div hl).2 ((bounds i j).1.trans (bounds i j).2)
    have fpos : Positive (tr F) := fun j i => mul_pos (mul_pos (ap i) (hk i j)) (vp j)
    have final := plan_certificate (tr F) (tr Q) fpos (fun j i => hq i j)
      (related_trans (related_symm scaleF) scaleQ) exactRows _ ht (scaled_cross _ _ _ crossT scaleF)
    rw [gap_tr] at final
    simp only [err,F,plan_cols,abs_sub_comm (row (tr Q) _) (v _ * colProduct K a _)] at final
    change gap (plan K a v) Q/2 ≤ _ * ((∑ j, |v j * colProduct K a j - row (tr Q) j|)/2)
    linarith only [final]
end ScalingAudit
