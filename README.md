# lean_extensions

Centrally-maintained Lean 4 compiler extensions, consumed by projects as a Lake **plugin**
dependency. Logic lives here once; downstream projects opt in with a `require` + `plugins :=` line
and get the behavior at `lake build` and `lake serve` time without importing anything.

## Extensions

### Axiom Guard (`LeanExtensions.AxiomGuard`)

A command linter that **warns** when a declaration depends on a non-standard axiom — anything
beyond `propext`, `Quot.sound`, `Classical.choice`. `sorry` is included (`sorryAx` is non-standard).

The guard only ever warns. Enforcement is decided by the build invocation:

| Where | Command | Behavior |
|---|---|---|
| Local / editor | `lake build` (or `lake serve`) | warning surfaced, build succeeds — `sorry` not blocked |
| CI | `lake build --wfail` | fails (exit 1) on any warning, including axiom violations |

Configuration:
- `set_option linter.axiomGuard false in <decl>` — silence for one declaration.
- `linter.axiomGuard.allowedAxioms` — comma/space-separated fully-qualified names allowed *in
  addition to* the standard ones. Set project-wide in the lakefile `leanOptions`, or per-file via
  `set_option`.

## Consuming this in a project (DSL lakefile)

```lean
require leanExtensions from git
  "https://github.com/lambdaclass/lean_extensions.git" @ "main"

@[default_target]
lean_lib «MyLib» where
  roots := #[`MyLib]
  plugins := #[leanExtensions.LeanExtensions]

-- optional project-wide allow-list:
-- leanOptions := #[⟨`linter.axiomGuard.allowedAxioms, "My.Interface.foundationAxiom"⟩]
```

`plugins :=` is only available in `lakefile.lean` (the DSL), not `lakefile.toml`. The library is
built with `precompileModules := true` so Lake compiles it to a shared library loadable via
`lean --plugin` — the consumer ships nothing but the `require`; Lake compiles it on demand.

## Notes

- Lean options cannot hold list values (`DataValue` is `String`/`Bool`/`Name`/`Nat`/`Int`/`Syntax`
  only), hence the comma/space-separated `String` for `allowedAxioms`.
- CI must cover Lean v4.20.0 through latest stable, plus the latest RC and nightly.
