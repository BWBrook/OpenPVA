.rate_function <- function(value, label) {
  if (is.function(value)) {
    return(value)
  }
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    .stop(label, " must be one finite number or a function of (pop, state, context, params)")
  }
  force(value)
  function(pop, state, context, params) value
}

.per_individual <- function(value, n, label, lower = -Inf, upper = Inf) {
  if (n == 0L && length(value) <= 1L) {
    return(numeric())
  }
  if (length(value) == 1L) {
    value <- rep(value, n)
  }
  if (!is.numeric(value) || length(value) != n || any(!is.finite(value)) ||
      any(value < lower | value > upper)) {
    .stop(
      label, " must return one non-missing value per individual in [",
      lower, ", ", upper, "]"
    )
  }
  value
}

.eligible_rows <- function(eligible, pop, state, context, params) {
  n <- length(pop$id)
  if (is.null(eligible)) {
    return(seq_len(n))
  }
  flag <- eligible(pop, state, context, params)
  if (length(flag) == 1L) {
    flag <- rep(flag, n)
  }
  if (!is.logical(flag) || length(flag) != n || anyNA(flag)) {
    .stop("eligible must return one non-missing logical value per individual")
  }
  which(flag)
}

.check_optional_function <- function(value, label) {
  if (!is.null(value) && !is.function(value)) {
    .stop(label, " must be NULL or a function")
  }
  invisible(value)
}

age_process <- function(name = "age", increment = 1L) {
  increment <- .as_count(increment, "increment", minimum = 1)
  pva_process(
    name = name,
    run = function(state, context, params) {
      state$population$age <- state$population$age + params$increment
      pva_result(state)
    },
    params = list(increment = increment),
    requires = "population.age",
    writes = "population.age",
    description = "Advance the age of every living individual."
  )
}

survival_process <- function(
    probability,
    eligible = NULL,
    cause = "natural",
    name = "survival",
    requires = character(),
    params = list()) {
  probability <- .rate_function(probability, "probability")
  .check_optional_function(eligible, "eligible")
  if (!.is_name(cause)) {
    .stop("cause must be one non-empty character value")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      rows <- .eligible_rows(params$eligible, pop, state, context, params$user)
      survive <- .per_individual(
        params$probability(pop, state, context, params$user),
        length(pop$id), "survival probability", 0, 1
      )
      died <- rows[stats::runif(length(rows)) >= survive[rows]]
      if (length(died)) {
        state$population$alive[died] <- FALSE
      }
      pva_result(state, pva_events("death", length(died), params$cause))
    },
    params = list(
      probability = probability,
      eligible = eligible,
      cause = cause,
      user = params
    ),
    requires = unique(c("population.alive", requires)),
    writes = "population.alive",
    description = "Independent Bernoulli survival of eligible individuals."
  )
}

litter_poisson <- function(mean) {
  mean <- .rate_function(mean, "mean")
  function(mothers, pop, state, context, params) {
    expected <- .per_individual(
      mean(pop, state, context, params), length(pop$id), "litter mean", 0
    )
    stats::rpois(length(mothers), expected[mothers])
  }
}

litter_binomial <- function(size, mean, min_size = 0L) {
  size <- .as_count(size, "size", minimum = 1)
  min_size <- .as_count(min_size, "min_size")
  if (min_size > size) {
    .stop("min_size cannot exceed size")
  }
  if (!is.function(mean)) {
    .per_individual(mean, 1L, "litter mean", min_size, size)
  }
  mean <- .rate_function(mean, "mean")
  function(mothers, pop, state, context, params) {
    expected <- .per_individual(
      mean(pop, state, context, params), length(pop$id), "litter mean", 0
    )[mothers]
    if (any(expected < min_size | expected > size)) {
      .stop("litter mean for each breeding female must lie between min_size and size")
    }
    if (size == min_size) {
      return(rep(min_size, length(mothers)))
    }
    min_size + stats::rbinom(length(mothers), size - min_size,
                             (expected - min_size) / (size - min_size))
  }
}

litter_categorical <- function(sizes, probabilities) {
  if (!is.numeric(sizes) || !length(sizes) || any(!is.finite(sizes)) ||
      any(sizes < 0 | sizes > .Machine$integer.max) ||
      any(sizes != floor(sizes)) || anyDuplicated(sizes)) {
    .stop("sizes must be unique non-negative whole numbers")
  }
  if (!is.numeric(probabilities) || length(probabilities) != length(sizes) ||
      anyNA(probabilities) || any(probabilities < 0) ||
      abs(sum(probabilities) - 1) > 1e-12) {
    .stop("probabilities must be non-negative, match sizes and sum to 1")
  }
  sizes <- as.integer(sizes)
  function(mothers, pop, state, context, params) {
    sizes[sample.int(length(sizes), length(mothers), replace = TRUE, prob = probabilities)]
  }
}

