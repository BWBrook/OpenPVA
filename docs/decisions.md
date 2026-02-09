# OpenPVA decision log

> Record irreversible or high-impact decisions here.
> Format: ID, date, decision, rationale, status (active/superseded).

---

## DEC-001 — Compatibility strategy for reproduction refactor
- **Date**: 2026-02-08
- **Decision**:
  - Adopt probability/mean semantics for reproduction:
    - `breeding_prob_fun(ind)` returns baseline `p_breed_base` in `[0, 1]`.
    - `fecundity_lambda_fun(ind)` returns baseline `lambda_base >= 0`.
  - Controller (not lifecycle table helpers) owns stochastic realization:
    - Bernoulli draw for breeding realization.
    - Poisson draw for offspring count conditional on breeding.
  - Year-level reproduction EV/cat modifiers are applied in-controller before stochastic draws.
  - Backward compatibility path (required during transition):
    - Existing `breeding_fun` / `fecundity_fun` interfaces remain supported via explicit adapters.
    - Legacy YAML continues to run through migration/adaptation layers.
    - Deprecation warnings are allowed only after new interfaces are fully documented and tested.
  - Breaking-change definition for this refactor:
    - Removing legacy function channels without wrappers is breaking.
    - Changing output columns or meaning without schema docs + migration path is breaking.
    - Reordering lifecycle semantics in a way that changes existing scenario behavior without opt-in is breaking.
- **Rationale**:
  - Separating baseline rates from stochastic draws is required for clean EV/cat layering and clearer interpretation.
  - Adapter-first migration preserves existing scenarios and allows phased rollout with measurable regression protection.
- **Status**: active

## DEC-002 — Breeding table semantics (eligibility vs probability)
- **Date**: 2026-02-08
- **Decision**: Resolved by DEC-001. Breeding interfaces move to explicit baseline probability semantics (`p_breed_base` in `[0,1]`), with optional eligibility represented as a multiplicative/guard layer in adapters/builders.
- **Rationale**: Unifies EV/cat handling and avoids mixing structural eligibility with realized stochastic outcomes.
- **Status**: superseded by DEC-001

## DEC-003 — Reproduction EV model choice
- **Date**: 2026-02-08
- **Decision**: Reproduction EV/cat modifiers are year-level controller inputs applied to baseline `p_breed_base` and `lambda_base` prior to stochastic draws. Concrete distributional forms (e.g., logit-normal/lognormal) are implementation details to be parameterized in WP-0.5.4/WP-0.5.5, not hard-coded in this decision.
- **Rationale**: Locks architecture and compatibility now while leaving numeric EV-family choice configurable during implementation.
- **Status**: active

## DEC-004 — YAML schema versioning and deprecation policy
- **Date**: 2026-02-08
- **Decision**:
  - Adopt `schema_version: 1` as the initial YAML schema contract.
  - Treat missing `schema_version` as legacy schema 0 and migrate in-memory to v1 on read.
  - Reject unknown future schema versions with explicit errors.
  - Keep schema evolution additive; preserve legacy support via migration where feasible.
- **Rationale**:
  - Prevent silent schema drift while maintaining backward compatibility for existing scenario files.
  - Make parsing/validation failures explicit and actionable for users.
- **Status**: superseded by DEC-011

## DEC-005 — Density module interface
- **Date**: 2026-02-08
- **Decision**:
  - Introduce channel-specific density modifiers for:
    - survival probability,
    - breeding probability,
    - fecundity lambda.
  - Lock composition order:
    - baseline rate -> density modifier -> year EV/cat modifier -> bounds clamp -> stochastic draw.
  - Support global and patch-level density state in initial implementation.
  - Preserve legacy compatibility:
    - `K` maps to global ceiling scaling on survival channel.
    - `K_patches` maps to patch-level ceiling scaling on survival channel.
  - Keep density channels opt-in beyond survival compatibility adapters.
