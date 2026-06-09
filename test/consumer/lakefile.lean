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
