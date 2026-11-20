# Antigravity Swarm Smoke-Test & Model Benchmark

Use this guide to verify which model IDs in your Antigravity account work reliably with `antigravity-swarm-router` (specifically checking **file edit + `post_message` compliance**, **latency**, and **`test-runner` log compression**).

## Step 1: Check Available Model IDs

Run in Antigravity:

```text
swarm{action: "models", all: true}
```

Confirm your `TIER_LOW`, `TIER_ARCHITECT`, and `TIER_CODER` IDs in `AGENTS.md` exist in the returned `models` array.

---

## Step 2: Run the 4-Check Swarm Smoke Test

Paste this prompt into an Antigravity session inside a disposable test folder (or temporary directory):

```text
Run a temporary Swarm smoke test in a new temp directory (clean it up after):
1. Create BOARD_TEST.md (3-row Markdown table with T-2 status TODO) and failing_math.py (with a failing unittest that prints 50+ lines of verbose output).
2. Spawn a Tier 1 `board-updater` worker (using TIER_LOW from AGENTS.md) to mark T-2 DONE and append T-4. Record:
   - Did it edit BOARD_TEST.md?
   - Did it call `post_message` (not stall silently in `waiting`)?
   - Wall-clock seconds and reply character count.
3. Spawn a Tier 1 `test-runner` worker (using TIER_LOW from AGENTS.md) to run `python -m unittest -v` on failing_math.py. Record:
   - Raw stdout+stderr byte size vs compressed `[FAIL]` board message byte size.
4. Spawn a Tier 1 worker on a non-existent file `MISSING.md` to verify 1-turn Fail-Fast (`@coordinator [ERROR] ... -> ESCALATE(...)`).
5. Report results as a Markdown table, then kill test workers and delete the temp folder.
```

---

## Step 3: Pass Criteria

| Check | Expected Pass Condition | If It Fails |
| :--- | :--- | :--- |
| **Board Update (`TIER_LOW`)** | Edits file accurately **and** posts `@coordinator [done] [OK]` | If it edits silently without `post_message` (Stuck-Worker bug), switch `TIER_LOW` to `claude-sonnet-5-5-low` or `gemini-3.8-flash-low` |
| **Test Runner (`TIER_LOW`)** | Extracts only failing test name + `file:line` + core error (compressed >=70% vs raw log) | Switch `test-runner` model in `AGENTS.md` |
| **Fail-Fast Escalation** | Stops in **1 turn** with `@coordinator [ERROR] ... -> ESCALATE(...)` | Check `.agent/skills/board-updater/SKILL.md` is loaded |

*Tested on Antigravity (Nov 2026) — `gpt-oss-120b-medium` was observed failing the `post_message` compliance check (silent `waiting`), whereas `gemini-4-argon-low`, `claude-sonnet-5-5-low`, and `gemini-3.8-flash-low` passed.*
