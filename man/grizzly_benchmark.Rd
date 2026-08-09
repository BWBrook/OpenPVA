\name{grizzly_benchmark_parameters}
\alias{grizzly_benchmark_parameters}
\alias{grizzly_benchmark_processes}
\alias{grizzly_benchmark_scenario}
\alias{grizzly_benchmark_scenarios}
\alias{run_grizzly_benchmark}
\alias{summarise_grizzly_benchmark}
\title{Synthetic canonical grizzly-like benchmark}
\description{
  Construct and run the explicitly uncalibrated, source-labelled Goal 003
  benchmark through ordinary OpenPVA process composition. The fixture is not
  empirical grizzly truth, a calibrated Greater Yellowstone model, a recovery
  criterion or a management recommendation.
}
\usage{
grizzly_benchmark_parameters(horizon = 12L, quasi_extinction_threshold = 4L)
grizzly_benchmark_processes(parameters = grizzly_benchmark_parameters(), scenario = c("baseline", "female_low_survival", "female_high_survival", "human_mortality", "immigration", "environmental_variation", "human_mortality_before_reproduction"), include_observation = TRUE)
grizzly_benchmark_scenario(scenario = c("baseline", "female_low_survival", "female_high_survival", "human_mortality", "immigration", "environmental_variation", "human_mortality_before_reproduction"), parameters = grizzly_benchmark_parameters(), n_runs = 20L, n_steps = parameters$horizon, seed = 20260809L, include_observation = TRUE)
grizzly_benchmark_scenarios(parameters = grizzly_benchmark_parameters(), n_runs = 20L, seed = 20260809L)
run_grizzly_benchmark(scenario = "baseline", parameters = grizzly_benchmark_parameters(), n_runs = 20L, n_steps = parameters$horizon, seed = 20260809L, parallel = FALSE, workers = 2L)
summarise_grizzly_benchmark(output, benchmark = NULL)
}
\arguments{
  \item{horizon}{Number of annual intervals.}
  \item{quasi_extinction_threshold}{Explicit threshold used by summaries.}
  \item{parameters}{The benchmark parameter fixture.}
  \item{scenario}{For \code{run_grizzly_benchmark()}, one of the five canonical
  scenario names. The scenario builder also accepts ordinary extension names.}
  \item{include_observation}{Whether to include the non-mutating observation process.}
  \item{n_runs}{Number of replicate runs.}
  \item{n_steps}{Number of annual intervals.}
  \item{seed}{Root RNG seed.}
  \item{parallel}{Whether to use supported fork execution.}
  \item{workers}{Number of fork workers.}
  \item{output}{Result from \code{run_grizzly_benchmark()} or \code{run_scenario()}.}
  \item{benchmark}{Optional explicit benchmark provenance list. Generic
  \code{run_scenario()} output must supply this explicitly; mutable scenario
  metadata is not trusted automatically.}
}
\value{A parameter list, process list, scenario, scenario set, run result or summary list, depending on the function.}
\seealso{\code{pva_process}, \code{scenario_spec}, \code{run_scenario}}
