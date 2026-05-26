# Interpretation notes (artefact behaviour)

Purpose: record what the software artefacts *actually do* after changes.
This is not a diary; it’s a “what I saw when I ran it” record.

For each major change, create an entry.

---

### [2026-02-09] WP-2B.6 performance hardening + uncertainty docs integration

- **Change summary**:
  - Added bounded ensemble parallelism controls to
    `run_scenario_ensemble()` (`parallel`, `n_cores`) with deterministic
    draw-seed handling under fixed seeds.
  - Added CI-heavy uncertainty smoke step covering:
    - serial/parallel ensemble consistency,
    - sensitivity helper smoke,
    - calibration helper smoke.
  - Extended documentation narrative in:
    - `docs/reference/uncertainty_api.md`
    - `docs/reference/ci_profiles.md`
    - `quarto/basic_demo.qmd` (uncertainty/sensitivity/calibration workflow section).
- **Artefacts inspected**:
  - `artefacts/WP-2B.6/performance_profile.md`
  - `artefacts/WP-2B.6/parallel_repro_comparison.csv`
  - `artefacts/WP-2B.6/quarto_render_log.txt`
- **Observed behaviour**:
  - In local reproducible profiling, parallel ensemble evaluation (`n_cores=2`)
    showed bounded speedup with matching draw-level summaries to serial mode.
  - Quarto render completed successfully with known non-blocking output-path
    warnings (unchanged from prior runs).
  - CI-style uncertainty smoke command passed locally and confirmed deterministic
    serial/parallel sampled-parameter identity under fixed seeds.
- **Follow-up tasks**:
  - [x] Line 2B queue exhausted; next work requires roadmap promotion.

---

### [2026-02-09] WP-2B.5 hindcast/calibration scaffold

- **Change summary**:
  - Added calibration scaffold APIs:
    - `score_hindcast_fit()`
    - `generate_calibration_candidates()`
    - `run_calibration_search()`
  - Added calibration reference note:
    `docs/reference/calibration_scaffold.md`.
  - Extended output/public API docs and schema-contract tests for calibration
    outputs.
- **Artefacts inspected**:
  - `artefacts/WP-2B.5/hindcast_scores.csv`
  - `artefacts/WP-2B.5/calibration_candidates.csv`
  - `artefacts/WP-2B.5/calibration_best_fit.md`
- **Observed behaviour**:
  - Candidate generation was deterministic under fixed seeds and produced
    bounded parameter sets.
  - Calibration search produced stable objective rankings and recoverable
    best-fit candidates under seeded toy fixtures.
  - Objective/error tables remained interpretable with explicit per-target
    residual columns.
- **Follow-up tasks**:
  - [x] Execute `WP-2B.6` performance/docs integration.

---

### [2026-02-09] WP-2B.4 sensitivity diagnostics (PRCC + OAT elasticity)

- **Change summary**:
  - Added sensitivity diagnostics:
    - `summarise_sensitivity_prcc()`
    - `summarise_sensitivity_oat()`
  - Added sensitivity reference note:
    `docs/reference/sensitivity_diagnostics.md`.
  - Updated output/public API docs and schema-contract tests for sensitivity
    output tables.
- **Artefacts inspected**:
  - `artefacts/WP-2B.4/sensitivity_prcc.csv`
  - `artefacts/WP-2B.4/sensitivity_oat.csv`
  - `artefacts/WP-2B.4/diagnostic_plots/prcc_barplot.png`
  - `artefacts/WP-2B.4/diagnostic_plots/oat_elasticity.png`
  - `artefacts/WP-2B.4/diagnostic_summary.md`
- **Observed behaviour**:
  - PRCC ranking showed strong positive influence of `harvest_quota` on
    extinction probability in the inspected ensemble fixture.
  - Bounded OAT diagnostics produced directional elasticity signals for tested
    stressor parameters on mean final abundance.
  - Diagnostic tables and plots were reproducible under fixed seeds and
    remained within expected numeric domains.
- **Follow-up tasks**:
  - [x] Execute `WP-2B.5` hindcast/calibration scaffold.

---

### [2026-02-09] WP-2B.3 YAML schema v3 uncertainty block + migration tests

- **Change summary**:
  - Added schema v3 uncertainty parsing in `read_scenario_yaml()` with support
    for both `uncertainty.params.<parameter>` and direct
    `uncertainty.<parameter>` mappings.
  - Added explicit schema discipline:
    - schema v2 rejects `uncertainty` blocks and points users to
      `schema_version: 3`.
    - schema v3 remains additive and migration-compatible.
  - Wired scenario-level uncertainty handoff by allowing
    `run_scenario_ensemble(..., uncertainty_spec = NULL)` to use
    `scenario$uncertainty_spec`.
  - Added migration and parser regression coverage, including snapshot fixture
    for v2 -> v3 migration.
- **Artefacts inspected**:
  - `artefacts/WP-2B.3/schema_migration_fixtures.md`
  - `artefacts/WP-2B.3/yaml_uncertainty_examples/v3_uncertainty_params.yaml`
  - `artefacts/WP-2B.3/v3_ensemble_sampled_parameters.csv`
  - `artefacts/WP-2B.3/v3_ensemble_summary_per_draw.csv`
  - `artefacts/WP-2B.3/v3_ensemble_summary_overall.csv`
- **Observed behaviour**:
  - Schema v3 YAML scenarios now carry validated `uncertainty_spec` directly in
    scenario objects and run through seeded ensembles without additional
    uncertainty arguments.
  - Schema v2 uncertainty misuse fails loudly with explicit migration guidance,
    preventing silent schema drift.
  - Inspected draw-level outputs showed plausible directional risk patterns:
    higher sampled `harvest_quota` and `cat_surv_prob` aligned with higher
    extinction/floor-breach risk in the artefact tables.
- **Follow-up tasks**:
  - [x] Execute `WP-2B.4` sensitivity diagnostics.

---

### [2026-02-09] WP-2B.2 ensemble runner + uncertainty sampling primitives

- **Change summary**:
  - Added R-level uncertainty APIs:
    - `sample_uncertainty_parameters()`
    - `run_scenario_ensemble()`
    - `summarise_ensemble_outputs()`
  - Added uncertainty API reference note:
    `docs/reference/uncertainty_api.md`.
  - Updated public API and output schema docs for ensemble contracts.
