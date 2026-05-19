# install_renv.R

repos <- Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE", unset = "")
if (!nzchar(repos)) {
  repos <- Sys.getenv("RSPM", unset = "")
}
if (!nzchar(repos)) {
  repos <- "https://cloud.r-project.org"
}

pkg_type <- Sys.getenv("R_PKG_TYPE", unset = "")
if (nzchar(pkg_type)) {
  options(pkgType = pkg_type)
}
options(repos = c(CRAN = repos))

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = repos)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Failed to install renv from configured repositories: ", repos)
}