offspring_sex_bernoulli <- function(female_probability = 0.5) {
  if (!is.numeric(female_probability) || length(female_probability) != 1L ||
      is.na(female_probability) || female_probability < 0 || female_probability > 1) {
    .stop("female_probability must be one number in [0, 1]")
  }
  function(mothers, pop, state, context, params) {
    ifelse(stats::runif(length(mothers)) < female_probability, "F", "M")
  }
}

mate_random <- function(eligible) {
  if (!is.function(eligible)) {
    .stop("eligible must be a function of (pop, state, context, params)")
  }
  function(pop, state, context, params) {
    n <- length(pop$id)
    males <- .eligible_rows(eligible, pop, state, context, params)
    males <- males[pop$sex[males] == "M"]
    if (!length(males)) {
      return(rep(NA_integer_, n))
    }
    males[sample.int(length(males), n, replace = TRUE)]
  }
}

mate_from_field <- function(field = "mate_id") {
  if (!.is_name(field)) {
    .stop("field must be one non-empty name")
  }
  lookup <- function(pop, state, context, params) {
    ids <- pop[[field]]
    if (!is.numeric(ids) || length(ids) != length(pop$id) || any(is.nan(ids)) ||
        any(ids < 1L | ids > .Machine$integer.max | ids != floor(ids), na.rm = TRUE)) {
      .stop("mate field must contain positive integer IDs or NA")
    }
    match(ids, pop$id)
  }
  attr(lookup, "mate_field") <- field
  lookup
}

reproduction_process <- function(
    breeding_probability,
    litter_size,
    offspring_sex,
    mate = NULL,
    require_mate = !is.null(mate),
    newborn_fields = NULL,
    newborn_field_names = character(),
    inherit = character(),
    name = "reproduction",
    requires = character(),
    params = list()) {
  breeding_probability <- .rate_function(breeding_probability, "breeding_probability")
  if (!is.function(litter_size)) {
    .stop("litter_size must be a function, for example litter_poisson()")
  }
  if (!is.function(offspring_sex)) {
    .stop("offspring_sex must be a function, for example offspring_sex_bernoulli()")
  }
  .check_optional_function(mate, "mate")
  mate_field <- attr(mate, "mate_field", exact = TRUE)
  .check_optional_function(newborn_fields, "newborn_fields")
  if (!.is_flag(require_mate)) {
    .stop("require_mate must be TRUE or FALSE")
  }
  if (require_mate && is.null(mate)) {
    .stop("require_mate = TRUE needs a mate function")
  }
  newborn_field_names <- .field_names(newborn_field_names, "newborn_field_names")
  inherit <- .field_names(inherit, "inherit")
  reserved <- c(names(.core_field_types), "pedigree_F")
  if (any(c(newborn_field_names, inherit) %in% reserved) ||
      length(intersect(newborn_field_names, inherit))) {
    .stop("newborn_field_names and inherit must be distinct non-core fields")
  }
  if (length(newborn_field_names) && is.null(newborn_fields)) {
    .stop("newborn_field_names needs a newborn_fields function")
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      user <- params$user
      n <- length(pop$id)
      probability <- .per_individual(
        params$breeding_probability(pop, state, context, user),
        n, "breeding probability", 0, 1
      )
      father <- if (is.null(params$mate)) {
        rep(NA_integer_, n)
      } else {
        params$mate(pop, state, context, user)
      }
      if (length(father) != n || !is.null(dim(father)) ||
          !(is.numeric(father) || (is.logical(father) && all(is.na(father)))) ||
          any(is.nan(father)) ||
          any(father < 1L | father > n | father != floor(father), na.rm = TRUE)) {
        .stop("mate must return one valid whole-number row index (or NA) per individual")
      }
      female <- pop$sex == "F"
      if (any(female & !is.na(father) & pop$sex[as.integer(father)] != "M")) {
        .stop("mate returned a row that is not male for a female")
      }
      father_id <- pop$id[as.integer(father)]
      if (!is.null(params$mate_field)) {
        recorded <- pop[[params$mate_field]]
        absent <- female & is.na(father) & !is.na(recorded)
        if (any(absent)) {
          if (!all(recorded[absent] %in% context$departed_males)) {
            .stop("recorded sire must be a living male or one lost earlier in this interval")
          }
          father_id[absent] <- recorded[absent]
        }
      }
      candidates <- which(female & probability > 0)
      if (params$require_mate) {
        candidates <- candidates[!is.na(father_id[candidates])]
      }
      breeders <- candidates[stats::runif(length(candidates)) < probability[candidates]]
      litter <- if (length(breeders)) {
        params$litter_size(breeders, pop, state, context, user)
      } else {
        integer()
      }
      if (!is.numeric(litter) || !is.null(dim(litter)) || length(litter) != length(breeders) ||
          any(!is.finite(litter)) || any(litter < 0 | litter != floor(litter)) ||
          sum(litter) > .Machine$integer.max - state$next_id) {
        .stop("litter_size must return one finite, non-negative integer per breeding female within the ID limit")
      }
      mothers <- rep(breeders, litter)
      n_born <- length(mothers)
      if (n_born) {
        fathers <- father[mothers]
        extra <- if (is.null(params$newborn_fields)) {
          list()
        } else {
          params$newborn_fields(mothers, fathers, pop, state, context, user)
        }
        if (!setequal(names(extra), params$newborn_field_names)) {
          .stop("newborn_fields must return exactly the declared newborn_field_names")
        }
        inherited <- lapply(pop[params$inherit], `[`, mothers)
        state <- do.call(add_individuals, c(
          list(
            state,
            sex = params$offspring_sex(mothers, pop, state, context, user),
            age = 0L,
            mother_id = pop$id[mothers],
            father_id = father_id[mothers]
          ),
          extra,
          inherited
        ))
      }
      pva_result(
        state,
        pva_events(c("birth", "breeding_females"), c(n_born, length(breeders)))
      )
    },
    params = list(
      breeding_probability = breeding_probability,
      litter_size = litter_size,
      offspring_sex = offspring_sex,
      mate = mate,
      mate_field = mate_field,
      require_mate = require_mate,
      newborn_fields = newborn_fields,
      newborn_field_names = newborn_field_names,
      inherit = inherit,
      user = params
    ),
    requires = unique(c("population.sex", "population.alive",
                        if (!is.null(mate_field)) paste0("population.", mate_field), requires)),
    writes = character(),
    creates = c("sex", "age", "mother_id", "father_id", newborn_field_names, inherit),
    description = "Bernoulli breeding, a modeller-chosen litter distribution and explicit offspring sex."
  )
}

