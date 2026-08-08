% Generated manually from R/process_core.R because roxygen2 is unavailable.
\name{validate_processes}
\alias{validate_processes}
\title{Validate an ordered process list}
\usage{validate_processes(processes, state = NULL)}
\arguments{
\item{processes}{Non-empty ordered process list.}
\item{state}{Optional initial state for dependency preflight.}
}
\value{The process list, invisibly.}
\description{Validates process shape, parameters, fields and creation declarations.}
