# bootstrap_env.R

source("scripts/install_renv.R", local = TRUE)

options(renv.config.pak.enabled = FALSE)
renv::restore(prompt = FALSE)
