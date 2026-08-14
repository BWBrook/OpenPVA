#' Construct an exogenous introduction process
#'
#' Appends explicitly initialized living individuals at the process's declared
#' lifecycle position. This one primitive can represent immigration,
#' supplementation, stocking or exogenous translocation; its name and biology
#' remain modeller-owned.
#'
#' @param count A fixed non-negative integer-like count, or a function called as
#'   `count(state, context, params)` and returning one such count.
#' @param initializer Function called as
#'   `initializer(index, id, state, context, params)` for each newcomer. It must
#'   return a named list whose fields exactly match `initializer_fields`. Every
#'   call in one execution receives the same pre-process `state`.
#' @param initializer_fields Character vector naming every biological field
#'   returned by `initializer`. `id` and `alive` are engine-owned and cannot be
#'   declared.
#' @param source Non-blank modeller-supplied source or provenance label retained
#'   on every introduction event.
#' @param name Process name, for example `"immigration"` or `"stocking"`.
#' @param group_by Optional subset of `initializer_fields` used to partition
#'   aggregate introduction events. Grouped rows replace the ungrouped total,
#'   so their values sum to the number added without double-counting.
#' @param requires Additional state paths used by `count` or `initializer`.
#' @param params Explicit modeller parameters passed to both callbacks.
#'
#' @return A validated creation process.
#' @export
introduction_process <- function(
    count,
    initializer,
    initializer_fields,
    source,
    name = "introduction",
    group_by = character(),
    requires = character(),
    params = list()) {
  count <- .normalize_introduction_count_spec(count)
  initializer_fields <- .normalize_initializer_fields(initializer_fields)
  source <- .normalize_introduction_source(source)
  group_by <- .normalize_introduction_groups(group_by, initializer_fields)
  if (!is.function(initializer)) {
    stop("initializer must be a function", call. = FALSE)
  }
  if (!is.list(params)) {
    stop("params must be a list", call. = FALSE)
  }

  declared_initializer_fields <- initializer_fields
  pva_process(
    name = name,
    run = function(state, context, process_params) {
      pre_state <- state
      realised_count <- if (is.function(process_params$count)) {
        process_params$count(pre_state, context, process_params$model)
      } else {
        process_params$count
      }
      realised_count <- .normalize_non_negative_count(
        realised_count,
        "count callback result"
      )
      if (!realised_count) {
        return(pva_result(state))
      }

      allocation <- .allocate_ids_trusted(state, realised_count)
      state <- allocation$state
      newcomers <- vector("list", realised_count)
      for (index in seq_len(realised_count)) {
        fields <- process_params$initializer(
          as.integer(index),
          allocation$ids[[index]],
          pre_state,
          context,
          process_params$model
        )
        fields <- .validate_initializer_result(
          fields,
          process_params$initializer_fields
        )
        newcomers[[index]] <- c(
          list(id = allocation$ids[[index]], alive = TRUE),
          fields
        )
      }
      state$population <- c(state$population, newcomers)
      events <- .build_introduction_events(
        newcomers,
        process_params$source,
        process_params$group_by
      )
      pva_result(state, events)
    },
    params = list(
      count = count,
      initializer = initializer,
      initializer_fields = initializer_fields,
      source = source,
      group_by = group_by,
      model = params
    ),
    requires = unique(c("population.id", "next_id", requires)),
    writes = unique(c(
      "population", "next_id", "population.id", "population.alive",
      if (length(initializer_fields)) {
        paste0("population.", initializer_fields)
      } else {
        character()
      }
    )),
    creates = paste0(
      "population.",
      c("id", "alive", initializer_fields)
    ),
    validate_params = function(process_params) {
      .validate_introduction_params(process_params)
      if (!identical(
        process_params$initializer_fields,
        declared_initializer_fields
      )) {
        stop(
          "initializer_fields cannot be changed after process construction",
          call. = FALSE
        )
      }
      invisible(process_params)
    },
    description = "Append explicitly counted and initialized exogenous individuals."
  )
}

.normalize_introduction_count_spec <- function(count) {
  if (is.function(count)) {
    return(count)
  }
  .normalize_non_negative_count(count, "count")
}