- **Artefacts inspected**:
  - `artefacts/WP-2B.2/ensemble_sample_table.csv`
  - `artefacts/WP-2B.2/ensemble_summary_per_draw.csv`
  - `artefacts/WP-2B.2/ensemble_summary_overall.csv`
  - `artefacts/WP-2B.2/domain_sanity_note.txt`
- **Observed behaviour**:
  - Seeded uncertainty draws are deterministic.
  - Ensemble summaries show plausible directional response to drawn management
    intensity and survival modifiers.
  - Draw-level extinction risk and mean final abundance varied substantially
    across sampled regimes, as expected for stress-testing uncertainty.
- **Follow-up tasks**:
  - [x] Execute `WP-2B.3` YAML schema v3 uncertainty integration.

---

### [2026-02-09] WP-2B.1 uncertainty/validation contract lock

- **Change summary**:
  - Locked Line 2B uncertainty/validation semantics in `DEC-026`.
  - Added reference contract note:
    `docs/reference/uncertainty_validation_contract.md`.
  - Added WP artefact summary:
    `artefacts/WP-2B.1/decision_summary.md`.
- **Artefacts inspected**:
  - Decision record and contract note for consistency of:
    - uncertainty taxonomy,
    - modifier composition order,
    - draw-level semantics,
    - additive compatibility boundaries.
- **Observed behaviour**:
  - No runtime code-path changes were introduced in this WP.
  - Contract now explicitly unblocks implementation work for `WP-2B.2`.
- **Follow-up tasks**:
  - [x] Execute `WP-2B.2` ensemble/sampling implementation.

---

### [2026-02-09] WP-2A.6 spatial-genetic docs + Quarto narrative upgrade

- **Change summary**:
  - Added spatial/genetic interpretation reference guide:
    `docs/reference/spatial_genetic_outputs.md`.
  - Updated Quarto demo with endpoint vs time-series vs connectivity workflow.
  - Added docs index links and refreshed CI profile docs for spatial regression
    coverage.
- **Artefacts inspected**:
  - Full tests pass (`PASS 607`, `FAIL 0`, `WARN 0`).
  - Lint pass (`No lints found`).
  - Targets smoke (`sim_basic`) completed.
  - Quarto render completed (existing non-blocking output-path warning).
  - `R CMD check --as-cran` note-only status (`3` notes).
- **Observed behaviour**:
  - Documentation and demo narrative now align with implemented spatial/genetic
    APIs and scenario-pack examples.
  - No runtime regressions observed from documentation-facing updates.
- **Follow-up tasks**:
  - [x] Priority Queue exhausted; await next promoted WP tranche.

---

### [2026-02-09] WP-2A.5 domain-sanity spatial/genetic scenario pack

- **Change summary**:
  - Added packaged YAML scenario trio:
    - `demo_spatial_genetic_fragmented.yaml`
    - `demo_spatial_genetic_connected.yaml`
    - `demo_spatial_genetic_asymmetric.yaml`
  - Added reusable spatial/genetic initializers and dispersal regime helpers.
  - Added YAML parser hooks for `dispersal_fun`/`inherit_fun`/`mating_fun`.
- **Artefacts inspected**:
  - `artefacts/WP-2A.5/scenario_pack_comparison_metrics.csv`
  - `artefacts/WP-2A.5/scenario_pack_final_occupancy.csv`
  - `artefacts/WP-2A.5/scenario_pack_final_diversity.csv`
  - `artefacts/WP-2A.5/domain_sanity_note.txt`
- **Observed behaviour**:
  - Movement regime signal is directional and plausible:
    - off-diagonal transition share:
      - fragmented: `0.066`,
      - connected: `0.474`,
      - asymmetric: `0.257`.
  - Connected regime retains higher occupancy in patch 3 than fragmented.
  - Asymmetric regime can produce sink-like behavior (patch 3 occupancy near
    zero in inspected seeded run), which is biologically plausible under strong
    directional flow and density/harvest settings.
- **Domain sanity**:
  - No implausible explosive growth observed in inspected outputs.
  - One regime produced severe patch-level decline by design; kept as a stress
    case and documented explicitly.
- **Follow-up tasks**:
  - [x] Execute WP-2A.6 (docs + Quarto interpretation upgrade).

---

### [2026-02-09] WP-2A.4 spatial-genetic contract tests and snapshot gates

- **Change summary**:
  - Expanded regression filter to include `test_spatial_patches.R` in heavy CI.
  - Added seeded spatial/genetic snapshot slice to reproducibility fixtures.
  - Expanded output contract checks for time-series/connectivity helper outputs.
- **Artefacts inspected**:
  - Regression filter pass (`PASS 234`, `FAIL 0`, `WARN 0`).
  - Snapshot fixture file:
    `artefacts/WP-2A.4/snapshot_fixtures.md`.
  - Updated heavy CI workflow:
    `artefacts/WP-2A.4/ci-heavy-validation.yaml`.
- **Observed behaviour**:
  - Snapshot and schema gates are stable and reproducible under fixed seeds.
  - New spatial outputs are covered by explicit contract assertions.
- **Follow-up tasks**:
  - [x] Execute WP-2A.5 (domain-sanity scenario pack).

---

### [2026-02-09] WP-2A.3 dispersal/connectivity diagnostics

- **Change summary**:
  - Added `summarise_patch_connectivity_timeseries()` output pathway and
    validation coverage.
  - Added comparative connectivity artefacts under controlled regime settings.
- **Artefacts inspected**:
  - `artefacts/WP-2A.3/connectivity_metrics.csv`
  - `artefacts/WP-2A.3/connectivity_transitions_overall.csv`
  - `artefacts/WP-2A.3/connectivity_turnover.csv`
- **Observed behaviour**:
  - Regime ranking is coherent in seeded diagnostics:
    - fragmented shows minimal cross-patch movement,
    - connected shows strongest mixing,
    - asymmetric sits between them with directional bias.
  - Turnover (`colonized`/`extirpated`) remains bounded and interpretable.
- **Follow-up tasks**:
  - [x] Execute WP-2A.4 (regression gate hardening).

---

### [2026-02-09] WP-2A.2 time-series patch occupancy/diversity outputs

- **Change summary**:
  - Added per-run/per-year/per-patch occupancy and diversity helpers requiring
    optional `population_history`.
  - Added simulation/scenario/YAML support for `record_population_history`.
- **Artefacts inspected**:
  - Targeted tests pass (`PASS 285`, `FAIL 0`, `WARN 0`).
  - Time-series artefacts:
    - `artefacts/WP-2A.2/patch_occupancy_timeseries_overall.csv`
    - `artefacts/WP-2A.2/patch_genetic_diversity_timeseries_overall.csv`
