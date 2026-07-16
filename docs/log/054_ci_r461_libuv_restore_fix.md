# 054 CI R 4.6.1 libuv restore fix

## Failed run

- Published push-triggered `ci-fast` run `29473461250` failed on `main` at
  `1d777fe6d80b5b24bcaff77d4530349c158b8bca`:
  `https://github.com/BWBrook/OpenPVA/actions/runs/29473461250`.
- Checkout, R setup, system dependency installation, and `renv` installation
  passed. The failure occurred in `Restore dependencies`.
- Source installation of locked `fs` 2.1.0 failed during configure with
  `fatal error: uv.h: No such file or directory` and
  `ERROR: configuration failed for package 'fs'`. The configure output
  explicitly recommended `libuv1-dev` for Debian and Ubuntu.
- `bslib`, `pkgload`, `rmarkdown`, `sass`, and `testthat` then failed through
  dependency failures rather than independent errors.

## Diagnosis and repair

- The previous green main baseline locked `fs` 1.6.7, whose declared system
  requirement was only GNU make. The current lock uses `fs` 2.1.0, which
  declares `libuv1-dev` on Debian/Ubuntu (or a bundled libuv build with CMake).
- Root-cause hypothesis: the Ubuntu source restore lacks the libuv headers now
  required by locked `fs` 2.1.0.
- Added exactly `libuv1-dev` to the shared pre-restore apt list in both the fast
  and heavy workflows, and synchronized both reference commands in
  `docs/reference/ci_profiles.md`.
- Did not add `USE_BUNDLED_LIBUV`, CMake, or any unrelated package.

## Local static verification

- `actionlint .github/workflows/*.yaml`: exit `0`.
- Bounded inspection confirmed each workflow apt list and each documented apt
  command contains `libuv1-dev` exactly once.
- `git diff --check`: exit `0`.
- No R restore, tests, build, or runtime workflow was run locally; the required
  verification is a fresh push-triggered Ubuntu `ci-fast` run.

## Status and scope

- GitHub verification remains pending. Goal 001 remains open until a fresh
  push-triggered `ci-fast` run succeeds.
- This repair changes no scientific behaviour, API, schema, package/runtime
  lock, or R version.
