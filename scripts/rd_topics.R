# Documentation source for scripts/build_rd.R. Text is Rd markup.

callback <- r"(\code{(pop, state, context, params)})"

common_arguments <- list(
  name = "Process name used in events, accounting and error messages.",
  requires = r"(Additional state paths (\code{population.<field>} or \code{globals.<name>}) read by the supplied functions; checked before a run starts.)",
  params = r"(Named list of modeller parameters, passed unchanged to every supplied function as \code{params}.)",
  eligible = paste0(
    "Optional function of ", callback,
    r"( returning one logical value per living individual. \code{NULL} means every living individual.)"
  ),
  state = r"(A \code{pva_state}.)",
  field = "Name of the population field the process reads or writes.",
  cause = r"(Label stored with the accounting event, for example \code{"natural"} or \code{"harvest"}.)",
  result = r"(A \code{pva_run} from \code{\link{run_scenario}}.)",
  validation = r"(\code{"strict"} checks every process transition (declared writes, types, engine-owned fields and cohort accounting). \code{"fast"} skips those checks and gives bit-identical output for a valid model.)",
  backend = r"(\code{"fork"}, \code{"psock"}, or \code{"auto"} (fork on Unix, PSOCK on Windows).)",
  cluster = r"(Optional cluster from \code{parallel::makePSOCKcluster()}. Use this to reuse workers or to initialise dependencies looked up dynamically.)",
  workers = "Number of local worker processes.",
  metric = "Name of the census metric to summarise.",
  threshold = r"(Quasi-extinction threshold: a run is below threshold when \code{metric < threshold}.)",
  process_name = r"(Select the interval census by name when more than one is recorded.)",
  occurrence = "Select the scheduled occurrence (1, 2, ...) when the same census name appears several times.",
  include_initial = "Whether year zero counts. The default includes it when the scenario supplies an initial census.",
  n = "Number of living individuals (or any abundance the feedback acts on).",
  capacity = "Carrying capacity, or a function of (state, context, params) returning it."
)

