# Internal helpers --------------------------------------------------------

.heterozygosity_from_alleles <- function(alleles) {
  if (is.null(alleles) || !is.matrix(alleles) || nrow(alleles) != 2L) {
    return(NA_real_)
  }
  n_loci <- ncol(alleles)
  if (n_loci == 0L) {
    return(NA_real_)
  }
  mean(alleles[1L, ] != alleles[2L, ])
}

.Fhat_from_alleles <- function(alleles) {
  H <- .heterozygosity_from_alleles(alleles)
  if (is.na(H)) {
    return(NA_real_)
  }
  1 - H
}

#' Initialize simple diploid genotypes
#'
#' Assigns each individual a 2 x `n_loci` integer matrix representing two haplotypes.
#'
#' @param population List of individual objects.
#' @param n_loci Positive integer number of loci.
#' @param n_alleles Positive integer number of possible allele states (coded 1, 2, ...).
#'
#' @return The population list with `alleles` matrices populated.
#' @export
initialize_genotypes <- function(population, n_loci, n_alleles = 2L) {
  n_loci <- as.integer(n_loci)
  n_alleles <- as.integer(n_alleles)
  if (is.na(n_loci) || n_loci <= 0L) {
    stop("n_loci must be a positive integer", call. = FALSE)
  }
  if (is.na(n_alleles) || n_alleles <= 0L) {
    stop("n_alleles must be a positive integer", call. = FALSE)
  }
  if (!length(population)) {
    return(population)
  }

  allele_values <- seq_len(n_alleles)
  populate_ind <- function(ind) {
    maternal <- sample(allele_values, size = n_loci, replace = TRUE)
    paternal <- sample(allele_values, size = n_loci, replace = TRUE)
    ind$alleles <- rbind(maternal, paternal)
    rownames(ind$alleles) <- c("hap1", "hap2")
    ind$F <- .Fhat_from_alleles(ind$alleles)
    ind
  }

  lapply(population, populate_ind)
}

#' Simple diploid inheritance with optional mutation
#'
#' Samples one haplotype from each parent at every locus and applies optional mutation.
#'
#' @param mother Individual object with a populated `alleles` matrix.
#' @param father Individual object with a populated `alleles` matrix.
#' @param mutation_rate Numeric in [0, 1]; per-allele mutation probability.
#' @param n_alleles Optional positive integer for the number of allele states; if `NULL`,
#'   inferred from parental alleles.
#'
#' @return A 2 x `n_loci` integer matrix of offspring alleles.
#' @export
inherit_genotype_simple <- function(mother, father, mutation_rate = 0, n_alleles = NULL) {
  if (!is.matrix(mother$alleles) || !is.matrix(father$alleles)) {
    stop("Both parents must have allele matrices", call. = FALSE)
  }
  if (!identical(dim(mother$alleles), dim(father$alleles))) {
    stop("Parental allele matrices must have matching dimensions", call. = FALSE)
  }
  n_loci <- ncol(mother$alleles)
  if (n_loci <= 0L) {
    stop("Allele matrices must have at least one locus", call. = FALSE)
  }
  mutation_rate <- as.numeric(mutation_rate)
  if (length(mutation_rate) != 1L || is.na(mutation_rate) || mutation_rate < 0 || mutation_rate > 1) {
    stop("mutation_rate must be a single value in [0, 1]", call. = FALSE)
  }

  if (is.null(n_alleles)) {
    allele_max <- max(c(mother$alleles, father$alleles), na.rm = TRUE)
    if (!is.finite(allele_max) || allele_max <= 0) {
      stop("Unable to infer allele states from parents", call. = FALSE)
    }
  } else {
    allele_max <- as.integer(n_alleles)
    if (is.na(allele_max) || allele_max <= 0L) {
      stop("n_alleles must be a positive integer", call. = FALSE)
    }
  }

  offspring <- matrix(NA_integer_, nrow = 2L, ncol = n_loci)
  rownames(offspring) <- c("hap1", "hap2")
  for (locus in seq_len(n_loci)) {
    offspring[1L, locus] <- mother$alleles[sample.int(2L, 1L), locus]
    offspring[2L, locus] <- father$alleles[sample.int(2L, 1L), locus]
  }

  if (mutation_rate > 0) {
    mut_mask <- stats::runif(length(offspring)) < mutation_rate
    if (any(mut_mask)) {
      offspring[mut_mask] <- sample.int(allele_max, sum(mut_mask), replace = TRUE)
    }
  }

  offspring
}

#' Summarise neutral genetic diversity
#'
#' Computes mean heterozygosity and its complement (\eqn{\hat{F}}) for individuals with genotypes.
#'
#' @param population List of individual objects.
#' @param alive_only Logical; restrict to alive individuals (default TRUE).
#'
#' @return A tibble with summary statistics.
#' @export
summarise_genetic_diversity <- function(population, alive_only = TRUE) {
  if (!length(population)) {
    return(tibble::tibble(
      n_individuals = 0L,
      alive_only = alive_only,
      mean_heterozygosity = NA_real_,
      mean_Fhat = NA_real_
    ))
  }

  eligible <- Filter(function(ind) {
    has_genotype <- !is.null(ind$alleles) && is.matrix(ind$alleles)
    alive_flag <- if (alive_only) ind$alive else TRUE
    has_genotype && alive_flag
  }, population)

  if (!length(eligible)) {
    return(tibble::tibble(
      n_individuals = 0L,
      alive_only = alive_only,
      mean_heterozygosity = NA_real_,
      mean_Fhat = NA_real_
    ))
  }

  heterozygosity <- vapply(eligible, function(ind) {
    .heterozygosity_from_alleles(ind$alleles)
  }, numeric(1))

  mean_H <- mean(heterozygosity, na.rm = TRUE)
  mean_F <- mean(1 - heterozygosity, na.rm = TRUE)
  if (is.nan(mean_H)) mean_H <- NA_real_
  if (is.nan(mean_F)) mean_F <- NA_real_

  tibble::tibble(
    n_individuals = length(eligible),
    alive_only = alive_only,
    mean_heterozygosity = mean_H,
    mean_Fhat = mean_F
  )
}

#' Build an inbreeding-aware survival function
#'
#' Wraps a baseline survival function with a linear penalty based on an individual's
#' inbreeding coefficient (`F`).
#'
#' @param base_survival_fun Function returning baseline survival probabilities in [0, 1].
#' @param beta Non-negative numeric strength parameter (0 = no inbreeding effect).
#'
#' @return A function suitable for use as a survival function.
#' @export
make_inbreeding_survival_fun <- function(base_survival_fun, beta) {
  beta <- as.numeric(beta)
  if (length(beta) != 1L || is.na(beta) || beta < 0) {
    stop("beta must be a non-negative numeric scalar", call. = FALSE)
  }
  function(ind) {
    p_base <- base_survival_fun(ind)
    F_i <- ind$F
    if (is.null(F_i) || is.na(F_i)) {
      F_i <- 0
    }
    scale <- 1 - beta * F_i
    if (scale < 0) scale <- 0
    if (scale > 1) scale <- 1
    p_scaled <- p_base * scale
    if (p_scaled < 0) p_scaled <- 0
    if (p_scaled > 1) p_scaled <- 1
    p_scaled
  }
}
