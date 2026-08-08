# Evidence review: scientific uses of GAPPS

## Review question

Which studies actually configured or ran the Generalized Animal Population
Projection System, for what taxa and decisions, which processes mattered, and
what limitations were reported?

This is a targeted historical evidence review, not a systematic review with a
complete bibliographic database.

## Search and provenance

Searches were run on 2026-08-08 using the exact expanded name, `GAPPS`, `GAPPS
II`, author names, and combinations with grizzly/brown bear, harvest, genetics,
inbreeding, immigration, contraception, feral horse, woodhen, whooping crane,
Soay sheep, and PVA. Sources included publisher/DOI records, university theses,
USGS, NPS and Alaska government repositories, accessible full-text papers and
backward/forward citation chains.

Inclusion required evidence that GAPPS was configured or run. Software reviews,
proposals, bibliography entries and later papers that merely cited GAPPS were
classified separately. Searches stopped when additional hits were duplicate
citations, reviews, or acronym collisions (notably gastric cancer and Android
Google Apps).

The BibTeX keys below refer to `../../references/gapps.bib`.

## Claim-source ledger

| Claim | Best evidence | Strength and caveat |
|---|---|---|
| Origin in grizzly population/harvest modelling | Harris thesis [@harris1984]; 1986 manual citation [@harris_metzgar_bevins1986] | Strong origin evidence; manual full text inaccessible |
| Harris was not sole documented author | 1986 manual citation; Alaska report names Bevins as programmer [@miller_miller1990] | Strong; respective intellectual/programming contributions are not fully documented |
| Explicit ordered script and DBF tables | Woodhen manuscript Appendix II [@brook1995woodhen] | Strong accessible script evidence; one application, not the manual |
| Individual demographic and genetic integration | Harris & Allendorf [@harris_allendorf1989] | Strong substantive use |
| Explicit management interventions | Assateague [@kirkpatrick1995]; deer contraception [@seagle_close1996]; GYE survival scenarios [@harris_etal2006] | Strong; Assateague later moved to VORTEX modelling |
| Density/stochastic implementation changed results | Mills et al. [@mills_etal1996]; Brook et al. [@brook_etal1999; @brook_burgman_frankham2000] | Strong comparative evidence |
| Native metapopulation support | No substantive evidence found | Do not claim; modified Assateague version added space |

## Precursor and origin evidence

Harris's 1984 thesis followed individual grizzlies with age, sex, dependency and
reproductive histories to test whether harvest observations could diagnose
population decline [@harris1984]. It is strong evidence for the scientific
origin of GAPPS, but is not counted here as a verified application of a named,
released GAPPS version.

## Verified substantive uses

| Taxon/system | Decision or scientific question | Configuration and processes | Reported output or limitation | Source |
|---|---|---|---|---|
| Grizzly bear | Could harvest age/sex structure diagnose decline? | Persistent individuals; age, sex, dependency and reproductive history; annual Bernoulli events; harvest observation samples | Small realistic harvest samples had weak power to distinguish decline | [@harris_metzgar1987] |
| Grizzly bear genetics | How did demography and immigration affect effective size and genetic variation? | Individual pedigrees, reproductive success, heterozygosity and immigration scenarios | Male reproductive skew materially reduced effective size; no generic inbreeding default follows | [@harris_allendorf1989; @allendorf_etal1991] |
| Assateague feral horse | Could persistent PZP contraception control population growth? | Modified GAPPS model; individual reproductive histories, targeted treatment, spatial-resource/social-band attributes | Demonstrated individual-targeted management; spatial capability was a modification, not evidence of base metapopulation support | [@kirkpatrick1995] |
| White-tailed deer | What contraception coverage and duration would reduce a small suburban population? | GAPPS II 1.2; age/sex rates, carrying-capacity feedback, vehicle mortality via hunting, treatment efficacy and immigration | At least 50% treatment and a 5–10-year horizon were reported; only ten replicates per scenario limited Monte Carlo resolution | [@seagle_close1996] |
| Lord Howe woodhen | Could package projections reproduce a monitored recovery? | Explicit GAPPS script; DBF rates, shared variables, ordered breeding/mating/litter/age/birth/survival/weaning, summaries and purging | Manuscript Appendix II provides the script [@brook1995woodhen]; the journal article reports the retrospective/prospective results [@brook_etal1997] |
| Whooping crane | How sensitive were projections to package semantics? | Matched demographic inputs across GAPPS plus five other package implementations (six total) | Breeding structure and version-specific semantics changed outcomes | [@brook_etal1999] |
| Six empirical/hypothetical systems | Why did PVA packages disagree? | Standardized wolf, deer, crane, lizard, woodhen and hypothetical models | Two-sex demographic stochasticity and sex-ratio handling explained material divergence | [@brook_burgman_frankham2000] |
| Twenty-one long-term datasets | Were PVA projections retrospectively calibrated? | GAPPS and other packages fitted/projected monitored populations; GAPPS completed 20 datasets | Broad calibration with slight pessimism; brook-trout scale exhausted GAPPS memory | [@brook_etal2000nature] |
| Greater Yellowstone grizzly | How would alternative independent-female survival affect short-term trajectory? | Sex, age and family status; Bernoulli breeding/death/independence; annual rate variation; alternative survival regimes | Decision-relevant trajectory distributions; no persistent frailty and no endogenous landscape | [@harris_etal2006] |

