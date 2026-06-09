#!/usr/bin/env bash
# Behavioral test suite for the AxiomGuard linter.
#
# Asserts both registration paths:
#   - import-based fixtures under test/LeanExtensions/Test/ (linter loaded via `import`)
#   - the nested plugin-consumer package under test/consumer/ (linter loaded via `plugins :=`,
#     with NO import) — so we never claim support for an unexercised procedure.
#
# For each fixture we check the guard's distinctive substring ("non-standard axiom") in the
# `lake env lean` output, and that `lake build --wfail` fails iff a warning is expected.
#
# Run from the repo root:  test/run.sh
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
ROOT="$(pwd)"
pass=0; fail=0
GUARD_RE='non-standard axiom'

note() { printf '%s\n' "$*"; }
ok()   { note "PASS  $1"; pass=$((pass+1)); }
bad()  { note "FAIL  $1"; fail=$((fail+1)); }

# assert_guard <file> <expect: warn|silent> <label>
# Builds the file's library context via `lake env lean` and checks for the guard message.
assert_guard() {
  local file="$1" expect="$2" label="$3"
  local out; out="$(lake env lean "$file" 2>&1)"
  if printf '%s' "$out" | grep -q "$GUARD_RE"; then
    if [ "$expect" = warn ]; then ok "$label (guard fired)"; else bad "$label (guard fired, expected silent)"; printf '%s\n' "$out" | grep "$GUARD_RE"; fi
  else
    if [ "$expect" = silent ]; then ok "$label (guard silent)"; else bad "$label (guard silent, expected warning)"; fi
  fi
}

note "== import-based fixtures =="
# Ensure the linter lib and the shared Defs are built so imports resolve.
lake build LeanExtensions LeanExtensionsTests >/dev/null 2>&1
assert_guard test/LeanExtensions/Test/Good.lean     silent "Good (no non-standard axioms)"
assert_guard test/LeanExtensions/Test/Bad.lean      warn   "Bad (uses evil)"
assert_guard test/LeanExtensions/Test/Silenced.lean silent "Silenced (set_option linter.axiomGuard false in)"
assert_guard test/LeanExtensions/Test/Allowed.lean  silent "Allowed (benign allow-listed)"
assert_guard test/LeanExtensions/Test/Excluded.lean warn   "Excluded (benign allowed, evil still caught)"

note ""
note "== --wfail gate (CI enforcement) =="
# A bare-import build of the whole test lib must FAIL under --wfail (Bad+Excluded warn).
if lake build LeanExtensionsTests --wfail >/dev/null 2>&1; then
  bad "test lib under --wfail (expected failure, got success)"
else
  ok "test lib under --wfail fails the build"
fi

note ""
note "== plugin-consumer path (no import) =="
# The `plugins :=` wiring is only applied by `lake build` (which passes `--plugin` to lean), NOT
# by a bare `lake env lean`. So we assert against the build output: force a clean re-elaboration
# of the consumer module and check the guard message appears even though Consumer.lean has no
# `import LeanExtensions.AxiomGuard`.
consumer_out="$(
  cd test/consumer || exit 2
  touch Consumer.lean
  lake build 2>&1
)"
if printf '%s' "$consumer_out" | grep -q "$GUARD_RE"; then
  ok "consumer: guard fires via plugins:= with no import"
else
  bad "consumer: guard did NOT fire via plugin path"
  printf '%s\n' "$consumer_out"
fi
if ( cd test/consumer && lake build --wfail >/dev/null 2>&1 ); then
  bad "consumer under --wfail (expected failure, got success)"
else
  ok "consumer under --wfail fails the build"
fi

note ""
note "== LSP round-trip (guard diagnostics reach a language-server client) =="
# Requires `uv` (for leanclient). Skip with a notice if uv is unavailable rather than failing the
# whole suite on a missing optional tool.
if command -v uv >/dev/null 2>&1; then
  if test/lsp_diagnostics_test.py; then
    ok "LSP round-trip: guard diagnostic published to leanclient"
  else
    bad "LSP round-trip test failed"
  fi
else
  note "SKIP  LSP round-trip (uv not installed)"
fi

note ""
note "== $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
