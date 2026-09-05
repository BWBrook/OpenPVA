# Goal 011 log

## 2026-08-16 - authority and source reconciliation

- Barry accepted and authorised publication of Goal 010, approved Goal 011 as
  an external ordinary-R modeller vertical slice, and selected the Lord Howe
  Island woodhen case maintained in `rPVA`.
- Goal 010 was published at `9d48609`; Goal 011 began from clean
  `main...origin/main` at that commit.
- The clean rPVA checkout was fetched and already matched `origin/main` at
  `8727caa`; it has no repo-local `AGENTS.md`.
- The 1980 no-intervention, pig-control and combined captive/pig scenarios are
  the smallest directly comparable management set: common starting state,
  common 40-year horizon and a separation of habitat release from the captive
  programme.
- Source review confirmed that the case is unusually aligned with OpenPVA's
  heritage: Brook et al. (1997) used the woodhen to compare five PVA packages,
  including GAPPS, against observed population behaviour.
- The rPVA scientific audit explicitly records mixed female-equivalent and
  whole-bird semantics, proxy pairs, tuned teaching parameters, a hard ceiling
  and illustrative aggregate genetics. Goal 011 will preserve the conservation
  question and supplied evidence while repairing those bookkeeping ambiguities.
- The captive schedule is interpreted as 13 pairs released in each of three
  years, or 78 birds total. This matches the executable rPVA schedule and the
  approximate historical programme scale; it is recorded as a reconstruction,
  not a newly inferred release history.
- No rPVA files were edited and no rPVA simulations or checks were run.

## 2026-08-16 - implementation and validation

- Added `inst/examples/woodhen/` as a copyable ordinary-R model project. Its
  runtime uses only exported functions from an installed OpenPVA package; the
  rPVA repository is provenance, not a runtime input.
- Implemented three common-start 40-year scenarios, explicit female and male
  individuals, one-to-one mate availability, annual environmental/cyclone
  draws, scheduled capture and exact captive-release receipts.
- A first smoke run exposed the legacy ceiling as a poor biological contract.
  The focused repair added explicit annual territory holders: at most the
  annual pair capacity breeds, while surplus mature birds remain observable
  floaters rather than being deleted.
- Retained mother and father IDs for every record in every full run. Exact
  pedigree reconstruction is validated on a short matched run; long-horizon
  coefficient reconstruction is intentionally omitted because pedigree does
  not yet affect fitness and added substantial cost without decision value.
- An eight-replicate-per-scenario installed-package run from `/tmp`, with four
  fork workers, completed all scenarios and wrote a reloadable evidence bundle.
  All 24 accounting rows reconciled, pair-capacity excess was zero, the bundle
  retained 112,975 known-parentage records and `result.rds` was 837,678 bytes.
- That small ensemble estimated horizon extinction as 0.625, 0 and 0 for no
  intervention, pig control and combined management respectively. These are
  workflow evidence with large reported Monte Carlo errors, not calibrated
  management estimates or a ranking of the two intervention scenarios.
- Focused Woodhen tests: 22 passed. Full suite: 505 passed with no failures,
  warnings or skips. Lint found no issues; `renv::status()` was consistent;
  `git diff --check` passed.
- A clean R 4.6.1 source build and `R CMD check --no-manual
  --no-build-vignettes` completed with status `OK` outside the repository.
- One focused review repaired the source manifest from a machine-local path to
  the portable rPVA repository URL. No new package export or dependency was
  needed.
- Goal 011 remained uncommitted and unpublished pending Barry's acceptance.

## 2026-09-05 - acceptance

- Barry accepted the validated Goal 011 tranche and authorised commit and push.
- No scientific or implementation changes occurred after the recorded
  validation; the live diff was re-inspected before publication.
