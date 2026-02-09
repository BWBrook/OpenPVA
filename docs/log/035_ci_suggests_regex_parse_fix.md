# Log 035 — CI `Suggests` regex parse fix (gh-fix-ci follow-up)

## Date
- 2026-02-09

## Trigger
- GitHub Actions `ci-fast` run on commit `4268623`:
  - `https://github.com/BWBrook/OpenPVA/actions/runs/21813514649`

## Failure summary
- Failing step: `Ensure suggested packages`.
- Error class: R parse-time string escape failure.
- Key snippet:
  - `'\s' is an unrecognized escape in character string`

## Root-cause analysis
- The regex used in workflow inline R (`'\\s*\\(.*\\)$'`) is not valid as
  written under current R string parsing rules when passed through `Rscript -e`
  in this shell/YAML context.
- This caused parse failure before dependency-install logic could run.

## Implemented fix
- Updated workflows:
  - `.github/workflows/ci-fast.yaml`
  - `.github/workflows/ci-heavy-validation.yaml`
- Replaced the fragile escaped regex with a parse-safe equivalent:
  - from: `'\\s*\\(.*\\)$'`
  - to: `'[[:space:]]*[(].*[)]$'`
- Updated local CI documentation command examples in
  `docs/reference/ci_profiles.md` to match.

## Verification done
- Reproduced failing parse locally with `Rscript -e`.
- Verified replacement regex works locally with representative input.
- Validated workflow YAML syntax after edits.

## Follow-up
1. Push and monitor next `ci-fast` run for full pipeline status.
2. If green, close CI incident chain and move back to roadmap WPs.
