/-
Copyright (c) 2026 LambdaClass. All rights reserved.
Released under MIT OR Apache-2.0 license as described in the LICENSE files.
Authors: Mario Rugiero
-/
import Lean
open Lean Elab Command

/-!
# Axiom Guard

A command linter that warns when a declaration depends on a non-standard kind of unproven
assumption — anything beyond the three Lean considers standard (`propext`, `Quot.sound`,
`Classical.choice`). `sorry` is included, since `sorryAx` is itself non-standard.

The guard always emits **warnings**, never errors. Enforcement is left to the build invocation:
CI runs `lake build --wfail` (fail on any warning); local builds run plain `lake build` and stay
unblocked while `sorry` is in flight.

Configuration:
* `set_option linter.axiomGuard false in <decl>` — silence the guard for one declaration.
* `linter.axiomGuard.allowedAxioms` — comma/space-separated fully-qualified names to allow
  *in addition to* the standard ones. Set project-wide in the lakefile `leanOptions`, or per-file
  via `set_option`. Lets a project legitimately introduce one known assumption while still
  catching every other (spurious) one.
-/

namespace LeanExtensions.AxiomGuard

/-- The always-allowed standard axioms. -/
def standardAxioms : NameSet :=
  (NameSet.empty).insert ``Classical.choice |>.insert ``propext |>.insert ``Quot.sound

register_option linter.axiomGuard : Bool := {
  defValue := true
  descr := "warn when a declaration depends on a non-standard assumption \
    (beyond propext/Quot.sound/Classical.choice)"
}

register_option linter.axiomGuard.allowedAxioms : String := {
  defValue := ""
  descr := "extra fully-qualified names (comma/space separated) allowed in addition to \
    the standard ones"
}

/-- Parse the `allowedAxioms` option string into a `NameSet`, seeded with the standard ones. -/
def parseAllowed (s : String) : NameSet :=
  let tokens := (s.splitToList fun c => c == ',' || c == ' ').filterMap fun t =>
    let t := t.trim
    if t.isEmpty then none else some t.toName
  tokens.foldl (·.insert ·) standardAxioms

/-- Extract the fully-qualified name of the declaration introduced by `stx`, if it is a
declaration command. Resolves the `declId` against the current namespace. -/
def declNameOf? (stx : Syntax) : CommandElabM (Option Name) := do
  if stx.getKind != ``Lean.Parser.Command.declaration then return none
  let idStx := stx[1][1][0]
  let id := idStx.getId
  if id.isAnonymous then return none
  return some ((← getCurrNamespace) ++ id)

/-- The axiom-guard linter. Runs after each command; if the command introduced a declaration that
transitively depends on a non-allowed assumption, emits a warning at the command position.

`withSetOptionIn` peels any `set_option ... in` wrapper so that (a) the inner declaration is
inspected (the wrapper command has kind `Lean.Parser.Command.in`, not `declaration`, so it would
otherwise be skipped) and (b) `getOptions` reflects the per-declaration option overrides — which is
exactly how `set_option linter.axiomGuard(.allowedAxioms) ... in <decl>` is honored. -/
def axiomGuardLinter : Linter where
  run := Lean.withSetOptionIn fun stx => do
    let opts ← getOptions
    unless opts.get linter.axiomGuard.name linter.axiomGuard.defValue do return
    let allowed := parseAllowed (opts.get linter.axiomGuard.allowedAxioms.name "")
    let some declName ← declNameOf? stx | return
    unless (← getEnv).contains declName do return
    for ax in (← collectAxioms declName) do
      unless allowed.contains ax do
        -- When the flagged declaration IS the axiom being introduced, say so directly rather than
        -- the self-referential "X depends on forbidden X". Flagging the declaration site is
        -- intentional: it catches a new non-standard axiom the moment it is introduced (e.g. an
        -- agent slipping one in during proving), not only at later use sites.
        let msg :=
          if ax == declName then
            m!"`{declName}` introduces a non-standard axiom"
          else
            m!"`{declName}` depends on non-standard axiom `{ax}`"
        logWarningAt stx
          m!"{msg}\n\n\
            Allow it via `linter.axiomGuard.allowedAxioms`, \
            or silence with `set_option linter.axiomGuard false`."

initialize addLinter axiomGuardLinter

end LeanExtensions.AxiomGuard
