# _targets.R

devtools::load_all(quiet = TRUE)

targets::tar_option_set(
  packages = character()
)

list(
  targets::tar_target(pop0, initialize_population(50)),
  targets::tar_target(pop1, age_individuals(pop0)),
  targets::tar_target(pop2, apply_survival(pop1, default_survival_fun)),
  targets::tar_target(breeders, determine_breeding(pop2, default_breeding_fun))
)
