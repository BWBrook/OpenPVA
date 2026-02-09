# WP-0.4.1 artefact bundle

This bundle captures YAML schema v1 contract implementation and migration evidence.

## Implemented outcomes

- Added schema-version handling in `read_scenario_yaml()`:
  - missing version treated as legacy schema 0 and migrated to v1
  - `schema_version: 1` accepted
  - unknown/invalid versions rejected with clear errors
- Updated packaged demo YAML files to include `schema_version: 1`.
- Added tests for migration and version validation.

## Verification

- `devtools::test()` -> pass (`308` tests).
- `R CMD check --no-manual --as-cran` -> pass with `0` errors, `0` warnings, `3` notes.
- Migration evidence (`migration_evidence.txt`):
  - legacy YAML returns scenario attribute `yaml_schema_version: 1`
  - v1 YAML returns scenario attribute `yaml_schema_version: 1`

## Evidence files

- `document.log`
- `tests.log`, `tests_summary.txt`
- `migration_evidence.txt`
- `build.log`, `rcmdcheck.log`, `check_summary.txt`
- `OpenPVA.Rcheck/00check.log`
- `session_info.txt`
