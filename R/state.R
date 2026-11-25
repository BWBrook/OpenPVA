.core_field_types <- c(
  id = "integer",
  sex = "character",
  age = "integer",
  alive = "logical",
  mother_id = "integer",
  father_id = "integer",
  origin = "character",
  entry_time = "integer"
)

.engine_owned_fields <- c("id", "origin", "entry_time", "pedigree_F")

.reserved_fields <- c(names(.core_field_types), "pedigree_F")

.stop <- function(...) {
  stop(..., call. = FALSE)
}

.is_count <- function(value, minimum = 0) {
  is.numeric(value) && length(value) == 1L && is.finite(value) &&
    value >= minimum && value == floor(value) && value <= .Machine$integer.max
}

.as_count <- function(value, label, minimum = 0) {
  if (!.is_count(value, minimum)) {
    .stop(label, " must be one whole number >= ", minimum)
  }
  as.integer(value)
}

.is_flag <- function(value) {
  is.logical(value) && length(value) == 1L && !is.na(value)
}

.is_name <- function(value) {
  is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)
}

.field_names <- function(fields, label) {
  if (is.null(fields)) {
    return(character())
  }
  if (!is.character(fields) || anyNA(fields) || any(!nzchar(fields)) ||
      anyDuplicated(fields)) {
    .stop(label, " must be a character vector of unique non-empty names")
  }
  fields
}

.whole_field <- function(value, label) {
  if (is.integer(value)) return(value)
  if (is.logical(value) && all(is.na(value))) return(as.integer(value))
  if (!is.numeric(value) || any(is.nan(value)) ||
      any(!is.na(value) & (!is.finite(value) | value != floor(value) |
                           abs(value) > .Machine$integer.max))) {
    .stop(label, " must be whole numbers representable as integers")
  }
  as.integer(value)
}

pva_population <- function(
    sex,
    age,
    ...,
    mother_id = NA_integer_,
    father_id = NA_integer_) {
  n <- length(sex)
  extra <- list(...)
  if (length(extra) && (is.null(names(extra)) || any(!nzchar(names(extra))))) {
    .stop("additional population fields must be named")
  }
  recycle <- function(value, label) {
    if (length(value) == 1L) {
      return(rep(value, n))
    }
    if (length(value) != n) {
      .stop(label, " must have length 1 or the same length as sex")
    }
    value
  }
  population <- c(
    list(
      id = seq_len(n),
      sex = as.character(sex),
      age = .whole_field(recycle(age, "age"), "age"),
      alive = rep(TRUE, n),
      mother_id = .whole_field(recycle(mother_id, "mother_id"), "mother_id"),
      father_id = .whole_field(recycle(father_id, "father_id"), "father_id"),
      origin = rep("initial", n),
      entry_time = rep(-1L, n)
    ),
    Map(recycle, extra, names(extra))
  )
  .validate_population(population)
}

.as_population <- function(population) {
  if (is.data.frame(population)) {
    population <- as.list(population)
    population <- lapply(population, function(column) {
      if (is.factor(column)) as.character(column) else column
    })
  }
  if (!is.list(population) || is.null(names(population))) {
    .stop("population must be a named list of equal-length vectors or a data frame")
  }
  if (!all(c("sex", "age") %in% names(population))) {
    .stop("population must contain sex and age")
  }
  if (all(names(.core_field_types) %in% names(population))) {
    return(.validate_population(population))
  }
  supplied <- setdiff(names(.core_field_types), c("sex", "age", "mother_id", "father_id"))
  if (any(supplied %in% names(population))) {
    .stop(
      "population supplies engine fields without the complete core set: ",
      paste(intersect(supplied, names(population)), collapse = ", ")
    )
  }
  do.call(pva_population, population)
}

