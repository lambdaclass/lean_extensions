-- NOTE: deliberately NO `import LeanExtensions.AxiomGuard`. The guard is loaded as a plugin via
-- the lakefile `plugins :=`. If the plugin path works, the linter fires on the declaration below
-- (which depends on a non-standard axiom) with no import at all.
import Consumer.Defs

namespace Consumer

theorem uses_evil : (1 : Nat) = 2 := evil.elim

end Consumer
