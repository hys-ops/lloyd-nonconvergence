import PlanCertificate
import ScalingLimits

open Finset Filter
open scoped Topology
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

/-- One full round: correct rows, then columns, using the margins of D. -/
def roundStep (P D : Table I J) := tr (fixRow (tr (fixRow P D)) (tr D))
def iterate (P D : Table I J) : ℕ → Table I J
  | 0 => P
  | n+1 => roundStep (iterate P D n) D

private theorem round_data (P D : Table I J) (hp : Positive P) (hd : Positive D)
    (cols : SameCols P D) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    let T := roundStep P D
    Positive T ∧ SameCols T D ∧ Cross T t ∧ Related P T ∧
    err T D ≤ rate t * err P D ∧ gap P T ≤ (1 + rate t) * err P D := by
  let F := fixRow P D
  obtain ⟨h1,_,m1,c1,v1,e1⟩ := half_step P D hp hd cols t ht hc
  obtain ⟨h2,_,m2,c2,v2,e2⟩ := half_step (tr F) (tr D) h1 (fun j i => hd i j) m1 t ht c1
  have r := rate_range ht
  refine ⟨h2, m2, c2, ?_, ?_, ?_⟩
  · refine ⟨fun i => row D i / row P i, fun j => row (tr D) j / row (tr F) j,
      fun i => div_pos (row_pos hd i) (row_pos hp i),
      fun j => div_pos (row_pos (P:=tr D) (fun j i => hd i j) j) (row_pos h1 j), ?_⟩
    intro i j; dsimp [roundStep,fixRow,tr,F]; ring
  · exact e2.trans ((mul_le_mul_of_nonneg_right r.2.le (err_nonneg _ _)).trans_eq (one_mul _)
      |>.trans e1)
  · have bound := gap_triangle P F (roundStep P D)
    have second : gap F (roundStep P D) = err (tr F) (tr D) := by
      rw [←gap_tr]; exact v2
    rw [show gap P F = err P D from v1,second] at bound
    rw [add_mul,one_mul]
    exact bound.trans (add_le_add_right e1 _)

/-- Both prescribed margins are attained by the limit of the actual alternating updates.
The arbitrary positive table D specifies only the desired margins. -/
theorem alternating_limit (P D : Table I J) (hp : Positive P) (hd : Positive D)
    (cols : SameCols P D) (t : ℝ) (ht : 1 ≤ t) (hc : Cross P t) :
    ∃ L : Table I J, Positive L ∧ Related P L ∧ SameCols L D ∧ row L = row D ∧
      ∀ i j, Tendsto (fun n => iterate P D n i j) atTop (𝓝 (L i j)) := by
  let A := iterate P D
  have r := rate_range ht
  have invs (n : ℕ) : Positive (A n) ∧ SameCols (A n) D ∧ Cross (A n) t ∧ Related P (A n) ∧
      err (A n) D ≤ err P D * rate t ^ n := by
    induction n with
    | zero =>
      exact ⟨hp,cols,hc,⟨fun _ => 1,fun _ => 1,fun _ => one_pos,fun _ => one_pos,
        fun _ _ => by simp [A,iterate]⟩, by simp [A,iterate]⟩
    | succ n ih =>
      obtain ⟨h,c,x,s,b,_⟩ := round_data (A n) D ih.1 hd ih.2.1 t ht ih.2.2.1
      refine ⟨h,c,x,related_trans ih.2.2.2.1 s, b.trans ?_⟩
      calc
        _ ≤ rate t * (err P D * rate t ^ n) := mul_le_mul_of_nonneg_left ih.2.2.2.2 r.1
        _ = _ := by rw [pow_succ]; ring
  have conv i j : ∃ l : ℝ, Tendsto (fun n => A n i j) atTop (𝓝 l) := by
    apply cauchySeq_tendsto_of_complete
    apply cauchySeq_of_le_geometric (rate t) ((1+rate t)*err P D) r.2
    intro n
    have h := invs n
    have d := (round_data (A n) D h.1 hd h.2.1 t ht h.2.2.1).2.2.2.2.2
    rw [Real.dist_eq,abs_sub_comm]
    exact (entry_le_gap (A n) (A (n+1)) i j).trans (d.trans
      ((mul_le_mul_of_nonneg_left h.2.2.2.2 (by linarith only [r.1] : 0 ≤ 1+rate t)).trans_eq
        (mul_assoc _ _ _).symm))
  choose L lim using conv
  have cl j : row (tr L) j = row (tr D) j := by
    apply tendsto_nhds_unique (tendsto_finsetSum univ (fun i _ => lim i j))
    apply Tendsto.congr' _ tendsto_const_nhds
    exact Eventually.of_forall fun n => ((invs n).2.1 j).symm
  have rl i : row L i = row D i := by
    have rl' := tendsto_finsetSum univ (fun j _ => lim i j)
    have limit := ((tendsto_pow_atTop_nhds_zero_of_lt_one r.1 r.2).const_mul (err P D))
    have lower : ∀ n, |row D i - row (A n) i| ≤ err P D * rate t ^ n := fun n =>
      (single_le_sum (fun k _ => abs_nonneg (row D k-row (A n) k)) (mem_univ i)).trans (invs n).2.2.2.2
    have h := le_of_tendsto_of_tendsto ((tendsto_const_nhds.sub rl').abs) limit
      (Eventually.of_forall lower)
    change |row D i-row L i| ≤ err P D*0 at h
    rw [mul_zero] at h
    exact (sub_eq_zero.mp (abs_nonpos_iff.mp h)).symm
  have closed := closed_scalings P L A hp (fun n => (invs n).1) (fun n => (invs n).2.2.2.1)
    lim (fun i => (rl i) ▸ row_pos hd i)
    (fun j => (cl j) ▸ row_pos (P:=tr D) (fun j i => hd i j) j)
  exact ⟨L,closed.1,closed.2,cl,funext rl,lim⟩
end ScalingAudit
