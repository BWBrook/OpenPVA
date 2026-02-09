# Release evidence automation (non-publishing)

OpenPVA includes a scripted process for generating release-candidate evidence
bundles without creating tags or publishing artefacts.

## Script

- `scripts/build_release_evidence.sh`

Usage:

```bash
scripts/build_release_evidence.sh rc1
```

The argument must be `rcN` (for example, `rc1`, `rc2`).

## What the script does

For the current package version in `DESCRIPTION`, it creates:

- `artefacts/release_<VERSION>-<rcN>/`

It then runs and records:

- `renv::restore()`
- lint (`lintr::lint_package()`)
- full tests (`devtools::test()`)
- minimal targets smoke (`sim_basic`)
- Quarto render
- tarball build
- `R CMD check --no-manual --as-cran`
- deterministic toy scenario outputs (`.rds` + `.csv`)

## Non-publishing boundary

This script intentionally does **not**:

- create git tags,
- create GitHub releases,
- publish to CRAN.

Final publication steps remain maintainer-controlled.
