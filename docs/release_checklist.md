# Release checklist

A release is a maintainer-approved, tagged state. Historical release bundles do
not prove the current checkout.

## Scope and records

- [ ] Release scope and version decision are explicit.
- [ ] `docs/plan.md`, `docs/decisions.md`, current help and README are truthful.
- [ ] Only accepted changes are committed and the worktree is clean.

## Package evidence

- [ ] Project dependencies restore from the committed lockfile.
- [ ] `Rscript scripts/run_tests.R` passes.
- [ ] A representative canonical benchmark completes with plausible bounded
      outputs and exact event accounting.
- [ ] `lintr::lint_package()` reports no lints.
- [ ] An isolated source build succeeds.
- [ ] The selected ordinary or `--as-cran` `R CMD check` returns the accepted
      status.
- [ ] Relevant GitHub CI runs are successful at the exact candidate commit.

## Publication

- [ ] Maintainer review is complete.
- [ ] Version and release notes are final.
- [ ] Tag, GitHub release and any CRAN submission are separately authorised.

There is no current release-evidence bundle script. Build logs or compact
evidence should be captured only when a release goal requests them; older
tracked bundles remain historical provenance.
