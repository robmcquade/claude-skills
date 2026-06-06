# pressure-test — what is enforced vs judgment-grade

This skill deliberately splits its mechanisms into two layers. The point of the split is honesty:
the user must never be told a security-relevant artifact was rigorously tested when a critical step
silently relied on the model's discretion. Read this when you are unsure what the orchestrator
actually guarantees.

Design principle: *loading discipline is the wrong layer for rules whose failure produces durable
wrong output — those need enforcement at output time*, and *triggering is judgment, not
deterministic — a probabilistic safety net, not a hard guarantee.* The mechanisms whose failure
produces durable wrong output were moved off prose onto the script.

## ENFORCED (deterministic; owned by scripts/Invoke-PressureTest.ps1 in Mode B)

| Mechanism | How it is enforced | Failure it prevents |
|---|---|---|
| **Auto-escalation on sensitive content** | `Test-Sensitivity.ps1` regex/keyword/Luhn scan classifies HARD/SOFT signals; a HARD signal forces `deep`. The orchestrator re-runs the scan itself and the floor cannot be lowered by caller arguments. | A security/PII/credential artifact silently getting the shallow pass (F1/F2). |
| **Fail-closed on uncertainty / errors** | `uncertain` with no human resolution, an unreadable file, or a scan error all resolve to `deep + firewalled`. Never to `clean`/`standard`. | Under-testing because detection was ambiguous or failed. |
| **Deep panel cannot be under-sized** | The orchestrator errors (exit 2) if fewer than the required lenses are supplied for the resolved depth. | A "deep" run quietly running with 3 critics. |
| **Exactly one calibrated critic** | The orchestrator forces the count: promotes one if zero, strips extras if more than one; downgrades to uncalibrated (and flags it) if no standards slice is supplied. | Zero-calibrated (measures against generic best practice) or all-calibrated (no fresh-eyes baseline) (F9). |
| **Completion barrier + roll-call** | `Wait-Job` blocks on all critic subprocesses; each output must parse and carry `status:complete`; a FAILED critic retries once, then the run STOPS (`ok:false`) instead of synthesizing a partial set. | The verifier grading an incomplete finding set; a crashed critic read as a clean lens (F3/D1/D2). |
| **Schema-forced output** | Every critic/verifier runs `claude -p --json-schema <inline>`; the validated object returns in the envelope's `structured_output`. | Free-text findings that can't be reconciled or checked. |
| **Quote-existence check** | Only `artifact-quote` findings are substring-checked (`String.Contains`); non-matching ones auto-drop to `dropped_for_quote`. `artifact-absence` (a finding about something MISSING) and `external-source` (prior-art/web) findings bypass the check and go to the verifier, so genuine gaps and prior-art are not silently lost. Searcher (firewall stage B) findings are force-tagged `external-source` since the searcher has no artifact to quote. | Fabricated/misread findings reaching synthesis (persuasion-over-truth) — without nullifying absence/prior-art findings, which the substring check used to over-drop. |
| **Egress firewall on firewalled runs** | The web lens is split into a local-only abstractor (holds the artifact, `--disallowedTools WebSearch,WebFetch`) that emits scrubbed questions, and a searcher (`--disallowedTools Read,Grep,Glob`) that gets only the questions, never the artifact. Tool access is enforced by the CLI, not requested in prose. The skill's frontmatter sets `disallowed-tools: WebSearch, WebFetch`, which **blocks** those tools in the main session (deny rules take precedence; note `allowed-tools` would NOT block — an unlisted tool still falls through to the permission mode). So only the isolated searcher subprocess reaches the web. | Sensitive specifics (secrets, PII, client names, hostnames) leaving in a web query/URL — from a subprocess critic OR from the main context (F6). |
| **Independent verification** | The verifier is a separate fresh `claude -p` subprocess, not the synthesizing context re-grading what it absorbed. | Same-context bias re-importing the confirmation bias the fan-out exists to escape. |
| **KEPT + DOWNGRADED manifest with stable IDs and titles** | `manifest.json` lists `verifier_kept` and `verifier_downgraded` with ids and titles; the synthesis contract requires covering every id (downgraded at adjusted severity) and citing each `id — title` inline. | A KEPT Critical finding silently dropped in synthesis, or a DOWNGRADED finding vanishing entirely (F4/F06) — coverage is auditable against the manifest. |
| **Untrusted-artifact boundary** | Each subprocess gets `--append-system-prompt` instructing it to treat the artifact as DATA, never instructions. | Prompt injection from artifact content steering a critic. |

## JUDGMENT-GRADE (irreducibly the model's; the honest mitigation is disclosure, not a rigor claim)

These cannot be made deterministic by regex or schema. Trying to fake rigor here would reproduce the
exact false-reassurance the skill exists to prevent.

- **Semantic correctness of a critique** — whether a finding is actually *true* and *matters*. Mitigation: the independent verifier re-derives each from its quote; convergence is explicitly not treated as evidence.
- **Lens derivation quality** — whether the chosen lenses are the right ones for this artifact. Mitigation: derive-from-artifact-first ordering; one calibrated critic against the user's standards.
- **Sensitivity of genuinely novel content** — the detector catches known patterns/keywords; a never-before-seen sensitive shape may read as `clean`. Mitigation: SOFT keywords floor to `uncertain` → ask/deep; model judgment may only RAISE sensitivity above the deterministic floor, never lower it.
- **Scrubbing adequacy in the firewall** — whether the abstractor's questions are truly specifics-free. The artifact is structurally kept out of the searcher's context, but the abstractor still authors the questions. Mitigation (optional, not yet built): a `PreToolUse` hook that re-scans each outgoing web query with `Test-Sensitivity` and blocks a query that still trips a HARD signal — the deterministic backstop behind the structural firewall.
- **The final synthesis prose, and covering every surviving finding in it** — what reaches the user. The script produces the authoritative KEPT/DOWNGRADED manifest, but cannot police the model's final wording. Mitigation: the `id — title` coverage list makes omissions auditable against the manifest; it is not a mechanical gate.
- **Honestly relaying the user's choice on an `uncertain` verdict** — the script accepts `UncertainResolution='standard'` as the user's decision; it cannot verify the user actually said it. A lazy agent could self-assign `standard` and under-test. Mitigation: the blast radius is bounded — only SOFT-signal artifacts reach `uncertain` (a detected secret is HARD → forced deep, not downgradable), and unresolved/unattended uncertainty fails closed to deep. Whether the agent honestly reports the user's answer is the same floor as the mode probe.
- **Choosing to invoke the orchestrator at all (the mode probe / Step 0 entry)** — the script can only enforce what runs after it is called. Whether the agent runs the gate instead of hand-judging sensitivity, and whether it picks Mode B when a shell exists, is the one step upstream of all enforcement. Mitigation: the probe is deterministic (`Test-Path` on the bundled script) so the *answer* is factual, but *running* it is the agent's. This and the synthesis-coverage item are the two irreducible floor steps: everything between them is enforced; these two bookends are not.

## Mode A (no shell) — everything above is JUDGMENT-GRADE

On a surface without a shell (claude.ai web/mobile) none of the ENFORCED column runs. The skill must
lead with the degrade ("inline single-context pass — the enforced gate and fresh-eyes subprocesses did
not run; this is judgment-grade") and must self-apply the sensitivity judgment, the quote check, and
the no-artifact-in-web-search rule by hand. An inline pass presented as if it were enforced is itself a
failure mode.