- **Observed behaviour**:
  - Time-series outputs have expected run/year/patch granularity.
  - Occupancy probabilities stayed within `[0, 1]` in inspected seeded runs
    (min `0.8`, max `1.0`).
- **Follow-up tasks**:
  - [x] Execute WP-2A.3 (connectivity diagnostics).

---

### [2026-02-09] WP-2A.1 deprecation framework (1.x runtime-safe)

- **Change summary**:
  - Added package-level soft-deprecation helper with once-per-session behavior.
  - Applied soft deprecations to legacy reproduction wrapper interfaces.
  - Added migration guide (`docs/reference/migration_1x_to_2x.md`).
- **Artefacts inspected**:
  - Targeted tests pass (`PASS 55`, `FAIL 0`, `WARN 0`).
  - Runtime demo:
    - first call warning count: `1`,
    - repeated call warning count: `0`,
    - suppression-option warning count: `0`.
- **Observed behaviour**:
  - Warnings are actionable and non-noisy while preserving runtime
    compatibility for legacy pathways.
- **Follow-up tasks**:
  - [x] Execute WP-2A.2 (time-series spatial/genetic outputs).

---

### [2026-02-09] WP-1.3.3 decision-support outputs expansion

- **Change summary**:
  - Added `summarise_final_abundance(sim_output, floor = 0)` for final-abundance
    risk/resilience summaries.
  - Extended `compare_scenarios()` with additive final-abundance metrics and
    explicit `final_n_floor`.
  - Updated output schema/API docs and regression contract tests.
- **Artefacts inspected**:
  - Targeted tests pass (`PASS 130`, `FAIL 0`).
  - Full tests pass (`PASS 531`, `FAIL 0`).
  - Lint pass (`n_lints=0`).
  - Targets smoke (`sim_basic`) pass.
  - Quarto render pass.
  - `R CMD check --as-cran` note-only status (`3` notes).
  - Seeded management comparison/demo outputs:
    - `artefacts/WP-1.3.3/scenario_decision_comparison.csv`
    - `artefacts/WP-1.3.3/final_abundance_per_run.csv`
    - `artefacts/WP-1.3.3/final_abundance_overall.csv`
- **Observed behaviour**:
  - Increased harvest pressure raised extinction and floor-breach risk.
  - Lower carrying capacity reduced mean/quantile final abundance while
    preserving expected directional ranking among scenarios.
- **Domain sanity**:
  - New metrics are bounded and interpretable (probabilities in `[0,1]`,
    quantiles ordered, no negative abundance artefacts).
  - Existing decision outputs remained available and unchanged.
- **Follow-up tasks**:
  - [x] Priority Queue exhausted; await promotion of new WPs.

---

### [2026-02-09] WP-1.3.2 spatial/genetic enhancement increment

- **Change summary**:
  - Added `summarise_patch_genetic_diversity_final()` to report per-patch
    final-time genotyped counts and diversity metrics across runs.
  - Added tests for aggregation and validation behavior.
  - Updated output schema/API docs for spatial/genetic helper coverage.
- **Artefacts inspected**:
  - Targeted tests pass (`PASS 115`, `FAIL 0`).
  - Full tests pass (`PASS 501`, `FAIL 0`).
  - Lint pass (`n_lints=0`).
  - Targets smoke (`sim_basic`) pass.
  - Quarto render pass.
  - `R CMD check --as-cran` note-only status (`3` notes).
  - Seeded spatial/genetic demo outputs:
    - `artefacts/WP-1.3.2/patch_occupancy_final.csv`
    - `artefacts/WP-1.3.2/patch_genetic_diversity_final.csv`
- **Observed behaviour**:
  - Patch-level occupancy and diversity summaries are stable and interpretable
    with expected variation between patches.
  - Zero-genotype patch cases are handled without invalid output values.
- **Domain sanity**:
  - Heterozygosity and F-hat remained in plausible ranges.
  - No regressions observed in broader simulation or schema contract tests.
- **Follow-up tasks**:
  - [x] Execute WP-1.3.3 (decision-support outputs expansion).

---

### [2026-02-09] WP-1.3.1 reproduction feature extension

- **Change summary**:
  - Added `require_mate` reproduction control with backward-compatible default
    (`FALSE`).
  - Added `make_mate_limited_mating_fun(max_mates_per_male)` for mate-scarcity
    constraints.
  - Threaded controls through controller, scenario, and YAML pathways.
- **Artefacts inspected**:
  - Targeted tests pass (`PASS 196`, `FAIL 0`).
  - Full tests pass (`PASS 493`, `FAIL 0`).
  - Lint pass (`n_lints=0`).
  - Targets smoke (`sim_basic`) pass.
  - Quarto render pass.
  - `R CMD check --as-cran` note-only status (`3` notes).
  - Seeded mating-control comparison:
    - `artefacts/WP-1.3.1/mating_control_metrics.csv`
    - `artefacts/WP-1.3.1/mating_control_note.txt`
- **Observed behaviour**:
  - Under male quota constraints, `require_mate = TRUE` lowers births by
    skipping unmated females.
  - Legacy behavior remains available with `require_mate = FALSE`.
- **Domain sanity**:
  - No regressions observed in broader simulation outputs/tests.
  - New mating controls produce plausible directional responses in seeded
    comparisons.
- **Follow-up tasks**:
  - [x] Execute WP-1.3.2 (spatial/genetic enhancement increment).

---

### [2026-02-09] WP-1.2.3 release automation scaffold (non-publishing)

- **Change summary**:
  - Added `scripts/build_release_evidence.sh` to generate release evidence
    bundles reproducibly.
  - Added release automation reference docs and checklist integration.
  - Executed automation run to produce `artefacts/release_1.0.0-rc2/`.
- **Artefacts inspected**:
  - Automation run log:
    - `artefacts/WP-1.2.3/release_automation_run.log`
  - Generated release bundle manifest:
    - `artefacts/WP-1.2.3/release_bundle_manifest.txt`
  - Bundle check outputs:
    - tests pass (`PASS 483`, `FAIL 0`),
    - targets smoke pass (`sim_basic`),
    - Quarto render pass,
    - `R CMD check --as-cran` note-only status (`3` notes).
- **Observed behaviour**:
  - Script produced a complete release-style evidence bundle without manual
    command choreography.
  - Non-publishing boundaries were respected (no tags, no publish actions).
