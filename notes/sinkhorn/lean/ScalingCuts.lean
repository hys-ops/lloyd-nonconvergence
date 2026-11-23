import ManyRows

open Finset
noncomputable section
namespace ScalingAudit
variable {I J : Type*} [Fintype I] [Fintype J]
abbrev Table (I J : Type*) := I → J → ℝ
def row (P : Table I J) (i : I) := ∑ j, P i j
def tr (P : Table I J) : Table J I := fun j i => P i j
def gap (P Q : Table I J) := ∑ i, ∑ j, |Q i j - P i j|
def err (P Q : Table I J) := ∑ i, |row Q i - row P i|
def Positive (P : Table I J) := ∀ i j, 0 < P i j
def Related (P Q : Table I J) := ∃ (a : I → ℝ) (b : J → ℝ),
  (∀ i, 0 < a i) ∧ (∀ j, 0 < b j) ∧ ∀ i j, Q i j = a i * P i j * b j
def SameCols (P Q : Table I J) := ∀ j, row (tr P) j = row (tr Q) j
def cap (I : Type*) [Fintype I] : ℝ := (Fintype.card I - 1 : ℕ)

private lemma cut_upper (f : I → ℝ) (zero : ∑ i, f i = 0) (s : Finset I) :
    2 * ∑ i ∈ s, f i ≤ ∑ i, |f i| := by
  classical
  have e := s.sum_add_sum_compl f
  have l := Finset.sum_le_sum (s := s) (fun i _ => le_abs_self (f i))
  have r := Finset.sum_le_sum (s := sᶜ) (fun i _ => neg_le_abs (f i))
  rw [Finset.sum_neg_distrib] at r
  rw [←s.sum_add_sum_compl (fun i => |f i|)]
  linarith

/-- A column has a single sign change in the common row-weight order.
Every upper cut carries nonnegative flow. At most card(I)-1 cuts are needed. -/
theorem ordered_cut_bound [Nonempty I] (f : I → J → ℝ) (a : I → ℝ) (b : J → ℝ)
    (col : ∀ j, ∑ i, f i j = 0)
    (up : ∀ i j, b j ≤ a i → 0 ≤ f i j) (down : ∀ i j, a i ≤ b j → f i j ≤ 0) :
    (∑ i, ∑ j, |f i j|) ≤ cap I * ∑ i, |∑ j, f i j| := by
  classical
  obtain ⟨base, _, hbase⟩ := univ.exists_min_image a univ_nonempty
  let cuts := univ.erase base
  let S (h : I) := univ.filter (fun i => a h ≤ a i)
  let F (h : I) (j : J) := ∑ i ∈ S h, f i j
  have Fpos (h j) : 0 ≤ F h j := by
    by_cases v : b j ≤ a h
    · exact sum_nonneg fun i hi => up i j (v.trans (mem_filter.mp hi).2)
    · have neg := Finset.sum_nonpos (s := (S h)ᶜ) (fun i hi => down i j (by
        have n := mem_compl.mp hi
        exact (lt_of_not_ge (fun hi' => n (mem_filter.mpr ⟨mem_univ _, hi'⟩))).le.trans (le_of_not_ge v)))
      have z := (S h).sum_add_sum_compl (fun i => f i j)
      change 0 ≤ ∑ i ∈ S h, f i j
      linarith [col j]
  have each (j : J) : (∑ i, |f i j|) ≤ 2 * ∑ h ∈ cuts, F h j := by
    let T := univ.filter (fun i => b j ≤ a i)
    have val : (∑ i, |f i j|) = 2 * ∑ i ∈ T, f i j := by
      rw [← T.sum_add_sum_compl (fun i => |f i j|)]
      have p := sum_congr (s₁:=T) rfl (fun i hi => abs_of_nonneg (up i j (mem_filter.mp hi).2))
      have n := sum_congr (s₁:=Tᶜ) rfl (fun i hi => abs_of_nonpos (down i j (le_of_not_ge fun h =>
        (mem_compl.mp hi) (mem_filter.mpr ⟨mem_univ _, h⟩))))
      rw [p,n,sum_neg_distrib]
      linarith [T.sum_add_sum_compl (fun i => f i j), col j]
    rw [val]
    apply mul_le_mul_of_nonneg_left _ (by norm_num)
    by_cases ne : T.Nonempty
    · obtain ⟨h, hh, hm⟩ := T.exists_min_image a ne
      have eq : T = S h := by
        ext i
        exact ⟨fun hi => mem_filter.mpr ⟨mem_univ _, hm i hi⟩,
          fun hi => mem_filter.mpr ⟨mem_univ _, (mem_filter.mp hh).2.trans (mem_filter.mp hi).2⟩⟩
      rw [eq]
      by_cases hb : h = base
      · have all : S h = univ := by
          apply Finset.eq_univ_of_forall
          intro i
          exact mem_filter.mpr ⟨mem_univ _, hb ▸ hbase i (mem_univ _)⟩
        rw [all, col]
        exact sum_nonneg fun k _ => Fpos k j
      · exact single_le_sum (fun k _ => Fpos k j) (mem_erase.mpr ⟨hb,mem_univ _⟩)
    · rw [Finset.not_nonempty_iff_eq_empty.mp ne, sum_empty]
      exact sum_nonneg fun k _ => Fpos k j
  have total : (∑ i, ∑ j, f i j) = 0 := by rw [sum_comm]; simp [col]
  calc
    _ = ∑ j, ∑ i, |f i j| := sum_comm
    _ ≤ ∑ j, 2 * ∑ h ∈ cuts, F h j := sum_le_sum (fun j _ => each j)
    _ = ∑ h ∈ cuts, 2 * ∑ i ∈ S h, ∑ j, f i j := by
      simp only [F, mul_sum]
      rw [sum_comm]
      exact sum_congr rfl (fun _ _ => sum_comm)
    _ ≤ ∑ _h ∈ cuts, ∑ i, |∑ j, f i j| := sum_le_sum fun h _ => cut_upper _ total (S h)
    _ = _ := by simp [cuts, cap, nsmul_eq_mul]

theorem count_certificate [Nonempty I] (P Q : Table I J) (hp : Positive P)
    (rel : Related P Q) (cols : SameCols P Q) :
    gap P Q ≤ cap I * err P Q := by
  obtain ⟨a,b,ha,hb,e⟩ := rel
  have diff i j : Q i j - P i j = (a i - 1/b j) * (P i j * b j) := by
    rw [e]; field_simp [(hb j).ne']
  have h := ordered_cut_bound (fun i j => Q i j - P i j) a (fun j => 1/b j)
    (fun j => by rw [sum_sub_distrib]; exact sub_eq_zero.mpr (cols j).symm)
    (fun i j hij => by rw [diff]; exact mul_nonneg (sub_nonneg.mpr hij) (mul_pos (hp i j) (hb j)).le)
    (fun i j hij => by rw [diff]; exact mul_nonpos_of_nonpos_of_nonneg (sub_nonpos.mpr hij) (mul_pos (hp i j) (hb j)).le)
  simpa only [gap, err, row, sum_sub_distrib] using h
end ScalingAudit