### Grizzly-bear population monitoring and harvest

Harris and Metzgar simulated individual grizzlies to assess whether harvest
age/sex structure could detect decline [@harris_metzgar1987]. The observation
process was central: realistic small
harvest samples had poor power to distinguish equilibrating from declining
populations. This is evidence for separating the latent population process from
harvest observations in a modern model.

Alaska Department of Fish and Game acquired GAPPS and commissioned a dBASE-III-
compatible version from Harris and programmer C. D. Bevins. The final report
describes brown/black-bear harvest applications and the difficulty of
interpreting stochastic outputs when identical inputs yield different
trajectories [@miller_miller1990]. This is a documented management use, not a
claim that the model supplied an unambiguous decision.

### Grizzly genetics and connectivity

Harris and Allendorf traced heterozygosity loss through simulated pedigrees and
compared demographic estimators of effective population size
[@harris_allendorf1989]. Variation in male lifetime reproductive success was a
major determinant of effective size. Allendorf, Harris and Metzgar subsequently
examined immigration and loss of variation in an isolated grizzly population
[@allendorf_etal1991]. These studies substantiate integrated genetics and
demography; they do not justify a generic inbreeding default.

### Feral-horse fertility control

The National Park Service Assateague programme constructed a modified GAPPS model
of individual horse life histories to ask whether PZP contraception could alter
population dynamics [@kirkpatrick1995]. A modified version represented spatial
resources and social bands. This demonstrates targeted, persistent individual
management. Later Assateague PHVA projections used VORTEX and must not be
attributed to GAPPS.

### White-tailed deer contraception

Seagle and Close used GAPPS II 1.2 for a small suburban deer population at NASA
Goddard [@seagle_close1996]. They modelled age/sex rates, capacity feedback,
vehicle mortality through the hunting module, contraception efficacy and
immigration over 30 years. At least 50% treatment was needed for decline, a
5–10-year horizon was required even at high treatment, and immigration interacted
nonlinearly with treatment. Only ten replicates per scenario were used, so the
reported Monte Carlo resolution is limited.

### Comparative PVA and model falsification

Mills et al. used GAPPS II 1.3 with three other packages for standardized
increasing and decreasing grizzly populations [@mills_etal1996]. Small input
differences and especially density implementations caused large divergence.

Brook and colleagues used GAPPS in:

- retrospective/prospective Lord Howe woodhen comparisons, with the exact
  Appendix II script in the January 1995 manuscript [@brook1995woodhen] and
  journal results in Brook et al. [@brook_etal1997];
- a detailed whooping-crane comparison of GAPPS plus five other package
  implementations (six total), where breeding structure and package-version
  semantics changed outcomes [@brook_etal1999];
- standardized wolf, deer, crane, lizard, woodhen and hypothetical examples,
  exposing two-sex demographic stochasticity [@brook_burgman_frankham2000];
- retrospective validation of 21 long-term population datasets
  [@brook_etal2000nature]. GAPPS ran 20; brook trout was omitted because large
  population sizes exhausted the program's memory.

These are substantive software uses and strong behavioural evidence. They are
not evidence that GAPPS directly guided management for every taxon. Soay sheep
is verified as one retrospective dataset, not as a standalone GAPPS management
study.

### Greater Yellowstone grizzly projections

Harris et al. used GAPPS with 1983–2002 demographic data for short-term
projections under alternative survival rates for independent females
[@harris_etal2006]. Individuals were classified by sex, age and family status;
annual breeding, death and independence were Bernoulli events, with annual
variation in rates. The work informed assessment of human-caused mortality but
explicitly lacked data for persistent individual heterogeneity and represented
spatial variation through alternative survival regimes rather than an endogenous
landscape.

## Mentions, proposals and unresolved leads

- An early Assateague proceedings paper proposed a modified spatial GAPPS model;
  the later NPS monograph verifies that a model was built.
- Repeated claims of other large-mammal applications cite Dixon et al. (1991)
  and Dobson et al. (1992), but those primary applications were not reliably
  resolved.
- The 1986 and 1993 manuals were not recovered. Exact genetics, immigration,
  harvest and reseeding syntax remains unverified.

## Synthesis for OpenPVA

Demonstrated users needed explicit lifecycle order, persistent individuals,
two-sex reproduction, density and environmental responses, individual-targeted
management, immigration, genetics, replicate trajectories, and validation
against observations. They were limited by package-specific semantics, weak
spatial structure, memory, opaque stochastic interpretation, and demanding
parameter evidence.

The modern promise should therefore be transparent process composition with
strong execution and validation contracts—not a promise that a large menu of
processes removes structural uncertainty.

## Highest-value remaining evidence task

Recover and inspect either the 1986 Version 3.0 or 1993 GAPPS II manual. Further
general web search is otherwise at citation saturation.
