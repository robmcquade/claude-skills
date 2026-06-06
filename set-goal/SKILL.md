---
name: set-goal
description: Compose a strong condition for Claude Code's built-in /goal autonomous loop, then hand it back ready to paste. /goal keeps Claude working across turns until a fast evaluator model (Haiku by default) judges the condition met — and that evaluator sees only the main transcript, not your files and not a subagent's internal work unless Claude restates it, so the condition must be provable from what Claude surfaces. This skill turns a rough aim into a well-formed condition — the three things the docs call for (a measurable end state, a stated check, constraints that must hold) plus the turn or time cap the docs recommend separately — validates it against the transcript-only rule and the common failure modes, and explains the residual risks. User-invoked only. Adaptive — refines a draft you pass, or drafts from the project and asks only the gaps from a blank slate. Pass deep to adversarially stress the drafted condition with a fresh-context subagent.
argument-hint: "[deep] [optional rough goal or task to refine]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Agent
---

# Set-Goal

Compose a **strong condition string for the built-in `/goal` command** and hand it back ready to paste. `/goal <condition>` runs an autonomous loop: Claude keeps working across turns until a separate fast evaluator model (the configured small/fast model, Haiku by default) judges the condition met, or you run `/goal clear`. A vague condition is the thing that wastes turns or never terminates — this skill's whole job is to make the finish line unambiguous and machine-checkable.

**User-invoked only** (`disable-model-invocation: true`). **This skill does not run `/goal`** — a skill can't invoke a built-in slash command. It produces the condition string for you to use in an interactive session, the Claude desktop app, `claude -p`, or Remote Control (in a session you paste it; with `claude -p` the condition goes in the command, not pasted into a session).

## The one constraint that drives everything

The evaluator **judges only what Claude has surfaced in the main transcript.** It does not run commands and does not read files; it sees only what lands in the conversation. A subagent's internal work doesn't count unless the main agent prints or restates it. So the condition must be **provable from what Claude surfaces.** Every draft is tested against this first:

> "All tests in `test/auth` pass" works only because Claude runs the tests and the result lands in the transcript for the evaluator to read. A condition that depends on a file the evaluator would have to open, or on work that stayed inside a subagent and never got restated, is unverifiable — rewrite it so the proof appears in the conversation.

