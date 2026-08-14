% Generated manually from R/process_demography.R because roxygen2 is unavailable.
\name{reproduction_process}
\alias{reproduction_process}
\title{Construct a reproduction process}
\usage{
reproduction_process(
  breeding_probability,
  fecundity_mean,
  offspring_sex,
  name = "reproduction",
  mating = NULL,
  require_mate = FALSE,
  newborn_initializer = NULL,
  initializer_fields = character(),
  inherit_fields = character(),
  requires = character(),
  params = list()
)
}
\arguments{
\item{breeding_probability}{Function returning a breeding probability.}
\item{fecundity_mean}{Function returning a Poisson litter mean.}
\item{name}{Process name.}
\item{mating}{Optional mate-selection function.}
\item{require_mate}{Whether reproduction requires a father.}
\item{offspring_sex}{Required function returning \code{"F"} or \code{"M"}.}
\item{newborn_initializer}{Function returning additional newborn fields.}
\item{initializer_fields}{Fields promised by \code{newborn_initializer}.}
\item{inherit_fields}{Maternal fields copied to newborns.}
\item{requires}{Additional state requirements.}
\item{params}{Explicit model parameters.}
}
\value{A validated lifecycle process.}
\description{Draws breeding and litter events against one pre-process state and explicitly initialises newborn state.}
