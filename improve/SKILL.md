---
name: improve
description: Take an artifact, idea, problem statement, thought process, or solution and return a materially stronger REWRITTEN version of it, plus a grounded account of what changed and why. An evaluator-optimizer loop — a fresh-context critic finds what's weak, the work is revised, repeated until it converges — and an independent fresh-context verifier checks the rewrite (fixes applied, no new errors, no meaning or voice drift) before it reaches you. It PRODUCES the result (the counterpart to /pressure-test, which only recommends). User-invoked only. In Claude Code it dispatches fresh-context subagents; on a surface without subagents it runs the same loop inline. Bounded so it never iterates forever — a goal confirmed up front, the evaluator owning the stop, and a hard pass cap. Pass an explicit goal as an argument, or it derives and states one. Preserves your voice and intent; for files it writes a .orig sidecar first so the original is always recoverable.
argument-hint: "[deep] [optional: the goal / what 'better' means here]"
disable-model-invocation: true
allowed-tools: Agent, Read, Grep, Glob, Edit, Write, WebSearch, WebFetch
---

# Improve

Take a thing — a file, a draft, an idea, a problem statement, a thought process, a solution — and **produce a materially stronger version of it**, verified before it reaches you, plus a grounded account of what changed and why. This skill **rewrites**; it hands back the improved result, not a list of suggestions. (To get the diagnosis and recommendations *without* a rewrite, use `/pressure-test`. Natural pipeline — `/pressure-test` to find and prescribe → `/improve` to execute.)

**User-invoked only** (`disable-model-invocation: true`) — producing a rewrite is always a deliberate ask.

It works on more than finished artifacts:
- **Artifact** (doc, prompt, memo, code) → a tighter, stronger artifact.
- **Problem statement** → a crisper, better-scoped, more precise statement.
- **Thought process / reasoning** → tighter logic, surfaced assumptions, fixed gaps.
- **Idea / solution** → a more robust, better-considered version.

## Two modes — chosen by surface capability

One check: **can you dispatch subagents (is the Agent tool available)?**

- **Yes → Mode B (dispatch).** The default in Claude Code. Fresh-context critic, fresh-context verifier.
- **No → Mode A (inline).** Fallback for surfaces without subagents (claude.ai web/mobile). Run the same loop single-context — see the Inline procedure near the end — and, because there is no fresh verifier, **present the rewrite for confirmation rather than auto-applying.** Flag that you are single-context.

The critic and verifier run in **fresh context** because a critic that watched the work get made tends to restate and justify it rather than diagnose it — and the same anchored agent can't neutrally audit its own rewrite.

## Step 0 — Establish the goal and disclose the spend (do this first)

A rewrite with no target is the thing that iterates forever and wastes time — the goal is the convergence anchor.

1. Identify the thing being improved (the artifact/idea named or pasted; if nothing was named, the most recent durable artifact produced or edited in this session — name your pick).
2. State, in one line, **what a better version optimizes for** — the goal, the audience, the bar to clear. If the user passed a goal argument, use it.
3. **State the goal and (if dispatching subagents) the spend, then proceed in the same turn — don't gate on approval.** E.g.: "Improving this toward: [goal]. Running default: 1 fresh critic + 1 verifier per pass." or "Running deep: [N] fresh rewriters + a judge + a verifier." For a fuzzy input (a thought process, a vague idea), pin the goal down first and let the user redirect; for a tight goal, state and go. The user can interrupt.

The goal travels into every dispatched subagent's prompt — subagents inherit nothing (not the conversation, not an active `/goal`).

## The loop (evaluator-optimizer)

The critique is where almost all the value is (research: ~94% of refinement failures trace to bad feedback, not bad rewriting), so the critic must be sharp, specific, and unanchored.

Each pass:
1. Hold the current draft.
2. **Critique** — a fresh-context evaluator judges the draft against the goal and returns ranked, evidenced fixes (no rewrite).
3. **Revise** — apply the fixes, producing the next draft. Preserve voice and intent (hard rules below).
4. **Check termination** (below). If not done, loop; if done, go to **Verify the rewrite**.