- **Domain sanity**:
  - No simulation behavior changes introduced by automation scaffolding.
  - Toy scenario outputs generated in the bundle remained plausible and stable.
- **Follow-up tasks**:
  - [x] Execute WP-1.3.1 (reproduction feature extension).

---

### [2026-02-09] WP-1.2.2 reproducibility gate tightening

- **Change summary**:
  - Added seeded snapshot-style regression tests for:
    - deterministic replicate output slices, and
    - v1->v2 YAML migration structure.
  - Expanded heavy reproducibility CI filter to include
    `test_reproducibility_snapshots.R`.
  - Updated schema/output docs to describe snapshot-based gate coverage.
- **Artefacts inspected**:
  - Snapshot tests: `PASS 2`, `FAIL 0`.
  - Focused reproducibility/schema filter:
    - `PASS 131`, `FAIL 0`.
  - Full tests:
    - `PASS 483`, `FAIL 0`.
  - Lint: `n_lints=0`.
  - Targets smoke (`sim_basic`): completed.
  - Quarto render: completed.
  - `R CMD check --no-manual --as-cran`: note-only status (`3` notes).
  - Snapshot fixture copy in artefacts:
    - `artefacts/WP-1.2.2/snapshot_fixtures.md`
- **Observed behaviour**:
  - Seeded output slices and migration snapshots are stable and reproducible
    across repeated test runs.
  - Gate now detects both structural contract drift and subtle seeded-behavior
    drift.
- **Domain sanity**:
  - No simulation behavior regressions observed in the full test suite.
  - Snapshot scope remains bounded to avoid brittle noise while preserving
    detection sensitivity.
- **Follow-up tasks**:
  - [x] Execute WP-1.2.3 (release automation scaffold, non-publishing).

---

### [2026-02-09] WP-1.2.1 CI profile split (fast + heavy validation)

- **Change summary**:
  - Split CI into explicit `ci-fast` and `ci-heavy-validation` workflows.
  - Added reproducible local-equivalent command contract in
    `docs/reference/ci_profiles.md`.
  - Added heavy-profile reproducibility checks and bounded targets smoke step.
- **Artefacts inspected**:
  - Fast profile:
    - lint pass (no lints),
    - tests pass (`PASS 481`, `FAIL 0`),
    - `R CMD check --no-manual` note-only status.
  - Heavy profile:
    - reproducibility/schema tests pass (`PASS 129`, `FAIL 0`),
    - full tests pass (`PASS 481`, `FAIL 0`),
    - minimal targets smoke (`sim_basic`) completed,
    - Quarto render completed,
    - `R CMD check --no-manual --as-cran` note-only status (`3` notes).
  - Evidence bundle:
    - `artefacts/WP-1.2.1/check_summary.txt`
    - `artefacts/WP-1.2.1/README.md`
- **Observed behaviour**:
  - Fast profile provides quick gating while heavy profile verifies stronger
    reproducibility contracts.
  - No regressions observed in package/runtime behavior from CI orchestration
    changes.
- **Domain sanity**:
  - This WP changes validation orchestration only; model dynamics are unchanged.
  - Seed/schema/output regression gates remain green under heavy profile checks.
- **Follow-up tasks**:
  - [x] Execute WP-1.2.2 (seeded snapshots + schema regression tightening).

---

### [2026-02-09] WP-1.1.3 YAML density support + schema/migration tests

- **Change summary**:
  - Added YAML `density` block support with channel-level configuration for
    `survival`, `breeding`, and `fecundity`.
  - Added density shorthand (`density.K`, `density.K_patches`) and explicit
    validation to prevent mixing with top-level legacy `K`/`K_patches`.
  - Added packaged density YAML example (`demo_density_v2.yaml`) and expanded
    YAML parser tests for valid/invalid density configurations.
- **Artefacts inspected**:
  - Focused YAML parser tests: `PASS 75`, `FAIL 0`.
  - Full tests: `PASS 481`, `FAIL 0`.
  - Lint: `lintr::lint_package()` reported no lints.
  - Package checks: `R CMD check --no-manual --as-cran` passed (`0` errors,
    `0` warnings; `3` notes).
  - Quarto: `quarto render quarto` succeeded (existing non-blocking warning on
    output-path configuration).
  - Targets: minimal smoke invocation completed.
  - YAML density sanity outputs:
    - `artefacts/WP-1.1.3/yaml_density_metrics.csv`
    - `artefacts/WP-1.1.3/density_v2_summary.csv`
    - `artefacts/WP-1.1.3/legacy_density_summary.csv`
- **Observed behaviour**:
  - Schema v2 scenarios with explicit density blocks parse to active
    `density_spec` and run successfully.
  - Schema v2 scenarios without density block continue to run using legacy
    top-level `K` pathways.
  - Schema v1 legacy YAML remains runnable.
- **Domain sanity**:
  - Additive density YAML support did not break legacy schema behavior in
    inspected runs.
  - Parser rejects malformed density blocks with explicit, channel-specific
    errors.
- **Follow-up tasks**:
  - [x] Execute WP-1.2.1 (CI profile split: fast PR gate + scheduled heavy validation).

---

### [2026-02-08] WP-1.1.2 R-level density integration

- **Change summary**:
  - Added exported density module API and integrated channel multipliers for
    survival, breeding probability, and fecundity lambda.
  - Preserved legacy `K`/`K_patches` pathways with explicit mixed-input
    validation.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`461` pass, `0` fail).
  - Lint: `lintr::lint_package()` reported no lints.
  - Package checks: `R CMD check --no-manual --as-cran` passed (`0` errors,
    `0` warnings; `3` notes).
  - Quarto: `quarto render quarto` succeeded.
  - Targets: minimal smoke target invocation completed.
  - Domain sanity outputs:
    - `artefacts/WP-1.1.2/density_channel_demo_summary.csv`
    - `artefacts/WP-1.1.2/density_compatibility_summary.csv`
- **Observed behaviour**:
  - Density channels reduced abundance and births in the seeded toy comparison
    relative to a neutral baseline.
  - Legacy patch-density behavior and equivalent explicit adapter produced
    matching alive counts in seeded comparison.
- **Domain sanity**:
  - No invalid probability/lambda behavior observed in tested density pathways.
  - Legacy `survival_scale` diagnostics remain consistent (`NA` under patch
    legacy, `1` under explicit `density_spec`).
