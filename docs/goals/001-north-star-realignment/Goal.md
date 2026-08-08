# Goal 001 — North Star and architecture realignment

## Objective

Make OpenPVA's modern, open-R successor mission authoritative and reviewable:

> The modeller defines the biological program; OpenPVA supplies the execution
> engine, reusable processes, scientific contracts, and reproducible analysis
> machinery.

Ground that mission in verified GAPPS use, specify a minimal credible grizzly
reference model, define the smallest R-native lifecycle-process contract that
allows community processes without controller edits, and map the shortest route
from the current fixed dispatcher to that target.

## Scientific decision

The deliverable supports a product and architecture decision, not a new estimate
of grizzly viability. The grizzly model is an acceptance benchmark: it must show
that alternative lifecycle and management assumptions can be stated, run,
inspected, and tested. Its parameter values are not scientific defaults.

## Read first

1. `docs/vision_and_scope.md`
2. `docs/literature/gapps_evidence_review.md`
3. `docs/design/canonical_grizzly_reference_model.md`
4. `docs/design/lifecycle_process_contract.md`
5. `docs/design/realignment_gap_map.md`
6. `docs/architecture_core.md`

## Starting state

- Assigned repository state: clean `main...origin/main` at `03d99b3`.
- Observed at start of this authoring pass: clean `main...origin/main`.
- Current lifecycle order accepts six labels and dispatches them through
  conditionals in `R/simulation_core.R`.
- Reproduction creates newborns without copying maternal `patch_id`; this is a
  recorded implementation defect, not part of this docs-only goal.
- Existing spatial, genetic, uncertainty, calibration, YAML, and reporting
  capabilities are real, but breadth does not substitute for a programmable
  biological process contract or a canonical empirical benchmark.

## Scope

- North Star, heritage, literature, architecture, canonical-model, lifecycle
  contract, gap map, current-facing index/plan/decision documentation.
- Stable citations and explicit separation of observation, inference, and
  OpenPVA design choice.
- Documentation-only validation.

## Non-goals

- No R code, tests, YAML, Quarto, package metadata, artefacts, or releases.
- No numerical grizzly parameterisation or claim of management suitability.
- No DSL, registry, plugin manager, dependency-injection framework, or class
  hierarchy.
- No backward-compatibility layer for the future realignment.
- No commit, push, tag, release, checkout, reset, clean, or stash.

## Review surface

Reviewers should decide whether:

1. the North Star is biologically and architecturally precise;
2. historical claims match the cited evidence and caveats;
3. the grizzly benchmark is minimal but scientifically credible;
4. an ordered list of validated process objects is sufficient;
5. the gap classification and staged route are proportionate;
6. locked RNG, field/birth, event, time/census, and expected-value-oracle
   defaults are lean enough for Stage 1.

## Authority and pause conditions

This goal may resolve documentation wording and the approved reversible
mechanics. Barry's remaining decision is strategic acceptance of the package.
Pause if an empirical biological default, materially different product scope,
or implementation is needed to support a claim.

## Validation

Only:

- inspect the exact diff and diffstat;
- run `git diff --check`;
- search current-facing docs for stale Phase-1 claims and contradictory fixed-
  lifecycle language;
- verify all referenced internal paths exist;
- make lightweight metadata checks for cited sources.

Do not run R, `renv`, tests, package checks, `targets`, Quarto, builds, release
automation, or linters.

## Completion criterion

Complete when the listed documentation is internally coherent, evidence-grounded,
and sufficient for review of the next implementation decision. Publication is
outside this goal.
