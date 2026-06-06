# pressure-test — what it is, in plain language

**One line:** Hand it a piece of real work — a memo, a contract redline, a plan, a prompt, a decision — and it comes back with an honest critique: what's strong, what's weak, what you're assuming without realizing it, how it could fail, and a specific fix for each weakness. It tells you what to change; it doesn't rewrite the thing (that's `/improve`'s job).

This document explains how it works and why it's built the way it is. The operating instructions live next to it in `SKILL.md`.

---

## The problem it solves

When you ask the same Claude that *just helped you build something* to critique it, you get a bad critique. It tends to re-explain and defend the reasoning it just used, because that reasoning is fresh in its head — this is confirmation bias, and it's baked in. A useful critique has to come from somewhere that never saw how the work got made.

The skill solves that by spinning up **fresh-context critics**: separate Claude processes that are handed only the artifact and the goal, with no memory of the conversation that produced it. They critique the *thing*, not the story behind it. Think of it as sending your draft to several sharp outside reviewers who weren't in the room — except it happens in seconds.

## Why it's built on a script instead of just instructions

Most skills are a page of instructions Claude reads and follows. This one has a different problem: some of its steps, if Claude simply *forgot* to do them, would produce confidently-wrong output that looks fine. Three examples:

- A security document reviewed at shallow depth (a missed vulnerability reads the same as "no vulnerabilities").
- A reviewer that grades an incomplete set of findings (looks thorough, isn't).
- A made-up quote — a critic "quoting" a line the artifact doesn't actually contain — reaching the final summary.

The standing principle behind it: *rules whose failure produces durable wrong output can't live at the "remember to do this" layer — they need to be enforced at the moment of output.* So in Claude Code these critical steps are owned by a **deterministic orchestrator** — a PowerShell script (`Invoke-PressureTest.ps1`) that runs them the same way every time — and Claude does the *judgment* inside the gates the script enforces. Claude decides *what* to critique and *how* to phrase the findings; the script guarantees the critics actually ran, the quotes are real, and the depth matched the risk.

Three steps can't be enforced by any script, because they sit before, inside, and after it: *deciding to invoke the script at all*; *honestly passing along your answer* in the one case you're asked (when an "uncertain" artifact could go deep or standard, Claude must not quietly pick "standard" on your behalf); and *making sure the final write-up covers every surviving finding*. Those are honestly flagged as "Claude's judgment, not guaranteed" — the skill never claims more safety than it has.

## How a run works (the orchestrated path, in Claude Code)

1. **It identifies the target and states what it's for.** What is this artifact trying to achieve, who's it for, what bar must it clear? A vague target produces vague critique, so it pins this down — and it actually opens the file and quotes its first line as proof it's testing the right thing, rather than guessing from the filename.

2. **The sensitivity gate (this is the automatic safety escalation).** A detector script scans the artifact. If it finds anything security-, credential-, or personal-data-shaped, the run is *forced* to "deep + firewalled" no matter what you asked for — you don't get to talk it into going shallow on sensitive material. A clean artifact runs at normal depth; an "uncertain" verdict is the one moment the skill is allowed to pause and ask you.

3. **It derives the review angles ("lenses") from this specific artifact.** Generic reviewers give generic feedback, so it first writes the 1–3 angles that come from *this* work's actual risk surface (where would *this* fail?), then fills the remaining slots from a standing library — steelman-then-attack, real-world failure modes, hidden assumptions, adjacent alternatives, prior-art ("has this been done before?"), the skeptical-stakeholder view (what a hostile lawyer or CFO would say). A standard run uses 3 critics; a deep run uses 4–5. Exactly one critic is given a slice of *your* preferences and past decisions so it judges against your bar specifically; the rest stay pure outside-eyes.

4. **The orchestrator runs the panel.** It launches each lens as its own fresh Claude process, forces each to return findings in a strict format, waits for all of them (a critic that errors out is retried once, then the whole run *stops* rather than handing you a half-done review), auto-deletes any finding that claims a word-for-word quote the artifact doesn't actually contain (findings about something *missing*, and outside prior-art that cites a source instead of an artifact quote, are passed to the verifier rather than dropped — so real gaps and references aren't lost), and then runs **one independent verifier** that re-grades the whole pile — keep, downgrade, or drop each finding. The result is written to a manifest file: the authoritative, verified list.

5. **The firewall (on sensitive runs).** The "has this been done before?" lens normally searches the web — but you can't paste a sensitive document's specifics into a web search. So on a sensitive run the skill *splits* that job: one process holds the artifact and writes *scrubbed* research questions; a completely separate process that never sees the artifact does the actual web searching. The artifact itself never reaches a search query by construction of the split — the one part left to judgment is how thoroughly the questions were scrubbed. And the main session has no web tools at all (only that isolated searcher process does), so nothing can leak from here either.

6. **It delivers the findings in paced layers.** First a short orientation — strengths, the headline weaknesses, and the single highest-leverage change — then it stops and offers you a few specific threads to pull. When you pick one, it goes deep on that. Every verified finding gets cited by ID so you can check that nothing was quietly dropped.

## When it runs

**You invoke it** — `/pressure-test` (or `/pressure-test deep`). It never fires on its own, because spinning up a panel of critics is a deliberate act. Use it on durable work where early choices constrain later ones — files, frameworks, contracts, public-facing content, prompts, proposals. Skip it for single-fact lookups or things you've already decided and are ready to ship.

## The honesty rule when it can't run fully

On a surface with no shell (like the claude.ai web app), the script-enforced gate and the fresh-eyes critics *can't* run. There, the skill runs the same review angles in a single context and **leads with the disclosure**: "this is a judgment-grade pass — the enforced gate and fresh-eyes processes did not run." And critically: if the full path *starts* but then a step crashes, it does **not** quietly downgrade to the lesser mode and pretend everything's fine — it stops and shows you the error. Falsely reassuring you is the exact failure this skill exists to prevent.

## Related

`/improve` is its counterpart and the natural next step: pressure-test *finds and prescribes*, improve *executes the rewrite*. Pipeline them — test, then improve.
