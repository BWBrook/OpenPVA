# Goal 003 log

## 2026-08-09 - authorised start

- Barry authorised Goal 003 after publication of Goals 001 and 002.
- Starting state was verified clean on `main...origin/main` at `e07a90d`.
- This log will record implementation evidence, the single review/repair pass,
  exact validation results and residual limitations.

## 2026-08-09 - implementation and focused acceptance

- Added `R/grizzly_benchmark.R` with a synthetic source-labelled fixture,
  ordinary annual environment, ageing/dependency, mate-gated breeding,
  reproduction, disjoint cub/yearling and independent survival, targeted human
  mortality, immigration, observation and census processes.
- Added baseline, low/high independent-female survival, human mortality and
  immigration scenarios, plus explicit annual-environment and mortality-order
  extension demonstrations.
- Added replicate-preserving trajectory/event/run summaries with initial versus
  interval census, geometric finite growth, quasi-extinction probability and
  Monte Carlo error, event strata, process order, effective-parameter hash,
  streams and software provenance.
- Added focused tests for fixture bounds, empty/one-sex/all-dependent states,
  extension composition, order falsification, seeded reproducibility,
  independent expectation, accounting, dependency transitions and female
  survival alternatives.
- Focused Goal 003 suite: **54 passed, 0 failed, 0 warnings, 0 skipped**.

## 2026-08-09 - focused self-review and repair

The review pass corrected eight material issues before stopping: mortality
probability semantics, cub/yearling status timing, maternal-care eligibility,
human mortality strata, initial-census growth anchoring, parameter/units and
survival-bound validation, survival-only environmental variation, and effective
scenario hashing. The observer now reports binomial detection separately from
latent abundance, the fixture links initial dependants to a living maternal
record, dependency events retain explicit `from`/`to` states, and the event
summary retains stratum columns.

## 2026-08-09 - final gates

- Focused Goal 003 suite: **56 passed, 0 failed, 0 warnings, 0 skipped**.
- Full package test suite: **238 passed, 0 failed, 0 warnings, 0 skipped**.
- `R CMD build --no-build-vignettes .`: succeeded.
- `R CMD check --no-manual --no-build-vignettes`: **Status: OK** under R
  4.6.1 on Apple Silicon macOS.
- `git diff --check`: clean.
- Generated tarball and check directory removed.

Residual limitations are deliberate: the fixture is synthetic and
uncalibrated; observation is a simple binomial detection demonstration; the
benchmark does not add density, space, genetics, disease, habitat, YAML,
targets, reporting, uncertainty or calibration workflows; fork parallelism and
the pre-existing `renv` advisory remain outside this goal. No commit or push
was performed.

## 2026-08-09 - independent bounded audit and repair

The authorised audit found six material contract issues and repaired only
those issues. The stochastic oracle now makes the three eligible initial
females explicit, fills zero-event replicates before comparing the unconditional
birth mean to `n_eligible * fecundity_lambda`, and uses the analytic Poisson
Monte Carlo standard error. A matched conditional human-mortality frequency
calibration was added. Summary crossing now includes the initial census and
retains a phase/time discriminator; finite growth is `NA` for zero initial
abundance. Successful births immediately mark their mother `caring`, blocking
same-interval repeated reproduction through a benchmark-local wrapper.

Human mortality is documented as a conditional hazard at process position, with
exact event age and age class derived from the declared maturity boundary.
Immigration count and age are validated and normalised before process
construction, including zero-count behaviour. The canonical runner now accepts
only the five named benchmark scenarios; mutable extensions use
`grizzly_benchmark_scenario()` plus `run_scenario()`, and generic summaries
require explicit benchmark metadata. Event summaries retain dependency
`from`/`to` fields. Added/updated focused tests cover all repaired contracts,
including initial-threshold and empty-plus-immigration summaries.

Fresh post-repair gates: focused Goal 003 **80 passed, 0 failed, 0 warnings,
0 skipped**; retained full suite **262 passed, 0 failed, 0 warnings, 0
skipped**; `R CMD build --no-build-vignettes .` succeeded; `R CMD check
--no-manual --no-build-vignettes` returned **Status: OK** under R 4.6.1;
`git diff --check` was clean; the forbidden fixed-label/controller scan was
empty; and generated tarball/check-directory artifacts were removed. The
worktree remains uncommitted on `main...origin/main` at `e07a90d`.

## 2026-08-09 - final micro-repair

The final bounded repair aligned mating with mature-male eligibility, added a
post-dependent-survival maternal-status refresh, made the repeated-reproduction
oracle decisive with a high bounded fecundity fixture, removed implicit trust
of mutable scenario metadata in generic summaries, and tightened source/unit
metadata validation to reject missing or blank values. Focused tests cover
immature-male selection, no-mature-male reproduction, live versus dead
dependants, and metadata failures.

Fresh micro-repair gates: focused Goal 003 **93 passed, 0 failed, 0 warnings,
0 skipped**; retained full suite **275 passed, 0 failed, 0 warnings, 0
skipped**; isolated `R CMD build --no-build-vignettes .` and
`R CMD check --no-manual --no-build-vignettes` both succeeded (`Status: OK`);
`git diff --check` was clean; the forbidden fixed-label/controller scan was
empty; and generated artifacts were removed. No commit or push was performed.
