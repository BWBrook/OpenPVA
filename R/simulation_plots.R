#' Plot mean population trajectory with variation
#'
#' Draws a ribbon and line summarising trajectories from replicated simulations.
#'
#' @param trajectory_summary Tibble produced by `compute_mean_trajectory()`.
#'
#' @return A ggplot object visualising mean trajectories with ±1 SD ribbon.
plot_mean_trajectory <- function(trajectory_summary) {
  if (!nrow(trajectory_summary)) {
    stop("trajectory_summary must have at least one row")
  }
  ggplot2::ggplot(trajectory_summary, ggplot2::aes(x = .data$year, y = .data$mean_n_alive)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = pmax(.data$mean_n_alive - .data$sd_n_alive, 0),
        ymax = .data$mean_n_alive + .data$sd_n_alive
      ),
      alpha = 0.2
    ) +
    ggplot2::geom_line() +
    ggplot2::labs(
      x = "Year",
      y = "Mean population size (alive)"
    ) +
    ggplot2::theme_minimal()
}
