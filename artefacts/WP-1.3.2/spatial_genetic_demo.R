devtools::load_all('.')

init_fun <- function() {
  pop <- initialize_population(n = 24, max_age = 4)
  pop <- initialize_patches(pop, patch_ids = c(rep(1L, 12), rep(2L, 12)))
  initialize_genotypes(pop, n_loci = 8, n_alleles = 3L)
}

sc <- scenario_spec(
  name = "wp132_spatial_genetic_demo",
  n_runs = 6,
  n_years = 6,
  init_fun = init_fun,
  survival_fun = default_survival_fun,
  breeding_fun = function(ind) FALSE,
  fecundity_fun = function(ind) 0L,
  K_patches = c(40, 30),
  lifecycle_steps = c("age", "survival", "dispersal", "breeding_births", "harvest"),
  dispersal_fun = make_markov_dispersal_fun(matrix(c(0.85, 0.15, 0.20, 0.80), nrow = 2, byrow = TRUE)),
  seed = 20260209L
)

out <- run_scenario(sc)
occ <- summarise_patch_occupancy_final(out$sim_output, n_patches = 2, alive_only = TRUE)
gen <- summarise_patch_genetic_diversity_final(out$sim_output, n_patches = 2, alive_only = TRUE)

write.csv(occ, "artefacts/WP-1.3.2/patch_occupancy_final.csv", row.names = FALSE)
write.csv(gen, "artefacts/WP-1.3.2/patch_genetic_diversity_final.csv", row.names = FALSE)

cat("WP-1.3.2 spatial/genetic demo summary\n")
print(occ)
print(gen)