- **Rationale**:
  - Aligns density semantics with the existing reproduction refactor model where
    baseline rates and stochastic realization are separated.
  - Extends density effects beyond survival without breaking legacy scenarios.
  - Creates a stable contract for upcoming R-level and YAML-level density work.
- **Status**: active

## DEC-006 — Release policy
- **Date**: 2026-02-08
- **Decision**:
  - Adopt semantic versioning from `1.0.0` onward.
  - Version increment rules:
    - `MAJOR` (x.0.0): breaking changes to documented stable public API,
      YAML schema contract, or output schema contract.
    - `MINOR` (1.x.0): backward-compatible features and additive schema fields.
    - `PATCH` (1.0.x): backward-compatible bug fixes, test/doc improvements,
      and non-semantic internal refactors.
  - Stable vs experimental API status is documented in
    `docs/reference/public_api.md` and is part of the release contract.
  - Deprecation policy:
    - Deprecations must be documented in `NEWS.md` and user docs.
    - Removed functionality must have at least one prior release with explicit
      deprecation guidance, except for security/integrity emergencies.
    - Planned removals are deferred to the next `MAJOR` unless explicitly
      declared otherwise.
  - Release evidence policy:
    - Each release candidate must include an artefact bundle and checklist
      updates (`artefacts/release_<...>/`, `docs/release_checklist.md`).
- **Rationale**:
  - Provides predictable expectations for users relying on the package in
    research workflows.
  - Aligns API/schema stability promises with reproducible release evidence.
- **Status**: active

## DEC-007 — Public repository metadata policy
- **Date**: 2026-02-08
- **Decision**: Keep `DESCRIPTION` `URL` and `BugReports` fields unset until the canonical public repository URL is live and returns 200. Use local/remote git configuration as internal provenance until then.
- **Rationale**: Current remote points to a repository path that returns 404 in `R CMD check --as-cran` URL validation, creating avoidable NOTES and ambiguous user-facing metadata.
- **Status**: active

## DEC-008 — Deterministic RNG contract for replicated runs
- **Date**: 2026-02-08
- **Decision**:
  - Add optional integer `seed` to `run_basic_simulation_replicates()`.
  - Thread `seed` through `scenario_spec()`/`run_scenario()` and YAML (`read_scenario_yaml()` top-level `seed`).
  - Seeded runs must restore caller RNG state on exit.
- **Rationale**:
  - Reproducible simulation outputs are required for stable demos, regression tests, and review artefacts.
  - Restoring caller RNG state prevents side effects when seeded runs are embedded in larger workflows.
- **Status**: active

## DEC-009 — Reproduction API naming and adapter strategy (0.5.2/0.5.3)
- **Date**: 2026-02-08
- **Decision**:
  - Adopt exported naming:
    - `validate_breeding_prob_table()`
    - `build_breeding_prob_fun_from_table()`
    - `validate_fecundity_lambda_table()`
    - `build_fecundity_lambda_fun_from_table()`
  - Provide explicit adapters:
    - `as_breeding_fun()`, `as_breeding_prob_fun()`
    - `as_fecundity_fun()`, `as_fecundity_lambda_fun()`
  - Keep legacy builders as wrappers:
    - `build_breeding_fun_from_table()`
    - `build_fecundity_fun_from_table()`
- **Rationale**:
  - Clear naming distinguishes baseline rate functions from legacy realized/eligibility interfaces.
  - Adapter-first strategy enforces backward compatibility during staged controller/YAML refactors.
- **Status**: active

## DEC-010 — Controller reproduction EV/cat parameterization (WP-0.5.4)
- **Date**: 2026-02-08
- **Decision**:
  - In controller reproduction pathway, apply year-level lognormal multipliers to:
    - breeding probability (`env_repro_p_sd`),
    - fecundity lambda (`env_repro_lambda_sd`).
  - Apply catastrophe as Bernoulli year event with shared multiplicative factor:
    - `cat_repro_prob`,
    - `cat_repro_mult`.
  - Expose year-level realized modifiers in summary output:
    - `env_repro_p_mult`,
    - `env_repro_lambda_mult`,
    - `cat_repro_mult`,
    - `repro_catastrophe`.
