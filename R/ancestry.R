# Row indices follow pedigree order. Zero denotes an unrecorded, unrelated
# parent. A supplied founder block can contain arbitrary starting kinships.
.ancestry_base <- function(ids, base = NULL) {
  n <- length(ids)
  diagonal <- if (is.null(base)) rep(0.5, n) else diag(base)
  related <- integer()
  if (!is.null(base)) {
    related <- which(vapply(seq_len(n), function(j) sum(base[, j] != 0) > 1L, logical(1)))
    if (length(related) < n) base <- base[related, related, drop = FALSE]
  }
  residual <- diagonal
  residual[related] <- 0
  list(id = ids, mother = integer(n), father = integer(n), F = 2 * diagonal - 1,
       d = residual, related = related, base = base)
}

.ancestor_graph <- function(ped, rows) {
  active <- frontier <- unique(rows)
  while (length(frontier)) {
    parents <- unique(c(ped$mother[frontier], ped$father[frontier]))
    frontier <- setdiff(parents[parents != 0L], active)
    active <- c(active, frontier)
  }
  active <- sort.int(active)
  nil <- length(active) + 1L
  mother <- match(ped$mother[active], active, nil)
  father <- match(ped$father[active], active, nil)
  index <- match(active, ped$related, 0L)
  base <- which(index > 0L)
  list(rows = active, mother = mother, father = father,
       children = which(mother != nil | father != nil), d = ped$d[active],
       base = base, base_K = ped$base[index[base], index[base], drop = FALSE])
}

# K = T D T'. Trace the source's inherited contributions back through T',
# apply the founder covariance and Mendelian sampling variances D, then
# propagate covariance forward through T. Only ancestors of the query occur.
.graph_covariance <- function(graph, source, target) {
  n <- length(graph$rows)
  weight <- numeric(n + 1L)
  weight[source] <- 1 / length(source)
  for (i in rev(graph$children)) {
    half <- 0.5 * weight[i]
    m <- graph$mother[i]
    f <- graph$father[i]
    weight[m] <- weight[m] + half
    weight[f] <- weight[f] + half
  }
  value <- c(graph$d * weight[seq_len(n)], 0)
  b <- graph$base
  if (length(b)) value[b] <- graph$base_K %*% weight[b]
  for (i in graph$children) {
    value[i] <- value[i] + 0.5 * (value[graph$mother[i]] + value[graph$father[i]])
  }
  value[target]
}

.ancestry_pairs <- function(ped, mother, father) {
  out <- numeric(length(mother))
  known <- which(mother > 0L & father > 0L)
  if (!length(known)) return(out)
  m <- mother[known]
  f <- father[known]
  root <- ped$mother == 0L & ped$father == 0L
  if (length(ped$related)) {
    i <- match(m, ped$related, 0L)
    j <- match(f, ped$related, 0L)
    base <- which(i != 0L & j != 0L)
    out[known[base]] <- ped$base[cbind(i[base], j[base])]
  }
  same <- m == f
  out[known[same]] <- 0.5 * (1 + ped$F[m[same]])
  query <- known[!same & !(root[m] & root[f])]
  for (group in split(query, mother[query])) {
    dam <- mother[group[1L]]
    sires <- unique(father[group])
    graph <- .ancestor_graph(ped, c(dam, sires))
    kin <- .graph_covariance(graph, match(dam, graph$rows), match(sires, graph$rows))
    out[group] <- kin[match(father[group], sires)]
  }
  out
}

.ancestry_add <- function(ped, ids, mother, father) {
  coefficient <- .ancestry_pairs(ped, mother, father)
  self <- c(0, 0.5 * (1 + ped$F))
  ped$d <- c(ped$d, 0.5 - 0.25 * (self[mother + 1L] + self[father + 1L]))
  ped$id <- c(ped$id, ids)
  ped$mother <- c(ped$mother, mother)
  ped$father <- c(ped$father, father)
  ped$F <- c(ped$F, coefficient)
  ped
}

.ancestry_matrix <- function(ped, ids) {
  rows <- match(ids, ped$id)
  graph <- .ancestor_graph(ped, rows)
  local <- match(rows, graph$rows)
  n <- length(rows)
  out <- matrix(0, n, n)
  for (i in seq_len(n)) out[, i] <- .graph_covariance(graph, local[i], local)
  out
}

.initial_ancestry <- function(pop) {
  n <- length(pop$id)
  m <- match(pop$mother_id, pop$id, 0L)
  f <- match(pop$father_id, pop$id, 0L)
  if (any(m == 0L & !is.na(pop$mother_id)) || any(f == 0L & !is.na(pop$father_id))) {
    .stop("unresolvable initial parent ID: supply an aligned initial kinship matrix")
  }
  if (any(pop$sex[m] != "F") || any(pop$sex[f] != "M")) {
    .stop("initial parentage has a non-female mother or non-male father")
  }
  rows <- which(m == 0L & f == 0L)
  ped <- .ancestry_base(pop$id[rows])
  position <- integer(n)
  position[rows] <- seq_along(rows)
  while (length(ped$id) < n) {
    lookup <- c(0L, position)
    mother <- lookup[m + 1L]
    father <- lookup[f + 1L]
    rows <- which(position == 0L & (m == 0L | mother > 0L) & (f == 0L | father > 0L))
    if (!length(rows)) .stop("cyclic initial parentage: supply an aligned initial kinship matrix")
    position[rows] <- length(ped$id) + seq_along(rows)
    ped <- .ancestry_add(ped, pop$id[rows], mother[rows], father[rows])
  }
  ped
}
