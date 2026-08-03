# _targets.R
#
# Declarative pipeline for the basic OpenPVA demos.
# Functions are sourced directly from `R/` so the pipeline stays runnable from a
# checkout without relying on `devtools::load_all()`.

targets::tar_source()

targets::tar_option_set(packages = character())

demo_reps_n_runs <- 20L
demo_reps_n_years <- 30L
demo_dense_harvest_n_runs <- 15L
demo_dense_harvest_n_years <- 30L
demo_spatial_n_runs <- 5L
demo_spatial_n_years <- 20L

list(
  # Single-run demonstration
  targets::tar_target(
    sim_basic,
    {
      set.seed(20260301L)
      run_basic_simulation(
        initial_population = initialize_population(50),
        n_years = 20
      )
    }
  ),

  # Replicated simulations (baseline and density + harvest scenarios)
  targets::tar_target(
    sim_basic_reps,
    run_basic_simulation_replicates(
      n_runs = demo_reps_n_runs,
      n_years = demo_reps_n_years,
      init_fun = function() initialize_population(50),
      seed = 20260302L
    )
  ),
  targets::tar_target(
    sim_basic_dense_harvest,
    run_basic_simulation_replicates(
      n_runs = demo_dense_harvest_n_runs,
      n_years = demo_dense_harvest_n_years,
      init_fun = function() initialize_population(100),
      density_spec = density_spec(
        survival_fun = make_ceiling_density_fun(K = 80)
      ),
      harvest_quota = 5,
      seed = 20260303L
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
  ),

  # Spatial example: two-patch scenario with dispersal
  targets::tar_target(
    spatial_scenario_two_patch,
    {
      sc <- make_two_patch_spatial_scenario(
        name = "two_patch_targets",
        n_runs = demo_spatial_n_runs,
        n_years = demo_spatial_n_years,
        initial_n = c(50L, 10L),
        K_patches = c(80, 40),
        dispersal_matrix = matrix(c(0.9, 0.1,
                                    0.2, 0.8),
                                  nrow = 2, byrow = TRUE)
      )
      sc$seed <- 20260304L
      sc
    }
  ),
  targets::tar_target(
    spatial_sim_two_patch,
    run_scenario(spatial_scenario_two_patch)
  ),
  targets::tar_target(
    spatial_two_patch_patch_summary,
    summarise_patch_occupancy_final(
      sim_output = spatial_sim_two_patch$sim_output,
      n_patches = 2
    )
  )
)
