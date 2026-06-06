# claude-skills

Four production-grade [Claude Code](https://www.claude.com/product/claude-code) skills for doing serious thinking work — stress-testing an artifact, rewriting it stronger, setting a verifiable autonomous-loop goal, and fact-checking content about AI tooling. Each one is built around a single idea: **fresh, unanchored judgment beats a model grading its own work** — and where a missed step would produce confidently-wrong output, the skill enforces it deterministically instead of hoping the model remembers.

Built and maintained by [Rob McQuade](https://robmcquade.com/skills).

---

## The skills

| Skill | What it does | Invoke |
|---|---|---|
| **pressure-test** | Stress-tests a piece of real work — surfaces strengths, weaknesses, hidden assumptions, failure modes, and prior art, then hands back prioritized fixes. Finds and prescribes; does not rewrite. | `/pressure-test [deep]` |
| **improve** | Takes an artifact, idea, or argument and returns a materially stronger *rewritten* version — verified for drift and regressions before it reaches you. Produces the result. | `/improve [deep]` |
| **set-goal** | Composes a strong, machine-checkable condition for Claude Code's built-in `/goal` autonomous loop, validated against the transcript-only rule so the loop actually terminates. | `/set-goal [deep]` |
| **evaluate-ai-merits** | Fact-checks external content about Claude, Anthropic products, MCP, agents, or AI tooling — routes to primary sources and flags the conflations that date fast (model-version, surface, preview-vs-GA). | (auto-fires on AI content, or invoke directly) |

### The flagship pairing: `pressure-test` → `improve`

These two are opposite halves of one pipeline and the reason this repo exists:

- **`/pressure-test`** *finds and prescribes* — it spins up a panel of fresh-context critics that never saw how the work was made, so they critique the thing, not the story behind it. You get diagnosis plus a specific fix for each weakness.
- **`/improve`** *executes* — it runs an evaluator-optimizer loop (a fresh critic finds what's weak, the work is revised, repeated until it converges) and an independent verifier checks the rewrite for meaning-drift and voice-flattening before you ever see it.

Run them in sequence: pressure-test to find the problems, improve to fix them. Hand `/improve` the recommendations from `/pressure-test` and it treats them as the first critique pass.

Each skill ships with a plain-language **`EXPLAINER.md`** (what it is and why it's built that way) alongside the operating **`SKILL.md`**.

---

## Why these are built the way they are

The common thread across all four is a refusal to let the model grade its own homework:

- **Fresh context, not self-review.** A model that just helped build something tends to restate and justify its own reasoning when asked to critique it — confirmation bias, baked in. pressure-test and improve push the critique into separate processes that were handed only the artifact and the goal.
- **Enforcement where forgetting is expensive.** A security document reviewed at shallow depth reads exactly like a clean one. So pressure-test's sensitivity escalation, panel size, quote-existence check, and egress firewall are owned by a deterministic orchestrator script — the model does *judgment inside the gates*, not the gating itself. What's enforced versus left to judgment is spelled out honestly in [`pressure-test/references/enforcement-model.md`](pressure-test/references/enforcement-model.md).
- **Bounded loops.** improve's loop is anchored to a stated goal, the evaluator (never the reviser) owns the stop, and there's a hard pass cap — so it can't polish forever. set-goal exists to make the *outer* `/goal` loop terminate by forcing a condition the evaluator can actually verify from the transcript.
- **Honest degradation.** On a surface without a shell or subagents (e.g. the claude.ai web app), the enforced machinery can't run. Each skill detects this, runs the same logic single-context, and **leads with the disclosure** rather than pretending it ran the full path.

---

## Install

Claude Code loads skills from `~/.claude/skills/` (personal, all projects) or a project's `.claude/skills/` (that repo only). Drop the skill directories into either.

**Personal install (recommended):**

```bash
git clone https://github.com/robmcquade/claude-skills.git
cd claude-skills

# copy the skills you want into your personal skills dir
mkdir -p ~/.claude/skills
cp -r pressure-test improve set-goal evaluate-ai-merits ~/.claude/skills/
```

On Windows (PowerShell):

```powershell
git clone https://github.com/robmcquade/claude-skills.git
Set-Location claude-skills
New-Item -ItemType Directory -Force "$HOME\.claude\skills" | Out-Null
foreach ($s in 'pressure-test','improve','set-goal','evaluate-ai-merits') {
  Copy-Item -Recurse -Force ".\$s" "$HOME\.claude\skills\$s"
}
```

Each skill directory must keep its structure intact — `SKILL.md` at the root, plus the bundled `scripts/`, `schemas/`, and `references/` for pressure-test. Restart Claude Code (or start a new session) and the skills appear; invoke with `/pressure-test`, `/improve`, `/set-goal`. (`evaluate-ai-merits` can fire automatically on AI-tooling content, or be invoked directly.) Three of the four are marked user-invoked only (`disable-model-invocation: true`) — they never fire on their own.

---

## Requirements

- **Claude Code.** These are Claude Code skills, not API prompts or chat-only content.
- **PowerShell 7 (`pwsh`) for pressure-test's enforced mode.** The pressure-test orchestrator (`Invoke-PressureTest.ps1`) and sensitivity detector (`Test-Sensitivity.ps1`) are PowerShell — which is cross-platform; install `pwsh` on macOS or Linux and the enforced path works there too. **Without `pwsh`, pressure-test still runs** — it falls back to its inline single-context mode (Mode A) and discloses that the enforced gate did not run. The other three skills have no shell dependency.
- The skills lean on Claude Code internals that evolve: skill frontmatter keys, the `${CLAUDE_SKILL_DIR}` substitution, `disallowed-tools` deny rules, and `claude -p --json-schema` structured output. They were **built and tested against Claude Code in mid-2026 (Opus 4.x era).** If a mechanism behaves differently on your version, that's the likely cause — check the current Claude Code docs.

---

## A note on the security test fixtures

`pressure-test/tests/Run-DetectorTests.ps1` deliberately contains secret-*shaped* strings — a fake AWS key (AWS's own documented `AKIAIOSFODNN7EXAMPLE`), a fake private-key block, the canonical test SSN `123-45-6789`, and Stripe's universal test card `4242 4242 4242 4242`. **Every value is fake**, standard published test data; they exist so the detector can prove it catches them. A secret scanner run over this repo *will* flag that file — that's the detector's own trip-wire data, not a leak. (The runtime fixtures are generated into a temp dir and deleted after each run; nothing secret-shaped is written into the tree.)

You can verify the detector yourself:

```bash
pwsh pressure-test/tests/Run-DetectorTests.ps1   # exit 0 = all pass
```

---

## License

[MIT](LICENSE) © 2026 Rob McQuade. Use them, fork them, adapt them. If they're useful, a link back to [robmcquade.com/skills](https://robmcquade.com/skills) is appreciated but not required.
