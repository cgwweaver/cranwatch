# r-universe: scores (+ components) and detected system libraries -------------
# /api/scores is global (ignores the universe in the URL): every indexed package
# across r-universe, ~1 request. Score formula (cranlike-server, routes/packages.js):
#   1 + sum(log10(max(1, x))) over stars, 3*dependents, scripts/10, 10*vignettes,
#   weeks with commits, contributors-1, 10 if on CRAN, 5 if README,
#   monthly downloads/1000, min(mentions, 10)

ru_fields <- c(
  "universe", "score", "stars", "dependents", "scripts", "downloads",
  "commits", "contributors", "vignettes", "datasets", "releases"
)

fetch_ru_scores <- function() {
  req_cranwatch(settings$ru_base, "api/scores") |>
    req_perform() |>
    resp_body_string() |>
    fromJSON() |>
    as_tibble() |>
    add_na_cols(ru_fields) |>
    mutate(across(all_of(setdiff(ru_fields, "universe")), as_num))
}

# One row per watched package. Same name in several universes -> prefer the
# universe matching the repo owner given in packages.yml, else the top score.
ru_metrics <- function(scores, watch) {
  if (is.null(scores)) return(tibble(package = character(), ru_universe = character()))

  watch |>
    select(package, repo) |>
    inner_join(scores, by = "package", relationship = "many-to-many") |>
    mutate(owner_match = coalesce(tolower(universe) == tolower(str_extract(repo, "^[^/]+")), FALSE)) |>
    arrange(desc(owner_match), desc(score)) |>
    distinct(package, .keep_all = TRUE) |>
    select(package, all_of(ru_fields)) |>
    rename_with(\(x) paste0("ru_", x), -package)
}

# NDJSON, one line per system library: {library, usedby: [{owner, package}], ...}
fetch_ru_sysdeps <- function() {
  req_cranwatch(settings$ru_base, "stats/sysdeps") |>
    req_perform() |>
    resp_body_string() |>
    str_split_1("\n") |>
    discard(\(line) line == "") |>
    map(parse_sysdep_line) |>
    list_rbind() |>
    distinct()
}

parse_sysdep_line <- function(line) {
  j <- fromJSON(line)
  tibble(library = j$library %||% NA_character_, package = j$usedby$package %||% character())
}