- **Rationale**:
  - Mirrors existing survival EV/cat style for conceptual consistency.
  - Keeps parameterization simple while enabling immediate analysis and regression coverage.
- **Status**: active

## DEC-011 — YAML schema v2 reproduction semantics and compatibility adaptation
- **Date**: 2026-02-08
- **Decision**:
  - Promote `schema_version: 2` as current YAML schema for reproduction semantics.
  - Keep `schema_version: 1` fully supported.
  - Parse canonical schema v2 reproduction channels:
    - `demography.breeding_prob.table`
    - `demography.fecundity_lambda.table`
    - `reproduction_ev` block keys:
      - `env_repro_p_sd`
      - `env_repro_lambda_sd`
      - `cat_repro_prob`
      - `cat_repro_mult`
  - Preserve compatibility by adapting v1-style reproduction fields where feasible,
    including:
    - `demography.breeding.table`
    - `demography.fecundity.table`
    - top-level reproduction EV keys.
  - Use exact-key parsing in demography blocks to avoid partial-name ambiguity
    (e.g. `breeding` vs `breeding_prob`).
- **Rationale**:
  - Locks a clear schema contract for the new reproduction model while preventing
    silent breakage of legacy YAML inputs.
  - Exact-key parsing removes a subtle class of parser errors that can arise
    from partial matching.
- **Status**: active

## DEC-012 — CI profile split and heavy-validation runtime budget
- **Date**: 2026-02-09
- **Decision**:
  - Split CI into two workflows:
    - `ci-fast`: PR/push gate for lint + tests + package checks.
    - `ci-heavy-validation`: scheduled/manual workflow for reproducibility-
      oriented checks.
  - Heavy profile includes:
    - reproducibility/schema-focused tests,
    - full package test suite,
    - Quarto render,
    - tarball build + `R CMD check --as-cran`,
    - minimal `targets` smoke run focused on `sim_basic`.
  - Exclude long-running replicate-heavy targets from scheduled heavy CI smoke
    to maintain predictable runtime while preserving broad model coverage
    through full test suite and dedicated artefact-cycle runs.
- **Rationale**:
  - Fast feedback is required for developer throughput on PRs.
  - Scheduled heavy validation should detect reproducibility drift without
    becoming so expensive that it is skipped or unstable.
  - Keeping heavy targets smoke bounded avoids cache/runtime brittleness while
    preserving meaningful workflow orchestration coverage.
- **Status**: active

## DEC-013 — Seeded snapshot regression scope
- **Date**: 2026-02-09
- **Decision**:
  - Add seeded snapshot-style regression checks that snapshot:
    - a bounded slice of replicate summary/extinction outputs, and
    - v1->v2 YAML migration shape for reproduction channels.
  - Keep snapshots intentionally scoped to stable, interpretable subsets rather
    than full simulation objects.
- **Rationale**:
  - Captures behavioral drift that column/type checks alone may miss.
  - Avoids brittle over-snapshotting that would create noisy false positives
    from unrelated internal changes.
- **Status**: active

## DEC-014 — Release automation boundary (non-publishing)
- **Date**: 2026-02-09
- **Decision**:
  - Provide scripted release-evidence generation via
    `scripts/build_release_evidence.sh`.
  - Keep automation scope strictly non-publishing:
    - no git tag creation,
    - no GitHub release publication,
    - no CRAN submission actions.
  - Keep final publish/tag decisions maintainer-controlled.
- **Rationale**:
  - Improves reproducibility and auditability of release-candidate evidence
    while preserving deliberate human control over irreversible publication
    actions.
