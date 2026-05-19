# 050 CI checkout Node 24 update

## Context

- GitHub Actions began annotating OpenPVA CI runs with a warning that Node.js 20
  actions are deprecated and will be forced onto Node.js 24 by default.
- The warning came from `actions/checkout@v4`.
- The warning did not cause the preceding `ci-heavy-validation` failure, but it
  is a near-term runner compatibility risk.

## Change

- Updated both CI workflows from `actions/checkout@v4` to
  `actions/checkout@v6`.

## Rationale

- Keeps OpenPVA CI ahead of GitHub's Node.js runner migration.
- This is a workflow-only compatibility update; it does not affect package code,
  lockfile contents, model behavior, or scientific outputs.