(Source: code.claude.com/docs/en/goal, for the transcript-only behavior. Separately — not stated on that page, but consistent with how skills work — there is no `${CLAUDE_GOAL}` placeholder and subagents don't inherit the goal, so `/goal` is an outer-loop layer, not a per-skill criterion.)

## Anatomy of a strong condition

The docs say a condition that holds up across many turns *usually has* three things (parts 1–3 below), and they recommend bounding the run with a turn/time clause *separately* (part 4). This skill treats all four as required output — the cap is what keeps an autonomous loop from running unbounded.

1. **One measurable end state** — a test result, a build exit code, a file count, an empty queue. One conceptual "done," even if it decomposes into a few independently-checkable clauses.
2. **A stated check** — *how* Claude proves it, naming the command and the expected signal: "`npm test` exits 0," "`git status` is clean," "`rg 'legacy_client'` returns no matches under `services/checkout`."
3. **Constraints that must hold** — what must *not* change on the way there: "no other test file is modified," "diff touches only `services/checkout`."
4. **A turn or time cap** — "…or stop after 20 turns." The docs recommend a turn/time clause to bound the run; this skill always includes one.

Render the final condition on **one line, cap clause last**. The docs' own examples separate clauses with plain "and"; this skill uses semicolons (or "and") for readability — a style choice, not a `/goal` requirement. Max 4,000 characters.

## Adaptive flow

Read the argument and recent conversation, then branch:

- **A draft or a task is present** → treat it as a draft. **Refine and validate it in one pass**, then ask only about the parts that are genuinely missing (usually the cap, the explicit check command, or the scope constraint). Name what you assumed. If the draft is the argument, just use it; if you're inferring the target from the in-flight session task rather than an explicit argument, **name the inferred target in one line and confirm before refining** — don't silently refine the wrong thing.
- **Nothing to work from** → draft as much as the project allows (read the repo for the real check command, infer the end state from the task), present that draft, and ask the genuinely unknown parts in **one consolidated prompt** — not four questions in sequence.

Either way, do not gate the whole thing on a wall of questions. Fill what you can from the project and the task; ask only what you cannot responsibly infer.

## Validation checklist (run this on every draft)

Test the candidate condition against each. Any "no" is a rewrite, not a warning to pass along silently:

1. **All four parts present** — one measurable end state, a named check (a specific command/count and its expected signal, not "tests pass" but "`npm test` exits 0"), the constraints that must hold, and a turn/time cap. (If it's really two unrelated goals, split them — only one goal is active per session.)
2. **Transcript-provable** — could the evaluator confirm this from the chat alone, with no file read and no tool call? If the proof lives in a file or stays inside a subagent, rewrite so Claude prints it.
3. **Binary** — would two reasonable people always agree "met / not met" from the same transcript? Kill gradients, "better," "improved," and subjective words.
4. **Scope constraint** — could it be satisfied by a change *outside* the intended area? Add a "diff touches only…" / "no other … modified" clause.
5. **Anti-gaming** — if it hinges on tests/lint passing, can it be met by weakening or deleting the check itself? Add "without modifying the tests" or equivalent.
6. **Evidence, not assertion** — does the language imply Claude must *show* the output, not just claim success? Prefer "…and the test output is shown" framing.
7. **Positive framing** — does it state what *done* looks like (then add the "and X didn't change" constraints), rather than only what to avoid?
8. **In scope** — does the condition smuggle in work beyond the actual task? If so, flag it; don't silently expand scope.

## Output

Hand back, in this order:

1. **The ready-to-paste command**, in a fenced block on its own so it copies cleanly — one line, cap clause last. For example:
   ```
   /goal All tests under test/auth pass — show `npm test -- test/auth` exiting 0; `git diff --stat` lists only src/auth and no test file is modified; or stop after 15 turns
   ```
2. **Why it's shaped this way** — two or three lines mapping the clauses to the four parts and noting what you assumed or inferred.
3. **Residual risks** — anything the checklist couldn't fully close (e.g., the check is slow, the cap is a guess, the end state is partly judgment). Name them so the choice stays with the user.
4. **Reminder** — paste it to start; `/goal` (no arg) shows status; `/goal clear` stops it.

## `deep` — adversarial stress (optional)

On `/set-goal deep`, after drafting, dispatch **one fresh-context subagent** to try to defeat the condition, then fold its findings in before you present:

```
Role: You are a skeptical evaluator of a /goal condition for Claude Code. The /goal evaluator
is a fast model that sees only the main conversation transcript — no file reads, no tool calls,
and no subagent internal work unless the main agent restates it. It judges the condition met/not-met
from what Claude surfaces.

Condition: <the drafted condition>
Task context: <one or two lines on what the user is actually trying to accomplish>

A basic checklist (transcript-provable, named check, binary, scoped, anti-gaming, bounded) has
already passed. Attack only the residual, non-obvious ways this fails:
- Unverifiable — a part that reads checkable but the evaluator could not actually confirm from
  transcript text alone.
- Gameable — a way to satisfy it without the real work (trivial edit, weakened test, satisfied
  on turn 1 before any work, out-of-scope change that still matches the wording).
- Ambiguous — wording where the evaluator could reasonably call "met" on partial credit.
- Mis-scoped or unbounded — wrong/missing cap, or scope creep beyond the task.
Return a ranked list of concrete defects, each with a specific rewrite. Do not rewrite the whole
condition; return the defects and targeted fixes.
```

Apply the fixes, then present the hardened condition with the defects it closed. Use `deep` for long or high-stakes runs; for a quick local check the inline checklist already covers it — if `deep` is invoked on something small, say so and offer to skip it.

## Composition

- **With the verification ladder** — `/goal` is the second rung of Claude Code's documented verification-loop ladder: in-prompt check → **`/goal` condition** → Stop hook → verification subagent (see the Claude Code best-practices doc). If the user needs a *hard* deterministic gate rather than an evaluator judgment, point them to a Stop hook instead; `/goal` is the right tool when the proof is something Claude surfaces and re-checks each turn.
- **With `/improve` and `/pressure-test`** — to run either unattended, wrap the session in the `/goal` condition this skill produces, and have each pass echo its evaluator verdict into the main transcript so the goal-evaluator can see it (those skills already bound themselves internally; the goal is just the outer safety cap).

## Failure modes for this skill

- **Composing an unverifiable condition** — the cardinal sin; the transcript-provable test (checklist #2) is the gate. If the proof isn't something Claude surfaces in the conversation, it doesn't count.
- **Shipping a vague finish line** — "improve performance," "make it better." Force a named check and a binary end state.
- **Omitting the cap** — every condition gets a turn/time clause; an unbounded loop is a defect, not a feature.
- **Silently inferring scope** — when you fill in the check command or constraints from the project, *say so*; a wrong inference costs more than the question.
- **Pretending it ran the goal** — it doesn't. Always hand back the string to paste; never imply the loop is active.
