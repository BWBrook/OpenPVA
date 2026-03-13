# bootstrap_env.R

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

options(renv.config.pak.enabled = FALSE)
renv::restore(prompt = FALSE)
