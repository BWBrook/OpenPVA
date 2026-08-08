% Generated manually from R/process_demography.R because roxygen2 is unavailable.
\name{census_process}
\alias{census_process}
\title{Construct a census observer process}
\usage{
census_process(
  summarise = NULL,
  name = "census",
  requires = c("population.id", "population.sex", "population.alive"),
  params = list()
)
}
\arguments{
\item{summarise}{Function returning named scalar metrics including \code{n_alive}.}
\item{name}{Process name.}
\item{requires}{State requirements.}
\item{params}{Explicit model parameters.}
}
\value{A non-mutating lifecycle process.}
\description{Observes state at its explicit position in the process list.}