- **Status**: active

## DEC-015 — Mate requirement and mate-limitation controls
- **Date**: 2026-02-09
- **Decision**:
  - Introduce `require_mate` as an additive reproduction control (default
    `FALSE` for backward compatibility).
  - Introduce `make_mate_limited_mating_fun(max_mates_per_male)` to support
    bounded male mate assignments within a reproduction step.
  - Thread `require_mate` through controller/scenario/YAML interfaces.
- **Rationale**:
  - Enables explicit mate-scarcity behavior without breaking legacy scenarios
    where unmated females may still produce offspring.
  - Keeps reproduction extension bounded while preserving composability through
    existing mating hooks.
- **Status**: active

## DEC-016 — Patch-level final-time genetic diversity summary contract
- **Date**: 2026-02-09
- **Decision**:
  - Add exported helper
    `summarise_patch_genetic_diversity_final(sim_output, n_patches, alive_only = TRUE)`.
  - Scope helper to final-time state only (not full time-series trajectories).
  - Aggregate by patch across runs using:
    - `mean_n_genotyped`,
    - `p_patch_genotyped`,
    - `mean_heterozygosity`,
    - `mean_Fhat`.
  - Keep patch IDs explicit and include zero-genotype patches in output.
- **Rationale**:
  - Provides immediately useful spatial/genetic diagnostics for management
    interpretation without introducing broad subsystem complexity.
  - Final-time scope keeps runtime/contract complexity bounded while preserving
    comparability across scenarios.
- **Status**: active

## DEC-017 — Decision-support expansion via additive final-abundance metrics
- **Date**: 2026-02-09
- **Decision**:
  - Add exported helper
    `summarise_final_abundance(sim_output, floor = 0)` with stable
    `per_run` + `overall` outputs.
  - Extend `compare_scenarios()` to include additive final-abundance metrics
    and optional `final_n_floor` (defaulting to `extinction_threshold`).
  - Preserve existing `compare_scenarios()` columns to avoid compatibility
    breakage.
- **Rationale**:
  - Management users need both extinction and resilience/floor-risk metrics for
    trade-off evaluation.
  - Additive extension avoids disruptive schema changes while increasing
    decision-support utility.
- **Status**: active

## DEC-018 — 1.x soft-deprecation runtime policy for legacy reproduction wrappers
- **Date**: 2026-02-09
- **Decision**:
  - Introduce a package-level soft-deprecation helper with:
    - once-per-session warning emission per deprecated interface,
    - explicit opt-out via `options(openpva.deprecation_warnings = FALSE)`.
  - Apply soft-deprecation warnings to retained legacy reproduction wrappers:
    - `validate_breeding_table()`
    - `make_default_breeding_table()`
    - `build_breeding_fun_from_table()`
    - `validate_fecundity_table()`
    - `build_fecundity_fun_from_table()`
  - Keep runtime behavior fully compatible throughout the 1.x line.
- **Rationale**:
  - Preserves 1.x stability while actively guiding migration to baseline-rate
    interfaces ahead of 2.0 removals.
  - Once-per-session warning behavior limits noise in long analyses and CI.
- **Status**: active

## DEC-019 — Spatial/genetic scenario-pack hooks and exact density key parsing
- **Date**: 2026-02-09
- **Decision**:
  - Add reusable spatial/genetic initialization helpers:
    - `initialize_spatial_population()`
    - `initialize_spatial_genetic_population()`
  - Add fixed three-patch dispersal regime helpers for scenario-pack use:
    - `dispersal_low_connectivity_fun()`
    - `dispersal_high_connectivity_fun()`
    - `dispersal_asymmetric_flow_fun()`
  - Extend YAML scenario parsing to accept optional function hooks:
    - `mating_fun`, `dispersal_fun`, `inherit_fun`.
  - Use exact key extraction (`[[...]]`) in density parser internals to avoid
    `$` partial-matching ambiguity between `K` and `K_patches`.
