import Lake
open Lake DSL

package «leanExtensions»

@[default_target]
lean_lib «LeanExtensions» where
  -- Required so this library compiles to a native shared library loadable via `lean --plugin`
  -- (the mechanism that runs `initialize addLinter` before elaboration). Scoped to THIS lib —
  -- not the package — so the test libs are not treated as (invalid) plugins.
  precompileModules := true

-- Test fixtures for the AxiomGuard linter (import-based path). Each module imports the linter
-- directly; diagnostics are asserted by test/run.sh. The plugin-loading consumption path
-- (`plugins :=`, no import) is exercised separately by the nested package in test/consumer.
lean_lib «LeanExtensionsTests» where
  srcDir := "test"
  globs := #[.submodules `LeanExtensions.Test]
