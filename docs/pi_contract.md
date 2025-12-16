# PI contract and review loop (OpenPVA)

This repo is developed under an “AI for Science / AI for Engineering” contract:

- **Codex CLI agent** = autonomous engineer (implements, tests, documents).
- **GPT‑5.2 Pro** = PI / tech lead (reviews ZIP snapshots, sets high-level direction).
- **Human maintainer** = coordinator (runs Codex, merges, zips for review).

## Review cadence

1. Codex works autonomously following `AGENTS.md` and `docs/plan.md`.
2. When Codex declares a milestone ready, the human zips the repo and sends to the PI (GPT‑5.2 Pro).
3. PI responds with:
   - critique,
   - a numbered revision plan with stopping rules,
   - a “Block for Codex” for the next sprint.
4. Repeat for 0–3 rounds per milestone. If >3 rounds are needed, the plan is likely wrong and must be reframed.

## Key principle

The human must not become the command-relay bottleneck.
The repository documents (`docs/*` + git history) are the persistent memory and source of truth.
