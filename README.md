# claude-skills

Five [Claude Code](https://www.claude.com/product/claude-code) skills I built because I kept needing them, then kept using them.

They do the thinking-heavy work: stress-test a piece of real work, make it leaner without breaking it, rewrite it stronger, set an autonomous-loop goal that actually stops, and fact-check the AI advice that goes stale a week after someone posts it. Every one of them runs on the same stubborn rule—**don't let the model grade its own homework.** A model that just helped you build something will defend its own reasoning the moment you ask it to critique that work; these hand the feedback to a fresh process that never saw how the sausage got made. And where forgetting a step produces confidently-wrong output—a security doc reviewed at shallow depth reads exactly like a clean one—the skill enforces the step in code instead of hoping the model remembers.

Built and maintained by [Rob McQuade](https://robmcquade.com/skills). MIT licensed. Take them, fork them, make them yours.

---

## The skills

| Skill | What it does | Invoke |
|---|---|---|
| **pressure-test** | Stress-tests real work—files, contracts, prompts, decisions—with a panel of fresh-context critics, checks prior art (has someone already hit this and solved it?), and hands back a specific fix for each weakness. Finds and prescribes; built to pair with **improve**, which executes the fixes. | `/pressure-test [deep]` |
| **improve** | Takes an artifact, an idea, or a half-formed argument and hands back a genuinely stronger rewrite—checked for drift and voice-flattening before you ever see it. Produces the result; hand it **pressure-test**'s findings and it folds them straight in. | `/improve [deep]` |
| **optimize-efficiency** | Reviews code, a script, a process, a prompt, or a plan for waste—resource use, speed, tokens—and returns location-anchored fixes, each through a hard no-regression gate so a "win" never quietly costs you correctness, safety, or security. Recommends; pairs with **improve** to execute. | `/optimize-efficiency [deep]` |
| **set-goal** | Writes a finish line for Claude Code's built-in `/goal` loop that the evaluator can actually check—so the loop stops instead of running all night. | `/set-goal [deep]` |
| **evaluate-ai-merits** | Fact-checks the AI-tooling content you just read against primary sources, and flags the parts that date fast—a model-version tip passed off as universal, a preview feature sold as shipped. | (auto-fires on AI content, or invoke directly) |

### The pairing I reach for most: `pressure-test` → `improve`

These two are opposite halves of one pipeline, and the reason this set exists.

- **`/pressure-test`** *finds and prescribes.* It spins up a panel of fresh-context critics, each handed only your artifact and what it's supposed to do. None of them watched you build it, so they critique the thing instead of the story behind it. You get the diagnosis—strengths, weaknesses, the assumptions you smuggled in without noticing—plus a specific fix for each weakness. It also checks prior art: has someone already hit this and solved it, so you're not reinventing a fix that already exists? It doesn't touch your work.
- **`/improve`** *executes.* A fresh critic finds what's weak, the work gets revised, repeat until it stops improving—then an independent verifier reads the rewrite against the original and flags any spot where the meaning shifted or your voice got sanded down to house style. Only then does it reach you.

Run them in order: pressure-test to find the problems, improve to fix them. Hand `/improve` the recommendations from `/pressure-test` and it recognizes the critique's already been done—it folds them in as the first pass and goes straight to revising, instead of re-deriving them. And you don't have to stop at one round: pressure-test the improved version, feed the new findings back to improve, and keep alternating for as many turns as the work earns. They're built for that loop.

Both are built for Claude Code, where the fresh-eyes processes and enforced gates actually run. They'll work on the claude.ai web app too, but in a reduced single-context form—and each says so up front when it can't run the full path.

Each skill ships with its operating **`SKILL.md`**; the two above also include a plain-language **`EXPLAINER.md`** that walks through what they are and why they're built this way—no jargon required.

---

## Why they're built this way

One thread runs through all five, and it's a refusal: don't let the model grade its own homework.

- **Fresh context, not self-review.** A model that just helped build something carries that work's reasoning into any critique of it—it restates and defends instead of diagnosing. So pressure-test and improve push the critique to separate processes handed only the artifact and the goal. Outside eyes, in seconds.
- **Enforcement where forgetting is expensive.** A security document reviewed at shallow depth reads exactly like a clean one—the failure is invisible. So pressure-test's sensitivity escalation, panel size, quote-existence check, and web firewall are owned by a deterministic script. The model does judgment *inside* the gates; it doesn't get to skip them. What's enforced versus what's left to judgment is written down honestly in [`pressure-test/references/enforcement-model.md`](pressure-test/references/enforcement-model.md)—the skill never claims more rigor than it has.
- **Loops that stop.** improve's loop is anchored to a goal you confirm up front, the evaluator—never the reviser—owns the call to stop, and there's a hard pass cap. So it can't polish forever. set-goal exists to make the *outer* `/goal` loop stop too, by forcing a finish line the evaluator can verify from the transcript alone.
- **Honest degradation.** On a surface with no shell or subagents—the claude.ai web app, say—the enforced machinery can't run. Each skill notices, runs the same logic in one context, and leads with the disclosure instead of pretending it ran the full path. Falsely reassuring you is the exact failure these were built to prevent.

---

## Install

Claude Code loads skills from `~/.claude/skills/` (personal, every project) or a project's `.claude/skills/` (that repo only). Drop in the ones you want.

**Personal install (the one I'd start with):**

```bash
git clone https://github.com/robmcquade/claude-skills.git
cd claude-skills

# copy the skills you want into your personal skills dir
mkdir -p ~/.claude/skills
cp -r pressure-test improve optimize-efficiency set-goal evaluate-ai-merits ~/.claude/skills/
```

On Windows (PowerShell):

```powershell
git clone https://github.com/robmcquade/claude-skills.git
Set-Location claude-skills
New-Item -ItemType Directory -Force "$HOME\.claude\skills" | Out-Null
foreach ($s in 'pressure-test','improve','optimize-efficiency','set-goal','evaluate-ai-merits') {
  Copy-Item -Recurse -Force ".\$s" "$HOME\.claude\skills\$s"
}
```

Keep each skill directory whole—`SKILL.md` at the root, plus the bundled `scripts/`, `schemas/`, and `references/` for pressure-test. Start a new Claude Code session and they show up; invoke with `/pressure-test`, `/improve`, `/optimize-efficiency`, `/set-goal`. (`evaluate-ai-merits` can fire on its own when you share AI-tooling content, or you can invoke it directly.) Four of the five are user-invoked only—they never fire unless you ask.

---

## Requirements

- **Claude Code.** These are Claude Code skills, not API prompts or chat-window content.
- **PowerShell 7 (`pwsh`) for pressure-test's enforced mode.** The pressure-test orchestrator (`Invoke-PressureTest.ps1`) and the sensitivity detector (`Test-Sensitivity.ps1`) are PowerShell—which runs on macOS and Linux too, so install `pwsh` there and the enforced path works the same. **Without it, pressure-test still runs**—it falls back to a single-context inline pass and tells you, plainly, that the enforced gate didn't run. The other three skills need no shell.
- These lean on Claude Code internals that move: skill frontmatter keys, the `${CLAUDE_SKILL_DIR}` substitution, `disallowed-tools` deny rules, and `claude -p --json-schema` structured output. They were **built and tested against Claude Code in mid-2026 (the Opus 4.x era).** If a mechanism behaves differently on your version, that's the first place to look—check the current Claude Code docs.

---

## A note on the security test fixtures

`pressure-test/tests/Run-DetectorTests.ps1` deliberately contains secret-*shaped* strings: a fake AWS key (AWS's own published `AKIAIOSFODNN7EXAMPLE`), a fake private-key block, the canonical test SSN `123-45-6789`, and Stripe's universal test card `4242 4242 4242 4242`. **Every value is fake**—standard published test data—and they're there so the detector can prove it catches them. A secret scanner pointed at this repo *will* flag that file. That's the trip-wire working, not a leak. (The runtime fixtures get generated into a temp dir and deleted after each run; nothing secret-shaped gets written into the tree.)

Check the detector yourself:

```bash
pwsh pressure-test/tests/Run-DetectorTests.ps1   # exit 0 = all pass
```

---

## Feedback & contributions

These got sharper every time someone poked a hole in them, so if you've got a genuinely good catch or idea, I want it. Bugs and concrete suggestions go in [Issues](https://github.com/robmcquade/claude-skills/issues); open-ended ideas and questions go in [Discussions](https://github.com/robmcquade/claude-skills/discussions); changes you want to make yourself go in a pull request (open an Issue first for anything bigger than a typo). [`CONTRIBUTING.md`](CONTRIBUTING.md) has the details.

---

## License

[MIT](LICENSE) © 2026 Rob McQuade. Use them, fork them, adapt them. If they earn their keep, a link back to [robmcquade.com/skills](https://robmcquade.com/skills) is appreciated—not required.
