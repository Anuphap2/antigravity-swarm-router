# Customizing Model Mappings

Edit the **Model Configuration** and **Fallback Quota Pool** tables at the top of `AGENTS.md`:

| Tier | Variable | Default Model ID | Quota Pool Strategy |
| :--- | :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `gemini-4-argon-low` | Isolated pool (preserves Hydrogen/Neon quota) |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` | High-reasoning Gemini pool |
| Tier 3 (Deep Coder) | `TIER_CODER` | `gemini-4-neon-high` | Deep coding Gemini pool |

## 1. Check Available Models & Live Quotas

```text
swarm{action: "models", all: true}
```

Look at `quotas.<model_id>.quota_remaining`. Pick a Tier 1 model in a **separate quota bucket** from Tier 2/3 so routine board updates do not drain your heavy-coding pool.

## 2. Example: Cross-Provider Fallback Mapping

```markdown
| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `claude-sonnet-5-5-low` | `.agent/skills/board-updater/SKILL.md` | Board updates, card moves, status summaries, formatting |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `claude-sonnet-5-5-medium` | `.agent/skills/system-architect/SKILL.md` | Architecture design, DB modeling, root-cause analysis, multi-worker spec split |
| Tier 3 (Deep Coder) | `TIER_CODER` | `claude-opus-5-5-high` | `.agent/skills/deep-coder/SKILL.md` | Multi-file refactoring, complex algorithms, concurrency/perf fixes, deep code reviews |
```

## 3. Sync Skill Frontmatter (Optional)

If your runtime reads `model:` directly from each `SKILL.md`, mirror the change in:

- `.agent/skills/board-updater/SKILL.md`
- `.agent/skills/system-architect/SKILL.md`
- `.agent/skills/deep-coder/SKILL.md`
