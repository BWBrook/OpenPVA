% Generated manually from R/scenario_core.R because roxygen2 is unavailable.
\name{scenario_spec}
\alias{scenario_spec}
\title{Construct a process-based simulation scenario}
\usage{
scenario_spec(
  name,
  n_runs,
  n_steps,
  init_fun,
  processes,
  seed = NULL,
  dt = 1,
  initial_census = NULL,
  record_population_history = FALSE
)
}
\arguments{
\item{name}{Scenario name.}
\item{n_runs}{Number of independent replicate streams.}
\item{n_steps}{Number of lifecycle intervals per replicate.}
\item{init_fun}{Function returning a population list or \code{pva_state}.}
\item{processes}{Direct ordered list of process objects.}
\item{seed}{Optional root integer seed.}
\item{dt}{Positive interval duration supplied in process context.}
\item{initial_census}{Optional observer run in the distinct initial phase at time zero.}
\item{record_population_history}{Whether to retain state after every interval.}
}
\value{An object of class \code{openpva_scenario}.}
\description{Defines a reusable modeller-supplied biological program.}
