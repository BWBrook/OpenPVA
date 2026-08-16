# Goal 009 log

## 2026-08-14 - authorised boundary

- Barry accepted Goal 008 and authorised Goal 009 as the second lean sweep.
- Goal 008 was committed locally at `d426910`; the repository began Goal 009
  clean on `main...origin/main [ahead 1]`. Publication remains unauthorised.
- Live-caller review separated the generic engine, accepted Stage 3 modules,
  benchmark, pedigree and explicit table builders from controller-era lifecycle
  mutators and an incompatible old-output analysis chain.
- Historical goals, logs, tracked artefacts and the deferred unrendered Quarto
  demo were explicitly excluded from deletion.

## 2026-08-14 - coherent surface implementation

- Removed direct age/survival/breeding/fecundity/harvest mutators, random
  `initialize_population()`, packaged default schedules and their public help.
- Removed the dormant summary, plotting, management, uncertainty, sensitivity
  and calibration chain, its exclusive tests and the now-unused optional-seed
  helper.
- Consolidated demographic age/sex lookup mechanics. Retained table builders
  now reject malformed individuals, uncovered sexes and uncovered age gaps;
  no implicit zero or terminal-age extrapolation remains.
- Removed `purrr` and `ggplot2` from direct imports. Retained `targets`, Quarto,
  YAML and `renv.lock` as deferred analysis/configuration machinery without
  environment churn.
- Removed the stale release-evidence script and current-facing compatibility,
  uncertainty, calibration and sensitivity pages. Current API, workflow,
  release and CI documentation now matches the executable package/workflows.
- `roxygen2` was not present in the project library, so the small generated
  namespace/help deletion was synchronized explicitly and is subject to the
  package build/check gate rather than installing or changing the environment.
- Initial focused table, spatial and accounting evidence passed **157/157**
  assertions with no failures, warnings or skips.

## 2026-08-14 - review repair and final evidence

- One focused self-review found that table validators still coerced malformed
  factor/character columns before strict lookup. They now require explicit
  numeric ages/rates and character sex columns, and reject empty tables. Added
  two direct regressions; no second polish loop was started.
- Post-repair focused table evidence passed **31/31** assertions. After the
  final audit removed a permanent obsolete-name deletion ledger, the retained
  full suite passed **579/579** in **35.1 seconds**, with no failures, warnings
  or skips.
- The operations audit also reclassified the retained Mac readiness evidence
  as historical provenance; it does not claim to prove the current checkout.
- An explicit two-replicate, three-step canonical baseline grizzly run completed
  with **40 events** and **2 run summaries**. `lintr::lint_package()` reported
  no lints.
- Fresh isolated R 4.6.1 source build succeeded and
  `R CMD check --no-manual --no-build-vignettes` returned **Status: OK** on
  Apple Silicon macOS. Both temporary build/check directories were removed.
- All **41** surviving exports resolve. Collate and current namespace/help are
  consistent, with no deleted-name residue in the active surface.
- `git diff --check` passed and no build/check artefact was created in the
  repository. The known `renv` out-of-sync advisory remains; `renv.lock` was
  deliberately not churned for removal of two direct imports.
- No staging, commit, push, tag, release or publication occurred in Goal 009.

## 2026-08-14 - accepted and published

- Barry accepted Goal 009. The reviewed payload was committed and pushed as
  `7dcb850` (`refactor: complete lean surface cleanup`).
