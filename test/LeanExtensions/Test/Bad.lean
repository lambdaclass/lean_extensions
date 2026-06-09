import LeanExtensions.AxiomGuard
import LeanExtensions.Test.Defs

/-! A declaration depending on the custom non-standard postulate `evil`. The guard must warn, so
    `lake build --wfail` (or `-D warningAsError=true`) on this file must FAIL. No `sorry` is used,
    so the builtin "declaration uses 'sorry'" warning does not confound the assertion. -/

namespace LeanExtensions.Test.Bad

theorem uses_evil : (1 : Nat) = 2 := evil.elim

end LeanExtensions.Test.Bad
