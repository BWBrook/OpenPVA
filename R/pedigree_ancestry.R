#' Declare base-founder pedigree fields
#'
#' A base founder has no recorded parents and is assumed unrelated and
#' non-inbred relative to the declared pedigree horizon.
#'
#' @return A named list suitable for an initial record or introduction
#'   initializer.
#' @export
pedigree_founder_fields <- function() {
  list(
    mother_id = NA_integer_,
    father_id = NA_integer_,
    pedigree_status = "base_founder",
    pedigree_F = 0
  )
}

#' Initialize exact pedigree inbreeding
#'
#' Every record must already declare `pedigree_status` as `"base_founder"` or
#' `"known_parentage"` and carry explicit parent IDs consistent with that
#' status. This function computes `pedigree_F`, or validates existing values
#' when every record already contains them.
#'
#' @param population Ordered append-only list of individual records.
#'
#' @return The population with exact numeric `pedigree_F` fields.
#' @export
initialize_pedigree <- function(population) {
  if (!is.list(population)) {
    stop("population must be a list", call. = FALSE)
  }
  if (!length(population)) {
    return(population)
  }
  population <- .normalize_population_integer_fields(population)
  has_F <- vapply(
    population,
    function(individual) "pedigree_F" %in% names(individual) &&
      !is.null(individual$pedigree_F),
    logical(1)
  )
  if (any(has_F) && !all(has_F)) {
    stop(
      "pedigree_F must be present on every record or absent from every record",
      call. = FALSE
    )
  }
  topology <- .pedigree_topology(population, require_F = all(has_F))
  expected <- .pedigree_expected_F(topology)
  if (all(has_F)) {
    observed <- vapply(population, `[[`, numeric(1), "pedigree_F")
    mismatch <- which(abs(observed - expected$F) > .pedigree_tolerance())
    if (length(mismatch)) {
      index <- mismatch[[1L]]
      stop(
        sprintf(
          "individual id %d has pedigree_F inconsistent with its recorded ancestry",
          topology$ids[[index]]
        ),
        call. = FALSE
      )
    }
  } else {
    for (index in seq_along(population)) {
      population[[index]]$pedigree_F <- expected$F[[index]]
    }
  }
  .validate_pedigree_population(population)
  population
}

#' Validate an enabled pedigree
#'
#' @param population Ordered append-only list of pedigree-enabled records.
#'
#' @return `population`, invisibly, after exact topology and coefficient
#'   validation.
#' @export
validate_pedigree <- function(population) {
  .validate_pedigree_population(population)
  invisible(population)
}

#' Construct known-parentage fields
#'
#' Computes exact ancestry for an exogenous individual whose two parents are
#' already present in the shared pre-process population. Same-batch newcomer
#' ancestry is therefore deliberately unsupported.
#'
#' @param mother_id Persistent public ID of the recorded mother.
#' @param father_id Persistent public ID of the recorded father.
#' @param state Current OpenPVA state containing the two earlier ancestors.
#'
#' @return A named list suitable for an introduction initializer.
#' @export
pedigree_parentage_fields <- function(mother_id, father_id, state) {
  mother_id <- .normalize_integer_scalar(mother_id, "mother_id", minimum = 1L)
  father_id <- .normalize_integer_scalar(father_id, "father_id", minimum = 1L)
  if (!is.list(state) || !is.list(state$population)) {
    stop("state must contain a population list", call. = FALSE)
  }
  topology <- .pedigree_topology(state$population, require_F = TRUE)
  mother_row <- match(mother_id, topology$ids)
  father_row <- match(father_id, topology$ids)
  if (is.na(mother_row)) {
    stop("mother_id does not reference an existing pedigree record", call. = FALSE)
  }
  if (is.na(father_row)) {
    stop("father_id does not reference an existing pedigree record", call. = FALSE)
  }
  if (mother_id == father_id) {
    stop("mother_id and father_id must reference distinct records", call. = FALSE)
  }
  if (!identical(state$population[[mother_row]]$sex, "F")) {
    stop("mother_id must reference a female ('F') record", call. = FALSE)
  }
  if (!identical(state$population[[father_row]]$sex, "M")) {
    stop("father_id must reference a male ('M') record", call. = FALSE)
  }
  D <- .pedigree_observed_D(topology, state$population)
  coefficient <- .pedigree_pair_inbreeding(
    mother_row,
    father_row,
    topology$mother_row,
    topology$father_row,
    D
  )
  list(
    mother_id = mother_id,
    father_id = father_id,
    pedigree_status = "known_parentage",
    pedigree_F = coefficient
  )
}

