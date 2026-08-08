% Generated manually from R/process_core.R because roxygen2 is unavailable.
\name{allocate_ids}
\alias{allocate_ids}
\title{Allocate stable individual identifiers}
\usage{allocate_ids(state, n)}
\arguments{
\item{state}{OpenPVA simulation state.}
\item{n}{Number of identifiers to allocate.}
}
\value{A list with updated \code{state} and integer vector \code{ids}.}
\description{Advances the engine-owned identifier allocator for a creation process.}
