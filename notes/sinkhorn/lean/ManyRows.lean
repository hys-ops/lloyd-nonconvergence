import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
open Finset
noncomputable section
namespace ManyRows
variable {I J : Type*} [Fintype I] [Fintype J]

/-- Binary odds bounded by t^2 imply the sharp one-sided TV estimate. -/
theorem odds_gap {p q t : ℝ} (hq : 0≤q) (ht : 1≤t)
    (hodds : p*(1-q)≤t^2*q*(1-p)) : p-q≤(t-1)/(t+1) := by
  have den : 0<t+1 := by linarith
  have cpos : 0<1+(t^2-1)*q := by
    have ht2 : 0≤t^2-1 := by nlinarith [sq_nonneg (t-1)]
    linarith [mul_nonneg ht2 hq]
  apply (le_div_iff₀ den).2
  by_contra! neg
  have a := mul_lt_mul_of_pos_right neg cpos
  have b := mul_le_mul_of_nonneg_right hodds den.le
  nlinarith only [a,b,mul_nonneg (sub_nonneg.mpr ht) (sq_nonneg ((t+1)*q-1))]

/-- Sum pairwise cross-ratio inequalities over an event and its complement. -/
theorem subset_gap [DecidableEq J] (p q : J → ℝ) (hq : ∀ j,0≤q j)
    (sp : ∑ j,p j=1) (sq : ∑ j,q j=1) (t : ℝ) (ht : 1≤t)
    (cross : ∀ i j,p i*q j≤t^2*q i*p j) (A : Finset J) :
    (∑ i ∈ A,p i)-(∑ i ∈ A,q i)≤(t-1)/(t+1) := by
  have h1 := Finset.sum_add_sum_compl A p
  have h2 := Finset.sum_add_sum_compl A q
  rw [sp] at h1; rw [sq] at h2
  apply odds_gap (Finset.sum_nonneg fun j _ => hq j) ht
  rw [show 1-(∑ j ∈ A,q j)=∑ j ∈ Aᶜ,q j by linarith,
      show 1-(∑ j ∈ A,p j)=∑ j ∈ Aᶜ,p j by linarith]
  have z := Finset.sum_le_sum (s:=A) (fun i _ =>
    Finset.sum_le_sum (s:=Aᶜ) fun j _ => cross i j)
  simpa only [← Finset.mul_sum,← Finset.sum_mul] using z

/-- Twice a row TV distance is twice the difference on its positive event. -/
theorem abs_sum_bound (p q : J → ℝ) (hq : ∀ j,0≤q j) (sp : ∑ j,p j=1) (sq : ∑ j,q j=1)
    (t : ℝ) (ht : 1≤t) (cross : ∀ i j,p i*q j≤t^2*q i*p j) :
    (∑ j,|p j-q j|)≤2*((t-1)/(t+1)) := by
  classical
  let A := univ.filter fun j => q j≤p j
  have hp (j) (hj : j∈A) : |p j-q j|=p j-q j :=
    abs_of_nonneg (sub_nonneg.mpr (mem_filter.mp hj).2)
  have hn (j) (hj : j∈Aᶜ) : |p j-q j|= -(p j-q j) := by
    apply abs_of_nonpos; apply sub_nonpos.mpr
    by_contra! h
    exact (mem_compl.mp hj) (mem_filter.mpr ⟨mem_univ _,h.le⟩)
  have total := Finset.sum_add_sum_compl A (fun j => p j-q j)
  have zero : (∑ i,(p i-q i))=0 := by rw [Finset.sum_sub_distrib,sp,sq,sub_self]
  rw [zero] at total
  rw [←Finset.sum_add_sum_compl A]
  rw [Finset.sum_congr rfl hp,Finset.sum_congr rfl hn,Finset.sum_neg_distrib]
  have bound := subset_gap p q hq sp sq t ht cross A
  rw [←Finset.sum_sub_distrib] at bound
  linarith

/-- Residual flow matched between rows controls the next marginal without a row count. -/
theorem paired_transfer (A : I → J → ℝ) (m k : I → I → ℝ) (hm : ∀ i l,0≤m i l)
    (hd : ∀ i l,(∑ j,|A i j-A l j|)≤2*k i l) :
    (∑ j,|∑ i,∑ l,m i l*(A i j-A l j)|) ≤ 2*(∑ i,∑ l,m i l*k i l) := by
  calc
    _ ≤ ∑ j,∑ i,∑ l,m i l*|A i j-A l j| := Finset.sum_le_sum fun j _ => calc
      _ ≤ ∑ i,|∑ l,m i l*(A i j-A l j)| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ _ := Finset.sum_le_sum fun i _ => by
        simpa only [abs_mul,abs_of_nonneg (hm _ _)] using
          Finset.abs_sum_le_sum_abs (fun l => m i l*(A i j-A l j)) Finset.univ
    _ = ∑ i,∑ l,m i l*(∑ j,|A i j-A l j|) := by
      rw [Finset.sum_comm]; apply Finset.sum_congr rfl; intro i _
      rw [Finset.sum_comm]; simp only [Finset.mul_sum]
    _ ≤ ∑ i,∑ l,m i l*(2*k i l) := Finset.sum_le_sum fun i _ =>
      Finset.sum_le_sum fun l _ => mul_le_mul_of_nonneg_left (hd i l) (hm i l)
    _ = _ := by simp only [Finset.mul_sum]; congr 1; funext i; congr 1; funext l; ring