topics <- list(
  pva_state = list(
    title = "Population state",
    functions = c("pva_population", "pva_state", "add_individuals"),
    arguments = list(
      sex = r"(Character vector of \code{"F"} and \code{"M"}, one per individual.)",
      age = "Whole-number ages (length one, or one per individual).",
      `...` = "Additional named fields: one value, or one per individual. For \\code{add_individuals()} they must be exactly the model's non-core fields.",
      mother_id = r"(Mother identifiers, with \code{NA} for an unknown mother.)",
      father_id = r"(Father identifiers, with \code{NA} for an unknown father.)",
      population = r"(A population from \code{pva_population()}, or a data frame or named list with at least \code{sex} and \code{age}.)",
      globals = "Named list of shared dynamic values, such as the year's environmental deviates.",
      pedigree = r"(Whether the engine tracks exact pedigree inbreeding. When \code{TRUE} the population gains the engine-owned field \code{pedigree_F}.)",
      kinship = "Optional matrix of starting coancestries in population order. It takes precedence over recorded initial parentage.",
      max_dense_kinship = "Maximum dense slots per replicate. Above this limit the engine computes exact kinship from a compact ancestry ledger. The default is 2000."
    ),
    description = r"(The population is columnar: a named list of equal-length vectors with one element per \emph{living} individual. \code{pva_population()} builds it, \code{pva_state()} wraps it with shared globals and the identifier allocator, and \code{add_individuals()} is the only way for a process to create individuals.)",
    details = r"(Core fields are \code{id}, \code{sex}, \code{age}, \code{alive}, \code{mother_id}, \code{father_id}, \code{origin} and \code{entry_time}. The engine owns \code{id}, \code{origin} (\code{"initial"}, \code{"birth"} or \code{"introduction"}), \code{entry_time} (the interval of entry, \code{-1} for the initial population) and \code{pedigree_F}; processes cannot write them. A process records mortality by setting \code{alive} to \code{FALSE}. After each process the engine moves those records out of the living table into the optional ledger, so every process starts with living individuals only.

Without a supplied matrix, initial parent IDs must resolve inside the initial population in an acyclic pedigree. Each unknown parent is an unrelated, non-inbred contribution. A newborn's inbreeding coefficient is its parents' kinship. Known parents can be living or can have died earlier in the same interval. Use \code{\link{kinship_matrix}} for living pairs in either storage mode.)",
    value = r"(\code{pva_population()} returns the columnar population. \code{pva_state()} returns a \code{pva_state} with elements \code{population}, \code{globals}, \code{next_id}, \code{kinship} and \code{max_dense_kinship}. \code{add_individuals()} returns the state with the new records appended and \code{next_id} advanced.)",
    examples = r"(population <- pva_population(sex = c("F", "F", "M"), age = c(3, 1, 4), patch_id = 1L)
state <- pva_state(population, globals = list(year_quality = 1), pedigree = TRUE)
state
state <- add_individuals(state, sex = "F", age = 0L, patch_id = 1L,
                         mother_id = 1L, father_id = 3L)
length(state$population$id))"
  ),
  pva_process = list(
    title = "Lifecycle processes and their execution contract",
    functions = c(
      "pva_process", "pva_result", "pva_events", "validate_processes",
      "execute_processes"
    ),
    arguments = list(
      run = r"(Function of \code{(state, context, params)} returning \code{pva_result()}.)",
      writes = r"(State paths the process may change. Writing \code{population.alive} is how a process records deaths or removals.)",
      creates = r"(For a process that adds individuals: the population fields it initialises. Must include \code{sex} and \code{age} and cover every non-core field.)",
      description = "Optional one-line description.",
      events = r"(\code{NULL} or events from \code{pva_events()}.)",
      census = r"(\code{NULL} or a named numeric vector of census metrics.)",
      event_type = r"(Character vector of event types. \code{"death"}, \code{"removal"}, \code{"birth"} and \code{"introduction"} are accounting events whose values must match the state change.)",
      value = "Numeric event values (length one, or one per event). Each accounting count must be a finite non-negative integer.",
      label = "Optional character labels such as a cause or source.",
      origin_patch_id = "Optional origin patch for each event, recorded as character.",
      destination_patch_id = "Optional destination patch for each event, supplied together with its origin.",
      processes = r"(Ordered list of \code{pva_process} objects.)",
      time = "Zero-based interval index supplied in the process context.",
      dt = "Interval duration supplied in the process context."
    ),
    description = r"(A lifecycle is a direct ordered list of ordinary R process objects. Each wraps a function and declares the state fields it requires, writes and creates. The engine calls the processes in order and owns time, identifiers, random-number streams, accounting and provenance.)",
    details = r"(The \code{context} passed to \code{run} is a read-only list with \code{run}, \code{time}, \code{dt}, \code{phase}, \code{n_steps}, \code{process_index}, \code{process_name}, \code{occurrence} and \code{departed_males} (IDs of males lost in earlier processes of this interval).

Under strict validation the engine checks after every process that only declared fields changed, that field types and lengths are intact, that existing records were neither deleted nor reordered, that new records came from \code{add_individuals()}, and that the accounting events equal the state change for each cohort separately: existing individuals that stopped living must equal the reported deaths or removals, and created individuals must equal the reported births or introductions. A process may report one loss type and one entry type per execution, and individuals it creates must be alive when it returns. Compensating errors that leave the net count unchanged are therefore still detected.

The engine records, for every process and interval, losses split into residents, individuals born in that interval and individuals introduced in that interval; see \code{\link{summarise_accounting}}.)",
    value = r"(\code{pva_process()} returns a validated \code{pva_process}; \code{pva_result()} a \code{pva_result}; \code{pva_events()} an event list. \code{validate_processes()} returns the validated list invisibly and, given a state, also checks the field plan. \code{execute_processes()} runs one interval with the caller's random-number stream and returns the new state with \code{events}, \code{census}, \code{accounting} and \code{ledger} data frames.)",
    examples = r"(harvest <- pva_process(
  name = "harvest_oldest",
  run = function(state, context, params) {
    oldest <- which.max(state$population$age)
    state$population$alive[oldest] <- FALSE
    pva_result(state, pva_events("removal", length(oldest), "harvest"))
  },
  requires = "population.age",
  writes = "population.alive"
)
state <- pva_state(pva_population(sex = c("F", "M", "F"), age = c(2, 9, 4)))
out <- execute_processes(state, list(harvest, census_process()))
out$census
out$accounting)"
  ),
  demography_processes = list(
    title = "Ageing, survival, reproduction and census processes",
    functions = c(
      "age_process", "survival_process", "staged_survival_process",
      "reproduction_process", "census_process"
    ),
    arguments = list(
      post_share = "Share of the interval's mortality hazard that falls after the mid-interval event, in [0, 1].",
      stage = r"(Which stage this process applies: \code{"pre"} (before the event) or \code{"post"} (after it).)",
      field = "Name of an unused temporary global shared by the pre and post stages. The post stage removes it. Use distinct names for overlapping pairs of stages.",
      increment = "Whole number of age units added per execution.",
      probability = paste0(
        "Survival probability over the whole interval: one number, or a function of ", callback,
        " returning one probability per living individual."
      ),
      breeding_probability = paste0(
        "Probability that a female breeds: one number, or a function of ", callback,
        " returning one probability per living individual (values for males are ignored)."
      ),
      litter_size = r"(Function of \code{(mothers, pop, state, context, params)} returning one litter size per breeding female, for example \code{\link{litter_poisson}()}.)",
      offspring_sex = r"(Function of \code{(mothers, pop, state, context, params)} returning \code{"F"} or \code{"M"} for each newborn; \code{mothers} holds one row index per newborn. Required: the engine supplies no default sex ratio.)",
      mate = paste0(
        "Optional function of ", callback,
        r"( returning, for each living individual, the row of its mate (the father of its offspring) or \code{NA}. See \code{\link{mate_random}()} and \code{\link{mate_from_field}()}.)"
      ),
      require_mate = "Whether a recorded mate is required. Supplying a mate function enables this by default. With mate = NULL, reproduction is female-dominant.",
      newborn_fields = r"(Optional function of \code{(mothers, fathers, pop, state, context, params)} returning a named list of the non-core fields of the newborns. The arguments hold current living row indices. A sire lost since mating has an \code{NA} row and retains his recorded ID in the offspring.)",
      newborn_field_names = r"(Names of the fields \code{newborn_fields} returns.)",
      inherit = "Non-core fields copied from each mother to her offspring.",
      metrics = paste0(
        "Optional function of ", callback,
        " returning a named numeric vector. The default reports ",
        r"(\code{n_alive}, \code{n_female} and \code{n_male}.)"
      )
    ),
    description = "Reusable demographic processes. All rate functions are vectorised over the living population.",
    details = r"(Every function supplied to one process sees the same pre-process population, so survival of one individual cannot depend on a death drawn earlier in the same process, and breeding cannot see newborns of the same process. Random draws are taken in population (identifier) order.

\code{staged_survival_process()} splits mortality around events such as a release. Write \eqn{q} for \code{post_share}. An original resident passes the pre stage when its uniform draw is below \eqn{a = s_{pre}^{1-q}}. Survivors carry the draw divided by \eqn{a} into the post stage, where the threshold is \eqn{s_{post}^q}. With fixed stage-specific rates the joint survival probability is their product. If rates are unchanged the final decision matches a single draw against the annual rate exactly. Entrants between stages draw afresh. A zero post share spares all individuals at the post stage.

A census is an ordinary non-mutating process: its position in the lifecycle defines whether it observes the population before or after breeding, mortality or management.)",
    value = r"(A \code{pva_process}.)",
    examples = r"(survival <- survival_process(
  probability = function(pop, state, context, params) ifelse(pop$age == 0, 0.5, 0.9)
)
breeding <- reproduction_process(
  breeding_probability = function(pop, state, context, params) as.numeric(pop$age >= 2),
  litter_size = litter_poisson(1.2),
  offspring_sex = offspring_sex_bernoulli(0.5),
  mate = mate_random(function(pop, state, context, params) pop$age >= 2)
)
scenario <- scenario_spec(
  name = "minimal",
  n_runs = 20, n_steps = 10, seed = 1,
  init_fun = function() pva_population(sex = rep(c("F", "M"), 10), age = 3),
  processes = list(survival, age_process(), breeding, census_process())
)
summarise_pva(run_scenario(scenario), threshold = 10))"
  ),
  reproduction_helpers = list(
    title = "Litter-size, offspring-sex and mating helpers",
    functions = c(
      "litter_poisson", "litter_binomial", "litter_categorical",
      "offspring_sex_bernoulli", "mate_random", "mate_from_field"
    ),
    arguments = list(
      mean = paste0(
        "Mean litter size: one number, or a function of ", callback,
        " returning one mean per living individual."
      ),
      size = "Maximum litter size of the bounded binomial distribution.",
      min_size = "Minimum litter size conditional on breeding. The mean must lie between the two bounds.",
      sizes = "Distinct litter sizes of the categorical distribution.",
      probabilities = r"(Probabilities of \code{sizes}; they must sum to one.)",
      female_probability = "Probability that a newborn is female.",
      eligible = paste0(
        "Function of ", callback,
        " returning one logical value per living individual; males flagged TRUE can sire offspring."
      )
    ),
    description = r"(Building blocks for \code{\link{reproduction_process}()}. Litter size can be Poisson, bounded binomial (under-dispersed, with a maximum) or an explicit categorical distribution. \code{mate_random()} gives each female a sire drawn at random from the eligible males, so breeding is limited only when no eligible male is alive. \code{mate_from_field()} reads a field of stable mate IDs, including sires lost since pairing in this interval. A bounded binomial litter adds \code{min_size} to a binomial draw with \code{size - min_size} trials, giving the specified conditional mean.)",
    value = r"(A function suitable for the corresponding argument of \code{\link{reproduction_process}()}.)",
    examples = r"(cubs <- litter_categorical(sizes = 1:3, probabilities = c(0.2, 0.6, 0.2))
pop <- pva_population(sex = c("F", "F", "M"), age = 6)
set.seed(1)
cubs(mothers = 1:2, pop = pop, state = NULL, context = NULL, params = NULL))"
  ),
  management_processes = list(
    title = "Removal, ceiling, introduction and pairing processes",
    functions = c(
      "removal_process", "ceiling_process", "introduction_process",
      "pairing_process"
    ),
    arguments = list(
      count = r"(Number of individuals to remove or introduce in an interval: one number, or a function of \code{(state, context, params)}. A removal takes at most the eligible number and reports any shortfall.)",
      probability = paste0(
        "Per-capita removal probability: one number, or a function of ", callback, "."
      ),
      select = paste0(
        "Function of ", callback,
        " returning the rows (or a logical vector) of the individuals to remove."
      ),
      order = r"(How a \code{count} removal chooses individuals: at random, or lowest identifiers first.)",
      capacity = r"(Capacity: one number, or a function of \code{(state, context, params)}. For \code{ceiling_process()} the maximum number of eligible individuals; for \code{pairing_process()} the maximum number of pairs (territories).)",
      fields = r"(Function of \code{(n, state, context, params)} returning a named list with \code{sex}, \code{age} and every non-core field (and optionally \code{mother_id} and \code{father_id}) of the \code{n} introduced individuals.)",
      creates = r"(Fields that \code{fields} initialises.)",
      source = "Label stored with the introduction event.",
      priority = r"(Which eligible individuals obtain a pair when capacity is limiting: lowest identifiers first (\code{"id"}) or a random draw (\code{"lottery"}).)",
      eligible = paste0(
        "Function of ", callback,
        r"( returning one logical value per living individual. Optional (\code{NULL} means everyone) except for \code{pairing_process()}.)"
      ),
      field = "Integer population field that receives each paired individual's mate identifier."
    ),
    description = r"(\code{removal_process()} takes individuals out of the population as accounted removals (harvest, culling, capture). \code{ceiling_process()} imposes a hard abundance ceiling by random deaths. \code{introduction_process()} adds individuals (supplementation, release, immigration). \code{pairing_process()} forms monogamous pairs each interval up to a capacity, leaving surplus eligible individuals as unpaired floaters; with unlimited capacity it is a pair (mate) limitation, with finite capacity a territory limit.)",
    value = r"(A \code{pva_process}.)",
    examples = r"(state <- pva_state(pva_population(
  sex = rep(c("F", "M"), each = 4), age = 2, mate_id = NA_integer_
))
territories <- pairing_process(
  eligible = function(pop, state, context, params) pop$age >= 1,
  capacity = 2
)
cull <- removal_process(count = 1, cause = "cull")
release <- introduction_process(
  count = 2,
  fields = function(n, state, context, params) {
    list(sex = c("F", "M"), age = 1L, mate_id = NA_integer_)
  },
  creates = c("sex", "age", "mate_id")
)
set.seed(1)
out <- execute_processes(state, list(territories, cull, release, census_process()))
out$events[, c("process_name", "event_type", "value")])"
  ),
  environment_processes = list(
    title = "Environmental variation and catastrophes",
    functions = c(
      "environment_process", "catastrophe_process", "beta_shapes", "shift_logit"
    ),
    arguments = list(
      variables = r"(Named list of functions of \code{(state, context, params)}. Each value is written to the global of the same name, in order, so later functions can read earlier ones.)",
      probability = r"(For \code{catastrophe_process()}: the per-interval probability of a catastrophe, as one number or a function of \code{(state, context, params)}. For \code{shift_logit()}: probabilities to shift.)",
      mortality = paste0(
        "Optional direct mortality applied when a catastrophe occurs: one probability, or a function of ",
        callback, "."
      ),
      global = "Name of the logical global that records whether the catastrophe occurred this interval.",
      mean = "Mean of the beta distribution, in (0, 1).",
      sd = "Standard deviation of the beta distribution.",
      deviation = "Deviation added on the logit scale. Structural probabilities zero and one remain fixed even under infinite shifts."
    ),
    description = r"(\code{environment_process()} draws the interval's shared environmental conditions into globals, where rate functions read them. \code{catastrophe_process()} draws a Bernoulli catastrophe flag and can apply direct mortality. \code{beta_shapes()} converts a mean and standard deviation to beta shape parameters, and \code{shift_logit()} perturbs probabilities on the logit scale.)",
    value = r"(The process constructors return a \code{pva_process}. \code{beta_shapes()} returns a list with \code{shape1} and \code{shape2}; \code{shift_logit()} returns probabilities.)",
    examples = r"(weather <- environment_process(
  variables = list(survival_deviate = function(state, context, params) rnorm(1, 0, 0.3))
)
cyclone <- catastrophe_process(probability = 0.05, mortality = 0.4, name = "cyclone")
survival <- survival_process(
  probability = function(pop, state, context, params) {
    shift_logit(0.85, state$globals$survival_deviate)
  },
  requires = "globals.survival_deviate"
)
state <- pva_state(
  pva_population(sex = rep(c("F", "M"), 25), age = 2),
  globals = list(survival_deviate = 0, cyclone = FALSE)
)
set.seed(3)
execute_processes(state, list(weather, cyclone, survival, census_process()))$census)"
  ),
  density_multipliers = list(
    title = "Density-feedback multipliers",
    functions = c(
      "ceiling_density_multiplier", "beverton_holt_multiplier", "ricker_multiplier"
    ),
    arguments = list(
      capacity = "Abundance at which the feedback reaches its reference strength.",
      growth = "Low-density growth multiplier (at least 1) that the feedback offsets at capacity."
    ),
    description = r"(Multipliers in (0, 1] for a vital rate. \code{ceiling_density_multiplier()} is 1 up to capacity and \code{capacity / n} above it. \code{beverton_holt_multiplier()} is \code{1 / (1 + (growth - 1) n / capacity)} and \code{ricker_multiplier()} is \code{growth^(-n / capacity)}; both equal \code{1 / growth} at capacity, so a rate that supports growth \code{growth} at low density gives zero growth at capacity.)",
    value = "A numeric vector of multipliers.",
    examples = r"(n <- c(0, 50, 100, 200)
beverton_holt_multiplier(n, capacity = 100, growth = 1.5)
ricker_multiplier(n, capacity = 100, growth = 1.5)
ceiling_density_multiplier(n, capacity = 100))"
  ),
  inbreeding = list(
    title = "Pedigree summaries and inbreeding depression",
    functions = c(
      "summarise_pedigree", "kinship_matrix", "inbreeding_multiplier",
      "inbreeding_proxy_process", "sex_ratio_effective_size"
    ),
    arguments = list(
      ids = "Distinct living IDs, in desired matrix order. Defaults to every living individual.",
      generation_time = "Generation time in model intervals. Required for the effective-size approximation.",
      inbreeding = "Inbreeding coefficients in [0, 1].",
      lethal_equivalents = r"(Slope \code{B} of the log-linear cost \code{exp(-B * F)}.)",
      effective_size = paste0(
        "Function of ", callback, " returning the interval's effective population size."
      ),
      migration = paste0(
        "Optional function of ", callback,
        " returning the fraction of the gene pool replaced by unrelated immigrants this interval."
      ),
      global = "Name of the numeric global holding the aggregate inbreeding coefficient.",
      n_females = "Number of breeding females.",
      n_males = "Number of breeding males."
    ),
    description = r"(\code{summarise_pedigree()} reports exact mean and maximum individual inbreeding, mean living kinship (including self-kinship) and gene diversity. \code{kinship_matrix(state, ids)} returns coancestry for the requested living individuals. The retained ancestry grows with the recorded pedigree. Starting animals with nonzero mutual kinship retain a covariance block. A full returned matrix requires quadratic space. \code{inbreeding_multiplier()} scales a particular fitness component by \code{exp(-B * F)} using lethal equivalents for that component and period.)",
    details = r"(The scalar proxy converts per-generation drift to per-interval drift \eqn{d = 1 - (1 - 1/(2N_e))^{1/G}}, with generation time \eqn{G}. The per-generation drift is capped at one, and zero effective size leaves drift at zero. The update is \eqn{(d + (1-d)F)(1-m)^2}, where \eqn{m} is the interval's immigrant gene fraction. Initialise the target global with a coefficient in [0, 1]. An interval with introductions and no migration function raises an error in strict mode and a warning in fast mode. This scalar approximation misses F1 heterosis under supplementation. Use \code{pedigree = TRUE} to distinguish the kinships of individual matings. \code{sex_ratio_effective_size()} gives \eqn{4N_fN_m/(N_f+N_m)}.)",
    value = r"(\code{summarise_pedigree()} returns a one-row data frame; \code{kinship_matrix()} a numeric matrix; \code{inbreeding_multiplier()} and \code{sex_ratio_effective_size()} numeric vectors; \code{inbreeding_proxy_process()} a \code{pva_process}.)",
    examples = r"(inbreeding_multiplier(c(0, 0.125, 0.25), lethal_equivalents = 3)
scenario <- scenario_spec(
  name = "one_pair", n_runs = 1, n_steps = 4, seed = 2,
  init_fun = function() {
    pva_state(pva_population(sex = c("F", "M"), age = 2), pedigree = TRUE)
  },
  processes = list(
    age_process(),
    reproduction_process(
      breeding_probability = function(pop, state, context, params) as.numeric(pop$age >= 2),
      litter_size = litter_categorical(2, 1),
      offspring_sex = offspring_sex_bernoulli(0.5),
      mate = mate_random(function(pop, state, context, params) pop$age >= 2),
      require_mate = TRUE
    ),
    census_process()
  )
)
summarise_pedigree(run_scenario(scenario, keep = "state")$states[[1]]))"
  ),
  scenario = list(
    title = "Define and run replicated scenarios",
    functions = c("scenario_spec", "run_scenario"),
    arguments = list(
      name = "Scenario name.",
      n_runs = "Number of Monte Carlo replicates.",
      n_steps = "Number of lifecycle intervals per replicate.",
      init_fun = r"(Function with no arguments returning a \code{pva_state} (or a population). It is called inside each replicate's random-number stream.)",
      processes = r"(Ordered list of \code{pva_process} objects executed every interval.)",
      seed = r"(Root seed. With \code{NULL} the caller's RNG supplies one root draw, so successive unseeded calls advance.)",
      dt = "Interval duration supplied in the process context.",
      initial_census = "Optional non-mutating census process run once before the first interval.",
      scenario = r"(A scenario from \code{scenario_spec()}.)",
      parallel = "Whether to run replicates on several local workers.",
      keep = r"(Which outputs to retain: any of \code{"census"}, \code{"events"}, \code{"accounting"}, \code{"state"} (final states) and \code{"ledger"} (every individual that ever lived, with its fate). The default retains census, events and accounting. Request final states or ledgers explicitly.)"
    ),
    description = r"(\code{scenario_spec()} bundles an initial state, an ordered lifecycle and a replicate design. \code{run_scenario()} executes it serially or in parallel.)",
    details = r"(Each replicate receives its own L'Ecuyer-CMRG stream, assigned before any work is dispatched, so results are bit-identical for a given seed whether replicates run serially, on fork workers or on a PSOCK cluster. After the optional root draw the caller's RNG kind and seed are restored, including on error.

Managed socket workers start with \code{--vanilla}. Both runners propagate the parent library paths and export statically referenced callback helpers and data. A supplied cluster can initialise resources resolved dynamically by the model.)",
    value = r"(\code{scenario_spec()} returns a \code{pva_scenario}. \code{run_scenario()} returns a \code{pva_run}: a list with the scenario, data frames \code{census}, \code{events} and \code{accounting}, lists \code{states} and \code{ledgers}, and \code{provenance} (root seed, streams, validation mode, process plan and versions).)",
    examples = r"(scenario <- scenario_spec(
  name = "decline",
  n_runs = 50, n_steps = 15, seed = 42,
  init_fun = function() pva_population(sex = rep(c("F", "M"), 6), age = 1),
  processes = list(survival_process(0.8), age_process(), census_process())
)
run <- run_scenario(scenario, keep = c("census", "accounting"))
summarise_pva(run, threshold = 2)
all(summarise_accounting(run)$reconciled))"
  ),
  summaries = list(
    title = "Viability, trajectory and accounting summaries",
    functions = c("summarise_pva", "summarise_trajectory", "summarise_accounting"),
    arguments = list(
      result = r"(A \code{pva_run} from \code{\link{run_scenario}} (or its census data frame). \code{summarise_accounting()} also accepts the result of \code{\link{execute_processes}} or a bare accounting data frame.)"
    ),
    description = r"(\code{summarise_pva()} reports the probability of being below the threshold at the horizon, the probability of ever falling below it (first crossing), time to threshold and final abundance, each with a Monte Carlo standard error or interval. \code{summarise_trajectory()} gives the same quantities by year. \code{summarise_accounting()} reconciles every interval by cohort.)",
    details = r"(Proportions carry a binomial Monte Carlo standard error and a 95 percent Wilson interval. The restricted mean time to threshold counts runs that never cross as reaching the horizon. Year \code{t} is the census taken in interval \code{t - 1}; year 0 is the initial census. Both risk functions apply the same year-zero and census selection. Passing the whole run checks every scheduled run and interval, including extinct replicates. A bare census table only identifies runs and times present in that table.

\code{summarise_accounting()} checks \code{n_start + births + introductions - deaths - removals = n_end} for each run and interval and reports losses separately for residents, individuals born in the interval and individuals introduced in the interval.)",
    value = r"(\code{summarise_pva()} returns a one-row data frame, \code{summarise_trajectory()} one row per year, and \code{summarise_accounting()} one row per run and interval with a logical \code{reconciled}.)"
  ),
  run_pva_ensemble = list(
    title = "Run a designed ensemble of scenarios",
    functions = "run_pva_ensemble",
    arguments = list(
      design = "Data frame with one row per ensemble member, for example the cross of structural variants, parameter draws and management options.",
      build = r"(Function of one design row (a named list) returning a list with \code{init_fun}, \code{processes} and \code{n_steps}, and optionally \code{initial_census}, \code{dt} and \code{keep}.)",
      n_runs = "Number of inner Monte Carlo replicates per member.",
      summarise = r"(Function of \code{(result, row)} returning a data frame of summaries for one member. The default is \code{\link{summarise_pva}()}.)",
      seed = "Root seed from which member seeds are derived.",
      seed_by = r"(Optional design columns that define blocks sharing one seed (common random numbers), for example the structural and parametric columns when management options should be compared on paired streams.)",
      cache_dir = "Optional directory for resumable member summaries.",
      cache_key = "Optional revision string for model inputs read from external files or resolved dynamically."
    ),
    description = "Separates the outer design (structure, parameters, management) from the inner Monte Carlo replicates. Each member is built, run and reduced to its summary inside a worker, so memory use does not grow with the size of the design.",
    details = r"(The builder and summary draw on a reproducible member substream. Cache entries record callback code and statically referenced inputs, package and R versions, the row, member seed, replicate count, validation mode and cache key. Member seeds are a deterministic function of \code{seed} and the design order, so the ensemble is reproducible and independent of the number of workers and of the backend.)",
    value = r"(A data frame: the design rows, \code{member}, \code{member_seed} and the summary columns. Provenance is attached as an attribute.)",
    examples = r"(design <- expand.grid(survival = c(0.7, 0.9), harvest = c(0, 2))
build <- function(row) {
  list(
    n_steps = 10,
    init_fun = function() pva_population(sex = rep(c("F", "M"), 10), age = 1),
    processes = list(
      survival_process(row$survival),
      removal_process(count = row$harvest),
      census_process()
    )
  )
}
run_pva_ensemble(design, build, n_runs = 40, seed = 7,
  summarise = function(result, row) summarise_pva(result, threshold = 5)
)[, c("survival", "harvest", "p_ever_below", "p_ever_below_mcse")])"
  ),
  age_sex_rate = list(
    title = "Vital rates from age-by-sex tables",
    functions = c("validate_age_sex_table", "age_sex_rate"),
    arguments = list(
      table = r"(Data frame with \code{age_min}, \code{age_max} (which may be \code{Inf}), \code{sex} and the value column.)",
      value = "Name of the column holding the rate."
    ),
    description = r"(\code{age_sex_rate()} compiles a table into a vectorised rate function for \code{\link{survival_process}()} or \code{\link{reproduction_process}()}. A one-sex table assigns zero to the omitted sex. An uncovered age for a represented sex raises an error.)",
    value = paste0(
      r"(\code{validate_age_sex_table()} returns the table invisibly. \code{age_sex_rate()} returns a function of )",
      callback, "."
    ),
    examples = r"(rates <- data.frame(
  age_min = c(0, 1, 0), age_max = c(0, Inf, Inf),
  sex = c("F", "F", "M"), p_surv = c(0.5, 0.9, 0.8)
)
survival <- age_sex_rate(rates, "p_surv")
survival(pva_population(sex = c("F", "F", "M"), age = c(0, 5, 2)), NULL, NULL, NULL))"
  ),
  spatial = list(
    title = "Movement among discrete patches",
    functions = c("patch_counts", "dispersal_process", "markov_dispersal_process"),
    arguments = list(
      pop = "A columnar population.",
      patches = "Vector of the declared patch identifiers.",
      destination = r"(Function of \code{(rows, pop, state, context, params)} returning one declared patch per eligible individual.)",
      transition = "Square row-stochastic matrix whose row and column names are the patch identifiers.",
      field = "Population field holding each individual's patch."
    ),
    description = r"(\code{dispersal_process()} moves eligible individuals to modeller-chosen patches; \code{markov_dispersal_process()} draws each destination from a transition matrix. The \code{dispersal} event counts movers. Each \code{patch_transition} row reports one realised origin, destination and count, including eligible individuals who stayed. \code{patch_counts()} tabulates abundance by patch for patch-specific density feedback.)",
    value = r"(The constructors return a \code{pva_process}; \code{patch_counts()} returns a named integer vector.)",
    examples = r"(transition <- matrix(c(0.9, 0.1, 0.2, 0.8), 2, byrow = TRUE,
                     dimnames = list(c("north", "south"), c("north", "south")))
state <- pva_state(pva_population(sex = rep(c("F", "M"), 10), age = 2, patch_id = "north"))
set.seed(4)
moved <- execute_processes(state, list(markov_dispersal_process(transition)))
patch_counts(moved$state$population, c("north", "south")))"
  )
)
