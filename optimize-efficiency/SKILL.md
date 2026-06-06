---
name: optimize-efficiency
description: Reviews a target — code, a script, a file, a process, a workflow, a prompt, a config, or a plan — for efficiency across four axes (resource use, code, speed, token usage) and returns prioritized, location-anchored recommendations, each carrying a per-candidate no-regression verdict, never a rewrite. Every recommendation must clear a forced guardrail: it may not reduce effectiveness, correctness, safety, or security, and the reviewer must enumerate the inputs whose output changes so a behavior change cannot be waved through as "clean." Trade-offs are surfaced for the user to decide; regressions are listed as declined. Recommends; does not edit. User-invoked only. Use when something works but feels wasteful, slow, bloated, expensive, or token-hungry, or before scaling a process whose per-run cost multiplies. Defer to /simplify to apply code simplifications, /code-review for correctness and bugs, and /pressure-test for general (non-efficiency) critique. Skip when correctness is unverified — fix that first.
argument-hint: "[deep] [optional: the target + what 'efficient enough' means here]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, PowerShell
---

# Optimize-Efficiency

Review a target — code, a script, a file, a process, a workflow, a prompt, a config, a plan — for **efficiency**, and hand back **prioritized, location-anchored recommendations**, each carrying a per-candidate **no-regression verdict**. This skill **recommends**; it does not rewrite, and it does not edit the target. The shell tools it holds (`Bash`, `PowerShell`) are for **measuring and inspecting only** — running a benchmark, reading a file, counting tokens — **never for modifying the target.** (Tooling can't enforce that with a shell present; it's a discipline, stated here so the boundary is explicit.) To execute the recommendations, pass them to `/improve`. Natural pipeline — `/optimize-efficiency` to find and prescribe → `/improve` to apply.

**User-invoked only** (`disable-model-invocation: true`) — an efficiency pass is a deliberate ask, not something to volunteer mid-task.

## When to use this — and when to defer

This skill is the **recommend-only efficiency lens with a forced no-regression gate**, across *all* target kinds (code, process, prompt, token cost, plan). It overlaps several siblings; pick the right one rather than running them all:

- **`/simplify`** — *applies* code simplifications to a diff. If the target is code-in-a-diff and you want the change *made*, use it. This skill stays recommend-only and covers non-code targets too.
- **`/code-review`** — correctness, bugs, security of changed code. Use it for "is this right?"; use this skill for "is this lean, without becoming any less right?"
- **`/pressure-test`** — general adversarial critique across every axis. Use it for broad "is this sound?"; this skill is the narrow efficiency cut with the formalized clean/trade-off/declined gate.
- **`/improve`** — *produces* the rewrite. This skill prescribes; `/improve` executes.

If two would apply, prefer the one whose scope matches the target's blast radius (changed lines → `/simplify`/`/code-review`; whole-system or non-code → this skill). Don't run overlapping reviewers on the same thing.

## The guardrail comes first

Efficiency is **never bought with effectiveness, correctness, safety, or security.** That is the one rule the whole skill is built around. A faster path that drops a needed result, a shorter script that deletes an input check, a cheaper prompt that loses a safety instruction, a leaner process that removes an audit trail — **none of those are efficiency wins; they are regressions wearing an efficiency costume.**

So every candidate optimization is run through the **no-regression gate** (below) before it can become a recommendation, and the gate's output is a **visible per-candidate verdict** — not a private judgment. The gate sorts each candidate into exactly three outcomes:

1. **Clean** — *demonstrably* preserves the result, the correctness, the safety posture, and the security posture (by argument; in `deep`, by test). "Demonstrably," not "provably": a reviewer detects *likely* regressions over the inputs considered — behavior-preservation over all inputs is not provable by inspection (program equivalence is undecidable in general). A clean verdict is a reasoned-or-tested judgment, scoped to a named input set, never a proof.
2. **Trade-off** — saves real cost but changes behavior at the margin, or trades one good for another (an edge case, a readability cost, mean-vs-tail latency) → surfaced as an **explicit, flagged trade-off**, both sides named, for the user to decide. Never applied silently.
3. **Regression** — buys efficiency by weakening effectiveness, correctness, safety, or security → **declined**, and listed as declined *with the reason*.

**Zero trade-offs and zero declines is a valid, honest outcome** — if a target genuinely has only clean wins, say so. **Never invent a token decline to look rigorous.** The proof the gate ran is the per-candidate verdict (below), not the presence of a decline.