- **Rationale**:
  - Enables fully packaged and reproducible spatial-regime scenario examples in
    both YAML and R pathways.
  - Eliminates a subtle parser ambiguity that could trigger false
    `K`/`K_patches` conflicts.
- **Status**: active

## DEC-020 — CI renv restore determinism guard
- **Date**: 2026-02-09
- **Decision**:
  - In GitHub Actions workflows, explicitly disable renv autoloader via
    `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`.
  - Keep restore path non-`pak` in CI with explicit
    `options(renv.config.pak.enabled = FALSE)` in restore commands.
- **Rationale**:
  - Prevents project autoload side effects during `install.packages("renv")`
    in CI jobs.
  - Avoids transient dependency-solver instability observed in `ci-fast`
    `renv::restore()` on `main` pushes.
- **Status**: active

## DEC-021 — CI system requirements preinstall policy
- **Date**: 2026-02-09
- **Decision**:
  - In GitHub Actions workflows, install required Ubuntu system packages before
    `renv::restore()`:
    - `libcurl4-openssl-dev`
    - `libfontconfig1-dev`
    - `libfreetype6-dev`
    - `libgit2-dev`
    - `libglpk-dev`
    - `libx11-dev`
    - `pandoc`
  - Apply this policy consistently to both `ci-fast` and
    `ci-heavy-validation`.
- **Rationale**:
  - Fixes binary load failures during dependency restore (for example
    `igraph.so` failing to load because `libglpk.so.40` was absent).
  - Aligns CI runtime environment with declared package/system requirements,
    reducing restore/check flakiness and follow-on runtime link errors.
- **Status**: active

## DEC-022 — CI lint-tool bootstrap outside renv lock
- **Date**: 2026-02-09
- **Decision**:
  - In `ci-fast`, add explicit lint-tool bootstrap:
    - install `lintr` from CRAN when `requireNamespace("lintr")` is false.
  - Keep this bootstrap step after `renv::restore()` and before lint execution.
- **Rationale**:
  - `renv.lock` currently does not guarantee `lintr` availability in CI, which
    caused the lint stage to fail even after dependency restore succeeded.
  - Conditional install keeps CI resilient while preserving existing lockfile
    behavior for core runtime dependencies.
- **Status**: superseded by DEC-023

## DEC-023 — CI `Suggests` bootstrap policy for check consistency
- **Date**: 2026-02-09
- **Decision**:
  - In both `ci-fast` and `ci-heavy-validation`, parse `DESCRIPTION` `Suggests`
    and conditionally install any missing suggested packages after
    `renv::restore()`.
  - Keep lint/test/check steps dependent on this bootstrap rather than relying
    on full `Suggests` coverage in `renv.lock`.
- **Rationale**:
  - Eliminates repeated CI failures from missing suggested packages (for
    example `lintr`, `quarto`) while keeping restore deterministic for core
    dependency set.
  - Provides a single scalable mechanism for future additions to `Suggests`
    without recurring workflow churn.
- **Status**: active

## DEC-024 — `targets` heavy smoke should not pre-invalidate fresh stores
- **Date**: 2026-02-09
- **Decision**:
  - In `ci-heavy-validation`, run heavy smoke as:
    - `targets::tar_make(..., names = c("sim_basic"))`
  - Do not call `targets::tar_invalidate()` before `tar_make()` in CI smoke.
- **Rationale**:
  - In fresh CI stores with no local metadata, `tar_invalidate()` can error
    (`names must be a character`) before the first pipeline run.
  - The smoke objective is to verify minimal pipeline execution, which is
    satisfied by direct `tar_make()` on selected targets.
- **Status**: active

