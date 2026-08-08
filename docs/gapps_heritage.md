# GAPPS heritage

This page records what the available evidence establishes about the Generalized
Animal Population Projection System (GAPPS), what can reasonably be inferred,
and what OpenPVA chooses to inherit. Detailed provenance is in
`literature/gapps_evidence_review.md` and `../references/gapps.bib`.

## 1. Observed history

- Richard B. Harris's 1984 University of Montana thesis used individual grizzly
  bears with age, sex, dependency and reproductive histories to study harvest
  signals and population status [@harris1984].
- The 1986 Version 3.0 manual is cited as **Harris, Metzgar and Bevins** and 123
  pages [@harris_metzgar_bevins1986]. The Alaska final report identifies C. D.
  Bevins as programmer and documents a dBASE-III-compatible version
  [@miller_miller1990]. The software origin is therefore early-to-mid-1980s
  grizzly work, not a late-1980s solo development.
- A commercial Applied Biomathematics generation, GAPPS II 1.2/1.3, was in use
  by 1993–1996 [@appliedbiomathematics1993; @seagle_close1996;
  @mills_etal1996].
- The strongest accessible script evidence is Appendix II of Brook's January
  1995 woodhen manuscript [@brook1995woodhen]:
  run/year loops, DBF input, censuses, algebraic shared variables, explicit
  lifecycle commands, summaries and purging. It demonstrates
  commands including `SETUP`, `RUN`, `YEAR`, `READ`, `CENSUS`, `SET`, `BREED`,
  `MATE`, `LITTER`, `AGE`, `BIRTH`, `SURVIVE`, `WEAN`, `SUMMARY`, and `PURGE`.
  The later journal article supplies the published ecological analysis
  [@brook_etal1997], but is not the source cited for the exact script.
- Direct applications modelled bear harvest and genetics, deer and horse
  contraception, grizzly survival/management scenarios, and comparative or
  retrospective PVAs across diverse vertebrates [@harris_allendorf1989;
  @kirkpatrick1995; @seagle_close1996; @brook_etal2000nature;
  @harris_etal2006].

## 2. What the evidence supports

GAPPS was:

- individual-based, with persistent life histories;
- explicitly ordered by annual biological and management events;
- stochastic at the individual-event and annual-environment levels;
- able to express age-, sex-, density- and state-dependent rates through tables
  and shared algebraic variables;
- used to connect demographic and genetic questions, including pedigrees,
  heterozygosity loss, inbreeding and effective population size;
- able to target management actions such as harvest or contraception at
  individuals or classes.

The evidence does **not** establish native metapopulation support. Spatial/map
attributes in the Assateague work came from a modified GAPPS version. Exact
syntax for `ALLELES`, `INBREED`, immigration, harvest and reseeding is not
verified because neither the 1986 nor 1993 manual was recovered. Capability
evidence must not be promoted into invented syntax.

The available sources also do not establish that GAPPS was closed source, a
binary-only product, or specifically DOS-based. Those claims are omitted until
primary documentation is retrieved.

## 3. Lessons from actual use

- **Order and mating semantics matter.** Cross-package comparisons found that
  small differences in monogamy and sex-ratio handling changed extinction risk
  [@brook_etal1999; @brook_burgman_frankham2000].
- **Density labels are not models.** Different implementations of nominally
  equivalent density dependence produced large divergence [@mills_etal1996].
- **Management is individual and time-dependent.** Deer and horse contraception
  depended on which females were treated, treatment efficacy, immigration,
  longevity and the planning horizon [@kirkpatrick1995; @seagle_close1996].
- **Genetics depends on demography.** Male reproductive skew strongly reduced
  effective size in simulated grizzlies [@harris_allendorf1989].
- **Stochastic output needs interpretation.** Alaska managers found ensembles
  less immediately explanatory than a deterministic model when identical inputs
  yielded different trends [@miller_miller1990]; OpenPVA should provide
  distributions and expected-value validation rather than a single stochastic
  trajectory.
- **Validation is possible but bounded.** Retrospective tests across 21
  populations found broadly calibrated, slightly pessimistic projections, while
  also exposing package-specific limits and model failures [@brook_etal2000nature].

## 4. OpenPVA design choices

OpenPVA inherits the following principles, rather than the historical
implementation:

1. the modeller owns the biological program and event order;
2. biological and management processes are separate reusable components;
3. stochasticity, density feedback, genetics and interventions are visible;
4. individual and global state changes are inspectable;
5. the engine owns execution, RNG, time, provenance and event collection;
6. new processes compose without edits to the controller.

OpenPVA deliberately chooses ordinary R functions and validated lists instead
of rebuilding the historical parser or DBF workflow. It adds contracts,
testing, independent expected-value checks, scalable output, spatial composition and
reproducible analysis, while retaining the right to omit processes unsupported
by evidence.

## 5. Claim discipline

Use these labels when discussing heritage:

- **Observation:** directly shown in an accessible primary source.
- **Inference:** synthesis supported by multiple sources but not explicit in a
  recovered manual.
- **OpenPVA choice:** a present design decision, not a historical GAPPS fact.

The one high-value archival task remaining is recovery and inspection of the
1986 or 1993 manual. Until then, this page is intentionally conservative.
