# Contributing

Thanks for taking the time—genuinely. These skills got sharper every time someone poked a hole in them, and outside eyes catch what I can't. If you've got a good catch or a real idea, I want it.

Here's where things go:

- **Found a bug?** A skill misbehaves, a script errors, or the docs don't match what actually happens → open a **Bug report** [Issue](https://github.com/robmcquade/claude-skills/issues/new/choose). Tell me which skill, what you did, what happened, and what you expected. A copy-pasteable repro beats a description every time.
- **Have a suggestion or an idea?** A sharper lens, a missing failure mode, a new skill worth building → open a **Suggestion** [Issue](https://github.com/robmcquade/claude-skills/issues/new/choose). Lead with the problem it solves, not just the fix.
- **Just thinking out loud?** Open-ended ideas, questions, "have you considered…" → start a [Discussion](https://github.com/robmcquade/claude-skills/discussions). No bug, no ask required.
- **Want to make the change yourself?** Open a pull request. For anything bigger than a typo, open an Issue or Discussion first so we're aligned before you spend the time—I'd hate for good work to miss.

A few things worth knowing before you dig in:

- **Keep the voice and the honesty.** These skills disclose what they *enforce* versus what's left to judgment, and they never claim more rigor than they have. Changes that overclaim get sent back—that honesty is the whole point.
- **pressure-test is script-backed.** If you touch `Invoke-PressureTest.ps1` or `Test-Sensitivity.ps1`, run the detector self-test and say so in the PR:
  ```bash
  pwsh pressure-test/tests/Run-DetectorTests.ps1   # exit 0 = all pass
  ```
- **No real secrets, ever.** The test fixtures use published fake values (AWS's documented example key, Stripe's test card) on purpose. Keep it that way.

By contributing, you agree your contribution is licensed under the repo's [MIT license](LICENSE). No CLA, no checklist theater. Good feedback is the whole point.