**Load-bearing, do not shorten:** the gate verdicts, the trade-offs, and the declines are the deliverable's spine. This skill prizes token economy *everywhere except here* — never compress or drop the gate reasoning, a trade-off, or a decline to save tokens.

## What it reviews

Anything with a cost and a job to do: **code/scripts** (algorithms, passes, allocations, I/O, hot paths) · **processes/workflows** (steps, hand-offs, repeated work, polling vs. events, batch vs. per-item, eager vs. lazy) · **prompts/agent designs** (tokens per call, context loaded but unused, tool sprawl, retries, fan-out) · **files/config/data shapes** (size, duplication, formats, load-up-front vs. on-demand) · **plans** (sequencing, idle parallelism, work that multiplies at scale).

If the user names a target, use it. If nothing is named, default to the most recent durable artifact in the session, **open it, quote its first line as proof-of-target**, and name your pick so the user can redirect. Never infer a file's contents or purpose from its name — read it.

## The four efficiency dimensions

Run the target against all four. A waste often shows up under more than one; rank by what it actually costs *this* target.

### 1. Resource use
Memory, allocations, handles, network calls, disk, compute, money (API spend, infra), and **build / CI / cold-start cost** (the per-run multiplier that bites when a process scales). Look for: loading whole inputs to use a slice; holding data longer than needed; per-item acquisition that could be pooled/batched; duplicate fetches.

### 2. Code
The work the code expresses, then the lines it takes to express it — in that order. Look for: redundant passes; repeated computation that could be hoisted or memoized; dead/duplicated logic; a standard primitive in place of a hand-rolled one. Fewer lines is a *secondary* good — never at the cost of clarity or correctness, and never by deleting a guard.

### 3. Speed
Latency **and** throughput **and** tail latency (p99) — and they can oppose each other, so a swap among them is a **trade-off, not a free win**. Look for: avoidable full scans where an index, a filter-at-source, or an early break would do; independent serial work that could parallelize; eager work on a usually-skipped path; repeated work that could be cached; blocking polls that could be event-driven.

### 4. Token usage
For prompts, agents, and any LLM-in-the-loop process — tokens are the governing resource. Look for: context loaded up front the task rarely needs (prefer just-in-time retrieval); **prompt/response caching** — a stable prefix ordering and a high cache-hit rate are usually the largest lever for repeated-prefix calls, so flag anything that needlessly breaks a cacheable prefix; verbose tool output that could be filtered/paginated/truncated; unbounded output that grows with input; redundant restating; fan-out that costs more than it returns. *"The context window is the most important resource to manage."*

## Procedure (default pass)

**Right-size it.** On a small, cold, non-security target, run steps 1–6 informally and deliver the compact verdict table — escalate a candidate to the full boundary verdict only when its change touches a guard, a boundary, or an output. Don't spend more reviewing than the target could save.

1. **Pin the target, its effectiveness bar, and the preconditions.**
   - State in one line what the target's job is and what "still works" means — the result it must produce, the correctness it keeps, the safety/security posture it must not lose. This bar is what every verdict is measured against.
   - **Baseline precondition:** confirm the target currently works (tests pass / it does its job). If correctness is unverified, **stop** — optimizing an already-broken target can't be certified non-regressing.
   - **Fail-closed on an unknown bar:** if you cannot pin the effectiveness bar, **certify nothing** — emit zero clean wins, mark every candidate trade-off-or-declined, and say plainly "bar unknown, cannot certify any change as non-regressing."
   - **Scope gate:** if the target spans multiple independent units (e.g. "optimize this whole repo"), **decompose** into per-unit passes each with its own pinned bar, or ask the user which unit actually costs. Don't review a blast radius you can't bound.
2. **Characterize the current cost.** Where does this target actually spend — which dimension dominates? Anchor to the line, the step, the call. Name the hot spot.
3. **Build the security inventory, then generate candidates *only where step 2 located cost*.** First list the target's security-relevant elements (guards, bounds, validations, scope limits, least-privilege constraints, untrusted-input-as-data handling) — the gate checks every candidate against this list. Then propose concrete changes, each tied to a specific location. **Generating candidates per-dimension regardless of cost manufactures the generic "improve performance" findings this skill exists to avoid — zero candidates is a valid result.**
4. **Route each candidate, then run it through the no-regression gate** (below) at the right tier — *light* for a provably input-independent, non-security change; *full* for anything touching output, a branch, a limit/bound, or a security element.
5. **Self-adversary pass (default) — mechanical, full-tier only.** For each *full-tier* candidate you'd call *clean*, walk its code-derived boundary list (every literal, cap, bound, comparison, and branch in the change) and name the concrete input that crosses each one, confirming its before→after was checked. A boundary you can't pair with a named input is a decline, not a clean. (In `deep`, a fresh-context subagent does this instead — stronger because it never saw your reasoning.)
6. **Prioritize the surviving clean wins by leverage** — cost saved against effort and risk — and **deliver** in the shape below.

