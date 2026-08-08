% Generated manually from R/process_core.R because roxygen2 is unavailable.
\name{pva_process}
\alias{pva_process}
\alias{print.pva_process}
\title{Construct an OpenPVA lifecycle process}
\usage{
pva_process(
  name,
  run,
  params = list(),
  requires = character(),
  writes = character(),
  creates = NULL,
  validate_params = NULL,
  description = NULL
)

\method{print}{pva_process}(x, ...)
}
\arguments{
\item{name}{Stable process name.}
\item{run}{Function called as \code{run(state, context, params)}.}
\item{params}{Explicit parameter list.}
\item{requires}{Required state paths.}
\item{writes}{State paths the process may write. Structural
\code{population} writes are reserved for declared creators; existing-record
changes require granular \code{population.<field>} paths.}
\item{creates}{Population fields initialised on every new individual, or \code{NULL}.}
\item{validate_params}{Optional parameter validator.}
\item{description}{Optional short description.}
\item{x}{A process object.}
\item{...}{Unused print arguments.}
}
\value{A validated \code{pva_process}; the print method returns it invisibly.}
\description{Wraps one ordinary R process function with explicit scientific metadata.}