## DEC-025 — Promote Line 2B.x roadmap tranche (uncertainty, validation, scale)
- **Date**: 2026-02-09
- **Decision**:
  - Extend the Priority Queue in `docs/roadmap.md` with `Line 2B.x` containing:
    - `WP-2B.1` through `WP-2B.6`.
  - Keep strict top-to-bottom queue execution semantics unchanged.
  - Sequence 2B work as:
    - contract lock (`WP-2B.1`) -> R-level uncertainty engine (`WP-2B.2`)
      -> YAML schema v3 integration (`WP-2B.3`) -> diagnostics (`WP-2B.4`)
      -> calibration scaffold (`WP-2B.5`) -> performance/docs hardening
      (`WP-2B.6`).
- **Rationale**:
  - Priority Queue was exhausted through `WP-2A.6`; autonomous execution
    requires a promoted next tranche.
  - This ordering keeps high-risk interface decisions ahead of implementation
    and preserves additive compatibility strategy before schema expansion.
- **Status**: active

## DEC-026 — Uncertainty/validation contract for Line 2B implementation
- **Date**: 2026-02-09
- **Decision**:
  - Lock uncertainty taxonomy for 2B implementation as:
    - parameter uncertainty on vital-rate baseline channels (survival,
      breeding probability, fecundity lambda),
    - management control uncertainty for selected scalar controls (e.g.
      harvest/supplementation intensity),
    - no explicit observation-error likelihood layer in 2B (out of scope).
  - Lock modifier composition order for rate channels:
    - baseline -> density modifier -> uncertainty modifier -> year EV/cat
      modifier -> bounds clamp -> stochastic draw.
  - Lock per-draw semantics:
    - sampled uncertainty parameters are fixed within a draw and shared across
      that draw's replicate runs unless explicitly marked year-varying.
  - Lock compatibility strategy:
    - uncertainty is additive and opt-in in 1.x,
    - existing deterministic/legacy pathways remain valid with default
      uncertainty disabled,
    - YAML uncertainty integration lands in schema v3 as additive fields.
  - Lock calibration/hindcast boundary for 2B:
    - provide transparent bounded scoring/search scaffold only,
    - full Bayesian/statistical inference remains out of scope.
- **Rationale**:
  - Prevents semantic drift across WP-2B.2 to WP-2B.6 by fixing interfaces and
    composition order before implementation.
  - Preserves backward compatibility while enabling a clear, testable
    uncertainty expansion path.
- **Status**: active

## DEC-027 — WP-2B.2 uncertainty API shape and distribution set
- **Date**: 2026-02-09
- **Decision**:
  - Introduce exported R-level APIs:
    - `sample_uncertainty_parameters()`
    - `run_scenario_ensemble()`
    - `summarise_ensemble_outputs()`
  - Adopt a named-list `uncertainty_spec` contract where each parameter uses:
    - `dist` in `{fixed, uniform, normal, lognormal}`,
    - distribution-specific scalar fields,
    - optional `lower`, `upper`, and `integer` controls.
  - Require uncertainty parameter names to match writable scenario fields
    (explicit error on unknown parameters).
  - Keep draw semantics fixed-within-draw and return draw-level provenance via
    `sampled_parameters` and `draw_results`.
  - Keep APIs experimental in 1.x while output schema is stabilized.
- **Rationale**:
  - Provides a bounded, interpretable uncertainty API without overcommitting to
    a larger inference framework.
  - Supports immediate ensemble analyses with explicit reproducibility and audit
    trails.
- **Status**: active

## DEC-028 — YAML schema v3 uncertainty discipline and scenario fallback wiring
- **Date**: 2026-02-09
- **Decision**:
  - Keep uncertainty schema strictly additive at `schema_version: 3`:
    - schema v3 accepts `uncertainty` as either direct parameter mapping or
      `uncertainty.params`.
    - schema v2 rejects `uncertainty` with explicit migration guidance to
      `schema_version: 3`.
  - Parse validated uncertainty mappings into `scenario$uncertainty_spec` for
    downstream ensemble workflows.
  - Update `run_scenario_ensemble()` to accept `uncertainty_spec = NULL` and
    use `scenario$uncertainty_spec` when available.
  - Preserve schema v2 reproduction compatibility behavior in schema v3:
    legacy `breeding_fun`/`fecundity_fun` inputs are adapted to baseline-rate
    channels so controller-level reproduction EV semantics remain consistent.
