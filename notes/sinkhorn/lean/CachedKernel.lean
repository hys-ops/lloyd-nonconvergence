import CacheReuse
import DenseChecks

open Finset
noncomputable section
namespace ScalingAudit
variable {I J : Type} [Fintype I] [Fintype J] [Nonempty I] [Nonempty J]

structure KernelValues (I J : Type) where
  matrix : Table I J
  firstColumns : J → ℝ
  columnFactor : ℝ
  propagatedFactor : ℝ

/-- The four mathematical payloads in the NumPy fast path, without guard/fallback
rounding. The first product uses the uniform initial row scaling for every solve. -/
def kernelValues (key : Table I J × ℝ) : KernelValues I J :=
  let K := gibbs key.1 key.2
  let S := (univ : Finset (I × J)).image (fun ij => K ij.1 ij.2)
  have hn : S.Nonempty := Finset.Nonempty.image univ_nonempty _
  let lo := S.min' hn
  let hi := S.max' hn
  let t := hi/lo
  ⟨K, colProduct K (fun _ => 1 / (Fintype.card I : ℝ)), factor J t,
    min (1+factor I t) (factor J t * rate t)⟩

theorem kernel_trace {Sig : Type} [DecidableEq Sig] [DecidableEq (Table I J × ℝ)]
    (signature : Table I J × ℝ → Sig) (calls : List (ReuseAudit.Call (Table I J × ℝ))) :
    ReuseAudit.run kernelValues signature calls none = ReuseAudit.fresh kernelValues calls :=
  ReuseAudit.trace_sound kernelValues signature calls
end ScalingAudit