## Termination — the evaluator owns the stop (never the reviser)

The agent that did the revising does not get to certify its own work as done. Bind every stop to the **fresh evaluator's** returned verdict. Stop at the FIRST of:

- **Goal met** — the evaluator judges the draft clears the bar.
- **No material gain** — the evaluator reports only Minor fixes remain (no Critical/Should-fix left). "Material" = the evaluator's Critical/Should-fix items resolved, never the reviser's self-assessment. (Gains typically plateau after 2–3 passes.)
- **Integrity breach** — if a pass is found to have changed meaning or flattened voice, stop and surface it; don't count it as a gain or silently keep it.
- **Hard cap** — 3 passes (so ≤3 critic dispatches in default mode). If still short at the cap, stop and say so plainly, with what's left.

State which stop condition fired when you deliver.

## Mode B — dispatch (Claude Code)

**Getting the artifact to a subagent** — it inherits nothing and must see the *complete* artifact, never a head/tail slice:
- File(s) → pass the absolute path(s) and tell the subagent to Read them in full.
- Short pasted text → paste it.
- Large (more than ~2k words) → paste the load-bearing sections and note what was excerpted and why.

**`/improve` (default)** — one fresh evaluator per pass:

```
ROLE: You are a skeptical independent editor. You did NOT write this and have no stake in it.
Critique it against the goal — find what's weak, missing, unclear, unsupported, or off-target.

GOAL: <confirmed goal from Step 0>

DRAFT: <paste the full text, OR the absolute path to Read in full, OR the noted load-bearing excerpt>

STANDARDS (optional): <relevant slice of the user's preferences/decisions, so you judge against THEIR bar>

RULES:
- Cite evidence for every point — quote the specific line/passage. No vibe-only notes.
- Rank fixes by leverage. Mark each Critical / Should-fix / Minor.
- Do NOT rewrite the artifact. Return ranked fixes only.
- Flag anything that, if "fixed", would damage the author's voice or change the intended meaning.
- End with: is this at the goal? (yes/no + remaining Critical/Should-fix count + the single highest-leverage remaining change.)
```

The main agent revises per the critique and loops.

**`/improve deep`** — parallel-variant panel, **one generate-judge-merge cycle** (it substitutes for the linear loop; it does not iterate inside it):

1. **Derive 2–3 rewrite angles from THIS artifact's weakness surface** — where is *this* draft most likely failing its goal? (clarity/rigor/concision are backstops only if the artifact suggests nothing sharper.)
2. Dispatch 2–3 fresh writers in parallel, one per angle, each rewriting toward the goal (artifact delivered per the rule above).
3. A fresh judge scores the variants + the original against the goal and synthesizes the strongest version, grafting the best moves from the runners-up.
4. The merged output goes through **Verify the rewrite** (below). If Verify returns "not at goal," you may run **one** further deep cycle — hard cap two cycles.

Use `deep` for artifacts where genuinely different structural approaches exist (architecture, strategy, multi-section docs). On a short or single-purpose artifact, default `/improve` dominates — if `deep` is invoked on something small, say so and offer to downgrade.

## Verify the rewrite (Mode B; always, before delivery and before any file write)

The rewrite is the high-risk step, so it gets an **independent fresh-context verifier** — not the anchored reviser grading its own output. After the loop (or the deep merge) produces the candidate, dispatch one verifier with {the original + the rewritten candidate + the goal} and this mandate:

```
You did NOT write either version. Compare the REWRITE against the ORIGINAL and the GOAL:
- FIXES: does each intended improvement actually appear in the rewrite?
- REGRESSIONS: any new errors, or claims/content not supported by the original?
- DRIFT: any sentence where the meaning or the author's stance/voice changed? Quote it.
- AT-GOAL: does the rewrite clear the goal? (yes/no)
Return PASS, or a list of drift/regression flags with quotes. Do NOT propose new improvements (that would never terminate).
```

