---
name: swarm-router
description: Swarm coordinator entrypoint (/swarm-router) that routes tasks across Tier 1 (board-updater, test-runner), Tier 2 (system-architect), and Tier 3 (deep-coder) using Default-Low, Escalate-High, warm reuse, and quota pool isolation.
---

# Swarm Router (`/swarm-router`)

Act as the **Swarm Coordinator** for the user's task using **Default-Low, Escalate-High** routing.

## 1. Load Model Config
- If workspace `AGENTS.md` exists, use its **Model Configuration** and **Fallback Quota Pool** tables.
- Otherwise use defaults:
  - `TIER_LOW` = `gemini-4-argon-low` (fallback: `claude-sonnet-5-5-low` or `gemini-3.8-flash-low`)
  - `TIER_ARCHITECT` = `gemini-4-hydrogen-high` (fallback: `claude-sonnet-5-5-medium`)
  - `TIER_CODER` = `gemini-4-neon-high` (fallback: `claude-opus-5-5-high`)

## 2. Route & Execute
1. **Micro-Task Bypass:** Zero-edit 1-line status post -> execute directly, do not spawn a worker.
2. **Single-Worker Threshold:** Clear 1–2 file task -> route to **1 worker** (`TIER_LOW` for board/tests, `TIER_CODER` for code); skip Tier 2 -> Tier 3 split.
3. **Multi-Step Swarm:** Assign non-overlapping file ownership (`workspace: "share"` for concurrent editors, `inherit` for readers/board/tests) and spawn via `swarm{action: "add", model, brief}`:
   - Board/formatting -> `TIER_LOW` + `board-updater` skill (dispatch **async/parallel**; never block code work)
   - Verbose tests/linters -> `TIER_LOW` + `test-runner` skill (pass only compressed `#seq` failure trace to `TIER_CODER`)
   - Architecture/RCA/spec split -> `TIER_ARCHITECT` + `system-architect` skill (require `file_path:startLine-endLine` handoffs)
   - Heavy code/concurrency/review -> `TIER_CODER` + `deep-coder` skill (read only handed-off line ranges)
4. **Warm Tier-1 Reuse:** Keep 1 Tier-1 worker alive in `waiting` and reuse via `@mention`; kill/respawn after **5–6 turns** or when done.

## 3. Fail-Fast & Watchdog
- **1-Strike Escalate:** If `TIER_LOW` fails once, stop retrying. Escalate in-place via `swarm{action: "model"}` if warm (then **kill or revert to `TIER_LOW`** right after), or `add` Tier 2/3 if cold.
- **Silent-Stall Watchdog:** If a briefed worker enters `waiting` without posting `[done]`/`[ERROR]`, `kill` it and retry once on the Fallback Pool; if fallback stalls, stop and report to the user.
