# Antigravity Swarm Router

Orchestrator instructions for Antigravity Swarm Mode using a **Default-Low, Escalate-High** routing strategy.

## Model Configuration

Edit model IDs **here only** to re-map tiers across the swarm (and mirror any ID changes in the corresponding `.agent/skills/*/SKILL.md` frontmatter if your runtime inspects skill metadata directly).

Run `swarm{action: "models", all: true}` to verify available model IDs in your environment.

| Tier | Variable | Model ID | Skill Path | Primary Scope |
| :--- | :--- | :--- | :--- | :--- |
| Tier 1 (Default) | `TIER_LOW` | `gemini-3.8-flash-low` | `.agent/skills/board-updater/SKILL.md` | Board updates, card moves, short status summaries, formatting |
| Tier 2 (Architect) | `TIER_ARCHITECT` | `gemini-4-hydrogen-high` | `.agent/skills/system-architect/SKILL.md` | System/DB modeling, architecture design, root-cause analysis, spec breakdown |
| Tier 3 (Deep Coder) | `TIER_CODER` | `gemini-4-neon-high` | `.agent/skills/deep-coder/SKILL.md` | Multi-file refactoring, complex algorithms, concurrency/perf fixes, deep code reviews |

---

## Orchestrator Routing Rules

1. **Default to Tier 1 (`TIER_LOW` = `gemini-3.8-flash-low`)** for every task unless it clearly matches Tier 2 or Tier 3 criteria below.
2. **Route to Tier 2 (`TIER_ARCHITECT` = `gemini-4-hydrogen-high`)** when the task requires:
   - Designing system architecture, module boundaries, or API contracts
   - Database schema modeling or migration planning
   - Diagnosing non-obvious bugs (root-cause analysis across multiple layers)
   - Breaking an ambiguous or multi-part spec into non-overlapping worker tasks
3. **Route to Tier 3 (`TIER_CODER` = `gemini-4-neon-high`)** when the task requires:
   - Coordinated multi-file refactoring across shared interfaces
   - Implementing non-trivial algorithms, parsers, or state machines
   - Fixing race conditions, concurrency bugs, or performance bottlenecks
   - Conducting deep security or correctness code reviews
4. **Swarm Execution Mechanics:**
   - Assign explicit, non-overlapping file ownership before spawning workers.
   - Pass `model` explicitly from the **Model Configuration** table when calling `swarm` (`action: "add"`), and instruct the worker to load its assigned `.agent/skills/<skill>/SKILL.md`.
   - Use `workspace: "share"` for concurrent editors/builders; keep `workspace: "inherit"` for read-only reviewers and board updaters.

---

## Token-Saving Rules

### 1. Minimal Context Handoff
- Pass **only** the exact file paths, line ranges, symbol names, and acceptance criteria a worker needs.
- **Never** forward full conversation history, unrelated files, or unedited command logs into a worker brief.
- On the swarm board, reference prior posts by sequence number (`#4`) instead of copy-pasting another worker's report, and `@mention` only the agent that must act next (`@name` wakes that agent and costs a turn).

### 2. Concise Return
- Workers must return **only** actionable output using one of these prefixes:
  - `@coordinator [done] [OK]` followed by modified/created file paths, a brief diff or change summary, and verification output (exit code / test count).
  - `@coordinator [ERROR]` followed by the blocking reason and escalation target.
- Do not include conversational filler, restatements of the brief, or speculative commentary.

### 3. Fail-Fast Escalation
- If `TIER_LOW` (`gemini-3.8-flash-low`) fails **once** (wrong edit, failing test, missing context, or ambiguity), **stop immediately**.
- Do **not** retry or loop on `gemini-3.8-flash-low`. Escalate directly to:
  - `TIER_ARCHITECT` (`gemini-4-hydrogen-high`) if the failure stems from unclear design, spec gaps, or root-cause uncertainty.
  - `TIER_CODER` (`gemini-4-neon-high`) if the failure stems from implementation complexity or multi-file coupling.
