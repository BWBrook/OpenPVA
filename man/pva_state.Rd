% Generated manually from R/process_core.R because roxygen2 is unavailable.
\name{pva_state}
\alias{pva_state}
\title{Construct OpenPVA simulation state}
\usage{pva_state(population, globals = list(), next_id = NULL)}
\arguments{
\item{population}{List of named individual records.}
\item{globals}{Named list of shared dynamic values.}
\item{next_id}{Next unused positive integer, or \code{NULL} to derive it.}
}
\value{A validated state list.}
\description{Constructs the engine-carried population, globals and identifier state.}
\details{Population records are append-only. Existing records retain their
position and identifier; mortality changes \code{alive}, and new records append
with consecutive engine-allocated identifiers.}