/-- Finite tail: if remaining marginal corrections contract, cumulative plan movement is bounded. -/
theorem sum_corrections (e : ℕ → ℝ) (r : ℝ) (h1 : r<1)
    (next : ∀ n,e (n+1)≤r*e n) (positive : ∀ n,0≤e n) (n : ℕ) :
    (∑ i ∈ Finset.range n,e i) ≤ e 0/(1-r) := by
  have aux : ∀ m,(1-r)*(∑ i ∈ Finset.range m,e i)+e m≤e 0 := by
    intro m; induction m with
    | zero => simp
    | succ m ih => rw [Finset.sum_range_succ]; linarith only [next m,ih]
  apply (le_div_iff₀ (sub_pos.mpr h1)).mpr
  linarith only [aux n,positive n]


/-- Probability row mixtures contract by the largest pairwise row TV. -/
theorem mixture_gap (A : I → J → ℝ) (u v : I → ℝ)
    (hu : ∀ i,0≤u i) (hv : ∀ i,0≤v i) (su : ∑ i,u i=1) (sv : ∑ i,v i=1)
    (r : ℝ) (hd : ∀ i l,(∑ j,|A i j-A l j|)≤2*r) :
    (∑ j,|∑ i,(u i-v i)*A i j|)≤2*r := by
  have z := paired_transfer A (fun i l => u i*v l) (fun _ _ => r)
    (fun i l => mul_nonneg (hu i) (hv l)) hd
  have eq (j) : (∑ i,∑ l,u i*v l*(A i j-A l j)) = ∑ i,(u i-v i)*A i j := by
    simp only [mul_sub,sub_mul,Finset.sum_sub_distrib]
    congr 1
    · apply Finset.sum_congr rfl; intro i _
      simp_rw [show ∀ l,u i*v l*A i j=(u i*A i j)*v l by intro l; ring]
      rw [←Finset.mul_sum,sv,mul_one]
    · rw [Finset.sum_comm]; apply Finset.sum_congr rfl; intro l _
      simp_rw [show ∀ i,u i*v l*A l j=u i*(v l*A l j) by intro i; ring]
      rw [←Finset.sum_mul,su,one_mul]
  have sz : (∑ i,∑ l,u i*v l*r)=r := by
    simp_rw [mul_assoc,←Finset.mul_sum,←Finset.sum_mul,sv,su,one_mul]
  simpa only [eq,sz] using z

/-- Full signed zero-mass Dobrushin inequality, retaining the actual L1 residual. -/
theorem residual_contraction (A : I → J → ℝ) (d : I → ℝ) (zd : ∑ i,d i=0)
    (r : ℝ) (hd : ∀ i l,(∑ j,|A i j-A l j|)≤2*r) :
    (∑ j,|∑ i,d i*A i j|)≤r*(∑ i,|d i|) := by
  let a i := max (d i) 0
  let b i := max (-d i) 0
  let e := ∑ i,a i
  have ha i : 0≤a i := le_max_right _ _
  have hb i : 0≤b i := le_max_right _ _
  have diff i : d i=a i-b i := by dsimp [a,b]; rcases le_total 0 (d i) with h|h <;> grind
  have ab i : |d i|=a i+b i := by dsimp [a,b]; rcases le_total 0 (d i) with h|h <;> grind
  have sb : (∑ i,b i)=e := by
    have h := Finset.sum_congr (s₁ := Finset.univ) rfl (fun i _ => diff i)
    rw [Finset.sum_sub_distrib,zd] at h; dsimp [e]; linarith
  have total : (∑ i,|d i|)=e+e := by simp only [ab,Finset.sum_add_distrib,sb,e]
  have en : 0≤e := Finset.sum_nonneg fun i _ => ha i
  rcases eq_or_lt_of_le en with h|h
  · have za : ∀ i,d i=0 := by
      have eq := (Finset.sum_eq_zero_iff_of_nonneg (s:=Finset.univ) (fun i _ => abs_nonneg (d i))).mp
        (show (∑ i,|d i|)=0 by rw [total,←h,add_zero])
      exact fun i => abs_eq_zero.mp (eq i (Finset.mem_univ _))
    simp [za]
  · have nn := h.ne'
    have zz := mixture_gap A (fun i => a i/e) (fun i => b i/e)
      (fun i => div_nonneg (ha i) h.le) (fun i => div_nonneg (hb i) h.le)
      (by simp only [div_eq_mul_inv,←Finset.sum_mul]; exact mul_inv_cancel₀ nn)
      (by simp only [div_eq_mul_inv,←Finset.sum_mul,sb]; exact mul_inv_cancel₀ nn) r hd
    have scaled (j) : (∑ i,d i*A i j)=e*(∑ i,(a i/e-b i/e)*A i j) := by
      rw [Finset.mul_sum]; apply Finset.sum_congr rfl; intro i _; rw [diff i]; field_simp
    simp only [scaled,abs_mul,abs_of_pos h,←Finset.mul_sum,total]
    nlinarith only [mul_le_mul_of_nonneg_left zz h.le]

