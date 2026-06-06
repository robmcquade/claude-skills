---
name: optimize-efficiency
description: Reviews a target — code, a script, a file, a process, a workflow, a prompt, a config, or a plan — for efficiency across four axes (resource use, code, speed, and token usage) and returns prioritized, location-anchored recommendations, each with an impact/effort/risk read, never a rewrite. Every recommendation passes a hard no-regression guardrail: it must not reduce effectiveness, correctness, safety, or security; trade-offs are surfaced explicitly for the user to decide, never applied silently, and optimizations that would cross that line are listed as declined with the reason. Recommends; does not edit — pair with /improve to execute. User-invoked only. Use when something works but feels wasteful, slow, bloated, expensive, or token-hungry; when asked to make something leaner, faster, cheaper, or lighter; or before scaling a process whose per-run cost will multiply. Skip when correctness is unverified (fix that first) or when there is no real efficiency concern.
argument-hint: "[deep] [optional: the target + what 'efficient enough' means here]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, PowerShell
---

# Optimize-Efficiency

Review a target — code, a script, a file, a process, a workflow, a prompt, a config, a plan — for **efficiency**, and hand back **prioritized, location-anchored recommendations**: for each waste, where it is, what it costs, the fix, and an impact/effort/risk read. This skill **recommends**; it does not rewrite. To execute the recommendations, pass them to `/improve`. Natural pipeline — `/optimize-efficiency` to find and prescribe the leanest change → `/improve` to apply it.

**User-invoked only** (`disable-model-invocation: true`) — an efficiency pass is a deliberate ask, not something to volunteer mid-task.

## The guardrail comes first

Efficiency is **never bought with effectiveness, correctness, safety, or security.** That is the one rule the whole skill is built around, and it dominates every recommendation. A faster path that drops a needed result, a shorter script that deletes an input check, a cheaper prompt that loses a safety instruction, a leaner process that removes an audit trail — **none of those are efficiency wins; they are regressions wearing an efficiency costume.**

So every candidate optimization is run through a **no-regression gate** (below) before it can become a recommendation. The gate has exactly three outcomes:

1. **Clean** — provably preserves the result, the correctness, the safety posture, and the security posture → it becomes a ranked recommendation.
2. **Trade-off** — saves real cost but changes behavior at the margin (an edge case, a readability cost, a small accuracy/latency trade) → it is surfaced as an **explicit, flagged trade-off** with both sides named, for the user to decide. Never applied silently, never buried in a list as if it were free.
3. **Regression** — buys efficiency by weakening effectiveness, correctness, safety, or security → it is **declined**, and listed as declined *with the reason*, so the user can see the cheaper-but-worse path was considered and rejected on purpose (not missed).

Listing the declined options is not filler — it is the proof the guardrail is real. A pass that surfaces only wins has not been pressure-tested against the temptation to cut a corner.

## What it reviews

Anything with a cost and a job to do:

- **Code / a script** — algorithms, data passes, allocations, I/O, redundant work, hot paths.
- **A process / workflow** — steps, hand-offs, repeated work, polling vs. events, batch vs. per-item, anything done eagerly that could be done lazily or once.
- **A prompt / an agent design** — tokens spent per call, context loaded that the task does not need, tool sprawl, retries, fan-out that does not pay for itself.
- **A file / config / data shape** — size, duplication, formats, what is loaded up front vs. on demand.
- **A plan** — sequencing, parallelism left on the table, work that will multiply when scaled.

If the user names a target, use it. If nothing is named, default to the most recent durable artifact in the session, **open it, quote its first line as proof-of-target**, and name your pick so the user can redirect. Never infer a file's contents or purpose from its name — read it.

## The four efficiency dimensions

Run the target against all four. A given waste often shows up under more than one; rank by what it actually costs *this* target, not by tidy coverage.

### 1. Resource use
Memory, allocations, file handles, network calls, disk, compute, money (API spend, infra). Look for: loading whole inputs to use a slice; holding data longer than needed; per-item resource acquisition that could be pooled or batched; work done for every element that only the result needs; duplicate fetches of the same thing.

### 2. Code
The work the code expresses, and the lines it takes to express it — in that order. Look for: redundant passes over the same data; repeated computation that could be hoisted or memoized; dead or duplicated logic; a clearer/cheaper standard primitive in place of a hand-rolled one. Fewer lines is a *secondary* good — never at the cost of clarity or correctness, and never by deleting a guard.

### 3. Speed
Wall-clock and latency. Look for: avoidable full scans where an index, a filter-at-source, or an early break would do; serial work that is independent and could run in parallel; eager work on a path that usually does not need it; repeated work that could be cached; blocking polls that could be event-driven.

### 4. Token usage
For prompts, agents, and any LLM-in-the-loop process — tokens are the governing resource. Look for: context loaded up front that the task rarely needs (prefer just-in-time retrieval); verbose tool output that could be filtered, paginated, or truncated; unbounded output that grows with input size; redundant restating; fan-out to subagents that costs more than it returns; retries without backoff. *"The context window is the most important resource to manage."*

