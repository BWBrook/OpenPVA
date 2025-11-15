# _targets.R

# Declarative pipeline for the basic OpenPVA demos.
# - pop0/pop1/pop2/breeders: minimal lifecycle sanity checks.
# - sim_basic: single-run example.
# - sim_basic_reps & sim_basic_dense_harvest: replicated scenarios.
# - *_summary / *_trajectory / *_plot: post-processing and reporting.

devtools::load_all(quiet = TRUE)

targets::tar_option_set(
  packages = character()
)

list(
  # Core lifecycle sanity checks
  targets::tar_target(pop0, initialize_population(50)),
  targets::tar_target(pop1, age_individuals(pop0)),
  targets::tar_target(pop2, apply_survival(pop1, default_survival_fun)),
  targets::tar_target(breeders, determine_breeding(pop2, default_breeding_fun)),

  # Single-run demonstration
  targets::tar_target(
    sim_basic,
    run_basic_simulation(
      initial_population = initialize_population(50),
      n_years = 20
    )
  ),

  # Replicated simulations (baseline and density + harvest scenarios)
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
  ),

  # Summaries and reporting
  targets::tar_target(
    sim_basic_reps_extinction_summary,
    summarise_extinction(sim_basic_reps)
  ),
  targets::tar_target(
    sim_basic_dense_harvest_extinction_summary,
    summarise_extinction(sim_basic_dense_harvest)
  ),
  targets::tar_target(
    sim_basic_dense_harvest_trajectory,
    compute_mean_trajectory(sim_basic_dense_harvest)
  ),
  targets::tar_target(
    sim_basic_dense_harvest_trajectory_plot,
    {
      plot_obj <- plot_mean_trajectory(sim_basic_dense_harvest_trajectory)
      if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
      out_path <- file.path("outputs", "sim_basic_dense_harvest_trajectory.png")
      ggplot2::ggsave(
        filename = out_path,
        plot = plot_obj,
        width = 7,
        height = 5,
        dpi = 300
      )
      out_path
    },
    format = "file"
  )
)
