% Generated manually from R/process_core.R because roxygen2 is unavailable.
\name{execute_processes}
\alias{execute_processes}
\title{Execute one ordered lifecycle interval}
\usage{
execute_processes(
  state,
  processes,
  run = 1L,
  time = 0L,
  dt = 1,
  stream_provenance = NULL,
  execution_id = NULL,
  phase = c("interval", "initial")
)
}
\arguments{
\item{state}{OpenPVA simulation state.}
\item{processes}{Ordered lifecycle process list.}
\item{run}{Replicate identifier.}
\item{time}{Interval label.}
\item{dt}{Positive interval duration.}
\item{stream_provenance}{Optional replicate-stream record.}
\item{execution_id}{Optional provenance identifier.}
\item{phase}{Execution phase.}
}
\value{A list with replacement state, events and process plan.}
\description{The single generic execution loop; it contains no biological categories.}
