# Reproducible Multi-Step Benchmark

Reproduce the multi-step pipeline benchmark (`pricing_service.py` + `test_pricing.py` + `BOARD.md`) in under 2 minutes.

## 1. Generate the Fixture

```bash
python tests/setup-bench.py /tmp/swarm-bench
```

*(On Windows PowerShell: `python tests/setup-bench.py $env:TEMP\swarm-bench`)*

This creates:
- `pricing_service.py` (141 lines; `apply_discount` bug at lines 123–129)
- `test_pricing.py` (prints 40 noisy passing log lines + 1 failing test, ~2 KB raw output)
- `BOARD.md` (status table to update across rounds)

## 2. Run `/swarm-router` on the Fixture

Open Antigravity in the fixture folder (with `antigravity-swarm-router` installed) and run:

```text
/swarm-router Fix the discount bug in pricing_service.py, verify with test_pricing.py (run tests via test-runner), and keep BOARD.md updated across TODO -> IN_PROGRESS -> VERIFYING -> DONE.
```

## 3. Measure & Compare

Record from `swarm{action: "status"}`, `read_board{since: 0}`, and `swarm{action: "models"}`:

1. **Worker Spawns vs. Tasks:** Verify `@board-updater` and `@test-runner` are reused warm (expected: 4 spawns for 7 sub-tasks).
2. **Line-Range Read Scope:** Check `v31-arch` handoff cites `pricing_service.py:123-129` (7 / 141 lines = `-95.0%`).
3. **Log Compression:** Compare `python /tmp/swarm-bench/test_pricing.py` raw output chars vs. `test-runner` board post chars.
4. **Quota Isolation:** Compare `quotas` before and after (`Argon`/`Claude` handles Tier 1 turns with `0%` drain on `Hydrogen`/`Neon`).
5. **Wall-Clock Time:** Compare end-to-end duration from first `add` to final `[done]` post.