- **Follow-up tasks**:
  - [x] Execute WP-1.1.3 (YAML density support + schema/migration tests).

---

### [2026-02-08] WP-1.1.1 density semantics decision lock

- **Change summary**:
  - Finalized `DEC-005` and replaced density design placeholder with an
    implementation-ready contract.
- **Artefacts inspected**:
  - `docs/decisions.md` (`DEC-005`)
  - `docs/design/density_module.md`
  - `artefacts/WP-1.1.1/decision_validation.txt`
- **Observed behaviour**:
  - This WP is decision/design-only and intentionally introduces no runtime
    behavior change by itself.
- **Domain sanity**:
  - Decision semantics are now explicit for channel set, composition order,
    state scope, and legacy compatibility mapping.
- **Follow-up tasks**:
  - [x] Execute WP-1.1.2 R-level integration with regression coverage.

---

### [2026-02-08] WP-1.0.2 release candidate evidence pack

- **Change summary**:
  - Produced `artefacts/release_1.0.0-rc1/` with package/check/quarto/tests,
    and deterministic toy-scenario outputs.
  - Updated release checklist to reflect completed RC evidence tasks.
- **Artefacts inspected**:
  - Package check: `0` errors, `0` warnings (`3` notes).
  - Tests: `437` pass, `0` fail.
  - Quarto: render succeeded.
  - Targets: minimal smoke target succeeded.
  - Toy scenario outputs and interpretation note included in release bundle.
- **Observed behaviour**:
  - Release candidate artefacts are reproducible and reviewable in one folder.
  - Toy scenario dynamics remain plausible under density, harvest, and EV/cat
    forcing.
- **Domain sanity**:
  - No regressions detected in release-candidate validation chain.
  - Release bundle contains enough context for external audit/review.
- **Follow-up tasks**:
  - [ ] Human maintainer: create tag/release publication from RC if approved.

---

### [2026-02-08] WP-1.0.1 API stabilization + 1.0.0 versioning

- **Change summary**:
  - Finalized semver/release policy and public API stability contract for the
    1.x line.
  - Bumped package version to `1.0.0` and added release notes.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`437` pass, `0` fail).
  - Targets: minimal smoke target `sim_basic` completed.
  - Quarto: `quarto render quarto` succeeded.
  - Package checks: `R CMD check` clean (`0` errors, `0` warnings; notes only).
- **Observed behaviour**:
  - Runtime model behavior is unchanged by this WP (policy/versioning scope).
  - Repository now has explicit stable vs experimental API boundaries for
    release-line governance.
- **Domain sanity**:
  - No biological/demographic semantics changed in this WP.
  - Existing v1/v2 YAML scenario pathways remain intact under 1.0.0 checks.
- **Follow-up tasks**:
  - [ ] Execute WP-1.0.2 release-candidate artefact bundle and checklist update.

---

### [2026-02-08] WP-0.5.6 docs/demo refresh for reproduction refactor

- **Change summary**:
  - Updated README and Quarto demo to foreground baseline reproduction channels,
    reproduction EV/cat configuration, and YAML schema v1/v2 behavior.
  - Added explicit user guidance for migration expectations from old YAML.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`437` pass, `0` fail).
  - Targets: minimal smoke target `sim_basic` completed.
  - Quarto: `quarto render quarto` succeeded.
  - YAML scenarios: schema v1 and v2 demonstration runs summarized in
    `artefacts/WP-0.5.6/repro_yaml_metrics.csv`.
- **Observed behaviour**:
  - Documentation now directly answers:
    - how to specify breeding/fecundity post-refactor,
    - how reproduction EV/cats are configured,
    - how legacy YAML remains supported.
  - v2 demo shows non-trivial reproduction EV/cat diagnostics, while v1 remains
    stable under compatibility pathways.
- **Domain sanity**:
  - No documentation-demo mismatches observed in reviewed snippets.
  - Reproduction summary diagnostics in examples align with controller outputs.
- **Follow-up tasks**:
  - [ ] Execute WP-1.0.1 API stabilization + release policy finalization.
  - [ ] Execute WP-1.0.2 release-candidate artefact bundle.

---

### [2026-02-08] WP-0.5.5 YAML schema v2 + reproduction EV migration

- **Change summary**:
  - Added schema v2 parsing for explicit reproduction-rate channels:
    - `demography.breeding_prob.table` (`p_breed`)
    - `demography.fecundity_lambda.table` (`lambda`)
  - Added canonical schema v2 `reproduction_ev` parsing.
  - Added compatibility migration/adaptation for v1-style reproduction fields.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`437` pass, `0` fail).
  - Targets: minimal smoke target `sim_basic` completed.
  - Quarto: `quarto render quarto` succeeded.
  - YAML scenarios: schema v1 (`demo_demography.yaml`) and schema v2
    (`demo_reproduction_v2.yaml`) both ran successfully.
- **Observed behaviour**:
  - `yaml_schema_version` attribute correctly reflects parsed schema (`1` vs `2`).
  - Schema v2 scenario summaries include reproduction EV/cat diagnostics
    (`env_repro_p_mult`, `env_repro_lambda_mult`, `cat_repro_mult`,
    `repro_catastrophe`).
  - Compatibility adaptation from v1-shaped fields under schema v2 is functional
    in parser tests.
- **Domain sanity**:
  - v2 demo outputs show plausible births and non-zero reproduction catastrophe
    incidence (`0.05` in demonstration sample).
  - No impossible probability/lambda values were observed in validated pathways.
- **Follow-up tasks**:
  - [ ] Execute WP-0.5.6 docs/demo refresh for end-user guidance.
  - [ ] Start WP-1.0.1 release-stability work after 0.5.x closure.

---

### [2026-02-08] WP-0.5.4 controller reproduction draws + reproduction EV/cat

- **Change summary**:
  - Added controller-level reproduction pathway using baseline
    `breeding_prob_fun` and `fecundity_lambda_fun`.
  - Added year-level reproduction EV/cat parameters and summary diagnostics.
  - Preserved legacy pathways and YAML v1 compatibility.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`405` pass, `0` fail).
  - Targets: not rerun in this WP (controller/pathway focus).
  - Quarto: `quarto render quarto` succeeded.
  - YAML scenarios: legacy `demo_demography.yaml` executed successfully through
    compatibility path.