.validate_population <- function(population, pedigree = NULL) {
  fields <- names(population)
  if (is.null(fields) || anyDuplicated(fields) || any(!nzchar(fields))) {
    .stop("population fields must have unique non-empty names")
  }
  missing <- setdiff(names(.core_field_types), fields)
  if (length(missing)) {
    .stop("population is missing core field(s): ", paste(missing, collapse = ", "))
  }
  n <- length(population$id)
  for (field in fields) {
    column <- population[[field]]
    if (!is.atomic(column) || is.null(column) || !is.null(dim(column))) {
      .stop("population field ", field, " must be an atomic vector")
    }
    if (length(column) != n) {
      .stop("population field ", field, " has length ", length(column), ", expected ", n)
    }
  }
  for (field in names(.core_field_types)) {
    if (!identical(typeof(population[[field]]), .core_field_types[[field]])) {
      .stop(
        "population field ", field, " must have type ",
        .core_field_types[[field]]
      )
    }
  }
  for (field in c("id", "sex", "age", "alive", "origin", "entry_time")) {
    if (anyNA(population[[field]])) {
      .stop("population field ", field, " cannot contain missing values")
    }
  }
  if (n) {
    if (anyDuplicated(population$id) || any(population$id < 1L)) {
      .stop("population id values must be unique positive integers")
    }
    if (is.unsorted(population$id)) {
      .stop("population records must be in increasing id order")
    }
    if (!all(population$sex %in% c("F", "M"))) {
      .stop("population sex must be 'F' or 'M'")
    }
    if (any(population$age < 0L)) {
      .stop("population age must be non-negative")
    }
    if (!all(population$origin %in% c("initial", "birth", "introduction"))) {
      .stop("population origin must be 'initial', 'birth' or 'introduction'")
    }
  }
  has_F <- "pedigree_F" %in% fields
  if (!is.null(pedigree) && pedigree != has_F) {
    .stop("pedigree_F must be present exactly when pedigree tracking is enabled")
  }
  if (has_F) {
    coefficient <- population$pedigree_F
    if (!is.double(coefficient) || anyNA(coefficient) ||
        any(coefficient < 0 | coefficient > 1)) {
      .stop("pedigree_F must be a non-missing double in [0, 1]")
    }
  }
  population
}

pva_state <- function(
    population,
    globals = list(),
    pedigree = FALSE,
    kinship = NULL,
    max_dense_kinship = 2000L) {
  if (inherits(population, "pva_state")) {
    .stop("population is already a pva_state")
  }
  if (!.is_flag(pedigree)) {
    .stop("pedigree must be TRUE or FALSE")
  }
  if (!is.null(kinship) && !pedigree) {
    .stop("kinship can be supplied only when pedigree = TRUE")
  }
  max_dense_kinship <- .as_count(max_dense_kinship, "max_dense_kinship", minimum = 1L)
  population <- .as_population(population)
  if ("pedigree_F" %in% names(population)) {
    .stop("pedigree_F is engine-owned; request it with pedigree = TRUE")
  }
  if (!all(population$alive)) {
    .stop("the initial population can contain living individuals only")
  }
  if (!is.list(globals) ||
      (length(globals) && (is.null(names(globals)) || any(!nzchar(names(globals))) ||
        anyDuplicated(names(globals))))) {
    .stop("globals must be a uniquely named list")
  }
  n <- length(population$id)
  state <- list(
    population = population,
    globals = globals,
    next_id = if (n) max(population$id) + 1L else 1L,
    kinship = NULL,
    max_dense_kinship = max_dense_kinship
  )
  if (pedigree) {
    if (!is.null(kinship)) {
      .validate_kinship(kinship, n)
      state$kinship <- if (n > max_dense_kinship) {
        .ancestry_base(population$id, unname(kinship))
      } else unname(kinship)
      state$population$pedigree_F <- 2 * diag(kinship) - 1
    } else if (n <= max_dense_kinship && all(is.na(population$mother_id)) &&
               all(is.na(population$father_id))) {
      state$kinship <- diag(0.5, n, n)
      state$population$pedigree_F <- numeric(n)
    } else {
      ancestry <- .initial_ancestry(population)
      state$kinship <- if (n > max_dense_kinship) ancestry else .ancestry_matrix(ancestry, population$id)
      state$population$pedigree_F <- ancestry$F[match(population$id, ancestry$id)]
    }
  }
  class(state) <- "pva_state"
  state
}

