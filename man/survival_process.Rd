% Generated manually from R/process_demography.R because roxygen2 is unavailable.
\name{survival_process}
\alias{survival_process}
\title{Construct an individual survival process}
\usage{
survival_process(
  probability,
  name = "survival",
  eligible = NULL,
  requires = character(),
  params = list(),
  cause = "natural"
)
}
\arguments{
\item{probability}{Function returning a survival probability.}
\item{name}{Process name.}
\item{eligible}{Optional eligibility function.}
\item{requires}{Additional state requirements.}
\item{params}{Explicit model parameters.}
\item{cause}{Death-cause label.}
}
\value{A validated lifecycle process.}
\description{Applies Bernoulli survival and emits aggregate death accounting.}