- **Observed behaviour**:
  - New summary fields (`env_repro_p_mult`, `env_repro_lambda_mult`,
    `cat_repro_mult`, `repro_catastrophe`) are present and populated.
  - Reproduction EV/cat probe run showed non-trivial multipliers and
    catastrophe frequency (`~0.306` in the demonstration sample).
  - Legacy YAML scenarios still run with plausible outputs.
- **Domain sanity**:
  - `p_breed` was bounded to `[0,1]` and `lambda` bounded to `>= 0` in controller checks.
  - No impossible reproduction explosions observed in demonstration outputs.
- **Follow-up tasks**:
  - [ ] Execute WP-0.5.5 YAML schema v2 migration for explicit reproduction semantics.
  - [ ] Execute WP-0.5.6 docs/demo refresh for new reproduction semantics.

---

### [2026-02-08] WP-0.5.3 fecundity lambda API + legacy wrappers

- **Change summary**:
  - Added explicit fecundity-lambda API (`lambda >= 0`) with table builder/validator.
  - Added adapters bridging lambda and legacy realized-count fecundity functions.
  - Kept legacy `build_fecundity_fun_from_table()` available as a wrapper.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`383` pass, `0` fail).
  - Targets: not rerun in this WP (focus on API layer + compatibility tests).
  - Quarto: `quarto render quarto` succeeded.
  - YAML scenarios: existing v1 YAML paths still parse/run under unchanged schema.
- **Observed behaviour**:
  - Lambda table probes return expected non-negative values by age/sex.
  - Legacy wrapper still yields realized non-negative offspring counts.
  - No regressions detected in existing scenario/simulation tests.
- **Domain sanity**:
  - Lambda values remain bounded below at 0 as expected.
  - No implausible reproduction artifacts observed in probe runs.
- **Follow-up tasks**:
  - [x] Execute WP-0.5.4 controller refactor for reproduction draws and reproduction EV/cats.
  - [ ] Thread new probability/lambda channels through controller internals.

---

### [2026-02-08] WP-0.5.2 breeding probability API + legacy wrappers

- **Change summary**:
  - Added explicit breeding-probability API (`p_breed` in `[0, 1]`) with table builder/validator.
  - Added adapters bridging probability and legacy logical breeding functions.
  - Kept legacy `build_breeding_fun_from_table()` available as a wrapper.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`383` pass, `0` fail).
  - Targets: not rerun in this WP (focus on API layer + compatibility tests).
  - Quarto: `quarto render quarto` succeeded.
  - YAML scenarios: existing v1 YAML paths still parse/run under unchanged schema.
- **Observed behaviour**:
  - Probability table probes return expected values by age/sex.
  - Legacy wrapper still maps to eligibility semantics (`p_breed > 0`).
  - No regressions detected in existing scenario/simulation tests.
- **Domain sanity**:
  - Probability outputs remain bounded within `[0, 1]`.
  - No demographic anomalies observed in compatibility checks.
- **Follow-up tasks**:
  - [x] Execute WP-0.5.3 fecundity lambda API work.
  - [x] Execute WP-0.5.4 controller refactor after both APIs are in place.

---

### [2026-02-08] WP-0.5.1 reproduction semantics decision lock

- **Change summary**:
  - Locked reproduction semantics on baseline probability/mean interfaces plus controller-side stochastic draws.
  - Finalized compatibility/deprecation policy for legacy reproduction APIs.
  - Updated design doc with implementation-ready responsibilities and a worked numeric example.
- **Artefacts inspected**:
  - Tests: not rerun for this decision-only WP (no engine code mutation).
  - Targets: not rerun for this decision-only WP.
  - Quarto: not rerun for this decision-only WP.
  - YAML scenarios: no runtime schema mutation in this WP.
- **Observed behaviour**:
  - This WP is architecture/documentation locking; runtime behavior is intentionally unchanged.
  - Decision outputs are now explicit and unambiguous for implementation WPs 0.5.2-0.5.5.
- **Domain sanity**:
  - No biological or stochastic runtime behavior changes introduced in this WP.
  - Existing deterministic-seed baseline from WP-0.4.3 remains the validation anchor.
- **Follow-up tasks**:
  - [x] Execute WP-0.5.2 breeding probability API scaffolding with compatibility wrappers.
  - [x] Execute WP-0.5.3 fecundity lambda API scaffolding with compatibility wrappers.

---

### [2026-02-08] WP-0.4.3 deterministic RNG interface

- **Change summary**:
  - Added optional `seed` support to replicated simulation execution.
  - Threaded deterministic seeding through `scenario_spec()`, `run_scenario()`, and `read_scenario_yaml()`.
  - Updated `_targets.R`, README, Quarto demo snippets, and packaged YAML demos to use explicit seeds.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`362` pass, `0` fail), including dedicated RNG determinism tests.
  - Targets: ran seeded replicate/scenario smoke behaviour through direct execution and packaged YAML runs; output snapshots saved in artefacts.
  - Quarto: `quarto render quarto` succeeded (render warning about external output path unchanged from prior WP).
  - YAML scenarios: seeded demo YAML execution outputs saved (`yaml_seeded_demo_summary.csv`, `yaml_seeded_demo_extinction.csv`).
- **Observed behaviour**:
  - Fixed-seed replicated outputs are identical across repeated runs in-session.
  - Unseeded replicated outputs remain stochastic.
  - Caller RNG state is restored after seeded replicate runs.
  - No schema/output contract regressions observed while adding seeding.
- **Domain sanity**:
  - EV/cat and demographic stochasticity remain plausible under seeded runs.
  - No impossible survival/birth artifacts observed in inspected seeded demo outputs.
- **Follow-up tasks**:
  - [x] Execute WP-0.5.1 reproduction semantics decision lock.
  - [x] Use deterministic seeds in 0.5.x refactor regression scenarios.

---

### [2026-02-08] WP-0.4.2 output schema contract coverage

- **Change summary**:
  - Added output schema contract documentation at `docs/reference/output_schema.md`.
  - Added dedicated regression tests for required output object columns/types.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`346` pass, `0` fail), including new output-schema tests.
  - Targets: not rerun in this WP.
  - Quarto: not rerun in this WP.
  - YAML scenarios: not primary target in this WP.
- **Observed behaviour**:
  - Core output objects (`run_basic_simulation*`, `run_scenario`, summary helpers) conform to documented structures.
  - Serialized example output confirms expected high-level shape and nesting.
  - No regressions observed in existing functionality while adding schema assertions.
- **Domain sanity**:
  - No model semantic changes introduced.
  - Domain behavior remains consistent with previous WPs.
