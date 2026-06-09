#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["leanclient>=0.10,<0.11"]
# ///
"""LSP round-trip test for the axiom guard.

Verifies that the extension's diagnostics actually reach a language-server client: it points
`leanclient` at the existing `test/consumer` project (which loads the guard via `plugins :=` with
no import) and asserts the guard's "non-standard axiom" warning is published for the declaration
that depends on the custom `evil` axiom — exactly what downstream tooling (e.g. lean4-toolkit's
lsp_utils) parses instead of `#print axioms` injection.

Reuses the consumer fixtures already tested by run.sh — no new project. The LSP server elaborates
*source* itself, but it cannot load a *plugin* whose shared library has not been built yet (the
dynlib is a build artifact); without it the file fatals before any diagnostic is published. So this
test ensures the consumer is built once (which fetches the dep and compiles the guard's dynlib)
before opening the client.

Run:  test/lsp_diagnostics_test.py     (PEP-723 inline deps; `uv run --script` provides leanclient)
Exit: 0 on success, 1 on assertion failure.
"""

import subprocess
import sys
from pathlib import Path

from leanclient import LeanLSPClient

HERE = Path(__file__).resolve().parent
CONSUMER = HERE / "consumer"

# Distinctive substrings emitted by LeanExtensions/AxiomGuard.lean.
GUARD_MARKER = "non-standard axiom"
# The consumer's fixtures (test/consumer/Consumer/Defs.lean + Consumer.lean): `evil`/`benign` are
# declared axioms; `uses_evil` depends on `evil`.
EXPECT_AXIOM = "evil"


def diagnostics_for(client: LeanLSPClient, rel: str):
    # Drain initial elaboration, then read the settled diagnostic set.
    client.get_diagnostics(rel, inactivity_timeout=10)
    return client.get_diagnostics(rel, inactivity_timeout=15).diagnostics


def main() -> int:
    if not (CONSUMER / "lakefile.lean").exists():
        print(f"FAIL: consumer project missing at {CONSUMER}")
        return 1

    # Plugin loading needs the guard's shared library compiled; build once if absent. This also
    # fetches the lean_extensions dependency. (The LSP elaborates source on its own, but cannot
    # load a not-yet-built plugin.)
    print("Building consumer (fetches dep + compiles the guard plugin)...")
    subprocess.run(["lake", "build"], cwd=CONSUMER, check=True)

    client = LeanLSPClient(str(CONSUMER), max_opened_files=4)
    failures = []

    # Consumer.lean depends on `evil` (no import of the guard — loaded via plugins:=).
    consumer_diags = diagnostics_for(client, "Consumer.lean")
    consumer_msgs = [d.get("message", "") for d in consumer_diags]
    guard_hits = [m for m in consumer_msgs if GUARD_MARKER in m]

    if not guard_hits:
        failures.append(
            f"expected a '{GUARD_MARKER}' diagnostic in Consumer.lean (guard loaded via plugins:=); "
            f"got messages: {consumer_msgs}"
        )
    elif not any(EXPECT_AXIOM in m for m in guard_hits):
        failures.append(
            f"guard fired but did not name '{EXPECT_AXIOM}'; guard diagnostics: {guard_hits}"
        )

    if failures:
        print("FAIL: LSP round-trip assertions failed:")
        for f in failures:
            print("  -", f)
        return 1

    print(f"PASS: guard '{GUARD_MARKER}' diagnostic published via LSP for Consumer.lean: {guard_hits}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
