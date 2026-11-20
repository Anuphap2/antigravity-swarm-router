# Antigravity Swarm Router

Orchestrator routing policy for Antigravity Swarm Mode using a **Default-Low, Escalate-High** strategy with **Quota Pool Isolation** and **Warm/Async Execution**.

## Model Configuration

Edit model IDs **here only** (and mirror `model:` in `.agent/skills/*/SKILL.md` if your runtime reads skill metadata directly). Check live IDs and quotas with `swarm{action: "models", all: true}`.

| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Board) | `TIER_LOW` | `gemini-4-argon-low` | `.agent/skills/board-updater/SKILL.md` | Board file updates, card moves, status summaries, formatting (isolated pool) |
| Tier 1 (Tests) | `TIER_LOW` | `gemini-4-argon-low` | `.agent/skills/test-runner/SKILL.md` | Run tests/linters/builds, strip noise, return only failing stack trace |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` | `.agent/skills/system-architect/SKILL.md` | Architecture design, DB modeling, root-cause analysis, line-range spec split |
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

1. **Default to Tier 1 (`TIER_LOW` = `gemini-4-argon-low`)** for board file edits, formatting, summaries, and test/linter runs so heavy `Hydrogen`/`Neon` quota is untouched.
2. **Offload Verbose Test Logs to `test-runner`:** Before asking `TIER_CODER` (`gemini-4-neon-high`) to debug a failing suite, run the suite on `test-runner` so `TIER_CODER` receives only the failing test ID and minimal traceback (`#seq` reference).
3. **Single-Worker Threshold:** If a task touches **1–2 files** with clear requirements and no cross-module ambiguity, **do not split Tier 2 -> Tier 3**. Route straight to one worker (`TIER_LOW` for text/boards, `TIER_CODER` for code).
4. **Route to Tier 2 (`TIER_ARCHITECT`)** for system/DB modeling, multi-layer root-cause analysis, or splitting large specs; **route to Tier 3 (`TIER_CODER`)** for heavy multi-file refactors, algorithms, concurrency/perf fixes, or deep reviews.
5. **Swarm Mechanics:** Assign non-overlapping file ownership; use `workspace: "share"` for concurrent file editors and `inherit` for readers, `test-runner`, and `board-updater`.

## Latency & Lifecycle Optimization

- **Micro-Task Bypass:** If a task requires **no file edits** and only a single short `post_message` (e.g., status update or ack), `@coordinator` executes it directly. Do NOT spawn `board-updater` for zero-edit micro-tasks.
- **Async Board Updates (Non-Blocking):** When `board-updater` edits do not block downstream code tasks (and touch separate files), dispatch `@board-updater` **in parallel** with `system-architect` or `deep-coder`. Do NOT wait for board confirmation before starting code work.
- **Warm Tier-1 Worker (Reuse):** For multi-step swarms with repeated board/test tasks, keep one Tier-1 worker (`@board-updater` or `@test-runner`) alive and reuse it via `@mention` instead of spawning/killing per turn.
  - **Context Cap:** Kill and respawn a warm worker after **5–6 turns** to prevent context bloat, and always kill it when the swarm finishes.

---

## Token-Saving Rules

### 1. Minimal Context & Targeted Line-Range Handoff
- Pass **only** exact `file_path:startLine-endLine` ranges, symbol names, and acceptance criteria—never full chat history, whole-file dumps, or raw logs.
- Reference prior board posts by `#seq` (`read_board{seqs:[7]}`) instead of copy-pasting specs or test logs.
- `@mention` only the agent that must act next (`@name` wakes that worker and costs a turn).

### 2. Concise Return
- Workers return **only**:
  - `@coordinator [done] [OK]` / `[FAIL]` + modified file paths + concise summary/diff or compressed failure trace
  - `@coordinator [ERROR]` + exact blocker + escalation target
- Zero preamble or restatement of the brief.

### 3. Fail-Fast & Stuck-Worker Watchdog
- If `TIER_LOW` fails **once**, **stop immediately**—never loop or retry on Tier 1.
- **Warm vs. Cold Escalation:** If a worker already read large files, escalate in-place with `swarm{action: "model", name, model: "<TIER_ARCHITECT|TIER_CODER>"}` to keep its context; **kill it (or revert to `TIER_LOW`) immediately after the escalated task** so it never stays warm on a heavy model. If it failed cold, `add` a Tier 2/3 worker directly.
- **Stuck-Worker Watchdog:** On `swarm{action: "status"}`, if a briefed worker enters `waiting` (or stays silent past expected completion) **without posting** `[done]` or `[ERROR]`, treat it as a silent-stall bug: `swarm{action: "kill", name: "<worker>"}` immediately and re-run on the **Fallback Quota Pool** (`claude-sonnet-5-5-low` for Tier 1). Cap at **1 fallback retry**—if fallback also stalls, stop and report to the user.
