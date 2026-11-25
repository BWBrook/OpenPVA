# The small-population store is an ordinary R value. Copy-on-modify isolates
# callbacks, and strict transition validation catches unauthorised writes.
.dense_store <- function(kinship, ids, limit) {
  n <- length(ids)
  capacity <- min(limit, max(16L, ceiling(1.25 * n)))
  values <- matrix(0, capacity, capacity)
  if (n) values[seq_len(n), seq_len(n)] <- kinship
  list(values = values, ids = c(ids, rep(NA_integer_, capacity - n)),
       pending = NULL, retained = integer())
}

.dense_materialise <- function(store, limit) {
  pending <- store$pending
  n <- length(pending$id)
  ids <- store$ids
  if (n) {
    values <- store$values
    occupied <- which(!is.na(ids))
    capacity <- length(ids)
    needed <- length(occupied) + n
    if (needed > capacity) {
      grown <- min(limit, max(ceiling(1.5 * capacity), needed))
      larger <- matrix(0, grown, grown)
      larger[seq_len(capacity), seq_len(capacity)] <- values
      values <- larger
      ids <- c(ids, rep(NA_integer_, grown - capacity))
    }
    slots <- which(is.na(ids))[seq_len(n)]
    to_old <- matrix(0, n, length(occupied))
    among <- matrix(0, n, n)
    for (parent in list(pending$mother, pending$father)) {
      k <- which(!is.na(parent))
      to_old[k, ] <- to_old[k, , drop = FALSE] + 0.5 * values[parent[k], occupied, drop = FALSE]
    }
    for (parent in list(pending$mother, pending$father)) {
      k <- which(!is.na(parent))
      among[, k] <- among[, k, drop = FALSE] +
        0.5 * to_old[, match(parent[k], occupied), drop = FALSE]
    }
    diag(among) <- 0.5 * (1 + pending$F)
    values[slots, occupied] <- to_old
    values[occupied, slots] <- t(to_old)
    values[slots, slots] <- 0.5 * (among + t(among))
    ids[slots] <- pending$id
    store$values <- values
  }
  ids[store$retained] <- NA_integer_
  store$ids <- ids
  store$retained <- integer()
  store$pending <- NULL
  store
}

.kinship_births <- function(store, pop, n_before, context, dead_females, limit) {
  new <- seq.int(n_before + 1L, length(pop$id))
  m <- pop$mother_id[new]
  f <- pop$father_id[new]
  existing <- seq_len(n_before)
  females <- pop$sex[existing] == "F"
  ids <- pop$id[existing]
  if (any(!is.na(m) & !m %in% c(ids[females], dead_females)) ||
      any(!is.na(f) & !f %in% c(ids[!females], context$departed_males))) {
    .stop("process '", context$process_name,
          "' supplied an unknown parent ID, non-female mother or non-male father in this interval")
  }
  if (!is.null(store$values)) {
    store <- .dense_materialise(store, limit)
    occupied <- which(!is.na(store$ids))
    if (length(occupied) + length(new) > limit) {
      store <- .ancestry_base(store$ids[occupied], store$values[occupied, occupied, drop = FALSE])
    }
  }
  if (is.null(store$values)) {
    store <- .ancestry_add(store, pop$id[new], match(m, store$id, 0L), match(f, store$id, 0L))
    coefficient <- utils::tail(store$F, length(new))
  } else {
    mother <- match(m, store$ids, incomparables = NA)
    father <- match(f, store$ids, incomparables = NA)
    known <- which(!is.na(mother) & !is.na(father))
    coefficient <- numeric(length(new))
    coefficient[known] <- store$values[cbind(mother[known], father[known])]
    store$pending <- list(id = pop$id[new], mother = mother, father = father, F = coefficient)
  }
  list(store = store, F = coefficient)
}

# Keep all parents available through parturition. After the interval only
# parents needed to resolve pending rows must keep their occupied slots.
.kinship_release <- function(store, dead_ids) {
  if (is.null(store$values) || !length(dead_ids)) return(store)
  pending <- store$pending
  if (length(pending$id)) {
    keep <- !pending$id %in% dead_ids
    store$pending <- if (any(keep)) lapply(pending, `[`, keep) else NULL
  }
  slots <- match(dead_ids, store$ids, 0L)
  slots <- slots[slots != 0L]
  if (length(store$pending$id)) {
    store$retained <- c(store$retained, slots)
  } else {
    store$ids[c(slots, store$retained)] <- NA_integer_
    store$retained <- integer()
  }
  store
}

.open_kinship <- function(state) {
  if (is.matrix(state$kinship)) {
    state$kinship <- .dense_store(state$kinship, state$population$id, state$max_dense_kinship)
  }
  state
}

.close_kinship <- function(state) {
  if (is.list(state$kinship) && !is.null(state$kinship$values)) {
    state$kinship <- kinship_matrix(state)
  }
  state
}

