/- A pure value-level model of the v0.2.0 admission policy. The Key includes
cost values, dimensions and regularization. Inputs to a call are stable values;
the Python byte comparator, allocation and concurrent mutation are outside the model. -/
namespace ReuseAudit
variable {Key Sig Payload : Type}

structure Entry (Key Sig Payload : Type) where
  signature : Sig
  prepared : Option (Key × Payload)
  skip : Nat

abbrev Cache (Key Sig Payload : Type) := Option (Entry Key Sig Payload)

def valid (build : Key → Payload) : Cache Key Sig Payload → Prop
  | none => True
  | some entry => ∀ k v, entry.prepared = some (k,v) → v = build k

/-- A candidate signature can reject a hit but cannot approve one. Admission on
the second call always builds from the current key, even on a signature collision. -/
def dispatch [DecidableEq Key] [DecidableEq Sig] (build : Key → Payload)
    (signature : Key → Sig) (allowed : Bool) (c : Cache Key Sig Payload) (k : Key) :
    Cache Key Sig Payload × Payload :=
  let sig := signature k
  if !allowed then (c,build k)
  else match c with
  | none => (some ⟨sig,none,0⟩,build k)
  | some e =>
    if e.signature ≠ sig then (some ⟨sig,none,0⟩,build k)
    else if e.skip > 0 then (some {e with skip := e.skip-1},build k)
    else match e.prepared with
    | none => (some ⟨sig,some (k,build k),0⟩,build k)
    | some (saved,v) => if saved = k then (c,v) else (some ⟨sig,none,8⟩,build k)

theorem dispatch_sound [DecidableEq Key] [DecidableEq Sig] (build : Key → Payload)
    (signature : Key → Sig) (allowed : Bool) (c : Cache Key Sig Payload) (k : Key)
    (inv : valid build c) :
    let out := dispatch build signature allowed c k
    valid build out.1 ∧ out.2 = build k := by
  cases allowed with
  | false => exact ⟨inv,rfl⟩
  | true =>
    cases c with
    | none => simp [dispatch,valid]
    | some e =>
      dsimp [dispatch]
      split
      · simp [valid]
      · split
        · exact ⟨inv,rfl⟩
        · cases h : e.prepared with
          | none => simp [valid]
          | some v =>
            obtain ⟨s,p⟩ := v
            by_cases eq : s = k
            · subst k; simpa using And.intro inv (inv s p h)
            · simp [eq,valid]

/-- Stateful calls, including interleaved cache clears, produce exactly the
same payloads as cold builds for every key. An optional payload models fallbacks. -/
inductive Call (K : Type) where
  | clear
  | solve (allow : Bool) (key : K)

def run [DecidableEq Key] [DecidableEq Sig] (build : Key → Payload) (sig : Key → Sig) :
    List (Call Key) → Cache Key Sig Payload → List Payload
  | [], _ => []
  | .clear :: tail, _ => run build sig tail none
  | .solve allow k :: tail, c =>
    let out := dispatch build sig allow c k
    out.2 :: run build sig tail out.1

def fresh (build : Key → Payload) : List (Call Key) → List Payload
  | [] => []
  | .clear :: tail => fresh build tail
  | .solve _ k :: tail => build k :: fresh build tail

theorem trace_sound [DecidableEq Key] [DecidableEq Sig] (build : Key → Payload)
    (sig : Key → Sig) (calls : List (Call Key)) :
    run build sig calls none = fresh build calls := by
  suffices ∀ c, valid build c → run build sig calls c = fresh build calls from this none trivial
  induction calls with
  | nil => intros; rfl
  | cons a tail ih =>
    intro c hc
    cases a with
    | clear => exact ih none trivial
    | solve allow k =>
      obtain ⟨ok,same⟩ := dispatch_sound build sig allow c k hc
      simp only [run,fresh,same,ih _ ok]
end ReuseAudit
