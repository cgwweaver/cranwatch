# r-universe: scores, score components, detected system libraries -------------
# Bulk requests, not one per package (all cached, see cached_get()):
#   1. ru_index:   global /api/search with no query = every indexed package,
#                  ranked by score, ~5 pages. Gives score, recursive dependents,
#                  scripts, stars + which universe is each package's home.
#                  Used for revdep ranking and to find watched packages.
#   2. ru_detail:  /api/packages?fields=... once per universe that hosts a
#                  watched package (~20). Gives the score's ingredients.
#   3. ru_sysdeps: /api/sysdeps on the cran universe: system library -> packages.
# NB a CRAN package's copy in the `cran` universe isn't its canonical record when
# it has a home universe (e.g. dplyr -> tidyverse: 5 vs 5000 stars), hence 1 -> 2.

ru_url <- function(universe, path) paste0(glue(settings$ru_universe, universe = universe), path)

ru_index_cols <- c(
  package = "Package", universe = "_user", score = "_score",
  dependents = "_usedby", scripts = "_searchresults", stars = "stars"
)

fetch_ru_index <- function() {
  size  <- settings$ru_page_size
  page  <- \(skip) glue("{settings$ru_global}/api/search?limit={size}&skip={skip}") |> cached_get() |> fromJSON()
  first <- page(0)
  skips <- if (first$total > size) seq(size, first$total - 1, by = size) else numeric()

  c(list(first), map(skips, page)) |>
    map(\(p) as_tibble(p$results) |> select(any_of(ru_index_cols))) |>
    list_rbind() |>
    mutate(across(c(score, dependents, scripts, stars), as_num)) |>
    distinct(package, universe, .keep_all = TRUE) # paging by score can repeat ties at page edges
}

# Each watched package's home universe: the one matching the repo owner in
# packages.yml if any, else the highest-scoring package of that name
ru_pick <- function(index, watch) {
  watch |>
    select(package, repo) |>
    inner_join(index, by = "package", relationship = "many-to-many") |>
    mutate(owner_match = coalesce(tolower(universe) == tolower(str_extract(repo, "^[^/]+")), FALSE)) |>
    arrange(desc(owner_match), desc(score)) |>
    distinct(package, .keep_all = TRUE) |>
    select(-repo, -owner_match)
}

ru_detail_fields <- c(
  "_score", "_stars", "_usedby", "_searchresults", "_downloads", "_mentions", "_readme", "_cranurl", "_bioc",
  "_updates", "_contributors.user", "_vignettes.title", "_datasets.name", "_releases.version"
)

fetch_ru_detail <- function(picked) {
  picked |>
    distinct(universe) |>
    pull() |>
    map(\(u) {
      ru_url(u, "/api/packages") |>
        paste0("?stream=true&limit=10000&fields=", paste(ru_detail_fields, collapse = ",")) |>
        cached_get() |>
        readLines(warn = FALSE, encoding = "UTF-8") |>
        keep(\(line) str_extract(line, '^\\{"Package":"([^"]+)"', group = 1) %in% picked$package) |> # parse only ours
        map(\(line) ru_components(fromJSON(line, simplifyVector = FALSE))) |>
        list_rbind() |>
        semi_join(picked, by = c("package", "universe"))
    }) |>
    list_rbind()
}

# One package record -> the numbers r-universe's score is built from
ru_components <- function(doc) {
  n      <- \(x) length(x %||% list())
  num    <- \(x) as_num(x %||% NA)
  truthy <- \(x) !is.null(x) && !identical(x, FALSE) && !identical(x, "") # JavaScript truthiness

  tibble(
    package      = doc$Package,
    universe     = doc$`_user`,
    score        = num(doc$`_score`),
    stars        = num(doc$`_stars`),
    dependents   = num(doc$`_usedby`),
    scripts      = num(doc$`_searchresults`),
    downloads    = num(doc$`_downloads`$count),
    mentions     = num(doc$`_mentions`),
    update_weeks = n(doc$`_updates`),
    commits      = sum(map_dbl(doc$`_updates` %||% list(), \(u) num(u$n))),
    contributors = n(doc$`_contributors`),
    vignettes    = n(doc$`_vignettes`),
    datasets     = n(doc$`_datasets`),
    releases     = n(doc$`_releases`),
    on_cran      = truthy(doc$`_cranurl`) || truthy(doc$`_bioc`),
    readme       = truthy(doc$`_readme`)
  )
}

# r-universe's calculate_score() (r-universe-org/frontend, routes/packages.js),
# term by term: score = 1 + rowSums(ru_score_parts(df)). Each ingredient is
# log10-scaled and weighted relative to GitHub stars ("1 revdep ~ 3 stars"),
# so 10 stars = 1 point, 100 stars = 2 points, ...
# Datasets are meant to count too, but a bug upstream means they never do.
# prefix = "ru_" for snapshot columns.
ru_score_parts <- function(df, prefix = "") {
  col <- \(x) df[[paste0(prefix, x)]]
  pts <- \(x) log10(pmax(1, coalesce(as.numeric(x), 0)))

  tibble(
    stars        = pts(col("stars")),
    dependents   = pts(col("dependents") * 3),
    scripts      = pts(col("scripts") / 10),
    vignettes    = pts(col("vignettes") * 10),
    activity     = pts(col("update_weeks")),
    contributors = pts(col("contributors") - 1),
    cran         = pts(if_else(col("on_cran") %in% TRUE, 10, 0)),
    readme       = pts(if_else(col("readme") %in% TRUE, 5, 0)),
    downloads    = pts(col("downloads") / 1000),
    mentions     = pts(pmin(col("mentions"), 10))
  )
}

# Share of packages where our recomputed score matches r-universe's: < 1 means
# they changed the formula and ru_score_parts() needs updating
ru_formula_match <- function(detail) {
  if (!nrow(detail)) return(NA_real_)
  mean(abs(1 + rowSums(ru_score_parts(detail)) - detail$score) < 0.01, na.rm = TRUE)
}

# One row per watched package found on r-universe: ingredients from ru_detail
# where we have them, else the headline numbers from the index
ru_metrics <- function(index, detail, watch) {
  if (is.null(index)) return(tibble(package = character(), ru_universe = character()))
  picked <- ru_pick(index, watch)
  detail <- detail %||% tibble(package = character(), universe = character())

  bind_rows(detail |> semi_join(picked, by = c("package", "universe")), picked) |>
    distinct(package, .keep_all = TRUE) |>
    rename_with(\(x) paste0("ru_", x), -package)
}

# NDJSON, one line per system library: {library, usedby: [{owner, package}], ...}
fetch_ru_sysdeps <- function() {
  ru_url("cran", "/api/sysdeps?stream=true") |>
    cached_get() |>
    readLines(warn = FALSE, encoding = "UTF-8") |>
    discard(\(line) line == "") |>
    map(parse_sysdep_line) |>
    list_rbind() |>
    distinct()
}

parse_sysdep_line <- function(line) {
  j <- fromJSON(line)
  tibble(library = j$library %||% NA_character_, package = j$usedby$package %||% character())
}
