# Lord Howe Island woodhen model project

This is a standalone ordinary-R model project that consumes the installed
OpenPVA package through exported functions only. It translates the 1980 Lord
Howe Island woodhen recovery comparison from the teaching-focused `rPVA`
repository into explicit individual state and process composition.

It is a historically grounded illustrative reconstruction, not a freshly
calibrated or current management assessment.

## Question and scenarios

Starting from the same 1980 population and projecting for 40 annual intervals,
compare:

1. no intervention and breeding habitat restricted to about 10 pairs;
2. pig control and habitat available for about 70 pairs;
3. pig control plus capture for captive breeding and three years of releases.

The primary endpoints are extinction at the horizon, ever falling below two
potential breeding pairs, final abundance, retained parentage and exact
intervention/accounting receipts.

## Run

Install OpenPVA, copy this directory anywhere, then run from a clean R session:

```sh
Rscript run.R
```

The default is 20 replicates per scenario. This is sufficient to prove the
workflow while its reported Monte Carlo standard errors make the limited
precision explicit. The script uses two deterministic fork workers on Unix and
one worker on Windows. An output directory, replicate count and worker count
can be supplied explicitly:

```sh
Rscript run.R /tmp/openpva-woodhen 100 4
```

The directory contains `result.rds` with replicate evidence and CSV views of
the manifest, summaries, accounting, events, censuses and parentage receipts.

## Biological programme

The declared annual order is:

```text
annual conditions -> survival -> age -> territory allocation -> reproduction -> management -> census
```

The project defines three local processes through `OpenPVA::pva_process()`:

- annual environmental, cyclone and breeding-capacity conditions;
- annual assignment of at most the available territory capacity to explicit
  female-male pairs, while retaining surplus mature birds as floaters;
- scheduled capture of living female-male pairs for captive breeding.

All other execution uses current OpenPVA constructors. Captive releases use
`introduction_process()`. Only territory holders breed, and non-holders remain
in the population rather than being removed by a hard abundance ceiling.

## Translation decisions

- The rPVA age vector is documented as female-equivalent state. This project
  instantiates the supplied female counts and matching males explicitly.
- The rPVA fecundity vector is executable female-equivalent recruitment even
  though some prose calls it fledglings. This project doubles those rates to
  total offspring before an explicit 50:50 sex draw, preserving the intended
  female recruitment while repairing the mixed state unit.
- One-to-one mate and territory availability is resolved by stable ID order.
  This is reproducible occupancy bookkeeping, not a model of competition,
  territory turnover or persistent pair bonds.
- The executable rPVA captive schedule is interpreted as 13 pairs released in
  each of three years, approximately 78 birds in total.
- Initial and released birds are pedigree base founders relative to the
  recorded horizon. The simulation retains exact parent IDs, then reconstructs
  and validates exact pedigree coefficients in a short matched audit. Parent
  IDs remain available for every full run, while long-horizon coefficient
  reconstruction is deliberately omitted because pedigree does not drive this
  model's demography. No aggregate `F`, lethal-equivalent, purging or
  inbreeding-fitness response is imposed during population dynamics.
- Environmental and catastrophe settings are inherited teaching assumptions.
  They are not Woodhen field estimates.
- Numerical parity with rPVA is neither expected nor asserted because its own
  scientific audit records mixed abundance/sex semantics and a hard population
  truncation.

## Evidence

The local source is `rPVA` commit `8727caa`, especially:

- `inst/extdata/woodhen/_woodhen_base.yaml`;
- `01_no_mgmt.yaml`, `02_pig_control.yaml`, `03_captive_pig.yaml`;
- `docs/teaching/woodhen/practical-2-ecological-assumptions-audit.md`.

Historical anchors are:

- Brook, Lim, Harden and Frankham (1997), *Does population viability analysis
  software predict the behaviour of real populations?*,
  <https://doi.org/10.1016/S0006-3207(97)00026-8>.
- Miller and Mullette (1985), *Rehabilitation of an endangered Australian
  bird: The Lord Howe Island woodhen*,
  <https://doi.org/10.1016/0006-3207(85)90057-6>.

The 1997 retrospective compared GAPPS, INMAT, RAMAS and VORTEX formulations.
This connection makes the Woodhen a direct test of OpenPVA's intended role as a
modern open-R descendant of the GAPPS construction philosophy.
