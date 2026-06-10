-- NOTE: deliberately NO `import LeanExtensions.AxiomGuard`. The guard is loaded as a plugin via
-- the lakefile `plugins :=`. If the plugin path works, the linter fires on `uses_evil` below
-- (which depends on a non-allowed axiom) with no import at all. `uses_benign`/`uses_benign_also`
-- depend on axioms allow-listed project-wide via `leanOptions` in the lakefile, so they must stay
-- silent — exercising the lakefile configuration path of `linter.axiomGuard.allowedAxioms`.
import Consumer.Defs

namespace Consumer

theorem uses_evil : (1 : Nat) = 2 := evil.elim
theorem uses_benign : True := benign
theorem uses_benign_also : True := alsoBenign

end Consumer