## The no-regression gate — a routed, hard-to-pad per-candidate verdict

Every candidate gets a verdict before it can be recommended — but the *weight* of the verdict is **routed by what the change touches**, so trivial wins stay cheap and only risky changes carry the full apparatus.

**Route first.** A candidate takes the **full tier** if its change introduces or alters any numeric literal, comparison operator, cap, slice/loop bound, or branch condition, **or** touches any element in the step-3 security inventory. Otherwise — a provably input-independent, non-security change (loop-invariant hoist, dead-code removal, rename, pure memoization) — it takes the **light tier**.

**Light tier — one line.** Name *why no input reaches the changed behavior*: the change touches no literal/cap/bound/branch and no security element, so output is identical for all inputs by construction. That sentence, plus location and evidence grade, is the whole verdict. Don't manufacture an enumeration where there's provably nothing to enumerate.

**Full tier — the boundary verdict.** The enumeration here is **code-derived, not free-form**, which is what makes it hard to fake: every literal, cap, bound, comparison, and branch *in the change itself* must appear as a boundary input with its before→after output, alongside the standard boundaries (empty, threshold, error path):

```
Candidate · <file:line or named step> · <one-line description>
  Boundary inputs (one per literal / cap / bound / comparison / branch in the change, + empty/threshold/error):
      <input or condition>  →  output before → after   (call out any whose output CHANGES)
  Result preserved?      Y/N + one-line evidence
  Correctness preserved? Y/N + one-line evidence
  Security:              N/A   — or —   Safety Y/N + Security Y/N, each citing a named inventory element
  Evidence grade:        [estimated]  or  [measured]
  Verdict:               clean | trade-off | declined   (+ reason; for trade-off, both sides)
```

Rules that make the verdict trustworthy:
- **Code-derived, not self-selected.** You don't choose which inputs "matter" — the change's own constants and branches *dictate* the boundary list. Omitting the one boundary the change moves is the exact failure this prevents; a boundary you can't pair with a named test input is a **decline**, not a clean.
- **"Clean" means output preserved — and the carve-out runs the safe direction.** A change is clean only if **no boundary input's output changes**, or every changed output is one the consumer **provably discards or normalizes**, shown by a cited consumer-side line. *Relying on* the changed output is the opposite of safe; absent a cited discard/normalize, an output change is a **trade-off**, never clean.
- **The evidence grade has teeth (see handoff).** Tag each verdict `[estimated]` or `[measured]`. Where a test suite or shell exists, a clean verdict on a full-tier change earns `[measured]` only after an **empirical** check — run the suite, diff the outputs; until then it is reasoned-clean, and the handoff treats the two differently.
- **Security only when present.** If step 3's inventory is empty, write `Security: N/A` and omit the security rows, so a real "preserved" stands out instead of a reflexive "yes." If it's non-empty, each row cites the specific element it checked.

## Delivery shape

