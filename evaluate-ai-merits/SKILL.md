---
name: evaluate-ai-merits
description: Evaluate the merits of external content about Claude, Anthropic products, Claude Code, MCP servers, AI agents, prompt engineering, or AI tooling broadly. Adds AI-specific verification on top of evaluate-merits — routes to primary sources, applies heightened date-of-recording sensitivity (AI tooling ships weekly), flags AI-specific conflations (built-in vs custom add-ons, model-version vs universal guidance, surface differences between claude.ai/Code/API, deprecated features, opinion vs Anthropic guidance, preview vs GA). Use whenever the user shares content on Claude or AI tooling. Composes with evaluate-merits when both apply. Do NOT use for direct AI questions not referencing external content — those are web search and answer.
---

# Evaluate AI Merits

## When to invoke

Whenever external content under evaluation involves Claude, Anthropic products, Claude Code, AI coding workflows, MCP servers, AI agents, prompt engineering, or AI tooling broadly. Often fires alongside general evaluation on the same content; when content is mixed (e.g., "how I use AI for marketing"), this skill still applies to the AI-specific claims even when the dominant domain is something else.

Do not invoke for direct AI questions that don't reference external content — those are web search and answer, not evaluation.

## Primary-source routing

- **Anthropic product docs:** docs.claude.com (Claude API, claude.ai, Claude Code), support.claude.com (consumer-facing support)
- **Anthropic blog and announcements:** claude.com/blog, anthropic.com/news — official feature announcements and guidance
- **Claude Code docs:** the Claude Code section of docs.claude.com is the canonical reference for commands, flags, slash commands, and CLI behavior
- **Creator threads:** e.g., Boris Cherny's posts aggregated at howborisusesclaudecode.com. Verify by handle and posting date, not by name attribution alone — guidance evolves
- **Third-party MCP servers:** the vendor's own docs, not third-party summaries
- **Model behavior claims:** the model card or release notes for the specific version in question

When primary source contradicts the content being evaluated, the contradiction is the story — surface it.

## Date sensitivity

AI tooling ships weekly. Apply these rules:

- Check content upload date against the feature's current state
- Content older than ~3 months on rapidly-changing features has high decay risk
- Model-version-specific guidance (Opus 4.5 → 4.6 → 4.7, each with different defaults and behavior) is especially time-sensitive — guidance for one version often doesn't transfer to the next
- For announcement-style content, verify the feature actually shipped (vs. still in beta/preview, or quietly pulled)
- "Currently" and "now" and "the new X" in older content are red flags

## Common conflations to flag

- **Built-in features vs custom community add-ons.** A slash command in core Claude Code is not the same as a custom skill in a community plugin. Both are real; treating them as equivalent misleads.
- **Model-version-specific guidance presented as universal.** "Use xhigh effort" is 4.7-era guidance, not eternal truth.
- **Surface differences.** A feature may exist on Claude Code but not claude.ai, or vice versa. Anthropic API ≠ claude.ai chat ≠ Claude Code. Tips often assume one surface without saying which.
- **Active vs deprecated.** Features get renamed, deprecated, or replaced. Older content may reference command names or paths that no longer exist.
- **Creator's personal setup vs recommended defaults.** Boris's full setup is one example, not the recommended starting point. Same for any individual engineer's workflow post.
- **Opinion vs Anthropic guidance.** "Anthropic recommends X" should be checkable against actual docs or blog posts. If it traces back to one engineer's tweet, label it accordingly.
- **Beta/preview vs GA.** A feature in preview may not be available to all users and may change before GA.

## Verification rules specific to AI content

- Source hierarchy for Claude/Anthropic claims: Anthropic docs > Anthropic blog > creator threads > third-party summaries
- For commands and flags: verify exact spelling and case (YouTubers regularly transpose `--chrome` to `--Chrome`, miss hyphens, or invent slash commands that don't exist)
- For model behavior claims: confirm they apply to current model versions, not just the version the content was recorded against
- For "X says Y" attributions: find the original poster's thread and date, not a recap

## Failure modes

- Trusting a secondary recap of a creator's posts without checking the creator's actual posts and dates
- Treating "Boris said X" as current without checking when X was said — Boris's threads span months and his guidance evolves with each model release
- Missing that a feature was deprecated or renamed between content posting and evaluation
- Conflating claude.ai features with Claude Code features (or with API capabilities)
- Missing that a "rule" was one engineer's preference or experiment, not Anthropic guidance
- Recommending a preview-stage feature as if it were generally available
- Letting a YouTuber's confident tone substitute for verification — confidence is not accuracy
