# OpenPVA plan and roadmap (agent-maintained)

> This file is a living roadmap. The Codex agent must keep it current.

## 1) Purpose

OpenPVA is a transparent, modular, reproducible individual-based PVA framework in R,
built around `renv` + `targets` + Quarto + YAML scenarios.

The aim is production-quality research software:
stable core API, documented scenario schema, strong tests, and reproducible demos.

## 2) Current status (to be filled by the agent)

- Repo structure summary:
  - Repository has a coherent R-package layout with lifecycle modules,
    scenario compilers, targets pipeline, Quarto demo content, and staged
    artefact bundles through `artefacts/WP-2B.6/`.
- Core simulation/controller status:
  - `run_basic_simulation()` / `run_basic_simulation_replicates()` support
    optional `record_population_history` capture for time-series spatial/genetic
    summaries.
  - Reproduction uses a single explicit baseline-rate pathway:
    `breeding_prob_fun` + `fecundity_lambda_fun` with controller-owned draws.
  - Density is configured explicitly through `density_spec()` and
    channel-specific YAML `density` blocks.
- YAML scenario status:
  - YAML ingestion (`read_scenario_yaml()`) now targets a single canonical
    `schema_version: 3` with explicit demography, density, management, and
    uncertainty blocks.
  - Packaged spatial/genetic scenario trio added under `inst/extdata/`:
    fragmented, connected, and asymmetric flow regimes.
- `targets` pipeline status:
  - Core targets remain runnable; smoke runs are used as reproducibility gates
    in artefact cycles and CI-heavy profile.
  - Default demo targets are intentionally smoke-sized for laptop-friendly
    fresh-checkout validation rather than heavy ensemble benchmarking.
- Quarto demos status:
  - Quarto project renders to `quarto/_site`.
  - Demo now includes spatial/genetic interpretation workflow guidance:
    endpoint vs time-series vs connectivity diagnostics.
- Tests status:
  - The canonical suite is green under R `4.6.1` (`561` pass, `0` fail,
    `0` warn, `0` skip).
  - Regression coverage targets retained controller behaviour, canonical YAML,
    spatial/genetic summaries, output contracts, and seeded reproducibility.
  - Package-native test entrypoint is `Rscript scripts/run_tests.R`, avoiding
    an unnecessary hard dependency on `devtools` for fresh restores.
  - The current Mac/CI reproducibility baseline is Homebrew R `4.6.1`; see
    `docs/log/053_r461_macos_ci_readiness_closure.md`.
  - Goal 001's R `4.6.1` baseline and libuv CI repair are published on
    `origin/main` at `a814fff` and confirmed by successful push-triggered
    `ci-fast` run `29474478675`.
- Package check status:
  - Tarball-based `R CMD check --no-manual --as-cran` passes with `0` errors
    and `0` warnings (`2` known notes; see
    `artefacts/release_1.0.0-rc4/00check.log`).
- Known failing tests / TODOs:
  - No known failing tests in canonical invocation.
  - Priority Queue is currently exhausted through `WP-2B.6`; next execution
    requires roadmap promotion of additional WPs.

## 3) Definition of Done for the next “reviewable milestone”

A milestone is “reviewable” when:

- `renv::restore()` works from a clean checkout (or equivalent documented process).
- Tests run and pass (or failures are explicitly documented + justified).
- `targets` pipeline runs cleanly (or a defined minimal subset).
- Quarto demo(s) render (or a defined minimal subset).
- The milestone has:
  - a short log entry in `docs/log/`,
  - interpretation notes in `docs/interpretation_notes.md`,
  - any key design choices recorded in `docs/decisions.md`.

## 4) Workstreams

### W1 — Core engine reliability
- Maintain invariants: individual/population representations, lifecycle module interfaces, controller semantics.
- Improve error messages and input validation where needed.
- Add regression tests for key engine behaviours.

### W2 — Scenario and YAML stability
- Keep one canonical YAML schema and document it clearly.
- Tighten function resolution to OpenPVA-owned names or explicit `pkg::fun`.
- Add tests for YAML parsing + scenario compilation + simulation run.

### W3 — Documentation and demos (Quarto)
- Ensure `quarto/basic_demo.qmd` remains runnable and reflects current APIs.
- Add short “How to” sections for:
  - demography tables,
  - EV/cats,
  - genetics,
  - spatial,
  - management comparisons.

