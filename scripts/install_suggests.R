# install_suggests.R

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

description <- read.dcf("DESCRIPTION")
suggests_field <- description[1, "Suggests"]

suggests <- trimws(unlist(strsplit(suggests_field, ",")))
suggests <- gsub("[[:space:]]*[(].*[)]$", "", suggests)
suggests <- suggests[nzchar(suggests)]

missing <- suggests[
  !vapply(suggests, requireNamespace, FUN.VALUE = logical(1), quietly = TRUE)
]

if (length(missing) > 0) {
  message("Installing missing Suggests: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = repos)
} else {
  message("All Suggests already installed.")
}