- **Follow-up tasks**:
  - [x] Execute WP-0.4.3 deterministic seed interface.
  - [x] Start reproduction semantics decision and refactor line (0.5.x) after 0.4.3.

---

### [2026-02-08] WP-0.4.1 YAML schema v1 + legacy migration

- **Change summary**:
  - Implemented explicit YAML `schema_version` handling in `read_scenario_yaml()`.
  - Added in-memory migration path from legacy schema 0 (missing version) to v1.
  - Added version validation errors for unknown/invalid versions and updated packaged YAML examples to v1.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`308` pass, `0` fail), including new schema-version tests.
  - Targets: not rerun in this WP.
  - Quarto: not rerun in this WP.
  - YAML scenarios: demo YAML files updated and verified via parser/tests.
- **Observed behaviour**:
  - Legacy YAML without `schema_version` still runs and is tagged with attribute `yaml_schema_version = 1`.
  - Explicit `schema_version: 1` YAML runs with same v1 attribute.
  - Unknown/invalid schema versions now fail early with clear parser errors.
- **Domain sanity**:
  - No demographic/genetic/spatial model semantic changes introduced.
  - Scenario execution results remain consistent with pre-schema contract behavior for legacy inputs.
- **Follow-up tasks**:
  - [x] Execute WP-0.4.2 output schema documentation/regression coverage.
  - [x] Execute WP-0.4.3 deterministic seed interface.

---

### [2026-02-08] WP-0.3.5 Quarto render stabilization

- **Change summary**:
  - Updated Quarto site config to render only existing pages and removed broken navbar targets.
  - Changed Quarto output directory from `docs/` to `outputs/quarto_site` to avoid source-doc clobbering.
- **Artefacts inspected**:
  - Tests: not rerun in this WP (documentation/render scope only).
  - Targets: not rerun in this WP.
  - Quarto: `quarto render quarto` passed with output written to `outputs/quarto_site`.
  - YAML scenarios: not a primary target in this WP.
- **Observed behaviour**:
  - Render completed successfully without missing-link warnings.
  - Site output no longer conflicts with authored markdown in `docs/`.
  - Rendered files include `outputs/quarto_site/index.html` and `outputs/quarto_site/about.html`.
- **Domain sanity**:
  - No model-behavior changes introduced.
  - Documentation rendering path is now deterministic and non-destructive.
- **Follow-up tasks**:
  - [x] Start WP-0.4.1 (YAML schema version contract + migration path).
  - [ ] Reintroduce executable Quarto demo variants as an explicit full-run profile if needed later.

---

### [2026-02-08] WP-0.3.4 CI baseline and lint gate

- **Change summary**:
  - Added active GitHub Actions workflow at `.github/workflows/ci.yaml`.
  - Added repository lint configuration via `.lintr` and wired lint as a failing CI gate.
  - Updated build/check pathway to tarball-based `R CMD check` for reliable CI behavior in this repo layout.
- **Artefacts inspected**:
  - Tests: passed via `R CMD check` (`tests/testthat.R` OK) in CI-equivalent run logs.
  - Targets: not rerun in this WP.
  - Quarto: not rendered in this WP.
  - YAML scenarios: not a primary target in this WP.
- **Observed behaviour**:
  - Local CI-equivalent chain passed:
    - renv restore
    - lint gate (`No lints found.` for configured lint set)
    - tarball build
    - `R CMD check` with `0` errors, `0` warnings.
  - Remaining check output is limited to known notes (license stub style + non-standard top-level files).
- **Domain sanity**:
  - No model-semantic changes introduced.
  - Core domain behavior remains as previously validated (WP-0.3.1/WP-0.3.3 examples).
- **Follow-up tasks**:
  - [ ] Execute WP-0.3.5 Quarto render stabilization.
  - [ ] Tighten lint baseline over time as legacy style debt is reduced.

---

### [2026-02-08] WP-0.3.3 README quickstart correctness

- **Change summary**:
  - Cleaned README placeholders/stale references and aligned quickstart instructions with current APIs.
  - Added explicit runnable quickstart snippets for both R-defined and YAML-defined scenarios.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`301` pass, `0` fail) via `artefacts/WP-0.3.3/tests.log`.
  - Targets: not rerun directly in this WP.
  - Quarto: not rendered in this WP.
  - YAML scenarios: demo YAML quickstart path executed successfully via README examples run.
- **Observed behaviour**:
  - README examples for `scenario_spec()` + `run_scenario()` and `read_scenario_yaml()` + `run_scenario()` executed successfully.
  - Tarball `R CMD check` retained `0` errors and `0` warnings; README empty URL note was eliminated.
  - Remaining notes stayed limited to license/top-level-file CRAN-style notes.
- **Domain sanity**:
  - README example runs produced plausible extinction summaries (including non-zero extinction risk in the YAML demo case).
  - No implausible numerical behaviour observed in example outputs.
- **Follow-up tasks**:
  - [ ] Implement CI quality gates in WP-0.3.4.
  - [ ] Stabilize Quarto render and navbar links in WP-0.3.5.

---

### [2026-02-08] WP-0.3.2 metadata hardening + package checks

- **Change summary**:
  - Hardened package metadata in `DESCRIPTION`, added `NEWS.md`, and added `inst/CITATION`.
  - Regenerated roxygen docs and fixed check warnings surfaced during WP execution.
- **Artefacts inspected**:
  - Tests: executed as part of `R CMD check` (`tests/testthat.R` OK).
  - Targets: not rerun in this WP (focus was packaging/check compliance).
  - Quarto: not rendered in this WP (queued in WP-0.3.5).
  - YAML scenarios: not a primary target in this WP.
- **Observed behaviour**:
  - Final tarball check completed with `0` errors and `0` warnings.
  - Remaining check output consists of `3` notes (CRAN incoming/README empty URL, LICENSE stub style, top-level non-standard files).
  - No simulation logic regressions detected in the check/test path.
- **Domain sanity**:
  - No new demographic/genetic/spatial behavioural changes introduced.
  - Existing domain sanity from WP-0.3.1 remains unchanged.
- **Follow-up tasks**:
  - [ ] Execute WP-0.3.3 and remove README placeholder/empty URL issues.
  - [ ] Revisit LICENSE stub formatting policy during release-line hardening.

---

### [2026-02-08] WP-0.3.1 bootstrap smoke-check baseline