### W4 — Testing and CI
- Maintain fast unit tests + a small set of integration tests.
- If CI exists, ensure it runs:
  - checks/tests,
  - minimal `targets` run,
  - optional Quarto render smoke test.

### W5 — Reproduction rate contract (completed)
The current line uses `breeding_prob_fun` and `fecundity_lambda_fun` baseline
channels, with controller-owned Bernoulli/Poisson draws and reproduction
EV/cat modifiers. The clean-break contract is documented in
`docs/design/reproduction_ev_semantics.md`; maintenance work should preserve
the named tests, YAML schema-v3 path, and output semantics.

### W6 — Density channel contract (completed)
The current line uses explicit `density_spec()` channels for survival, breeding,
and fecundity, including the `make_ceiling_density_fun()` constructor for
global or patch capacities. The contract is documented in
`docs/design/density_module.md`; maintenance work should preserve channel
ordering and finite multiplier validation.

## 5) Milestones

### M0 — Baseline green build
Success criteria:
- `renv` restore works.
- Tests pass.
- Minimal `targets` run succeeds.
- Demo renders (or minimal subset).
- Docs/plan, docs/log, docs/decisions, docs/interpretation updated.

### M1 — Reproduction refactor design locked (closed; historical)
Closure record:
- `docs/design/reproduction_ev_semantics.md` exists and is coherent.
- The interface and compatibility boundary are recorded in `docs/decisions.md`.
- The current clean-break controller supersedes the deferred feature-flag or
  alternate-path design.

### M2 — Reproduction refactor implemented + validated (closed; historical)
Closure record:
- New interfaces implemented.
- Controller draws moved into controller.
- Reproduction EV parameters supported (R-level).
- The current contract is clean-break; legacy scenarios are not promised, and
  the breaking boundary is documented in the reproduction design note.
- Tests and demos updated.

### M3 — YAML reproduction EV support (closed; historical)
Closure record:
- YAML schema extended.
- YAML parser builds new interfaces.
- Tests cover YAML + reproduction EV + simulation behaviour.

### M4 — Density module (minimal viable; closed; historical)
Closure record:
- Density modifiers interface implemented.
- At least one density function (e.g. ceiling/logistic) works for survival + reproduction.
- Tests and demos cover it.

## 6) Current phase and next steps (agent-maintained)

- **Current phase**:
  - Goal 001's R `4.6.1` baseline closure is published and CI-confirmed after
    completion of `WP-2B.6`. Independent review returned `ACCEPT_WITH_MINOR`,
    both precision findings are resolved, and push-triggered `ci-fast` run
    `29474478675` succeeded at published head `a814fff`. The scheduled/manual
    `ci-heavy` workflow did not run on the push.
- **Most recent milestone progress**:
  - Completed `WP-0.3.1` through `WP-2B.6`, including:
    - bootstrap baseline and artefact/log scaffolding,
    - clean-break rate-based reproduction and explicit density channel
      contracts,
    - spatial/genetic output expansion from final-time summaries to
      run/year/patch time-series and connectivity diagnostics,
    - seeded regression gates for spatial/genetic snapshot slices,
    - domain-sanity spatial/genetic scenario pack in `inst/extdata/`,
    - Quarto and reference-doc upgrades for scientific interpretation workflow,
    - uncertainty ensembles, sensitivity diagnostics, bounded calibration, and
      performance/documentation hardening through `Line 2B.x`.
  - Refreshed the local and CI reproducibility baseline to R `4.6.1` without
    changing package compatibility (`R >= 4.6.0`) or model behaviour; fresh
    evidence is in `artefacts/release_1.0.0-rc4/`.
  - Closed independent review with no Critical or Important findings by
    correcting the Quarto render destination and the lockfile/restore-workload
    package accounting, then recording orchestrator acceptance.
  - Published the R `4.6.1` baseline and libuv restore repair to `origin/main`;
    push-triggered `ci-fast` run `29474478675` completed successfully.
- **Immediate next steps**:
  1. Define the next roadmap tranche with Barry before promoting work packages
     or beginning autonomous feature execution.
  2. Keep tag, release-note, GitHub Release, CRAN, and the pre-existing
     `DESCRIPTION` `1.0.0` versus `NEWS` `1.0.1-development` release decision
     separate and open.
  3. Keep `ci-heavy` separate from the successful push confirmation; it is a
     scheduled/manual workflow and did not run for the Goal 001 publication.