**Orientation first (then stop for the user):** the single highest-leverage clean win, then the rest as a **compact verdict table** — `candidate · verdict · boundary-inputs-checked · grade` — one row each. Reserve the **full inline boundary block** for any win whose output changes at a boundary, and for every trade-off and decline (those always show their full reasoning). The table keeps a multi-candidate review lean; the full block appears only where the risk is. (The gate still *requires* the code-derived enumeration internally for every full-tier candidate — the table governs what's *shown*, not how hard the check was.) Follow with the flagged trade-offs (both sides) and the declined options (with reasons) — part of the deliverable, not an appendix.

- **"The fix" is a located prescription** — *what to change and where* — **not the rewritten target.** Producing the patch is `/improve`'s job.
- **Handoff contract to `/improve`:** only **clean** wins cross by default; a **trade-off** crosses only after the user opts in item-by-item; a **declined** item **never** crosses. **The evidence grade gates the crossing:** where a shell exists, an `[estimated]`-clean win whose change touches output / a branch / a limit / a bound must be measured (`[measured]`) before it auto-applies; an unmeasured one crosses only flagged *"unmeasured — verify before applying."* The payload carries each item's verdict label and grade.

Keep each recommendation **location-anchored** and **evidence-bearing**. "Improve performance" is not a finding; "lines 35 & 52 read the whole file to use the top 24 lines — bound the read; full tier, boundary inputs enumerated, verdict clean [measured]" is.

## `deep` — measure, don't guess

On `/optimize-efficiency deep`, raise rigor before delivering:
- **Measure instead of estimate** where you can — time the hot path, count calls/tokens, check sizes — and put the numbers in the transcript. Upgrade verdicts from `[estimated]` to `[measured]`.
- **Dispatch one fresh-context subagent** to run step 5's self-adversary with eyes that never saw your reasoning: which "clean" win crosses the guardrail, which saving is illusory at real workload, which decline was too hasty.
- **Budget the review itself:** state in one line that the review's own cost (subagent tokens, benchmark time) is proportionate to the saving on the table — don't spend more finding the win than the win returns.

Use `deep` for hot paths, anything that will scale, and high-stakes targets. On something trivial, say so and offer to skip it.

## Evaluation scenarios (the skill's own self-test)

Before trusting a change to this skill, it must still pass these — each exercises the guardrail, not just the happy path:

1. **Regression in disguise → must land `declined` (or `trade-off`).** A change that looks like a pure win but alters output past a threshold — e.g. capping an unbounded list to 15 items "to save tokens," which changes output for any input with >15 items. The input enumeration must surface the >15 case; a pass that calls this *clean* has failed.
2. **Genuine trade-off → must surface flagged.** A change that truly saves cost but shifts an edge case or trades mean latency for tail latency. It must appear as a both-sides trade-off, never silently applied or silently dropped.
3. **Clean win → must pass at the right tier.** A provably input-independent change (hoisting a loop-invariant, a rename) lands `clean` via the **light tier** — one line naming why no input reaches the changed behavior — *not* a manufactured full enumeration. A boundary-touching clean win instead shows its code-derived boundary verdict and, where a shell exists, earns `[measured]`.

## Inline / no-shell

On a surface without a shell or measurement tools (e.g. claude.ai web/mobile), you cannot benchmark — nothing here can reach `[measured]`. Say so plainly — *"reasoning-only pass; every verdict is `[estimated]`"* — reason from the artifact alone, and keep the routing, the code-derived enumeration, and the fail-closed rules exactly as strict. Because the measurement backstop is gone, **a clean win whose change touches output / a branch / a limit / a bound is downgraded to a trade-off here** — it crosses to `/improve` only on explicit item-by-item opt-in, never auto-applied. Losing measurement is a reason to claim fewer clean wins, not the same number more carefully.

## Composition

- **`/improve`** — opposite contracts: this skill finds and prescribes; `/improve` produces the rewrite. Pipeline: optimize-efficiency → improve, under the handoff contract above.
- **`/simplify`** — applies code simplifications to a diff; defer code-in-a-diff that you want *applied* to it.
- **`/code-review`** — correctness and bugs of changed code; defer "is it right?" to it.
- **`/pressure-test`** — general adversarial critique; this skill is the narrow efficiency cut.

## Failure modes for this skill

- **Greenlighting a regression via a padded or mis-routed enumeration** — the cardinal sin. The boundary list is code-derived: if a literal/cap/bound/branch in the change isn't paired with a named input and its before→after, you didn't run the gate. Routing a boundary-touching change to the light tier is the same failure.
- **Selling a regression as a win** — any saving touching a guard, a boundary, or a result is a trade-off or a decline, never a silent recommendation.
- **Inventing a decline to look rigorous** — zero declines is a valid outcome; the verdict artifact is the proof the gate ran, not a manufactured decline.
- **Shortening the gate for token economy** — the verdicts, trade-offs, and declines are load-bearing; never compress them to save tokens.
- **Optimizing cold code, or an unverified baseline** — characterize the hot spot first, and confirm the target works before touching it.
- **Asserting savings instead of showing them** — tie every claim to a location and a cost; tag `[estimated]`/`[measured]`; in `deep`, measure.
- **Rewriting instead of recommending** — hand back the located prescription; `/improve` executes.
- **Counting lines as the goal** — fewer lines is secondary; a denser form that drops an edge case is more fragile, not more efficient.
