import LeanExtensions.AxiomGuard
import LeanExtensions.Test.Defs

/-! Per-declaration silencing via `set_option linter.axiomGuard false in`. The guard must produce
    no warning, so this file passes under `-D warningAsError=true`. -/

namespace LeanExtensions.Test.Silenced

set_option linter.axiomGuard false in
theorem silenced_evil : (1 : Nat) = 2 := evil.elim

end LeanExtensions.Test.Silenced