#' Construct newborn pedigree fields
#'
#' This helper is designed for `reproduction_process(newborn_initializer = )`.
#' The reproduction creator already owns `mother_id` and `father_id`; this
#' helper supplies the two additional pedigree fields.
#'
#' @param mother Mother record selected by the reproduction process.
#' @param father Father record selected by the mating callback.
#' @param state Current OpenPVA state.
#'
#' @return A named list containing `pedigree_status` and `pedigree_F`.
#' @export
pedigree_newborn_fields <- function(mother, father, state) {
  if (!is.list(mother) || is.null(mother$id)) {
    stop("mother must be a pedigree record with an id", call. = FALSE)
  }
  if (!is.list(father) || is.null(father$id)) {
    stop(
      "pedigree-enabled reproduction requires two known parents",
      call. = FALSE
    )
  }
  fields <- pedigree_parentage_fields(mother$id, father$id, state)
  fields[c("pedigree_status", "pedigree_F")]
}

#' Extract the pedigree ledger
#'
#' @param population Pedigree-enabled population ledger.
#' @param alive_only Restrict output to living records.
#'
#' @return A tidy table in persistent ledger order.
#' @export
pedigree_ledger <- function(population, alive_only = FALSE) {
  if (!is.logical(alive_only) || length(alive_only) != 1L || is.na(alive_only)) {
    stop("alive_only must be one non-missing logical value", call. = FALSE)
  }
  .validate_pedigree_population(population)
  rows <- if (alive_only) {
    Filter(function(individual) isTRUE(individual$alive), population)
  } else {
    population
  }
  if (!length(rows)) {
    return(tibble::tibble(
      id = integer(),
      mother_id = integer(),
      father_id = integer(),
      sex = character(),
      alive = logical(),
      pedigree_status = character(),
      pedigree_F = numeric()
    ))
  }
  tibble::tibble(
    id = vapply(rows, `[[`, integer(1), "id"),
    mother_id = vapply(rows, `[[`, integer(1), "mother_id"),
    father_id = vapply(rows, `[[`, integer(1), "father_id"),
    sex = vapply(rows, `[[`, character(1), "sex"),
    alive = vapply(rows, `[[`, logical(1), "alive"),
    pedigree_status = vapply(rows, `[[`, character(1), "pedigree_status"),
    pedigree_F = vapply(rows, `[[`, numeric(1), "pedigree_F")
  )
}

#' Summarize pedigree inbreeding
#'
#' @param population Pedigree-enabled population ledger.
#' @param alive_only Restrict the coefficient summary to living records.
#'
#' @return A one-row tidy table of essential counts and coefficients.
#' @export
summarise_pedigree <- function(population, alive_only = TRUE) {
  ledger <- pedigree_ledger(population, alive_only = alive_only)
  if (!nrow(ledger)) {
    return(tibble::tibble(
      n_individuals = 0L,
      alive_only = alive_only,
      n_base_founders = 0L,
      n_known_parentage = 0L,
      mean_pedigree_F = NA_real_,
      max_pedigree_F = NA_real_
    ))
  }
  tibble::tibble(
    n_individuals = as.integer(nrow(ledger)),
    alive_only = alive_only,
    n_base_founders = as.integer(sum(ledger$pedigree_status == "base_founder")),
    n_known_parentage = as.integer(sum(ledger$pedigree_status == "known_parentage")),
    mean_pedigree_F = mean(ledger$pedigree_F),
    max_pedigree_F = max(ledger$pedigree_F)
  )
}

.pedigree_is_enabled <- function(population) {
  any(vapply(population, function(individual) {
    is.list(individual) && any(c("pedigree_status", "pedigree_F") %in% names(individual))
  }, logical(1)))
}

.pedigree_lineage_changed <- function(before, after) {
  fields <- c(
    "id", "mother_id", "father_id", "pedigree_status", "pedigree_F"
  )
  extract <- function(population) {
    lapply(population, function(individual) individual[intersect(fields, names(individual))])
  }
  !identical(extract(before), extract(after))
}

.pedigree_tolerance <- function() {
  64 * .Machine$double.eps
}

