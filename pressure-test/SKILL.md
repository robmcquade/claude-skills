---
name: pressure-test
description: Stress-test substantive work — surface strengths, weaknesses, hidden assumptions, failure modes, and adjacent ideas, then return prioritized, actionable fixes (each weakness plus how to fix it). Recommends the fixes; does not produce the rewrite (that is /improve's job). User-invoked only. In Claude Code a deterministic orchestrator auto-escalates security, PII, and credential artifacts to deep, fans out fresh-context subprocess critics with schema-forced output, firewalls sensitive content away from web search, runs an independent verifier, and emits a verified findings manifest; without a shell it runs the same lenses inline and discloses that the enforced gate did not run. Use on durable artifacts (files, frameworks, memos, redlines, decisions, contracts, public content, prompts, proposals) and multi-step work where early choices constrain later ones. Apparent narrowness ('just review this') can mask real stakes. Skip single-fact lookups and content already endorsed and ready to execute.
argument-hint: "[deep] [optional: the target/goal to test against]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, PowerShell
disallowed-tools: WebSearch, WebFetch
---

# Pressure-Test

Stress-test substantive work and come back with **both diagnosis and prescription** — strengths, weaknesses, hidden assumptions, failure modes, adjacent ideas, and **prioritized, actionable improvement recommendations** (for each weakness, a specific fix). This skill **recommends** the fixes and leaves the decision and execution with you; `/improve` **produces** the rewritten artifact. Natural pipeline — `/pressure-test` to find and prescribe → `/improve` to execute.

**User-invoked only** (`disable-model-invocation: true`) — fanning out a critic panel is deliberate, never automatic.

## Why this skill is built on a script, not on prose

Critical mechanisms here would be unreliable if they relied on the model remembering to follow instructions. The design principle: *loading discipline is the wrong layer for rules whose failure produces durable wrong output — those need enforcement at output time*, and *triggering is judgment, not deterministic — a probabilistic safety net, not a hard guarantee.* A security artifact reviewed at shallow depth, a verifier that grades an incomplete finding set, or a fabricated quote reaching synthesis are all **durable wrong outputs**. So in Claude Code those mechanisms are owned by a deterministic orchestrator (`scripts/Invoke-PressureTest.ps1`), and the model does **judgment inside the gates** the script enforces. What is enforced versus judgment-grade is spelled out in `references/enforcement-model.md` — read it if you are unsure what the script guarantees.

**The floor this cannot cross:** three steps are irreducibly yours, because they sit before, inside, and after the script — *choosing to invoke the orchestrator at all* (the mode probe); *honestly relaying the user's choice* when an `uncertain` verdict is resolved to `standard` (you must not self-assign it); and *covering every surviving finding in your final synthesis*. No skill text can force a reading agent to do any of these; the script guarantees everything else. They are judgment-grade by nature, not oversights — marked as such here and in `enforcement-model.md` so the skill never implies more enforcement than it has. (The relay's blast radius is bounded: only SOFT-signal artifacts ever reach `uncertain`; a *detected* secret is HARD → `sensitive` → forced deep, which no relay can downgrade.)

## Path convention used below

The commands below reference bundled scripts via `${CLAUDE_SKILL_DIR}` — the Claude Code substitution for this skill's own directory, resolved into the text before you read it (so it is correct regardless of machine, user, or working directory; it is not a shell variable and does not need to persist between calls). The bundled scripts locate their own siblings, so you only need the script path right. Shell state does NOT carry between separate tool calls — never rely on a variable set in one command being present in the next; each command below is self-contained.

## Two modes — chosen by a probe, not a guess

