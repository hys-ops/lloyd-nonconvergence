import HalfSteps

open Filter Finset
open scoped Topology
noncomputable section
namespace ScalingAudit
variable {I J : Type*} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

omit [Fintype I] [Fintype J] [Nonempty I] [Nonempty J] in
theorem related_trans {K P Q : Table I J} (h : Related K P) (g : Related P Q) : Related K Q := by
  obtain ⟨a,b,ha,hb,e⟩ := h
  obtain ⟨c,d,hc,hd,f⟩ := g
  exact ⟨fun i => c i*a i, fun j => b j*d j, fun i => mul_pos (hc i) (ha i),
    fun j => mul_pos (hb j) (hd j), fun i j => by rw [f,e]; ring⟩

omit [Fintype I] [Fintype J] [Nonempty I] [Nonempty J] in
theorem related_symm {P Q : Table I J} (h : Related P Q) : Related Q P := by
  obtain ⟨a,b,ha,hb,e⟩ := h
  exact ⟨fun i => (a i)⁻¹, fun j => (b j)⁻¹, fun i => inv_pos.mpr (ha i),
    fun j => inv_pos.mpr (hb j), fun i j => by rw [e]; field_simp [(ha i).ne',(hb j).ne']⟩

omit [Nonempty I] [Nonempty J] in
theorem entry_le_gap (P Q : Table I J) (i : I) (j : J) : |Q i j - P i j| ≤ gap P Q :=
  (single_le_sum (fun k _ => abs_nonneg (Q i k-P i k)) (mem_univ j)).trans
    (single_le_sum (fun l _ => sum_nonneg (fun k _ => abs_nonneg (Q l k-P l k))) (mem_univ i))

/-- A limit of positive diagonal scalings with strictly positive limiting margins
is itself positive and a diagonal scaling. No bounds on the scaling vectors are assumed. -/
theorem closed_scalings (K L : Table I J) (P : ℕ → Table I J) (hk : Positive K)
    (hP : ∀ n, Positive (P n)) (scale : ∀ n, Related K (P n))
    (lim : ∀ i j, Tendsto (fun n => P n i j) atTop (𝓝 (L i j)))
    (hr : ∀ i, 0 < row L i) (hc : ∀ j, 0 < row (tr L) j) :
    Positive L ∧ Related K L := by
  have cross (i l : I) (j m : J) :
      (L i j * L l m) * (K i m * K l j) = (L i m * L l j) * (K i j * K l m) := by
    apply tendsto_nhds_unique (((lim i j).mul (lim l m)).mul_const _)
    apply Tendsto.congr' _ (((lim i m).mul (lim l j)).mul_const _)
    apply Eventually.of_forall
    intro n
    obtain ⟨a,b,_,_,e⟩ := scale n
    dsimp only; simp only [e]; ring
  have nn i j : 0 ≤ L i j := ge_of_tendsto (lim i j) (Eventually.of_forall fun n => (hP n i j).le)
  have pos : Positive L := by
    intro i j
    by_contra! hz
    have z := le_antisymm hz (nn i j)
    obtain ⟨m,hm⟩ : ∃ m, 0 < L i m := by
      by_contra! h; exact not_le_of_gt (hr i) (sum_nonpos fun m _ => h m)
    obtain ⟨l,hl⟩ : ∃ l, 0 < L l j := by
      by_contra! h; exact not_le_of_gt (hc j) (sum_nonpos fun l _ => h l)
    have e := cross i l j m
    rw [z,zero_mul,zero_mul] at e
    exact (mul_pos (mul_pos hm hl) (mul_pos (hk i j) (hk l m))).ne' e.symm
  let i₀ : I := Classical.choice ‹Nonempty I›
  let j₀ : J := Classical.choice ‹Nonempty J›
  refine ⟨pos,fun i => L i j₀ / K i j₀, fun j => L i₀ j * K i₀ j₀ / (K i₀ j * L i₀ j₀),
    fun i => div_pos (pos _ _) (hk _ _), fun j => div_pos (mul_pos (pos _ _) (hk _ _)) (mul_pos (hk _ _) (pos _ _)), ?_⟩
  intro i j
  field_simp [(hk i j₀).ne',(hk i₀ j).ne',(pos i₀ j₀).ne']
  linarith only [cross i i₀ j j₀]

end ScalingAudit
