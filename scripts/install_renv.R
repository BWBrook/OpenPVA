# install_renv.R

.lockfile_renv_version <- function(path = "renv.lock") {
  if (!file.exists(path)) {
    return(NA_character_)
  }

  lockfile <- readLines(path, warn = FALSE)
  start <- grep('^\\s*"renv"\\s*:\\s*\\{\\s*$', lockfile)
  if (!length(start)) {
    return(NA_character_)
  }

  entry <- lockfile[seq.int(start[[1]], min(length(lockfile), start[[1]] + 80L))]
  version <- grep('^\\s*"Version"\\s*:', entry, value = TRUE)
  if (!length(version)) {
    return(NA_character_)
  }

  sub('^\\s*"Version"\\s*:\\s*"([^"]+)".*$', "\\1", version[[1]])
}

.installed_renv_version <- function() {
  tryCatch(
    as.character(utils::packageVersion("renv")),
    error = function(...) NA_character_
  )
}

.install_renv <- function(version, repos) {
  available <- tryCatch(
    utils::available.packages(repos = repos),
    error = function(...) NULL
  )

  current_repo_has_version <- !is.null(available) &&
    "renv" %in% rownames(available) &&
    isTRUE(available["renv", "Version"] == version)

  if (current_repo_has_version) {
    utils::install.packages("renv", repos = repos)
  } else {
    archive <- sprintf(
      "https://cran.r-project.org/src/contrib/Archive/renv/renv_%s.tar.gz",
      version
    )
    utils::install.packages(archive, repos = NULL, type = "source")
  }
}

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

target_version <- .lockfile_renv_version()
if (is.na(target_version)) {
  target_version <- "1.1.5"
}

installed_version <- .installed_renv_version()
if (!identical(installed_version, target_version)) {
  .install_renv(target_version, repos)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Failed to install renv from configured repositories: ", repos)
}

installed_version <- .installed_renv_version()
if (!identical(installed_version, target_version)) {
  stop(
    "Installed renv ",
    installed_version,
    " but renv.lock requires ",
    target_version,
    call. = FALSE
  )
}
