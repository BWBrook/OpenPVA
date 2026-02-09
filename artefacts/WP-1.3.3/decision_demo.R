devtools::load_all('.')

set.seed(20260209)
make_scenario <- function(name, quota, K) {
  scenario_spec(
    name = name,
    n_runs = 6,
    n_years = 12,
    init_fun = function() initialize_population(40),
    survival_fun = default_survival_fun,
    breeding_prob_fun = function(ind) if (ind$sex == "F" && ind$age >= 2) 0.65 else 0,
    fecundity_lambda_fun = function(ind) if (ind$sex == "F" && ind$age >= 2) 1.2 else 0,
    harvest_quota = quota,
    K = K,
    seed = 20260209L
  )
}

scenarios <- list(
  status_quo = make_scenario("status_quo", quota = 1L, K = 120),
  intensive_harvest = make_scenario("intensive_harvest", quota = 3L, K = 120),
  low_capacity = make_scenario("low_capacity", quota = 1L, K = 70)
)

cmp <- compare_scenarios(scenarios, extinction_threshold = 10, final_n_floor = 20)
write.csv(cmp, "artefacts/WP-1.3.3/scenario_decision_comparison.csv", row.names = FALSE)

out <- run_scenario(scenarios$status_quo)
final <- summarise_final_abundance(out$sim_output, floor = 20)
write.csv(final$per_run, "artefacts/WP-1.3.3/final_abundance_per_run.csv", row.names = FALSE)
write.csv(final$overall, "artefacts/WP-1.3.3/final_abundance_overall.csv", row.names = FALSE)

print(cmp)
