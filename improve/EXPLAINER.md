# improve — what it is, in plain language

**One line:** Hand it something — a draft, a prompt, an idea, a problem statement, a chain of reasoning — and it gives you back a genuinely stronger *rewritten* version, checked for damage before you ever see it, plus a plain account of what changed and why. It's the counterpart to `/pressure-test`: pressure-test *recommends* fixes, improve *makes* them.

This document explains how it works and why it's built the way it is. The operating instructions live next to it in `SKILL.md`.

---

## The problem it solves

"Make this better" is deceptively dangerous as an instruction to an AI. Two things go wrong:

1. **It never stops.** With no definition of "better," a rewrite loop can polish forever, each pass making smaller and smaller changes, wasting time and eventually making things worse.
2. **It quietly damages the original.** A rewrite can flatten your voice into generic prose, or subtly change what you were actually *claiming* or *deciding* — and you might not catch it, because the new version reads smoothly.

The skill is built almost entirely around preventing those two failures. The rewriting itself is the easy part.

## The core idea: a critic and a writer, kept separate

The skill runs an **evaluator-optimizer loop** — a fancy name for a simple idea borrowed from how good editing actually works: separate the person who *finds the problems* from the person who *fixes them*.

- A **fresh-context critic** (a separate Claude process that didn't write the draft and has no stake in it) reads the current version against the goal and returns a ranked list of specific, evidence-backed problems — quoting the exact lines. It does *not* rewrite anything.
- The main Claude then **revises** to address those problems, producing the next draft.
- Repeat — but bounded, so it can't run forever (see below).

Why the separation matters: a critic that watched the work get made tends to *restate and justify* it instead of diagnosing it. Research on this is blunt — about 94% of refinement failures trace back to bad *feedback*, not bad rewriting. So the skill spends its effort making the critique sharp and unanchored.

## How it knows when to stop

This is the part that keeps it from looping forever. The **critic** owns the decision to stop — never the writer, because the writer grading its own work as "done" is exactly the bias to avoid. It stops at the *first* of four conditions:

- **Goal met** — the critic judges the draft clears the bar.
- **No material gain** — only minor nitpicks remain, nothing important left to fix. (Gains usually flatten out after 2–3 passes.)
- **Integrity breach** — a pass got caught changing your meaning or flattening your voice; it stops and surfaces that rather than keeping the bad change.
- **Hard cap** — three passes, full stop. If it's still short, it says so plainly and tells you what's left.

It always tells you which of the four conditions fired.

## The verifier — the safety check on the rewrite

The rewrite is the high-risk step (it's the thing that can quietly damage your work), so before the result ever reaches you — and before any file is written — an **independent fresh-context verifier** compares the rewrite against the original and the goal, checking three things:

- **Fixes:** did each intended improvement actually make it in?
- **Regressions:** any new errors, or claims the original didn't support?
- **Drift:** any sentence where the meaning or your voice changed? (It quotes the offending line.)

If the verifier flags drift or a regression, the skill **surfaces it to you** rather than silently looping again. The verifier is deliberately *not* allowed to propose brand-new improvements — that would never terminate.

## Two modes, chosen automatically

- **Dispatch mode** (the default in Claude Code): real separate processes for the critic and verifier — genuine fresh eyes.
- **Inline mode** (fallback on surfaces without subagents, like the claude.ai web app): it runs the same loop in one context, holding the writer / critic / verifier stances *separately* as a substitute for true fresh eyes — and because there's no independent verifier, it **presents the rewrite for your confirmation** instead of auto-applying it. It tells you up front that it's running single-context.

## `/improve` vs `/improve deep`

- **`/improve`** (default): one fresh critic per pass, looping as above. Best for most things, and always best for short or single-purpose artifacts.
- **`/improve deep`**: instead of looping, it derives 2–3 genuinely different *rewrite approaches* from where this specific artifact is weakest, dispatches a separate writer for each in parallel, then has a judge score all the variants (plus the original) and synthesize the strongest one — grafting the best moves from the runners-up. Use it where genuinely different structural approaches exist (architecture, strategy, a multi-section document). On something small it just says so and offers to downgrade.

## Protecting the original

Several hard rules, all enforced by the verifier:

- **Don't flatten your voice** — improve *within* your register, not toward a generic house style.
- **Don't change meaning** — if a fix would alter what you're claiming or deciding, it asks instead of silently doing it.
- **Stay on the goal** — improving clarity isn't license to quietly re-scope your idea; scope changes are proposals, not edits.
- **Keep the original recoverable** — for a file, it first writes a `.orig` sidecar copy of the original before touching anything, so there's always a guaranteed way back. (If the file is already safely in git and clean, git *is* the way back and it skips the sidecar, telling you so.)

## When it runs

**You invoke it** — it never fires on its own, because producing a rewrite is always a deliberate ask. You can pass it a goal ("make this tighter for a non-technical reader"); if you don't, it derives one, states it, and proceeds — letting you redirect rather than gating on your approval first.

## What you get back

1. **The improved version** (written in place for a file, with the `.orig` safety copy made first).
2. **What changed & why** — a grounded before/after delta, read off the *actual* changes, not narrated from memory (the verifier confirms it matches reality).
3. **Which stop condition fired**, plus the verifier's verdict and any flags it raised.

## Related

`/pressure-test` is the natural front half: it finds and prescribes, improve executes. Run improve on pressure-test's recommendations and it treats them as the first round of critique and goes straight to revising.
