# Antigravity Swarm Router

Orchestrator routing policy for Antigravity Swarm Mode using a **Default-Low, Escalate-High** strategy with **Quota Pool Isolation**.

## Model Configuration

Edit model IDs **here only** (and mirror `model:` in `.agent/skills/*/SKILL.md` if your runtime reads skill metadata directly). Check live IDs and quotas with `swarm{action: "models", all: true}`.

| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `gemini-4-argon-low` | `.agent/skills/board-updater/SKILL.md` | Board updates, card moves, status summaries, formatting (isolated quota pool) |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` | `.agent/skills/system-architect/SKILL.md` | Architecture design, DB modeling, root-cause analysis, multi-worker spec split |
| Tier 3 (Deep Coder) | `TIER_CODER` | `gemini-4-neon-high` | `.agent/skills/deep-coder/SKILL.md` | Multi-file refactoring, complex algorithms, concurrency/perf fixes, deep code reviews |

### Fallback Quota Pool

Switch to a fallback model from an independent quota pool via `swarm{action: "model", name, model}` or `swarm{action: "add", model}` when a primary pool drops below 20% or hits exhaustion:

| Tier | Fallback Model ID | Notes |
| :--- | :--- | :--- |
| `TIER_LOW` | `claude-sonnet-5-5-low` or `gemini-3.8-flash-low` | Use `claude-sonnet-5-5-low` to avoid Gemini pool |
| `TIER_ARCHITECT` | `claude-sonnet-5-5-medium` | Independent pool for design/RCA |
| `TIER_CODER` | `claude-opus-5-5-high` | Independent pool for heavy coding/reviews |

---

## Orchestrator Routing Rules

1. **Default to Tier 1 (`TIER_LOW` = `gemini-4-argon-low`)** for routine updates, formatting, and summaries so heavy `Hydrogen`/`Neon` quota is untouched.
2. **Single-Worker Threshold (Avoid Unnecessary Splits):**
   - If a task touches **1–2 files** with clear requirements and no cross-module ambiguity, **do not split Tier 2 -> Tier 3**. Route straight to one worker (`TIER_LOW` for text/boards, `TIER_CODER` for code).
3. **Route to Tier 2 (`TIER_ARCHITECT` = `gemini-4-hydrogen-high`)** only when the task needs system/DB modeling, multi-layer root-cause analysis, or splitting a large spec into non-overlapping worker tasks.
4. **Route to Tier 3 (`TIER_CODER` = `gemini-4-neon-high`)** for coordinated multi-file refactors, complex algorithms, concurrency/performance fixes, or deep code reviews.
5. **Swarm Mechanics:** Assign non-overlapping file ownership; use `workspace: "share"` for concurrent file editors and `inherit` for readers/board updaters.

---

## Token-Saving Rules

### 1. Minimal Context Handoff
- Pass **only** exact file paths, line ranges, symbol names, and acceptance criteria—never full chat history or raw logs.
- Reference prior board posts by `#seq` (`read_board{seqs:[7]}`) instead of copy-pasting specs.
- `@mention` only the agent that must act next (`@name` wakes that worker and costs a turn).

### 2. Concise Return
- Workers return **only**:
  - `@coordinator [done] [OK]` + modified file paths + concise summary/diff + test exit status
  - `@coordinator [ERROR]` + exact blocker + escalation target
- Zero preamble or restatement of the brief.

### 3. Fail-Fast & Warm-Context Escalation
- If `TIER_LOW` fails **once**, **stop immediately**—never loop or retry on Tier 1.
- **Warm Context:** If the worker already read large files, escalate in-place with `swarm{action: "model", name, model: "<TIER_ARCHITECT|TIER_CODER>"}` to keep its context.
- **Cold Context:** If Tier 1 failed before reading target files, spawn a Tier 2/3 worker via `swarm{action: "add"}` directly.
