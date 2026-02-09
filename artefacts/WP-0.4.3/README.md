# WP-0.4.3 artefact bundle

Date: 2026-02-08

This bundle captures evidence for deterministic RNG support (`seed`) in
replicate/scenario pathways.

## Evidence contents

- `determinism_proof.txt`
  - Two seeded replicate runs produce identical outputs (`seeded_identical: TRUE`)
  - Two unseeded replicate runs produce non-identical outputs (`unseeded_identical: FALSE`)
  - Includes MD5 hashes for serialized outputs.
- `seeded_summary_a.rds`, `seeded_summary_b.rds`
- `unseeded_summary_a.rds`, `unseeded_summary_b.rds`
- `tests.log`
  - `devtools::test()` result: `PASS 362`, `FAIL 0`, `WARN 0`, `SKIP 0`.
- `lint.log`
  - `lintr::lint_package()` result: no lints found.
- `00check.log`
  - Tarball `R CMD check --no-manual --as-cran` complete; `0` errors, `0` warnings, `3` notes.
- `quarto_render.log`
  - `quarto render quarto` succeeded.
- `yaml_seeded_demo_summary.csv`, `yaml_seeded_demo_extinction.csv`
  - Seeded packaged YAML scenario execution output snapshot.

## Sanity interpretation

- Seeded replicated outputs are deterministic in-session.
- Unseeded runs remain stochastic.
- No output-schema drift observed while adding seeding support.