## Procedure (default pass)

1. **Identify and state the target and its effectiveness bar.** One line: what this target's job is, and what "still works" means for it — the result it must produce, the correctness it must keep, the safety/security posture it must not lose. This bar is what every recommendation is measured against; pin it down before optimizing, because you cannot tell a win from a regression without it.
2. **Characterize the current cost.** Where does this target actually spend — which dimension dominates? Anchor to specifics: the line, the step, the call. Do not optimize what does not cost; name the hot spot.
3. **Generate candidates per dimension.** For each of the four, list concrete changes that would cut cost, each tied to a specific location.
4. **Run every candidate through the no-regression gate** (below). Sort each into clean / trade-off / declined.
5. **Prioritize the clean wins by leverage** — cost saved against effort and risk. Lead with high-saving, low-risk, low-effort. A 2% saving that risks a guard is not above a 40% saving that is mechanical.
6. **Deliver** in the shape below.

## The no-regression gate

For each candidate, before it can be recommended, answer all four — and you must be able to *show* the reasoning, not assert it:

- **Result preserved?** Does the target still produce the same outputs (or a superset the caller relies on) for the inputs that matter, including the edge cases the current form handles?
- **Correctness preserved?** Does it stay correct under the same conditions — no new failure mode, no narrowed input domain, no precision lost the task needs?
- **Safety preserved?** Does it keep every guard, check, bound, validation, confirmation, audit trail, and fail-safe? (A guard that looks redundant usually is not — establish why it is there before removing it.)
- **Security preserved?** Does it keep every boundary, scope limit, least-privilege constraint, and the discipline of treating untrusted input as data? A "more general" or "fewer lines" change that widens what is read, trusted, or exposed is a regression even if it never misbehaves in testing.

Any "no" that the saving does not justify → **declined** (list it with the reason). Any "no" that is a genuine, bounded trade the user might want → **trade-off** (surface it flagged, both sides named). All "yes" → **clean** (recommend it).

## Delivery shape

**Orientation first (then stop for the user):** the single highest-leverage clean win (where, what it costs, the fix, the saving), then the ranked list of the other clean wins in one line each. Follow with the **flagged trade-offs** (both sides) and the **declined** options (with reasons) — these are part of the deliverable, not an appendix. Close by offering to expand any thread or to hand the clean wins to `/improve`.

Keep each recommendation **location-anchored** (file + line/section, or the named step) and **evidence-bearing** (the cost is shown or estimated from something concrete, not asserted). "Improve performance" is not a finding; "lines 35 & 52 read the whole file to use the top 24 lines — bound the read" is.

## `deep` — measure, don't guess

On `/optimize-efficiency deep`, raise rigor before delivering:

- **Measure instead of estimate** where you can — time the hot path, count the calls/tokens, check the size — and put the numbers in the transcript. An estimated saving is a hypothesis; a measured one is a finding.
- **Dispatch one fresh-context subagent** to attack the recommendations: which "clean" win actually crosses the guardrail, which saving is illusory once the real workload is considered, which declined option was declined too hastily. Fold its findings in before presenting.

Use `deep` for hot paths, anything that will scale, and high-stakes targets. For a quick local look the default pass is enough — if `deep` is invoked on something trivial, say so and offer to skip it.

## Inline / no-shell

On a surface without a shell or measurement tools (e.g. claude.ai web/mobile), you cannot benchmark. Say so plainly — *"reasoning-only pass; no measurements taken, savings are estimates"* — reason from the artifact alone, and keep the guardrail gate exactly as strict. Losing measurement is a reason to be *more* careful about claiming a win, not less.

## Composition

- **With `/improve`** — opposite contracts: this skill finds and prescribes the leanest change; `/improve` produces the rewrite. Pipeline: optimize-efficiency → improve.
- **With `/pressure-test`** — `/pressure-test` is the general critic (correctness, assumptions, failure modes across every axis); this skill is the narrow efficiency lens with a hard no-regression guarantee. Use pressure-test to ask "is this right?", optimize-efficiency to ask "is this lean, without making it any less right?"

## Failure modes for this skill

- **Selling a regression as a win** — the cardinal sin; the no-regression gate is the whole point. If a saving touches a guard, a boundary, or a result, it is a trade-off or a decline, never a silent recommendation.
- **Optimizing cold code** — cutting cost where there is no cost. Characterize the hot spot first (step 2); a clever fix to a path that runs once is wasted motion.
- **Asserting savings instead of showing them** — "this is faster" with no anchor. Tie every claim to a location and a concrete cost; in `deep`, measure it.
- **Hiding the trade-offs and declines** — surfacing only wins. The flagged trade-offs and the declined options are proof the guardrail ran; omitting them makes the pass look more free than it was.
- **Rewriting instead of recommending** — producing the patched target is `/improve`'s job. Hand back the prescription, anchored and prioritized, and let the user (or `/improve`) execute.
- **Counting lines as the goal** — fewer lines is a secondary good. A denser, cleverer form that is harder to read or drops an edge case is not more efficient; it is more fragile.
