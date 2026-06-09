import LeanExtensions.AxiomGuard
import LeanExtensions.Test.Defs

/-! Allow-list, positive direction: `benign` is listed in `linter.axiomGuard.allowedAxioms`, so a
    declaration depending on it produces no warning and the file passes under `-D warningAsError=true`.
    The exclusion direction (a non-listed dependence still warns) is covered by `Excluded.lean`. -/

namespace LeanExtensions.Test.Allowed

set_option linter.axiomGuard.allowedAxioms "LeanExtensions.Test.benign" in
theorem allowed_benign : True := benign

end LeanExtensions.Test.Allowed
