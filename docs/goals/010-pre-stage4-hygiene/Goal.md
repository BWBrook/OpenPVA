# Goal 010 - Pre-Stage 4 hygiene

## Objective

Reduce repeated validation and dormant delivery machinery so the accepted
process-native package enters Stage 4 with one lean test, CI, environment and
documentation surface.

## Required outcomes

1. Right-size repeated module tests and Monte Carlo workloads while preserving
   distinct scientific oracles, process-order consequences, engine contracts,
   accounting, RNG and pedigree evidence.
2. Remove duplicate CI test invocations; retain R 4.6.1 restore, lint, source
   build and both ordinary and heavy package-check profiles.
3. Delete the obsolete Quarto project and generated residue without replacement.
4. Remove dormant YAML, `targets` and Quarto package dependencies and snapshot
   the executable runtime/development closure.
5. Reconcile current programme and delivery records without altering historical
   evidence.

## Non-goals

Stage 4 implementation, scientific/API behavior changes, new dependencies,
dependency installation or upgrade, historical artefact pruning, release,
commit or publication.

## Acceptance evidence

- Before/after test inventory and runtime are recorded.
- The full suite and a canonical grizzly accounting smoke pass.
- `renv::status()` is clean and the lock remains on R 4.6.1.
- `actionlint`, lint, residue scans, Collate/NAMESPACE, and `git diff --check`
  pass.
- A fresh isolated R 4.6.1 source build and ordinary check return `Status: OK`.

## Publication boundary

No staging, commit, push, tag, release or publication is authorised.
