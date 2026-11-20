# Customizing Model Mappings

By default, `antigravity-swarm-router` maps three tiers in the **Model Configuration** table at the top of `AGENTS.md`:

| Tier | Variable | Default Model ID |
| :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `gemini-3.8-flash-low` |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` |
| Tier 3 (Deep Coder) | `TIER_CODER` | `gemini-4-neon-high` |

## 1. Check Available Models

In Antigravity Swarm Mode, list all model IDs accepted by your environment before editing:

```text
swarm{action: "models", all: true}
```

## 2. Swap Models in `AGENTS.md`

Update the **Model Configuration** table at the top of `AGENTS.md`. Example swapping to alternative tiers (e.g., `gemini-4-argon-low` for Tier 1, `claude-sonnet-5-5-medium` for Tier 2, `gemini-4-neon-xhigh` for Tier 3):

```markdown
| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `gemini-4-argon-low` | `.agent/skills/board-updater/SKILL.md` | Board updates, card moves, short status summaries, formatting |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `claude-sonnet-5-5-medium` | `.agent/skills/system-architect/SKILL.md` | System/DB modeling, architecture design, root-cause analysis, spec breakdown |
| Tier 3 (Deep Coder) | `TIER_CODER` | `gemini-4-neon-xhigh` | `.agent/skills/deep-coder/SKILL.md` | Multi-file refactoring, complex algorithms, concurrency/perf fixes, deep code reviews |
```

> **Note:** Use exact model IDs returned by `swarm{action: "models", all: true}` in your Antigravity session.

## 3. Sync Skill Frontmatter (Optional)

If you use tooling that reads `model:` directly from each `SKILL.md` YAML frontmatter, update the `model:` line in:

- `.agent/skills/board-updater/SKILL.md`
- `.agent/skills/system-architect/SKILL.md`
- `.agent/skills/deep-coder/SKILL.md`

Example:

```yaml
---
name: board-updater
description: Tier 1 lightweight worker for board updates, moving cards, short status summaries, and formatting tasks.
model: gemini-4-argon-low
tier: 1
---
```