census_process <- function(
    metrics = NULL,
    name = "census",
    requires = character(),
    params = list()) {
  .check_optional_function(metrics, "metrics")
  if (is.null(metrics)) {
    metrics <- function(pop, state, context, params) {
      c(
        n_alive = length(pop$id),
        n_female = sum(pop$sex == "F"),
        n_male = sum(pop$sex == "M")
      )
    }
  }
  pva_process(
    name = name,
    run = function(state, context, params) {
      pva_result(
        state,
        census = params$metrics(state$population, state, context, params$user)
      )
    },
    params = list(metrics = metrics, user = params),
    requires = unique(c("population.sex", "population.alive", requires)),
    description = "Non-mutating census; its position in the lifecycle defines what it observes."
  )
}

staged_survival_process <- function(
    probability,
    post_share,
    stage = c("pre", "post"),
    field = "survival_draw",
    cause = "natural",
    name = paste0("survival_", stage),
    requires = character(),
    params = list()) {
  stage <- match.arg(stage)
  probability <- .rate_function(probability, "probability")
  if (!is.numeric(post_share) || length(post_share) != 1L || is.na(post_share) ||
      post_share < 0 || post_share > 1) {
    .stop("post_share must be one number in [0, 1]")
  }
  if (!.is_name(field) || !.is_name(cause)) {
    .stop("field and cause must each be one non-empty character value")
  }
  path <- paste0("globals.", field)
  pva_process(
    name = name,
    run = function(state, context, params) {
      pop <- state$population
      n <- length(pop$id)
      annual <- .per_individual(
        params$probability(pop, state, context, params$user),
        n, "survival probability", 0, 1
      )
      previous <- state$globals[[params$field]]
      if (params$stage == "pre") {
        if (!is.null(previous)) {
          .stop("pre-stage needs an unused global named ", params$field)
        }
        draw <- stats::runif(n)
        threshold <- annual^(1 - params$post_share)
        survived <- draw < threshold
        died <- which(!survived)
        state$globals[[params$field]] <- list(
          id = pop$id[survived], share = params$post_share, rate = annual[survived],
          residual = draw[survived] / threshold[survived],
          whole = draw[survived] < annual[survived]
        )
      } else {
        if (is.null(previous$share) || previous$share != params$post_share) {
          .stop("post-stage needs a matching pre-stage with the same field and post_share")
        }
        index <- match(pop$id, previous$id)
        fresh <- is.na(index)
        draw <- previous$residual[index]
        draw[fresh] <- stats::runif(sum(fresh))
        survived <- draw < annual^params$post_share
        # Preserve U < s exactly, including ties at representable probabilities.
        same <- !fresh & annual == previous$rate[index]
        survived[same] <- previous$whole[index[same]]
        died <- which(!survived)
        state$globals[[params$field]] <- NULL
      }
      if (length(died)) {
        state$population$alive[died] <- FALSE
      }
      pva_result(state, pva_events("death", length(died), params$cause))
    },
    params = list(
      probability = probability,
      post_share = post_share,
      stage = stage,
      field = field,
      cause = cause,
      user = params
    ),
    requires = unique(c("population.alive", if (stage == "post") path, requires)),
    writes = c("population.alive", path),
    description = "One stage of an interval's survival split around a mid-interval event."
  )
}
