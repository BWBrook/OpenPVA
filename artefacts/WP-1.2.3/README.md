# WP-1.2.3 artefact bundle

Date: 2026-02-09

This bundle captures process evidence for non-publishing release automation.

## Automation implemented

- `scripts/build_release_evidence.sh`
- Documentation: `docs/reference/release_automation.md`

## Process run evidence

- `release_automation_run.log`: console output from
  `scripts/build_release_evidence.sh rc2`.
- `release_bundle_path.txt`: generated release bundle path.
- `release_bundle_manifest.txt`: generated bundle file manifest.

## Generated release bundle

- `artefacts/release_1.0.0-rc2/` contains end-to-end evidence:
  - restore/lint/tests/targets/quarto/build/check logs,
  - built tarball,
  - `00check.log`,
  - toy scenario outputs and interpretation note,
  - bundle README.

## Non-publishing boundary

- No tags were created.
- No GitHub/CRAN publication actions were executed.
