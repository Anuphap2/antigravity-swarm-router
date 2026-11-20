# Customizing Model Mappings

Edit the **Model Configuration** and **Fallback Quota Pool** tables at the top of `AGENTS.md`, or pick a built-in preset at install time (`--preset quota-saver | balanced | speed-first`):

| Tier | Variable | Default (`quota-saver`) | `balanced` | `speed-first` |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (`board-updater` & `test-runner`) | `TIER_LOW` | `gemini-4-argon-low` | `claude-sonnet-5-5-low` | `gemini-3.8-flash-low` |
| Tier 2 (`system-architect`) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` | `gemini-4-hydrogen-high` | `gemini-4-hydrogen-high` |
| Tier 3 (`deep-coder`) | `TIER_CODER` | `gemini-4-neon-high` | `gemini-4-neon-high` | `gemini-4-neon-high` |

## 1. Check Available Models & Live Quotas

```text
swarm{action: "models", all: true}
```

Inspect `quotas.<model_id>.quota_remaining`. Pick a Tier 1 model in a **separate quota bucket** from Tier 2/3 so routine board updates and test runs do not drain your heavy-coding pool.

## 2. Example: Cross-Provider Fallback Mapping

```markdown
| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Board) | `TIER_LOW` | `claude-sonnet-5-5-low` | `.agent/skills/board-updater/SKILL.md` | Board updates, card moves, status summaries, formatting |
| Tier 1 (Tests) | `TIER_LOW` | `claude-sonnet-5-5-low` | `.agent/skills/test-runner/SKILL.md` | Run tests/linters/builds, strip noise, return only failing stack trace |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `claude-sonnet-5-5-medium` | `.agent/skills/system-architect/SKILL.md` | Architecture design, DB modeling, root-cause analysis, multi-worker spec split |
| Tier 3 (Deep Coder) | `TIER_CODER` | `claude-opus-5-5-high` | `.agent/skills/deep-coder/SKILL.md` | Multi-file refactoring, complex algorithms, concurrency/perf fixes, deep code reviews |
```

## 3. Sync Skill Frontmatter (Optional)

If your runtime reads `model:` directly from each `SKILL.md`, mirror the change in:

- `.agent/skills/board-updater/SKILL.md`
- `.agent/skills/test-runner/SKILL.md`
- `.agent/skills/system-architect/SKILL.md`
- `.agent/skills/deep-coder/SKILL.md`

Then run the checks in [tests/swarm-smoke-test.md](../tests/swarm-smoke-test.md) to verify `edit + post_message` compliance before using new models in production swarms.