.validate_kinship <- function(kinship, n) {
  if (!is.matrix(kinship) || !is.double(kinship) || !identical(dim(kinship), c(n, n))) {
    .stop("kinship must be a double matrix with one row and column per living individual")
  }
  error <- "kinship must be symmetric, in [0, 1], with self-kinship of at least 0.5"
  if (n) {
    if (anyNA(kinship) || min(kinship) < 0 || max(kinship) > 1 || min(diag(kinship)) < 0.5) {
      .stop(error)
    }
    # Check a supplied founder block without constructing another full matrix.
    for (first in seq.int(1L, n, by = 128L)) {
      block <- seq.int(first, min(n, first + 127L))
      delta <- kinship[, block, drop = FALSE] - t(kinship[block, , drop = FALSE])
      if (max(abs(delta)) > 100 * .Machine$double.eps) .stop(error)
    }
  }
  invisible(kinship)
}

.validate_state <- function(state) {
  if (!inherits(state, "pva_state") ||
      !identical(names(state), c("population", "globals", "next_id", "kinship", "max_dense_kinship"))) {
    .stop("state must be created by pva_state()")
  }
  pedigree <- !is.null(state$kinship)
  .validate_population(state$population, pedigree = pedigree)
  n <- length(state$population$id)
  if (!is.integer(state$next_id) || length(state$next_id) != 1L ||
      is.na(state$next_id) || (n && state$next_id <= max(state$population$id))) {
    .stop("state next_id must exceed every allocated id")
  }
  if (is.matrix(state$kinship)) {
    .validate_kinship(state$kinship, n)
  } else if (pedigree && !is.list(state$kinship)) {
    .stop("invalid pedigree store")
  }
  state
}

print.pva_state <- function(x, ...) {
  cat(sprintf(
    "<pva_state | living: %d | fields: %s | globals: %d | pedigree: %s>\n",
    sum(x$population$alive),
    paste(names(x$population), collapse = ", "),
    length(x$globals),
    if (is.null(x$kinship)) "off" else "exact"
  ))
  invisible(x)
}

add_individuals <- function(
    state,
    sex,
    age,
    ...,
    mother_id = NA_integer_,
    father_id = NA_integer_) {
  population <- state$population
  n <- length(sex)
  if (!n) {
    return(state)
  }
  extra <- list(...)
  fields <- names(population)
  user_fields <- fields[is.na(match(fields, .reserved_fields))]
  supplied <- names(extra)
  if (!identical(supplied, user_fields) &&
      (!setequal(supplied, user_fields) || anyDuplicated(supplied))) {
    .stop(
      "new individuals must initialise exactly these fields: ",
      if (length(user_fields)) paste(user_fields, collapse = ", ") else "(none)",
      "; received: ",
      if (length(extra)) paste(names(extra), collapse = ", ") else "(none)"
    )
  }
  if (state$next_id > .Machine$integer.max - n) {
    .stop("the id allocator would overflow")
  }
  recycle <- function(value, label) {
    if (length(value) == 1L) {
      return(rep(value, n))
    }
    if (length(value) != n) {
      .stop("new field ", label, " must have length 1 or one value per new individual")
    }
    value
  }
  new <- c(
    list(
      id = seq.int(state$next_id, length.out = n),
      sex = as.character(sex),
      age = .whole_field(recycle(age, "age"), "age"),
      alive = rep(TRUE, n),
      mother_id = .whole_field(recycle(mother_id, "mother_id"), "mother_id"),
      father_id = .whole_field(recycle(father_id, "father_id"), "father_id"),
      origin = rep(NA_character_, n),
      entry_time = rep(NA_integer_, n)
    ),
    Map(recycle, extra, names(extra))
  )
  if (!is.null(state$kinship)) {
    new$pedigree_F <- rep(NA_real_, n)
  }
  for (field in names(population)) {
    if (!identical(typeof(new[[field]]), typeof(population[[field]]))) {
      .stop(
        "new field ", field, " has type ", typeof(new[[field]]),
        ", expected ", typeof(population[[field]])
      )
    }
    population[[field]] <- c(population[[field]], new[[field]])
  }
  state$population <- population
  state$next_id <- state$next_id + n
  state
}
