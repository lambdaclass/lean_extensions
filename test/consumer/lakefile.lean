import Lake
open Lake DSL

-- Nested consumer project: a genuinely separate Lake package that depends on the guard by
-- relative path and loads it via `plugins :=` WITHOUT importing it. This exercises the real
-- consumption path an external project uses, so we never claim support for an unexercised
-- procedure. Versioned together with the guard in the same repo, but built as its own package.
package consumer

require leanExtensions from ".." / ".."

-- A Dynlib target that resolves to the guard library's shared object. `LeanExtensions` is the
-- `lean_lib` bound in the required package's lakefile; its `shared` facet builds the dynlib.
target axiomGuardPlugin : Dynlib := do
  let some lib ← findLeanLib? `LeanExtensions
    | error "could not find the `LeanExtensions` lean_lib in the required package"
  lib.shared.fetch

@[default_target]
lean_lib Consumer where
  plugins := #[axiomGuardPlugin]
  -- Project-wide allow-list for the guard, passed to `lean` as `-D` flags by `lake build`.
  -- Names must be fully qualified; the value exercises both separators (comma and space).
  -- This only works under `lake build` (which also passes `--plugin`, registering the option
  -- before CLI option validation) — a bare `lake env lean` would reject the unknown `-D` name.
  leanOptions := #[⟨`linter.axiomGuard.allowedAxioms, "Consumer.benign, Consumer.alsoBenign"⟩]