Which mode you are in is an observable fact, not a preference. Probe it: run this via the **PowerShell tool** (the skill's own front door — getting here right is your judgment, the one irreducible step the script cannot own for you):
```
Test-Path "${CLAUDE_SKILL_DIR}\scripts\Invoke-PressureTest.ps1"
```
- **Returns `True` → Mode B (orchestrated).** The default in Claude Code: a shell exists AND the bundled scripts are reachable. The script owns the gate, fan-out, barrier, quote-check, verifier, and manifest. Follow Steps 0–3.
- **The PowerShell tool is unavailable, or the command itself cannot run → Mode A (inline).** Fallback for surfaces without a shell (claude.ai web/mobile). The enforced gate cannot run; you run the lenses single-context AND disclose the degrade. See the Inline procedure near the end.
- **Returns `False` (the shell ran but the script is not there) → broken install, not "no shell."** Report that the bundled scripts are not reachable at `${CLAUDE_SKILL_DIR}` and stop — do not substitute a degraded inline pass for a broken Mode B install.

**A broken Mode B is not Mode A.** If the probe returns `True` but a later gate/orchestrator command *errors* (crashes, or returns no JSON), surface the full error and **STOP** — do not silently fall back to inline. Degrading a real failure to a judgment-grade pass is the exact false-reassurance this skill exists to prevent.

The fan-out exists because same-context self-critique restates and justifies the reasoning that produced the artifact (confirmation bias). Fresh subprocess critics never saw that reasoning, so they critique the thing, not the story behind it.

---

## Step 0 — Identify the target, run the gate, disclose (Mode B)

1. **Identify the artifact under test.** Use what the user named or pasted. If nothing was named, default to the most recent durable artifact produced or edited in this session — and **open it and quote its first line** as proof-of-target before proceeding (never infer a file's contents from its name). Name your pick so the user can redirect. If nothing was named AND the session produced no durable artifact, **do not dispatch — ask the user what to test.**

2. **State the target** in one line: what this artifact is trying to achieve — its purpose, audience, and the bar it must clear. If the user passed a goal argument, use it. A vague target produces vague critique; pin it down.

3. **Run the gate (do not skip — this is the auto-escalation).** The gate is deterministic; you do not judge sensitivity yourself. Run:
   ```
   & "${CLAUDE_SKILL_DIR}\scripts\Test-Sensitivity.ps1" -Path '<artifact path>' -Json
   ```
   Prefer `-Path` always: for a pasted artifact, save it to a temp file by pasting it into a literal here-string piped to `Set-Content`, then point `-Path` at that file — this avoids the quoting hazards `-Text` hits on multi-line or quote-containing content:
   ```
   @'
   <paste the artifact text here>
   '@ | Set-Content "$env:TEMP\pt-artifact.txt"
   ```
   Add `-Partial` if you may be holding only an excerpt — concretely: the content was pasted with no confirmed file path; it references sections/headings not present in what you hold; you read only a line-range of a file; or the Read tool reported truncation on a large file. Read the `verdict`:
   - **`sensitive`** → the run will be forced to **deep + firewalled**, regardless of args. Do not try to override it.
   - **`clean`** → depth is `deep` if the user typed `deep`, else `standard`; egress open.
   - **`uncertain`** → resolve it now (this is the one allowed question in an otherwise non-blocking flow). Note `uncertain` means only SOFT topic signals matched — a *detected* secret/PII pattern is HARD → `sensitive` → forced deep, which this path cannot reach or downgrade:
     - **Human present:** ask once, defaulting to deep — *"This looks like it may touch &lt;signal&gt;; running deep unless you say standard."* Pass their answer to Step 2 as `UncertainResolution = 'deep'` or `'standard'`. Passing `'standard'` asserts the user actually chose it — do not self-assign it (that relay is on the judgment floor; see the floor note above).
     - **Unattended** (a `/goal`, `/loop`, or scheduled run with no one to ask — and whenever you cannot tell whether a human is present): do not block. Pass `Unattended = $true` to Step 2; the script auto-escalates uncertain to deep + firewalled and logs it. (The orchestrator re-runs the gate and fails closed to deep+firewall on unresolved uncertainty anyway, so forgetting cannot cause under-testing.)

4. **Disclose the depth and why in one line, then proceed in the same turn** — the spend disclosure does not wait for approval (only the uncertain question above can pause the flow). Example: *"Gate: sensitive (matched aws-access-key-id) → deep, 5 critics + verifier, web-firewalled. Escape if that's more than you want."* The user can still interrupt.

## Step 1 — Derive artifact-specific lenses (derivation first; the library is a backstop)

Generic roles produce generic critique. **Derive the lenses from this artifact**, then fill to the panel size the gate set (`standard` = 3, `deep` = 4–5; default 5 on deep, drop to 4 only if the 5th would be padding).

1. **First, write the 1–3 lenses that come from THIS artifact's specific risk surface** — the things that would actually make *this* work fail at its purpose.
2. **Then** fill remaining slots from the library only to cover real risks your derived lenses miss — never pad a slot with a lens that has no real risk to chase:
   - **Steelman-then-attack** — state the strongest version, then find where even that breaks.
   - **Failure modes in practice** — implementation friction, drift, adoption failure, second-order effects.
   - **Hidden assumptions & gaps** — what is smuggled in unstated; what is missing that its purpose requires.
   - **Adjacent ideas & alternatives** — what near this work strengthens it; what a different approach does better.
   - **Prior art / does-this-exist** — has this been done capably (your own decisions log first, then the field)? This is the **web lens** (`"web": true`); on a firewalled run the script isolates it (below).
   - **Skeptical stakeholder** — what a hostile operator, lawyer, CFO, or customer would say.

3. **Calibration — exactly one critic carries the standards slice.** If you keep a standards source — a writing-standards doc, a decisions log, a house-style or preferences file, a project's `CONTRIBUTING.md` — read the slice relevant to this artifact, write it to a file (e.g. `$env:TEMP\pt-standards.txt`), and pass it as `StandardsPath` so one critic judges against *your* bar rather than generic best practice. The other critics stay pure fresh-eyes. If you keep no such source, or none is relevant to this artifact, say so and omit `StandardsPath` — the script runs the panel uncalibrated and flags it. (The script caps calibration at one critic: exactly one when you pass `StandardsPath`, zero when you omit it — never more than one.)

4. **Write the lenses to a JSON file** (e.g. `$env:TEMP\pt-lenses.json`) — an array of `{ "name", "mandate", "web": bool, "calibrated": bool }`. Mark the prior-art lens `"web": true`; mark one lens `"calibrated": true`.

## Step 2 — Run the orchestrator (Mode B)

Build the argument set as a hashtable and splat it — copy-paste-safe, no fragile line continuations. Include only the optional keys that apply (switches are set to `$true`; omit otherwise):

```
$ptArgs = @{
    ArtifactPath        = '<artifact path>'        # or  ArtifactText = '<...>'
    Target              = '<the one-line target>'
    LensesPath          = '<lenses.json>'
    StandardsPath       = '<standards-slice.txt>'  # omit key entirely if nothing relevant
    Partial             = $true                    # only if you passed -Partial to the gate in Step 0
    UncertainResolution = 'deep'                   # or 'standard' — ONLY on an uncertain verdict a human actually resolved
    Unattended          = $true                    # only for an unattended run
    UserDeep            = $true                    # only if the user typed `deep` on a clean artifact
    # Model             = 'sonnet'                 # uncomment to pin a model; omitted = inherit the session model
}
& "${CLAUDE_SKILL_DIR}\scripts\Invoke-PressureTest.ps1" @ptArgs
```
The orchestrator **prints the complete manifest JSON to stdout** — that output lands in your context as the tool result, so you read the verdict and findings directly from it in Step 3. Do NOT rely on a `$manifest` shell variable surviving to the next step; shell state does not carry between tool calls. (The script also writes the manifest to a unique temp dir named in the JSON's `outdir` field, if you ever need the file.) Omit `OutDir` so each run gets its own collision-free directory. **Hygiene on a sensitive run:** the working directory holds per-critic prompt files that contain the artifact, and any temp file you wrote for a pasted artifact holds it too — delete both when done (`Remove-Item -Recurse` the `outdir` named in the JSON, plus `$env:TEMP\pt-artifact.txt` if you created it), so sensitive content does not linger in temp.

The script then **owns the parts that must not be left to judgment** and you do not re-implement them:

- **Gate** — re-runs the sensitivity scan and **forces deep + firewall on a sensitive (or uncertain-escalated) verdict**; the floor cannot be lowered by your arguments, and a `deep` panel cannot be under-sized (it errors if you supply too few lenses).
- **Fan-out** — spawns each lens as a fresh `claude -p` subprocess (stronger fresh context than an in-session subagent) with **schema-forced JSON output**.
- **Firewall** (firewalled runs — a sensitive verdict, or an uncertain verdict escalated to deep) — the web lens is split: a **local-only abstractor** holds the artifact, contributes its own local prior-art findings, AND emits *scrubbed* research questions; a **separate searcher** that never sees the artifact answers those questions with web search. Artifact content never reaches a web query. Tool access is enforced with `--disallowedTools`, not asked.
- **Barrier + roll-call** — blocks until all critics return; a critic that errors or returns invalid JSON **retries once, then the run STOPS** rather than synthesizing a partial result. A verifier that fails to return valid JSON stops the run immediately (it is not retried) — an unverified finding set is never delivered.
- **Quote-check** — every `artifact-quote` finding's quote must be a verbatim substring of the artifact, or it is **auto-dropped**. (`artifact-absence` and `external-source` findings bypass the substring check and go to the verifier — so "what's missing" and prior-art findings are not lost.)
- **Verifier** — one independent fresh subprocess re-grades the pooled findings KEEP/DOWNGRADE/DROP.
- **Manifest** — writes the authoritative result (`manifest.json`) including the **KEPT and DOWNGRADED findings with stable IDs and titles**, what was dropped (and why), soft lenses, and the synthesis contract.

Two failure shapes, both → **do not synthesize**: (1) the printed JSON has `ok:false` — it carries an `error` string and, where relevant, a `failed` list of critic ids; quote `error`, name the failed component, stop. (2) the command printed no JSON or exited non-zero (a crash) — there is no `error` field to quote; surface the raw stdout/stderr you received and stop.

## Step 3 — Synthesize from the manifest and deliver (paced)

Work from the manifest JSON the orchestrator printed in Step 2 (it is in your context as the tool result; re-read the file at the JSON's `outdir` only if you need it). Your synthesis should account for every finding in `verifier_kept` AND `verifier_downgraded` (the latter at its adjusted severity). This coverage is **your discipline, not a mechanical gate** — the script cannot police your final prose — but the manifest makes any omission auditable: cite each finding inline as `id — title` next to the recommendation that addresses it (a bare id list proves mention, not coverage), and close by listing the covered ids so a reader can diff them against the manifest.

**Turn 1 (orientation — then stop):** lead with **Strengths** (1–2 lines), the ranked **Weaknesses** headline (the KEPT Critical/Should-fix findings, each evidenced in a line), and the **single highest-leverage change**. Note honestly any findings the verifier dropped as over-reach, and any **soft lenses** the manifest flagged. Then stop and offer 2–3 specific threads to pull.

**On the user's chosen thread (expand):** Gaps (what's missing for the target) · Recommended improvements, ordered by leverage (for each KEPT/downgraded weakness, a specific actionable fix; invert weakness→strength where possible; name any risk that can't be cleanly mitigated) · Adjacencies.

You hand over the **prescription** — you do **not** return a rewritten artifact. If the user wants the stronger version produced, point them to `/improve` (or offer to run it on these recommendations).

---

## Inline procedure (Mode A — no shell, e.g. claude.ai)

The enforced gate and orchestrator cannot run here. Lead with the degrade, plainly: **"Inline single-context pass — the enforced gate, the fresh-eyes subprocesses, and calibration against your standards did not run; this is judgment-grade."** And if this is an **unattended** run (a `/goal` or scheduled pass with no human watching) on a no-shell surface, do not produce a judgment-grade pass at all — say the enforced flow cannot run here and stop.

1. **Judge sensitivity yourself** (you have no detector): if the artifact plausibly touches security, secrets, credentials, or PII, treat it as **sensitive**. When in doubt, treat as sensitive.
2. **No web search in Mode A — skip the prior-art web lens entirely** (say you skipped it). There is no firewall here, so reason only from what you already know; never put artifact specifics into a query. (This matches the skill's `disallowed-tools` intent; do not rely on the artifact being non-sensitive to justify a search.)
3. **Derive 2–3 lenses** (Step 1) — fewer than Mode B by design; one context can't hold more cleanly. This is the deliberate depth-over-breadth tradeoff for losing fresh eyes. For a sensitive artifact, spend the depth on the security/exposure lenses specifically rather than just adding count.
4. For each lens in turn, adopt a skeptical reviewer stance against the artifact + target, writing findings to working notes (cite a verbatim quote per finding, or name what is missing; rate severity; give a fix). Hold each lens separately.
5. **Verify your own findings** with a fresh, skeptical re-read: drop misreads and any quoted finding whose quote you can't locate in the artifact; dedupe; flag any lens that found nothing.
6. **Synthesize** using Step 3's *delivery shape* — orientation first (strengths, ranked weaknesses, single highest-leverage change), then expand on the user's chosen thread — but from your working notes, not a manifest (there is none in Mode A). Inline loses the fresh-eyes guarantee and the mechanical quote-check; compensate by being harder on yourself, not softer — and keep the degrade disclosure visible.

## Optional — unattended autonomy via `/goal`

`/goal` is a separate outer-loop layer. This skill does not depend on it. For an unattended **Mode B** pass, call the orchestrator with `Unattended = $true` (uncertain verdicts auto-escalate to deep+firewall rather than blocking on a question), and surface your synthesis into the main transcript so the evaluator can judge it. An unattended pass on a surface with **no shell** cannot run the enforced flow at all — say so and stop rather than presenting a judgment-grade inline pass as if it were gated. Per the scheduling rule, an unattended run must finish well before 5:00 AM Pacific.

## Composition

- **With `/improve`:** opposite contracts — pressure-test recommends, improve produces. Pipeline them: test → improve.

## Failure modes for this skill

- **Skipping the gate** (Mode B) — setting depth by hand instead of letting `Test-Sensitivity` set it. The gate is the auto-escalation; run it.
- **Treating an inline pass as enforced** — Mode A has no gate and no fresh eyes; if you don't disclose that, the user is falsely reassured. Always lead with the degrade.
- **Silently degrading a broken Mode B to Mode A** — a gate/orchestrator error means stop and surface, not fall back.
- **Sensitive content into a web query** — only a risk in Mode A. In Mode B the main session is denied `WebSearch`/`WebFetch` via `disallowed-tools` (deny rules block, unlike `allowed-tools`), and only the isolated searcher subprocess — which never sees the artifact — reaches the web. In Mode A you have no such guard, so skip the search on sensitive artifacts.
- **Generic critique** — lenses picked off the shelf instead of derived from the artifact. Step 1's derive-first order prevents it.
- **Dropping a KEPT or downgraded finding in synthesis** — `verifier_kept` + `verifier_downgraded` are authoritative; cite each `id — title` and list the covered ids.
- **Producing a rewrite** — recommending fixes is the job; the rewrite is `/improve`. Give the prescription, not the cured patient.
- **Front-loaded delivery** — orientation is short; depth follows the user's chosen thread.
- **Fabricated findings** — an empty lens is legitimate output; say "no real signal here," don't pad. (Mode B auto-drops unquotable `artifact-quote` findings; in Mode A you must do this yourself.)
