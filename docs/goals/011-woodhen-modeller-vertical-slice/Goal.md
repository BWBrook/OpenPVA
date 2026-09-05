# Goal 011 - Woodhen modeller vertical slice

## Objective

Prove that a modeller can use the installed OpenPVA package as a public
execution engine for a source-backed, inspectable and decision-facing PVA that
lives outside the package implementation.

The exemplar is a modern individual-based translation of the 1980 Lord Howe
Island woodhen recovery comparison already maintained in `rPVA`. It is a
historically grounded illustrative reconstruction, not a newly calibrated
management assessment.

## Required outcomes

1. Ship one self-contained ordinary-R model project under
   `inst/examples/woodhen/` that uses exported OpenPVA functions only.
2. Compare three common-start, 40-year scenarios: no intervention, pig control,
   and pig control plus captive breeding and release.
3. Replace the legacy female-equivalent bookkeeping with explicit female and
   male individuals, explicit mate availability, exact additions/removals and
   parentage records. Validate exact pedigree reconstruction in a short matched
   audit without imposing an uncalibrated inbreeding-fitness response on the
   long-horizon ensemble.
4. Express annual environmental/cyclone conditions, territory assignment and
   scheduled capture as project-local ordinary processes. Keep breeding
   capacity as explicit pair occupancy rather than deleting excess adults.
5. Record parameter values, units, evidence class, source repository commit,
   structural translations and inference limits.
6. Retain replicate-level events, censuses, final states and RNG provenance in
   a reloadable RDS bundle, with compact CSV summaries, accounting and a run
   manifest.
7. Report extinction and quasi-extinction probabilities with Monte Carlo
   standard errors, final abundance and intervention receipts.

## Scientific source boundary

- Primary local source: `/Users/bwbrook/git/rPVA` at `8727caa`.
- Core source files: `inst/extdata/woodhen/_woodhen_base.yaml` and scenarios
  `01_no_mgmt.yaml`, `02_pig_control.yaml`, `03_captive_pig.yaml`.
- Interpretation authority:
  `docs/teaching/woodhen/practical-2-ecological-assumptions-audit.md`.
- Historical anchors include Brook et al. (1997),
  <https://doi.org/10.1016/S0006-3207(97)00026-8>, and Miller and Mullette
  (1985), <https://doi.org/10.1016/0006-3207(85)90057-6>.

The rPVA reference ordering is diagnostic context, not a numerical parity
target. The translation must document every deliberate semantic departure.

## Non-goals

- Recalibration, parameter inference or a claim of current decision-grade
  adequacy.
- The 2019 rodent-eradication reconstruction, the 2025-2100 forecast or the
  teaching sensitivity catalogue.
- Porting aggregate `F`, lethal-equivalent or purging mechanics.
- A generic project framework, removal API, environmental API, result-store
  API or reporting API.
- YAML, `targets`, Quarto, Shiny, databases, a CLI framework or new package
  dependencies.
- Exact numerical reproduction of rPVA, GAPPS, VORTEX or historical field
  trajectories.

## Acceptance evidence

- The project runs end to end from a clean R session against an installed
  OpenPVA package, without `pkgload`, `:::`, sourcing `R/`, or another repo.
- All three scenarios share the declared initial state and horizon; only named
  management and capacity settings differ.
- Fixed seeds reproduce the scientific outputs, and scenario RNG relationships
  are stated rather than implied.
- Birth, introduction, death and removal accounting reconciles exactly for
  every run.
- Capture and release receipts match the realised individual events, including
  any stochastic shortfall.
- A simplified independently calculated age-structured expectation agrees with
  a matched stochastic configuration within a predeclared Monte Carlo bound.
- The full package suite, lint, `renv::status()`, residue scans and a fresh
  source-package check pass in proportion to the change.
- One focused scientific and delivery review finds no material defect.

## Publication boundary

Implementation and validation are authorised. Staging, commit, push, tag,
release and publication require Barry's separate acceptance.

Barry accepted Goal 011 and authorised commit and push on 2026-09-05.