- **Change summary**:
  - Ran baseline bootstrap/check cycle and created first WP artefact bundle at `artefacts/WP-0.3.1/`.
  - Populated baseline repo-memory docs for bootstrap status and current phase.
- **Artefacts inspected**:
  - Tests: `devtools::test()` passed (`301` pass, `0` fail) via `artefacts/WP-0.3.1/tests_devtools.log`.
  - Targets: forced minimal run passed (`2` completed, `3` skipped) via `artefacts/WP-0.3.1/targets_smoke_forced.log`.
  - Quarto: not rendered in this WP (deferred to WP-0.3.5 by roadmap scope).
  - YAML scenarios: not primary target in this WP; baseline YAML files detected in `inst/extdata/`.
- **Observed behaviour**:
  - Bootstrap completed and synchronized dependency state, including a lockfile update for `lattice`.
  - Toy scenario (`n_runs = 5`, `n_years = 20`, fixed seed) produced finite trajectories with `p_extinct = 0` at threshold `10`.
  - Generated trajectory plot artefact copied to `artefacts/WP-0.3.1/sim_basic_dense_harvest_trajectory.png`.
- **Domain sanity**:
  - Survival and trajectory outputs remained bounded and finite in inspected outputs.
  - No suspicious extinction dynamics observed in the toy baseline run.
  - No implausible explosions/NaN propagation observed in inspected summary CSVs.
- **Follow-up tasks**:
  - [ ] Execute WP-0.3.2 package metadata hardening and `R CMD check` evidence capture.
  - [ ] Validate full Quarto site rendering and navbar integrity in WP-0.3.5.

---

## Entry template

### [YYYY-MM-DD] [Short title, e.g. “Repro EV scaffold added”]

- **Change summary**:
  - …
- **Artefacts inspected**:
  - Tests: (what ran, pass/fail)
  - Targets: (what ran, pass/fail)
  - Quarto: (what rendered, pass/fail)
  - YAML scenarios: (which, pass/fail)
- **Observed behaviour**:
  - Bullet points: what changed in outputs; any surprising patterns.
- **Domain sanity**:
  - Are probabilities bounded?
  - Any suspicious extinction dynamics?
  - Any implausible growth/explosions?
- **Follow-up tasks**:
  - [ ] …
  - [ ] …

---

## Summary (maintained by agent)

A short running summary of:
- what the current engine supports reliably,
- what is known to be brittle or incomplete,
- what the next milestone is.

- Current reliable baseline:
  - Package tests are green (`531` pass) with reproducibility snapshot and
    output-schema regression coverage.
  - Default demo pipeline is now smoke-sized for fresh checkout verification on
    laptops, including macOS, rather than tuned as a heavy benchmark path.
  - YAML schema v1/v2 (including density/reproduction channels) is documented
    and regression-tested with legacy adaptation support.
  - Seeded replicate/scenario execution is deterministic and caller RNG-safe.
  - Decision-support summaries include extinction, harvest, and final-abundance
    risk metrics; spatial helpers include patch occupancy and patch-level final
    genetic diversity summaries.
- Known brittle/incomplete areas:
  - Full `targets` breadth remains heavier than smoke runs in routine cycles.
  - CRAN-style notes persist for non-standard top-level files and license stub
    formatting.
- Next milestone focus:
  - Priority Queue in `docs/roadmap.md` is currently exhausted through
    `WP-1.3.3`; next work requires promotion of new WPs.

### [2026-03-18] macOS smoke-default pass

- **Change summary**:
  - Reduced default `_targets.R` demo replicate counts to a smoke-sized laptop
    profile.
  - Added package-native `scripts/run_tests.R` entrypoint and switched current
    docs/release automation away from assuming `devtools` is installed.
- **Artefacts inspected**:
  - Tests: `Rscript scripts/run_tests.R` passed (`531` pass, `0` fail).
  - Targets: Quarto render passed; full default `targets` run was observed to be
    CPU-heavy but correct, motivating the smaller smoke defaults.
  - Quarto: `quarto render quarto` passed.
  - YAML scenarios: packaged examples remained available; no schema changes in
    this pass.
- **Observed behaviour**:
  - Fresh macOS restore completed without manual system-library intervention.
  - Direct tiny replicate benchmark (`2` runs x `5` years) completed quickly,
    confirming correctness.
  - Larger default ensemble settings consumed several minutes of single-core CPU
    time, which is acceptable for explicit heavier runs but too slow for a
    baseline smoke path.
  - The spatial demo target was also resized after validation showed it
    dominated the default pipeline runtime on laptop hardware.
- **Domain sanity**:
  - No demographic or extinction-behaviour regressions were observed in the
    inspected smoke outputs.
  - This pass changed only validation workload size and test/release invocation
    plumbing, not simulation semantics.
- **Follow-up tasks**:
  - [ ] Consider a future optional parallel demo/release profile for heavier
    ensemble validation.
  - [ ] Re-run the resized default `targets` pipeline end-to-end and capture the
    elapsed time in a future performance note if desired.

### [2026-05-26] Mac dev-box adoption smoke pass

- **Change summary**:
  - Moved local validation onto Barry's Mac mini dev-box without package-code
    changes.
  - Added a rig-managed R `4.5.3` runtime to match `renv.lock` while leaving the
    Homebrew R `4.6.0` install untouched.
- **Artefacts inspected**:
  - Tests: `PATH=/usr/local/bin:$PATH Rscript scripts/run_tests.R` passed
    (`532` pass, `0` fail).
  - Targets: forced `sim_basic` smoke target completed.
  - Quarto: `quarto render quarto` produced `outputs/quarto_site/index.html`.
  - Lint: `lintr::lint_package()` reported no lints.
- **Observed behaviour**:
  - `renv::restore()` is clean under R `4.5.3`.
  - R `4.6.0` cannot restore the lockfile cleanly because pinned `Matrix`
    `1.7-4` does not compile against R `4.6.0`; R `4.5.3` is therefore the
    canonical local runtime for this lockfile.
  - Official R source-package builds required Homebrew header/library paths,
    Homebrew `gfortran`, and Homebrew `libomp` for compatibility with the
    current Apple clang.
- **Domain sanity**:
  - This pass changed only machine tooling and validation runtime setup.
  - The `sim_basic` smoke target completed with no suspicious runtime behaviour
    observed.
- **Follow-up tasks**:
  - [ ] Promote the next roadmap tranche before new feature execution.
  - [ ] Consider documenting the Mac runtime command in a developer setup
    reference if additional Mac agents join the project.
