# WP-2B.2 Validation Summary

Date: 2026-02-09

## Commands executed

- `Rscript -e "devtools::test(filter = 'uncertainty_ensemble|rng_seed|output_schema_contract|management')"`
- `Rscript -e "devtools::test()"`
- `R CMD build --no-build-vignettes .`
- `R CMD check --no-manual OpenPVA_1.0.0.tar.gz`

## Results

- Targeted tests: `PASS 109`, `FAIL 0`, `WARN 0`.
- Full tests: `PASS 633`, `FAIL 0`, `WARN 0`.
- Build: success (`OpenPVA_1.0.0.tar.gz` generated).
- `R CMD check`: success with `1 NOTE`.

## Check note

- `License stub is invalid DCF.`
- This note is pre-existing in this repository's current license metadata and
  was not introduced by WP-2B.2 runtime changes.
