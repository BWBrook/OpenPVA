woodhen_parameters <- function() {
  ages <- 0:6
  age_max <- c(0:5, Inf)
  survival <- c(0.35, 0.65, 0.85, 0.75, 0.75, 0.65, 0.50)
  female_equivalent_fecundity <- c(0, 1.0, 2.0, 2.2, 2.0, 1.5, 0.5)

  female_rates <- data.frame(
    age_min = ages,
    age_max = age_max,
    sex = "F",
    p_surv = survival,
    p_breed = as.numeric(ages >= 1L),
    lambda = 2 * female_equivalent_fecundity
  )
  male_rates <- female_rates
  male_rates$sex <- "M"
  male_rates$p_breed <- 0
  male_rates$lambda <- 0

  list(
    model_id = "lord-howe-woodhen-1980",
    model_version = "woodhen-openpva-v1",
    source_repo = "https://github.com/BWBrook/rPVA",
    source_commit = "8727caa",
    start_year = 1980L,
    n_steps = 40L,
    default_n_runs = 20L,
    quasi_extinction_pairs = 2L,
    offspring_female_probability = 0.5,
    vital_rates = rbind(female_rates, male_rates),
    initial_population = data.frame(
      age = ages,
      females = c(9L, 3L, 2L, 1L, 1L, 1L, 1L),
      males = c(9L, 3L, 2L, 1L, 1L, 1L, 1L)
    ),
    annual_environment = list(
      survival_sd = 0.2,
      fecundity_log_sd = 0.2,
      cyclone_probability = 0.04,
      cyclone_survival_multiplier = 0.50,
      cyclone_fecundity_multiplier = 0.75
    ),
    scenarios = data.frame(
      scenario_id = c(
        "no_intervention",
        "pig_control",
        "pig_control_captive"
      ),
      label = c(
        "No intervention",
        "Pig control",
        "Pig control plus captive breeding"
      ),
      territory_capacity_pairs = c(10, 70, 70),
      territory_capacity_sd = c(1, 7, 7),
      capture = c(FALSE, FALSE, TRUE),
      release = c(FALSE, FALSE, TRUE),
      seed = c(198001L, 198002L, 198003L),
      stringsAsFactors = FALSE
    ),
    capture = list(
      times = c(0L, 1L),
      pairs_per_time = 2L,
      minimum_age = 1L
    ),
    release = list(
      times = c(1L, 2L, 3L),
      pairs_per_time = 13L,
      age = 2L,
      source = "1980s captive-breeding reconstruction"
    )
  )
}

woodhen_validate_parameters <- function(parameters) {
  if (!is.list(parameters)) {
    stop("parameters must be a list", call. = FALSE)
  }
  required <- c(
    "model_id", "model_version", "source_repo", "source_commit",
    "start_year", "n_steps", "default_n_runs", "quasi_extinction_pairs",
    "offspring_female_probability", "vital_rates", "initial_population",
    "annual_environment", "scenarios", "capture", "release"
  )
  missing <- setdiff(required, names(parameters))
  if (length(missing)) {
    stop("missing parameter field(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }

  rates <- parameters$vital_rates
  OpenPVA::validate_survival_table(
    rates[c("age_min", "age_max", "sex", "p_surv")]
  )
  OpenPVA::validate_breeding_prob_table(
    rates[c("age_min", "age_max", "sex", "p_breed")]
  )
  OpenPVA::validate_fecundity_lambda_table(
    rates[c("age_min", "age_max", "sex", "lambda")]
  )

  initial <- parameters$initial_population
  if (!is.data.frame(initial) ||
      !identical(names(initial), c("age", "females", "males")) ||
      any(initial$age != 0:6) ||
      any(initial$females < 0L) || any(initial$males < 0L)) {
    stop("initial_population must provide non-negative female and male counts for ages 0:6", call. = FALSE)
  }
  probability <- parameters$offspring_female_probability
  if (!is.numeric(probability) || length(probability) != 1L ||
      !is.finite(probability) || probability < 0 || probability > 1) {
    stop("offspring_female_probability must lie in [0, 1]", call. = FALSE)
  }
  scenarios <- parameters$scenarios
  scenario_fields <- c(
    "scenario_id", "label", "territory_capacity_pairs",
    "territory_capacity_sd", "capture", "release", "seed"
  )
  if (!is.data.frame(scenarios) || !all(scenario_fields %in% names(scenarios)) ||
      anyDuplicated(scenarios$scenario_id) ||
      any(scenarios$territory_capacity_pairs <= 0) ||
      any(scenarios$territory_capacity_sd < 0)) {
    stop("scenarios contain invalid identities or territory capacities", call. = FALSE)
  }

  invisible(parameters)
}
