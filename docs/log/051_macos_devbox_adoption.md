# 051 Mac dev-box adoption baseline

> Superseded by `docs/log/052_r460_macos_readiness_sweep.md`: R `4.5.3` was a
> transitional adoption runtime. The active OpenPVA baseline is now R `4.6.0`.

## Context

- Workflow moved from the previous WSL setup onto Barry's Mac mini dev-box.
- Repository was checked from `/Users/bwbrook/git/OpenPVA` on `main` at
  `bdb74ea`.
- `git fetch --prune origin && git pull --ff-only` reported the branch was
  already up to date with `origin/main`.

## Host and tooling

- Host: `Barry's Mac mini` (`Mac-mini.lan`), macOS `26.5`, `arm64`.
- Homebrew R on `PATH` remains `4.6.0`, but `renv.lock` records R `4.5.3`.
- Installed `r-rig` via Homebrew and added rig-managed R `4.5.3`
  (`4.5-arm64`) for this project.
- Use the lockfile-matched runtime with:

```bash
PATH=/usr/local/bin:$PATH Rscript bootstrap_env.R
PATH=/usr/local/bin:$PATH Rscript scripts/run_tests.R
```

## Local system adjustments

- Added `/Users/bwbrook/.R/Makevars` so official R source-package builds can
  see Homebrew headers/libraries and Homebrew `gfortran`.
- Installed the rig gfortran sysreq; Homebrew `gfortran` is the compiler used by
  `~/.R/Makevars`.
- Replaced the rig-installed R 4.5.3 `libomp.dylib` with a symlink to Homebrew
  `libomp` because the bundled library lacked the OpenMP symbol emitted by the
  current Apple clang. The original was retained as:
  `/Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/lib/libomp.dylib.orig`.
- Quarto CLI is available at `/Users/bwbrook/Applications/quarto/bin/quarto`
  (`1.9.37`); Pandoc (`3.9.0.2`) and TeX Live (`2026`) are available.

## Verification

- `renv::status()` under R `4.5.3`: no issues found.
- `Rscript scripts/run_tests.R`: `532` pass, `0` fail, `0` warn, `0` skip.
- `targets::tar_make(script = "_targets.R", store = "_targets", names = c("sim_basic"))`:
  completed `sim_basic`.
- `quarto render quarto`: rendered `outputs/quarto_site/index.html`.
- `lintr::lint_package()`: no lints found.

## Notes

- Running `/opt/homebrew/bin/Rscript` still uses R `4.6.0` and is intentionally
  not the canonical OpenPVA validation runtime while the lockfile is pinned to
  R `4.5.3`.
- No package code changes were required for Mac adoption.
