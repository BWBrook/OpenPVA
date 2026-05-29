# macOS R 4.6.0 readiness sweep

Date: 2026-05-29

Scope:

- Move OpenPVA from stale R `4.5.3` pinning to Homebrew R `4.6.0`.
- Refresh `renv.lock` and local package stack.
- Run CI-fast, CI-heavy, Quarto, targets, package-check, and release-evidence
  smoke equivalents on Barry's Mac mini.

Key results:

- `renv::status()`: clean under R `4.6.0`.
- `lintr`, `actionlint`, `shellcheck`: passed.
- Focused tests: `172` pass.
- Full tests: `532` pass.
- Uncertainty smoke: passed; PRCC rows `2`, calibration score rows `4`.
- Full default `targets` pipeline: `14` targets completed from an empty store.
- Quarto render: passed, output at `quarto/_site/index.html`.
- `R CMD check --no-manual --as-cran`: `0` errors, `0` warnings, `2` notes.
- Release evidence script: `scripts/build_release_evidence.sh rc3` completed.

Notable fixes:

- Updated release-evidence toy scenario from stale `K = 40` shortcut to
  explicit `density_spec(survival_fun = make_ceiling_density_fun(K = 40))`.
- Replaced shell `ls | head` tarball selection with an R-based mtime selection.
- Moved Quarto site output from `outputs/quarto_site` to `quarto/_site` to
  avoid Quarto 1.9 external-output-dir warnings.
