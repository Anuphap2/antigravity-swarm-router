# Contributing to `antigravity-swarm-router`

Contributions are welcome—especially verified model compatibility reports, installer fixes, and reproducible benchmark runs.

## Guidelines

1. **Keep Core Skills Lean (`<= 5`):** Do not add niche micro-skills. Every skill injects `name` and `description` into context; keep `SKILL.md` focused and concise (recommended `~900–1,500` bytes so small models do not drop rules).
2. **Test Model Behavior First:** Before proposing a model in `AGENTS.md` or `examples/custom-models.md`, run [tests/swarm-smoke-test.md](tests/swarm-smoke-test.md) and confirm the model **both** edits files **and** calls `post_message` reliably (no silent `waiting` stalls).
3. **No Personal Paths or Secrets:** Never commit local user paths or tokens.
4. **Line Endings:** Keep `.sh` files as LF (`.gitattributes` enforces `*.sh text eol=lf`).

## Pull Request Checklist

- [ ] Tested `install.sh` (`bash -n` + `--preset` / `--update` / `--uninstall`) or `install.ps1`
- [ ] Verified no leaked paths or placeholders
- [ ] Included exact observed results if modifying routing rules or benchmarks