kinship_matrix <- function(state, ids = state$population$id) {
  store <- state$kinship
  if (is.null(store)) .stop("pedigree tracking is not enabled for this state")
  rows <- match(ids, state$population$id)
  if (anyNA(rows) || anyDuplicated(rows)) .stop("ids must identify distinct living individuals")
  if (is.matrix(store)) return(store[rows, rows, drop = FALSE])
  if (is.null(store$values)) return(.ancestry_matrix(store, ids))
  store <- .dense_materialise(store, state$max_dense_kinship)
  slots <- match(ids, store$ids)
  store$values[slots, slots, drop = FALSE]
}

summarise_pedigree <- function(state) {
  state <- .validate_state(state)
  if (is.null(state$kinship)) .stop("pedigree tracking is not enabled for this state")
  n <- length(state$population$id)
  if (!n) {
    return(data.frame(
      n_living = 0L,
      n_founders = 0L,
      mean_inbreeding = NA_real_,
      max_inbreeding = NA_real_,
      mean_kinship = NA_real_,
      gene_diversity = NA_real_
    ))
  }
  coefficient <- state$population$pedigree_F
  founders <- is.na(state$population$mother_id) & is.na(state$population$father_id)
  store <- state$kinship
  mean_kinship <- if (is.list(store) && is.null(store$values)) {
    rows <- match(state$population$id, store$id)
    graph <- .ancestor_graph(store, rows)
    living <- match(rows, graph$rows)
    mean(.graph_covariance(graph, living, living))
  } else {
    mean(kinship_matrix(state))
  }
  data.frame(
    n_living = n,
    n_founders = as.integer(sum(founders)),
    mean_inbreeding = mean(coefficient),
    max_inbreeding = max(coefficient),
    mean_kinship = mean_kinship,
    gene_diversity = 1 - mean_kinship
  )
}

inbreeding_multiplier <- function(inbreeding, lethal_equivalents) {
  if (!is.numeric(inbreeding) || anyNA(inbreeding) || any(inbreeding < 0 | inbreeding > 1)) {
    .stop("inbreeding must be non-missing coefficients in [0, 1]")
  }
  if (!is.numeric(lethal_equivalents) || length(lethal_equivalents) != 1L ||
      !is.finite(lethal_equivalents) || lethal_equivalents < 0) {
    .stop("lethal_equivalents must be one non-negative number")
  }
  exp(-lethal_equivalents * inbreeding)
}

.update_inbreeding_proxy <- function(state, context, params) {
  current <- state$globals[[params$global]]
  if (!is.numeric(current) || length(current) != 1L || !is.finite(current) ||
      current < 0 || current > 1) {
    .stop("initialise globals.", params$global, " with one numeric inbreeding coefficient in [0, 1]")
  }
  size <- params$effective_size(state$population, state, context, params$user)
  rate <- if (is.null(params$migration)) {
    0
  } else {
    params$migration(state$population, state, context, params$user)
  }
  if (!is.numeric(size) || length(size) != 1L || is.na(size) || size < 0 ||
      !is.numeric(rate) || length(rate) != 1L || is.na(rate) || rate < 0 || rate > 1) {
    .stop("inbreeding proxy needs one effective size >= 0 and one migration rate in [0, 1]")
  }
  drift <- if (size > 0) min(1, 1 / (2 * size)) else 0
  drift <- -expm1(log1p(-drift) / params$generation_time)
  state$globals[[params$global]] <-
    (drift + (1 - drift) * current) * (1 - rate)^2
  pva_result(state)
}

inbreeding_proxy_process <- function(
    effective_size,
    generation_time,
    migration = NULL,
    name = "inbreeding_proxy",
    global = "inbreeding_proxy",
    requires = character(),
    params = list()) {
  if (missing(generation_time) || !is.numeric(generation_time) || length(generation_time) != 1L ||
      !is.finite(generation_time) || generation_time <= 0) {
    .stop("generation_time must be explicit and positive, in model intervals")
  }
  if (!is.function(effective_size)) {
    .stop("effective_size must be a function of (pop, state, context, params)")
  }
  if (!is.null(migration) && !is.function(migration)) {
    .stop("migration must be NULL or a function of (pop, state, context, params)")
  }
  if (!.is_name(global)) {
    .stop("global must be one non-empty name")
  }
  pva_process(
    name = name,
    run = .update_inbreeding_proxy,
    params = list(
      effective_size = effective_size,
      generation_time = generation_time,
      migration = migration,
      global = global,
      user = params
    ),
    requires = unique(c(paste0("globals.", global), requires)),
    writes = paste0("globals.", global),
    description = "Update an aggregate expected inbreeding coefficient from effective size."
  )
}

sex_ratio_effective_size <- function(n_females, n_males) {
  if (!is.numeric(n_females) || !is.numeric(n_males) ||
      anyNA(n_females) || anyNA(n_males) || any(n_females < 0) || any(n_males < 0)) {
    .stop("n_females and n_males must be non-negative numbers")
  }
  total <- n_females + n_males
  ifelse(total > 0, 4 * n_females * n_males / pmax(total, 1), 0)
}
