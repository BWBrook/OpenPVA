# ci_restore.R

# GitHub's setup-r action can leave RSPM/PPM binary-repository variables in the
# runner environment. OpenPVA CI restores the lockfile from CRAN sources so
# scheduled runs do not drift with external Linux binary availability.
Sys.unsetenv("RSPM")
Sys.setenv(
  RENV_CONFIG_PAK_ENABLED = "FALSE",
  RENV_CONFIG_PPM_ENABLED = "FALSE",
  RENV_CONFIG_RSPM_ENABLED = "FALSE",
  RENV_CONFIG_REPOS_OVERRIDE = "https://cloud.r-project.org",
  R_PKG_TYPE = "source"
)

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  pkgType = "source",
  renv.config.pak.enabled = FALSE,
  renv.config.ppm.enabled = FALSE,
  renv.config.rspm.enabled = FALSE
)

renv::restore(prompt = FALSE)
