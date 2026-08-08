% Generated manually from R/scenario_core.R because roxygen2 is unavailable.
\name{run_scenario}
\alias{run_scenario}
\title{Execute a process-based scenario}
\usage{
run_scenario(scenario, parallel = FALSE, workers = 2L)
}
\arguments{
\item{scenario}{Object created by \code{scenario_spec()}.}
\item{parallel}{Whether to use local fork workers.}
\item{workers}{Number of local workers when \code{parallel = TRUE}.}
}
\value{
A list containing the scenario and \code{sim_output}. The latter contains
ordered per-run results, combined events, census rows and RNG provenance.
}
\description{
Preassigns independent L'Ecuyer-CMRG streams and executes each replicate's
ordered process list.
}
