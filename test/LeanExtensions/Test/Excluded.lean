import LeanExtensions.AxiomGuard
import LeanExtensions.Test.Defs

/-! Allow-list, exclusion direction: with `benign` listed in `linter.axiomGuard.allowedAxioms`, a
    declaration depending on the NON-listed `evil` must still warn. This proves the allow-list is
    a precise exception, not a blanket disable — `benign` is permitted while `evil` is still caught
    under the very same option. test/run.sh asserts a `forbidden ...evil` warning appears here. -/

namespace LeanExtensions.Test.Excluded

set_option linter.axiomGuard.allowedAxioms "LeanExtensions.Test.benign" in
theorem excluded_evil : (1 : Nat) = 2 := evil.elim

end LeanExtensions.Test.Excluded
