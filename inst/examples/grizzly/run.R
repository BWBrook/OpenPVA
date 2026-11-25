script <- grep("^--file=", commandArgs(FALSE), value = TRUE)
source(file.path(dirname(sub("^--file=", "", script)), "model.R"))

comparison <- lapply(c(0, 0.08), function(harvest) {
  parameters <- grizzly_parameters(adult_female_mortality = harvest, adult_male_mortality = 0.05)
  run <- OpenPVA::run_scenario(grizzly_scenario(parameters))
  risk <- OpenPVA::summarise_pva(run, metric = "n_adult_female", threshold = 3)
  data.frame(adult_female_mortality = harvest, years = risk$horizon,
             ever_below_three_females = risk$p_ever_below, mcse = risk$p_ever_below_mcse)
})
print(do.call(rbind, comparison), row.names = FALSE)
