patch_counts <- function(pop, patches, field = "patch_id") {
  if (!.is_name(field) || is.null(pop[[field]])) {
    .stop("pop must contain the patch field ", field)
  }
  if (!length(patches) || anyNA(patches) || anyDuplicated(patches)) {
    .stop("patches must be unique non-missing patch identifiers")
  }
  location <- match(pop[[field]], patches)
  if (anyNA(location)) {
    .stop("an individual occupies a patch outside the declared patches")
  }
  counts <- tabulate(location, nbins = length(patches))
  names(counts) <- as.character(patches)
  counts
}

dispersal_process <- function(
    destination,
    patches,
    eligible = NULL,
    field = "patch_id",
    name = "dispersal",
    requires = character(),
    params = list()) {
  if (!is.function(destination)) {
    .stop("destination must be a function of (rows, pop, state, context, params)")
  }
  .check_optional_function(eligible, "eligible")
  if (!length(patches) || anyNA(patches) || anyDuplicated(patches)) {
    .stop("patches must be unique non-missing patch identifiers")
  }
  if (!.is_name(field)) {
    .stop("field must be one non-empty name")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      rows <- .eligible_rows(params$eligible, pop, state, context, params$user)
      events <- pva_events("dispersal", 0L)
      if (length(rows)) {
        origin <- pop[[params$field]][rows]
        from <- match(origin, params$patches)
        if (anyNA(from)) .stop("an individual occupies a patch outside the declared patches")
        target <- params$destination(rows, pop, state, context, params$user)
        if (length(target) != length(rows) || anyNA(target) ||
            !all(target %in% params$patches)) {
          .stop("destination must return one declared patch per eligible individual")
        }
        route <- paste(from, match(target, params$patches))
        first <- !duplicated(route)
        counts <- tabulate(match(route, route[first]))
        events <- pva_events(
          c("dispersal", rep("patch_transition", length(counts))),
          c(sum(target != origin), counts),
          origin_patch_id = c(NA_character_, as.character(origin[first])),
          destination_patch_id = c(NA_character_, as.character(target[first]))
        )
        state$population[[params$field]][rows] <- target
      }
      pva_result(state, events)
    },
    params = list(
      destination = destination,
      patches = patches,
      eligible = eligible,
      field = field,
      user = params
    ),
    requires = unique(c(paste0("population.", field), requires)),
    writes = paste0("population.", field),
    description = "Move eligible individuals among discrete patches."
  )
}

markov_dispersal_process <- function(
    transition,
    eligible = NULL,
    field = "patch_id",
    name = "dispersal",
    requires = character()) {
  if (!is.matrix(transition) || !is.numeric(transition) ||
      nrow(transition) != ncol(transition) || is.null(rownames(transition)) ||
      !identical(rownames(transition), colnames(transition)) ||
      anyNA(transition) || any(transition < 0) ||
      any(abs(rowSums(transition) - 1) > 1e-12)) {
    .stop("transition must be a square row-stochastic matrix with matching patch dimnames")
  }
  patches <- rownames(transition)
  dispersal_process(
    destination = function(rows, pop, state, context, params) {
      origin <- match(as.character(pop[[field]][rows]), patches)
      target <- origin
      for (patch in unique(origin)) {
        here <- which(origin == patch)
        target[here] <- sample.int(
          length(patches), length(here), replace = TRUE, prob = transition[patch, ]
        )
      }
      out <- patches[target]
      if (!is.character(pop[[field]])) {
        storage.mode(out) <- typeof(pop[[field]])
      }
      out
    },
    patches = patches,
    eligible = eligible,
    field = field,
    name = name,
    requires = requires
  )
}