- **Rationale**:
  - Enforces clear schema boundaries while keeping migration path explicit and
    backward-compatible.
  - Reduces ensemble invocation friction for YAML-driven workflows.
  - Avoids silent semantic drift where schema v3 would otherwise diverge from
    schema v2 reproduction compatibility expectations.
- **Status**: active

## DEC-029 — Sensitivity diagnostic contract (PRCC + bounded OAT)
- **Date**: 2026-02-09
- **Decision**:
  - Add exported diagnostics:
    - `summarise_sensitivity_prcc()`
    - `summarise_sensitivity_oat()`
  - PRCC scope:
    - compute partial rank correlations on draw-level ensemble summaries,
    - support inputs from `run_scenario_ensemble()` outputs,
      `summarise_ensemble_outputs()` lists, or direct draw tables,
    - return parameter-wise coefficients and p-values with stable schema.
  - OAT scope:
    - use explicit `oat_spec` baselines and bounded perturbations
      (`baseline ± delta` clamped by optional `lower`/`upper`),
    - evaluate scalar metrics via user-supplied `metric_fun`,
    - return local slope/elasticity and low/high percent-change diagnostics.
  - Keep sensitivity methods bounded and transparent:
    - no full global-SA ecosystem in this tranche,
    - no inference claims beyond local/ensemble interpretation.
- **Rationale**:
  - Delivers interpretable parameter-influence diagnostics for uncertainty
    outputs while keeping method scope aligned with the Line 2B contract.
  - Preserves auditability by enforcing explicit input specs and stable output
    tables.
- **Status**: active

## DEC-030 — Hindcast/calibration scaffold boundaries and objective contract
- **Date**: 2026-02-09
- **Decision**:
  - Add bounded calibration APIs:
    - `score_hindcast_fit()`
    - `generate_calibration_candidates()`
    - `run_calibration_search()`
  - Use transparent objective metrics (`rmse`, `mae`, `bias`, `mape`) with
    `objective_score = rmse` for ranking by default.
  - Restrict candidate generation to explicit bounded methods:
    - deterministic grid,
    - seeded bounded random draws.
  - Keep calibration outputs explicit and auditable:
    - per-candidate scores,
    - one-row best-fit summary,
    - recorded observed targets.
  - Keep this tranche scaffold-level:
    - no Bayesian inference, no production auto-tuning loops.
- **Rationale**:
  - Provides reproducible calibration support while preserving model
    transparency and avoiding overclaiming inferential rigor in the 2B scope.
  - Keeps tuning behavior inspectable via explicit parameter bounds and
    objective traces.
- **Status**: active

## DEC-031 — Ensemble parallelism policy for deterministic uncertainty workflows
- **Date**: 2026-02-09
- **Decision**:
  - Extend `run_scenario_ensemble()` with bounded parallel controls:
    - `parallel` (logical),
    - `n_cores` (positive integer).
  - Implement parallel draws via `parallel::mclapply()` on non-Windows
    platforms only.
  - Preserve deterministic behavior under fixed seeds by deriving explicit
    draw-level seeds and applying them to each draw scenario before execution.
  - Add CI-heavy uncertainty smoke coverage that exercises:
    - serial/parallel ensemble consistency,
    - PRCC sensitivity helper,
    - calibration scaffold helper path.
- **Rationale**:
  - Provides practical runtime improvement for uncertainty ensembles while
    maintaining reproducibility contracts central to OpenPVA.
  - Keeps parallel behavior bounded, explicit, and testable.
- **Status**: active
