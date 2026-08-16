# Goal 010 log

## 2026-08-14 - authorised boundary and baseline

- Barry accepted Goal 009, authorised its publication, and approved Goal 010 as
  the second lean-sweep stage before new development.
- Goal 010 began clean on published `main` at `7dcb850`.
- The baseline suite contained **98 test cases** and passed **579/579**
  assertions in **39.0 seconds** testthat time (**40.19 seconds** real), with no
  failures, warnings or skips.
- Density (**74 assertions, 15.7 seconds**), grizzly (**106, 11.3 seconds**) and
  the independent oracle (**1, 6.7 seconds**) dominated runtime.
- The lockfile contained **71 packages** on R 4.6.1 and the project reported
  out of sync. The tracked Quarto project also had ignored cache/site residue.

## 2026-08-14 - lean implementation

- Removed module-specific serial/fork repeats already owned by the global RNG
  contract, duplicate engine-stamping assertions, one repeated birth fixture,
  repeated invalid examples on the same branch and private performance-shape
  tests. Preserved independent analytic expectations, process-order effects,
  exact accounting, shared-prestate tests and public pedigree boundaries.
- Reduced the approved Monte Carlo samples and replaced the benchmark female-
  survival comparison with exact configured callback-rate evidence.
- Removed standalone test steps from both CI profiles; package checks remain the
  test authority. Added `scripts/run_lint.R` so lint is both a lean local entry
  point and an executable dependency consumer.
- Deleted the tracked Quarto project, ignored render/cache residue, obsolete
  ignore entries, `outputs/quarto_site/`, and the redundant
  `install_suggests.R` path. The unrelated retained trajectory PNG was not
  touched.
- Removed YAML, `targets` and Quarto from `Suggests`. A first normal snapshot
  correctly refused a globally recursive `Suggests` closure. The material
  repair restored standard recursive fields and used executable discovery;
  the changed snapshot reduced the lock from **71 to 43 packages**, retained
  test/lint tooling, removed dormant analysis/reporting closure, and kept R
  **4.6.1**. `renv::status()` then reported a consistent project.
- Metadata review then made `testthat` the sole package `Suggests`; `lintr`
  remains lock-only development tooling earned by `scripts/run_lint.R`.
- No package was installed, removed from the library, cleaned or upgraded.
  No staging, commit, push, tag, release or publication occurred.

## 2026-08-14 - review repair and final evidence

- One focused self-review found that the retained density accounting and
  pedigree-lineage fixtures still used six and five replicates. Both now use
  one run, which is sufficient for their retained deterministic contracts.
- Independent delivery review found two fail-closed defects in the initial
  hygiene pass. `bootstrap_env.R` still sourced the deleted Suggests installer,
  and the package-check test entry point conditionally skipped when `testthat`
  or the installed package namespace was missing. Bootstrap now ends with the
  lockfile restore, and `tests/testthat.R` calls `testthat::test_check()`
  directly so missing dependencies or namespace loading fail the CI check.
  The README no longer invokes a second redundant restore after sourcing the
  bootstrap.
- Independent scientific review restored compact final newcomer state and
  summary-source coverage, a distinct fixed-count overflow case, one fractional
  patch-domain case, and higher-power central Monte Carlo checks: benchmark
  births **400**, human mortality **500**, Markov transitions **4000**, and the
  independent process oracle **1000**. Sound density/introduction reductions
  and duplicate fork/provenance removals remain.
- Changed-context evidence passed **229/229 assertions** in **12.7 seconds**.
  The final suite contains **95 test cases** and passed **483/483 assertions**
  in **21.5 seconds** testthat time (**22.55 seconds** real), with no failures,
  warnings or skips. This is 96 fewer assertions and about 45% less testthat
  runtime than baseline; the provisional diagnostic target did not override
  scientific power or distinct branch evidence.
- The final lock audit found no R or package version changes. It added only
  `lintr`, `rex`, `xml2` and `xmlparsedata`; it removed 32 packages belonging to
  the dormant targets/plotting/reporting closure. `yaml` remains only as an
  `renv` dependency, not an OpenPVA `Suggests` entry. Snapshot-generated
  whitespace churn in `renv/activate.R` was restored exactly to `HEAD`.
- `renv::status()` reported no issues and the lock remains on R **4.6.1**.
  `actionlint .github/workflows/*.yaml`, `scripts/run_lint.R`, active-residue
  scans and `git diff --check` passed.
- A two-run, three-step canonical baseline produced **46 events**. Final record
  counts and living abundance reconciled exactly with initial abundance,
  births, introductions and deaths in both runs.
- All **14** Collate sources exist and all **41** exports resolve.
- A fresh isolated R 4.6.1 source build succeeded and ordinary
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK** on
  Apple Silicon macOS, with the fail-closed installed tests executed. The
  temporary build/check tree was removed and no repository artefact was created.
- No staging, commit, push, tag, release or publication occurred.