.normalize_initializer_fields <- function(fields) {
  if (!is.character(fields) || anyNA(fields) || any(!nzchar(fields)) ||
      any(grepl("\\.", fields))) {
    stop(
      "initializer_fields must be field names without population. prefixes",
      call. = FALSE
    )
  }
  if (anyDuplicated(fields)) {
    stop("initializer_fields must not contain duplicates", call. = FALSE)
  }
  reserved <- intersect(fields, c("id", "alive"))
  if (length(reserved)) {
    stop(
      "initializer_fields cannot override engine introduction fields: ",
      paste(reserved, collapse = ", "),
      call. = FALSE
    )
  }
  fields
}

.normalize_introduction_source <- function(source) {
  if (!is.character(source) || length(source) != 1L || is.na(source) ||
      !nzchar(trimws(source))) {
    stop("source must be a non-blank character scalar", call. = FALSE)
  }
  trimws(source)
}

.normalize_introduction_groups <- function(group_by, initializer_fields) {
  if (!is.character(group_by) || anyNA(group_by) || any(!nzchar(group_by))) {
    stop("group_by must be a character vector of initializer fields", call. = FALSE)
  }
  if (anyDuplicated(group_by)) {
    stop("group_by must not contain duplicates", call. = FALSE)
  }
  unknown <- setdiff(group_by, initializer_fields)
  if (length(unknown)) {
    stop(
      "group_by must contain only declared initializer_fields: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }
  event_fields <- c(
    "event_type", "value", "source", "run", "time", "process_index",
    "process_name", "process_occurrence", "phase"
  )
  reserved <- intersect(group_by, event_fields)
  if (length(reserved)) {
    stop(
      "group_by cannot use event or engine provenance fields: ",
      paste(reserved, collapse = ", "),
      call. = FALSE
    )
  }
  group_by
}

.validate_introduction_params <- function(process_params) {
  required <- c(
    "count", "initializer", "initializer_fields", "source", "group_by",
    "model"
  )
  if (!is.list(process_params) || !all(required %in% names(process_params))) {
    stop("introduction process parameters are incomplete", call. = FALSE)
  }
  .normalize_introduction_count_spec(process_params$count)
  fields <- .normalize_initializer_fields(process_params$initializer_fields)
  if (!is.function(process_params$initializer)) {
    stop("initializer must be a function", call. = FALSE)
  }
  .normalize_introduction_source(process_params$source)
  .normalize_introduction_groups(process_params$group_by, fields)
  if (!is.list(process_params$model)) {
    stop("introduction model params must be a list", call. = FALSE)
  }
  invisible(process_params)
}

.validate_initializer_result <- function(fields, initializer_fields) {
  if (!is.list(fields)) {
    stop("initializer must return a named list", call. = FALSE)
  }
  if (length(fields) &&
      (is.null(names(fields)) || any(!nzchar(names(fields))))) {
    stop("initializer must return a named list", call. = FALSE)
  }
  if (anyDuplicated(names(fields))) {
    stop("initializer cannot return duplicate field names", call. = FALSE)
  }
  unexpected <- setdiff(names(fields), initializer_fields)
  missing <- setdiff(initializer_fields, names(fields))
  if (length(unexpected) || length(missing)) {
    stop(
      "initializer fields must exactly match initializer_fields",
      call. = FALSE
    )
  }
  fields[initializer_fields]
}

.build_introduction_events <- function(newcomers, source, group_by) {
  source <- .normalize_introduction_source(source)
  if (!length(group_by)) {
    return(list(list(
      event_type = "introduction",
      value = as.integer(length(newcomers)),
      source = source
    )))
  }

  groups <- list()
  for (newcomer in newcomers) {
    values <- newcomer[group_by]
    valid <- vapply(values, function(value) {
      is.atomic(value) && length(value) == 1L && !is.na(value)
    }, logical(1))
    if (!all(valid)) {
      stop(
        "group_by fields must be non-missing atomic scalars on every newcomer",
        call. = FALSE
      )
    }
    matching <- which(vapply(groups, function(group) {
      identical(group$values, values)
    }, logical(1)))
    if (length(matching)) {
      group <- matching[[1L]]
      groups[[group]]$value <- groups[[group]]$value + 1L
    } else {
      groups[[length(groups) + 1L]] <- list(values = values, value = 1L)
    }
  }
  lapply(groups, function(group) {
    c(
      list(
        event_type = "introduction",
        value = as.integer(group$value),
        source = source
      ),
      group$values
    )
  })
}
