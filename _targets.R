# _targets.R

devtools::load_all(quiet = TRUE)

targets::tar_option_set(
  packages = character()
)

list(
  targets::tar_target(pop0, initialize_population(50)),
  targets::tar_target(pop1, age_individuals(pop0)),
  targets::tar_target(pop2, apply_survival(pop1, default_survival_fun)),
  targets::tar_target(breeders, determine_breeding(pop2, default_breeding_fun)),
  targets::tar_target(
    sim_basic,
    run_basic_simulation(
      initial_population = initialize_population(50),
      n_years = 20
    )
  ),
  targets::tar_target(
    sim_basic_reps,
    run_basic_simulation_replicates(
      n_runs = 100,
      n_years = 50,
      init_fun = function() initialize_population(50)
    )
  ),
  targets::tar_target(
    sim_basic_dense_harvest,
    run_basic_simulation_replicates(
      n_runs = 50,
      n_years = 50,
      init_fun = function() initialize_population(100),
      K = 80,
      harvest_quota = 5
    )
  )
)
