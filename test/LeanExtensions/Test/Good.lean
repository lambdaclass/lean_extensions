import LeanExtensions.AxiomGuard

/-! Clean declarations using only standard axioms (or none). The guard must stay silent, so this
    file passes even under `-D warningAsError=true`. -/

namespace LeanExtensions.Test.Good

theorem rfl_ok : (1 : Nat) = 1 := rfl

-- Uses `propext` (a standard, allowed axiom): no warning expected.
theorem propext_ok (p q : Prop) (h : p ↔ q) : p = q := propext h

end LeanExtensions.Test.Good