.validate_pedigree_population <- function(population) {
  if (!is.list(population)) {
    stop("population must be a list", call. = FALSE)
  }
  if (!length(population)) {
    return(.empty_pedigree_topology())
  }
  topology <- .pedigree_topology(population, require_F = TRUE)
  expected <- .pedigree_expected_F(topology)
  observed <- vapply(population, `[[`, numeric(1), "pedigree_F")
  mismatch <- which(abs(observed - expected$F) > .pedigree_tolerance())
  if (length(mismatch)) {
    index <- mismatch[[1L]]
    stop(
      sprintf(
        "individual id %d has pedigree_F inconsistent with its recorded ancestry",
        topology$ids[[index]]
      ),
      call. = FALSE
    )
  }
  topology
}

.empty_pedigree_topology <- function() {
  list(
    ids = integer(),
    mother_row = integer(),
    father_row = integer(),
    status = character()
  )
}

.pedigree_topology <- function(population, require_F) {
  n <- length(population)
  required <- c("id", "sex", "alive", "mother_id", "father_id", "pedigree_status")
  for (index in seq_len(n)) {
    individual <- population[[index]]
    if (!is.list(individual) || is.null(names(individual))) {
      stop("every pedigree individual must be a named list", call. = FALSE)
    }
    missing <- setdiff(required, names(individual))
    if (length(missing)) {
      stop(
        sprintf(
          "individual record %d is missing pedigree field(s): %s",
          index,
          paste(missing, collapse = ", ")
        ),
        call. = FALSE
      )
    }
    if (require_F && (!"pedigree_F" %in% names(individual) ||
        is.null(individual$pedigree_F))) {
      stop(
        sprintf("individual record %d is missing pedigree field pedigree_F", index),
        call. = FALSE
      )
    }
  }

  ids <- vapply(population, function(individual) {
    .normalize_integer_scalar(individual$id, "pedigree id", minimum = 1L)
  }, integer(1))
  if (anyDuplicated(ids)) {
    stop("pedigree id values must be unique", call. = FALSE)
  }
  sexes <- vapply(population, function(individual) {
    value <- individual$sex
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !value %in% c("F", "M")) {
      stop("pedigree sex must be 'F' or 'M'", call. = FALSE)
    }
    value
  }, character(1))
  mother_id <- vapply(population, function(individual) {
    .normalize_integer_scalar(
      individual$mother_id,
      "mother_id",
      allow_na = TRUE,
      minimum = 1L
    )
  }, integer(1))
  father_id <- vapply(population, function(individual) {
    .normalize_integer_scalar(
      individual$father_id,
      "father_id",
      allow_na = TRUE,
      minimum = 1L
    )
  }, integer(1))
  status <- vapply(population, function(individual) {
    value <- individual$pedigree_status
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !value %in% c("base_founder", "known_parentage")) {
      stop(
        "pedigree_status must be 'base_founder' or 'known_parentage'",
        call. = FALSE
      )
    }
    value
  }, character(1))

  if (require_F) {
    for (index in seq_len(n)) {
      value <- population[[index]]$pedigree_F
      if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
          value < 0 || value > 1) {
        stop("pedigree_F must be one finite numeric value in [0, 1]", call. = FALSE)
      }
    }
  }

  mother_row <- match(mother_id, ids, nomatch = 0L)
  father_row <- match(father_id, ids, nomatch = 0L)
  for (index in seq_len(n)) {
    one_missing <- xor(is.na(mother_id[[index]]), is.na(father_id[[index]]))
    if (one_missing) {
      stop(
        sprintf("individual id %d has unsupported partial parentage", ids[[index]]),
        call. = FALSE
      )
    }
    if (status[[index]] == "base_founder") {
      if (!is.na(mother_id[[index]]) || !is.na(father_id[[index]])) {
        stop(
          sprintf("base founder id %d must have both parents absent", ids[[index]]),
          call. = FALSE
        )
      }
      next
    }
    if (is.na(mother_id[[index]]) || is.na(father_id[[index]])) {
      stop(
        sprintf("known-parentage id %d must have both parents present", ids[[index]]),
        call. = FALSE
      )
    }
    if (mother_id[[index]] == father_id[[index]]) {
      stop(
        sprintf("individual id %d has the same mother_id and father_id", ids[[index]]),
        call. = FALSE
      )
    }
    if (mother_id[[index]] == ids[[index]] || father_id[[index]] == ids[[index]]) {
      stop(sprintf("individual id %d cannot be its own parent", ids[[index]]), call. = FALSE)
    }
    mother_match <- mother_row[[index]]
    father_match <- father_row[[index]]
    if (mother_match == 0L) {
      stop(
        sprintf("mother_id %d does not exist in the pedigree", mother_id[[index]]),
        call. = FALSE
      )
    }
    if (father_match == 0L) {
      stop(
        sprintf("father_id %d does not exist in the pedigree", father_id[[index]]),
        call. = FALSE
      )
    }
    if (mother_match >= index || father_match >= index) {
      stop(
        sprintf(
          "parents of individual id %d must be earlier records; later/cyclic topology is unsupported",
          ids[[index]]
        ),
        call. = FALSE
      )
    }
    if (sexes[[mother_match]] != "F") {
      stop(
        sprintf("mother_id %d must reference a female ('F') record", mother_id[[index]]),
        call. = FALSE
      )
    }
    if (sexes[[father_match]] != "M") {
      stop(
        sprintf("father_id %d must reference a male ('M') record", father_id[[index]]),
        call. = FALSE
      )
    }
  }
  list(
    ids = ids,
    mother_row = mother_row,
    father_row = father_row,
    status = status
  )
}

