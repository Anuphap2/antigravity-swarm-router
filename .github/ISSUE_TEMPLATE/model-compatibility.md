---
name: Model Compatibility Report
about: Report a model ID change, quota pool pairing, or silent-stall bug in Antigravity Swarm Mode
title: "[Model]: "
labels: enhancement
---

## Model Details
- **Model ID:** (from `swarm{action: "models", all: true}`)
- **Intended Tier:** Tier 1 (`board-updater` / `test-runner`) | Tier 2 (`system-architect`) | Tier 3 (`deep-coder`)

## Smoke-Test Results (`tests/swarm-smoke-test.md`)
- Edited target file cleanly? (Yes/No)
- Called `post_message` (`@coordinator [done]`) without silent `waiting` stall? (Yes/No)
- Observed wall-clock latency:
- Separate quota pool from `Hydrogen`/`Neon`? (Yes/No)