If the verifier flags drift or regressions, **surface them to the user** — do not silently re-loop. (Mode A fallback, no subagents: do this comparison yourself with an explicit fresh, skeptical stance, and prefer presenting the rewrite for confirmation over auto-applying.)

## Output

Hand back:

1. **The improved version.** For a file, **first write a `<name>.orig` sidecar copy of the original** — the guaranteed revert path; never assume git or checkpoints exist — then apply the edit. Never overwrite the source without the sidecar in place. (If the source is already safely version-controlled and clean, git is the revert path and the sidecar is redundant — say so and skip it.)
2. **What changed & why** — a grounded, bulleted delta read off the *actual* before/after (not narrated from memory); the verifier confirms it matches the real changes. The changes that matter, not a line-by-line dump.
3. **Stop condition** — which fired, plus the verifier's verdict and any surfaced flags.

## Inline procedure (Mode A — no subagents)

When subagents are unavailable, run the loop single-context — say up front: "single-context inline pass — no fresh-eyes subagents," and **present the rewrite for confirmation rather than auto-applying** (no fresh verifier exists to catch drift).

1. Establish the goal (Step 0).
2. **Critique** — adopt a skeptical, fresh-eyes editor stance and write the ranked, evidenced fixes out in full (externalize them; don't collapse critique into the rewrite).
3. **Revise** per those fixes, preserving voice and intent.
4. **Verify** — re-read the rewrite against the original with the Verify mandate above; note any drift/regression.
5. Terminate per the rules (judged from the evaluator stance, not the writer stance), then present the rewrite + grounded delta + your verify notes for the user to apply.

Hold the writer, critic, and verifier stances *separately* — the separation is what substitutes for fresh context.

## Preserve voice and intent (hard rules — the verifier enforces these)

- **Do not flatten the author's voice** into generic prose. Improve *within* their register, not toward a default house style.
- **Do not change meaning.** If a fix would alter what the author is claiming or deciding, surface it as a question instead of silently making it.
- **Stay on the goal.** Improving clarity is not license to re-scope the idea. Scope changes are proposals, not edits.
- **Keep the original recoverable.** The `.orig` sidecar (files) or presenting-for-confirmation (inline) is the revert path; never destroy the source without one.

## Optional — unattended via `/goal`

`/goal` is a separate outer loop (a Haiku evaluator over the MAIN transcript that never sees subagent output). To run `/improve` unattended, wrap the session in `/goal <measurable condition + turn cap>` and echo each pass's evaluator verdict into the main transcript so that gate can judge it. Not required — the internal termination already bounds the loop.

## Composition

- **With `/pressure-test`:** opposite contracts — pressure-test recommends, improve produces. Run `/improve` on `/pressure-test`'s recommendations and it treats those as the first critique pass (skip straight to revise), then continues the loop.

## Failure modes for this skill

- **Shipping an unverified rewrite:** the high-risk mutation reaching the user unchecked. The fresh-context verifier (always — before delivery and before any file write) is the gate.
- **Reviser self-certifying the stop:** the anchored agent declaring "done" on its own work. Termination is the evaluator's call, bound to its returned verdict.
- **Voice-flattening / meaning-drift:** the most damaging failure. Preserve register; surface meaning changes as questions; the verifier flags drift with quotes.
- **Iterating forever:** prevented by Step 0's confirmed goal + the four-way termination. If you can't name the goal, stop and ask — don't loop blindly.
- **Silent truncation:** giving a subagent a head/tail slice of a large artifact. Pass the full file (or a noted excerpt), never a silent cut.
- **Generic deep angles:** clarity/rigor/concision picked off the shelf. Derive the angles from the artifact's weakness surface.
- **Data loss:** overwriting a file with no revert path. Write the `.orig` sidecar first, always (unless git already guarantees recovery).
- **Self-reported delta:** narrating changes from memory. Read the delta off the actual before/after; the verifier confirms it.
