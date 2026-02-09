# OpenPVA news

## OpenPVA 1.0.0

- Declared the 1.x public API stability contract (`docs/reference/public_api.md`),
  with explicit stable vs experimental exported interfaces.
- Finalized semver/release policy in `docs/decisions.md` (DEC-006).
- Completed reproduction refactor line:
  - baseline reproduction rate channels (`breeding_prob_fun`,
    `fecundity_lambda_fun`),
  - controller-level reproduction EV/cat diagnostics,
  - YAML schema v2 support with schema v1 compatibility.
- Updated user-facing docs and demos (README + Quarto) to align with
  reproduction semantics and YAML v1/v2 behavior.
- No intentional breaking changes relative to the late 0.5.x line;
  compatibility wrappers and schema v1 support are retained for 1.x.

## OpenPVA 0.3.x (development line)

- Established baseline reproducibility and smoke-check workflow evidence under `artefacts/`.
- Hardened package metadata fields (`DESCRIPTION`) for check/release readiness.
- Added initial citation metadata in `inst/CITATION`.
