# 053 R 4.6.1 Mac/CI readiness closure

## Context

- Barry selected baseline closure and publication before further feature work.
- The starting branch was `main` at `6e56ad3`, exactly two commits ahead of
  `origin/main` at `bdb74ea`; `git fetch --prune origin` confirmed no upstream
  advance or divergence.
- Active `R` and `Rscript` were `/opt/homebrew/bin/R` and
  `/opt/homebrew/bin/Rscript`, both R `4.6.1`.
- Historical R `4.6.0` logs and evidence remain unchanged.

## Changes

- Snapshotted `renv.lock` under Homebrew R `4.6.1`. The only lockfile change
  was its R version field (`4.6.0` to `4.6.1`); package records were unchanged.
- Updated both CI workflow R pins and the current CI reference to `4.6.1`.
- Kept `DESCRIPTION` at `R (>= 4.6.0)` and the README compatibility badge at
  R `4.6+`.
- Replaced the stale README Phase 1 description with the mature post-`WP-2B.6`
  baseline status.
- Added `.DS_Store` to `.gitignore` and removed only the untracked root copy.
- Refreshed the current plan, interpretation notes, release checklist, and one
  canonical `rc4` evidence bundle.

## Verification

- Dependency state:
  - Local `renv::restore(prompt = FALSE)` completed with no downloads.
  - Local `renv::status()` reported no issues.
  - `renv.lock` contains 71 package records: `renv` plus a 70-package restore
    workload. A clean tracked-source export installed 67 workload packages into
    an empty external temporary library and retained 3 already-present packages,
    then reported a clean `renv::status()`.
  - Failed clean-restore layout 1 disabled project activation while overriding
    the library path. Restore returned, but the follow-up process did not attach
    that library and reported that no project packages were installed.
  - Failed clean-restore layout 2 activated an isolated library inside the
    exported source tree. Package installation completed, but `renv::status()`
    correctly rejected the layout after dependency discovery scanned the
    library's own package examples and reported false missing dependencies.
  - The corrected clean-restore rerun placed the empty isolated library outside
    the source tree, restored the locked stack, and ended with `No issues
    found -- the project is in a consistent state.`
  - All temporary source, library, and targets directories were removed.
- Static checks:
  - `actionlint .github/workflows/*.yaml`: exit `0`.
  - `shellcheck scripts/build_release_evidence.sh`: exit `0`.
  - `lintr::lint_package()`: `0` lints.
- Tests:
  - `Rscript scripts/run_tests.R`: `532` pass, `0` fail, `0` warn, `0` skip.
- Targets:
  - The first isolated targets invocation supplied an installed project library
    through `RENV_PATHS_LIBRARY`; renv treated it as a root, appended a platform
    suffix, and exited before dispatch because `targets` was unavailable.
  - The corrected rerun disabled project activation, supplied the exact library
    through `R_LIBS_USER`, and retained the empty external targets store.
  - A fresh full run in an isolated source tree and empty external store
    completed `14` targets with `0` skipped and no target warnings or errors.
  - Runtime was 1 minute 8.8 seconds.
- Quarto:
  - `quarto render quarto` completed and generated `_site/index.html` and
    `_site/about.html` plus site assets.
- Package build/check:
  - `R CMD build --no-build-vignettes .` produced
    `OpenPVA_1.0.0.tar.gz`.
  - `R CMD check --no-manual --as-cran OpenPVA_1.0.0.tar.gz` completed with
    `0` errors, `0` warnings, and `2` notes (`New submission`; non-standard
    top-level project files).
- Release evidence:
  - `scripts/build_release_evidence.sh rc4` completed without publishing.
  - Its forced `sim_basic` smoke completed, tests again passed `532`, Quarto
    rendered, package check retained the same two notes, and the 5-run release
    toy had `p_extinct = 0`.

## Fresh interpretation

- `sim_basic` ended year `20` with `n_alive = 375`.
- The 20-run baseline had `p_extinct = 0`.
- The 15-run density/harvest smoke had `p_extinct = 0.06666666666666667`, mean
  extinction time `21`, and no missing values across its 30-year trajectory.
- Spatial occupancy probabilities were bounded in `[0, 1]`; both patches were
  extinct in all five runs at year 20. This matches the pre-existing
  deterministic target cache and was not introduced by the runtime migration.
- No scientific behaviour, API, YAML schema, package version, or minimum-R
  change was made.

## Artefacts

- `artefacts/release_1.0.0-rc4/`

## Independent review and acceptance

- Independent review returned `ACCEPT_WITH_MINOR`, with no Critical or Important
  findings.
- Both precision findings are resolved: the README now names `quarto/_site` as
  the render destination, and the restore evidence now distinguishes 71 lockfile
  package records from the 70-package restore workload (67 installed, 3
  retained).
- The orchestrator independently verified the evidence and accepts Goal 001 as
  publication-ready.

## Remaining release work

- Origin publication and the resulting GitHub CI outcome are the next
  confirmation gate. The local evidence does not claim that GitHub CI has
  already run under R `4.6.1`.
- Tag creation, release notes, GitHub Release, CRAN submission, and the
  pre-existing `DESCRIPTION` `1.0.0` versus `NEWS` `1.0.1-development` release
  decision remain open.
- This closure pass performed no push, tag, GitHub Release, or CRAN submission.
