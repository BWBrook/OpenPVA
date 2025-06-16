# _targets.R

import::from("targets", tar_option_set, tar_target)
import::from("here", here)
import::here(initialize_population, age_individuals, apply_survival, determine_breeding,
             default_survival_fun, default_breeding_fun, .from = "R/init_population.R")

tar_option_set(packages = c("dplyr", "tibble", "purrr", "here"))

list(
  tar_target(pop0, initialize_population(50)),
  tar_target(pop1, age_individuals(pop0)),
  tar_target(pop2, apply_survival(pop1, default_survival_fun)),
  tar_target(breeders, determine_breeding(pop2, default_breeding_fun))
)