.pedigree_expected_F <- function(topology) {
  n <- length(topology$ids)
  F <- D <- numeric(n)
  for (index in seq_len(n)) {
    if (topology$status[[index]] == "base_founder") {
      F[[index]] <- 0
      D[[index]] <- 1
    } else {
      mother <- topology$mother_row[[index]]
      father <- topology$father_row[[index]]
      F[[index]] <- .pedigree_pair_inbreeding(
        mother,
        father,
        topology$mother_row,
        topology$father_row,
        D
      )
      D[[index]] <- 0.5 - 0.25 * (F[[mother]] + F[[father]])
    }
  }
  list(F = F, D = D)
}

.pedigree_observed_D <- function(topology, population) {
  F <- vapply(population, `[[`, numeric(1), "pedigree_F")
  D <- numeric(length(F))
  for (index in seq_along(F)) {
    if (topology$status[[index]] == "base_founder") {
      D[[index]] <- 1
    } else {
      D[[index]] <- 0.5 - 0.25 * (
        F[[topology$mother_row[[index]]]] + F[[topology$father_row[[index]]]]
      )
    }
  }
  D
}

.pedigree_pair_inbreeding <- function(
    mother_row,
    father_row,
    all_mothers,
    all_fathers,
    D) {
  mother_contribution <- .pedigree_ancestor_contributions(
    mother_row, all_mothers, all_fathers
  )
  father_contribution <- .pedigree_ancestor_contributions(
    father_row, all_mothers, all_fathers
  )
  shared <- intersect(names(mother_contribution), names(father_contribution))
  coefficient <- if (length(shared)) {
    0.5 * sum(
      mother_contribution[shared] * father_contribution[shared] *
        D[as.integer(shared)]
    )
  } else {
    0
  }
  if (coefficient < 0 && coefficient > -.pedigree_tolerance()) {
    coefficient <- 0
  }
  if (coefficient > 1 && coefficient < 1 + .pedigree_tolerance()) {
    coefficient <- 1
  }
  as.numeric(coefficient)
}

.pedigree_ancestor_contributions <- function(
    row,
    mother_row,
    father_row) {
  n <- length(mother_row)
  seen <- logical(n)
  stack <- integer(n)
  stack_size <- 1L
  stack[[stack_size]] <- row
  ancestors <- integer(n)
  n_ancestors <- 0L
  while (stack_size > 0L) {
    index <- stack[[stack_size]]
    stack_size <- stack_size - 1L
    if (seen[[index]]) {
      next
    }
    seen[[index]] <- TRUE
    n_ancestors <- n_ancestors + 1L
    ancestors[[n_ancestors]] <- index
    mother <- mother_row[[index]]
    if (mother > 0L) {
      stack_size <- stack_size + 1L
      stack[[stack_size]] <- mother
      stack_size <- stack_size + 1L
      stack[[stack_size]] <- father_row[[index]]
    }
  }
  ancestors <- sort(ancestors[seq_len(n_ancestors)], decreasing = TRUE)
  local_row <- integer(n)
  local_row[ancestors] <- seq_along(ancestors)
  contribution <- numeric(length(ancestors))
  contribution[[local_row[[row]]]] <- 1
  for (index in ancestors) {
    value <- contribution[[local_row[[index]]]]
    mother <- mother_row[[index]]
    if (mother > 0L) {
      mother_local <- local_row[[mother]]
      father_local <- local_row[[father_row[[index]]]]
      contribution[[mother_local]] <- contribution[[mother_local]] + 0.5 * value
      contribution[[father_local]] <- contribution[[father_local]] + 0.5 * value
    }
  }
  stats::setNames(contribution, as.character(ancestors))
}