omit [Fintype I] [Fintype J] in
/-- Product diagonal scalings preserve the kernel cross-ratio inequalities. -/
theorem diagonal_cross (K : I → J → ℝ) (a : I → ℝ) (b : J → ℝ) (t : ℝ)
    (ha : ∀ i,0≤a i) (hb : ∀ j,0≤b j)
    (h : ∀ i l j m,K i j*K l m≤t^2*(K l j*K i m)) (i l : I) (j m : J) :
    (a i*K i j*b j)*(a l*K l m*b m) ≤ t^2*(a l*K l j*b j)*(a i*K i m*b m) := by
  have hh := mul_le_mul_of_nonneg_right (h i l j m)
    (mul_nonneg (mul_nonneg (ha i) (ha l)) (mul_nonneg (hb j) (hb m)))
  linarith only [hh]

/-- The initial-to-limit bound for any convergent chain of alternating corrections.
For plans use the total variation metric (or L1 throughout). -/
theorem limit_certificate {P : Type*} [PseudoMetricSpace P] (pi : ℕ → P) (pstar : P)
    (lim : Filter.Tendsto pi Filter.atTop (nhds pstar)) (e : ℕ → ℝ) (r : ℝ) (hr : r<1)
    (step : ∀ n,dist (pi n) (pi (n+1))≤e n)
    (decay : ∀ n,e (n+1)≤r*e n) :
    dist (pi 0) pstar≤e 0/(1-r) := by
  have tri : ∀ n,dist (pi 0) (pi n)≤∑ i ∈ Finset.range n,e i := by
    intro n; induction n with
    | zero => simp
    | succ n ih =>
      rw [Finset.sum_range_succ]
      exact (dist_triangle _ (pi n) _).trans (add_le_add ih (step n))
  exact le_of_tendsto (tendsto_const_nhds.dist lim)
    (Filter.Eventually.of_forall fun n => (tri n).trans
      (sum_corrections e r hr decay (fun j => dist_nonneg.trans (step j)) n))
/-- A Sinkhorn half-step, applicable to either orientation: the opposite marginal contracts. -/
theorem scaled_kernel_contraction (K : I → J → ℝ) (a : I → ℝ) (b : J → ℝ)
    (hk : ∀ i j,0≤K i j) (ha : ∀ i,0≤a i) (hb : ∀ j,0≤b j)
    (rows : ∀ i,∑ j,a i*K i j*b j=1) (t : ℝ) (ht : 1≤t)
    (cross : ∀ i l j m,K i j*K l m≤t^2*(K l j*K i m))
    (d : I → ℝ) (zd : ∑ i,d i=0) :
    (∑ j,|∑ i,d i*(a i*K i j*b j)|) ≤ ((t-1)/(t+1))*(∑ i,|d i|) := by
  apply residual_contraction _ d zd
  intro i l
  apply abs_sum_bound _ _ (fun j => mul_nonneg (mul_nonneg (ha l) (hk l j)) (hb j))
    (rows i) (rows l) t ht
  intro j m
  simpa only [mul_assoc] using diagonal_cross K a b t ha hb cross i l j m

/-- Exact plan movement when adjusting its row masses by d. -/
theorem correction_size (A : I → J → ℝ) (hA : ∀ i j,0≤A i j)
    (rows : ∀ i,∑ j,A i j=1) (d : I → ℝ) :
    (∑ i,∑ j,|d i*A i j|)=∑ i,|d i| := by
  apply Finset.sum_congr rfl
  intro i _
  simp only [abs_mul,abs_of_nonneg (hA i _),←Finset.mul_sum,rows,mul_one]
end ManyRows
