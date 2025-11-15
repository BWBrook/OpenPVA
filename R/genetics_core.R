#' Initialize simple diploid genotypes
#'
#' Assigns each individual a 2 \u00d7 `n_loci` integer matrix representing two haplotypes.
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
#' @return A 2 \u00d7 `n_loci` integer matrix of offspring alleles.
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
    alleles <- ind$alleles
    if (!is.matrix(alleles) || nrow(alleles) != 2L) {
      stop("Allele matrices must be 2 \u00d7 L", call. = FALSE)
    }
    loci <- ncol(alleles)
    if (loci == 0L) {
      stop("Allele matrices must have at least one locus", call. = FALSE)
    }
    mean(alleles[1L, ] != alleles[2L, ])
  }, numeric(1))

  tibble::tibble(
    n_individuals = length(eligible),
    alive_only = alive_only,
    mean_heterozygosity = mean(heterozygosity),
    mean_Fhat = mean(1 - heterozygosity)
  )
}
