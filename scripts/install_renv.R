# install_renv.R

repos <- Sys.getenv("RSPM", unset = "")
if (!nzchar(repos)) {
  repos <- "https://cloud.r-project.org"
}

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = repos)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Failed to install renv from configured repositories: ", repos)
}
