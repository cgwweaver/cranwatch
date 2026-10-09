# Small shared helpers --------------------------------------------------------

msg <- function(..., .envir = parent.frame()) {
  message(format(Sys.time(), "%H:%M:%S "), glue(..., .envir = .envir))
}

base_pkgs <- function() rownames(installed.packages(priority = "base"))

# Every HTTP call goes through here: identifying UA, max N requests/sec per
# host, retries with backoff on 429/503, timeout
req_cranwatch <- function(url, ...) {
  request(url) |>
    req_url_path_append(...) |>
    req_user_agent(settings$user_agent) |>
    req_throttle(rate = settings$max_req_per_sec) |>
    req_retry(max_tries = 3) |>
    req_timeout(300)
}

# GET with a disk cache: within cache_hours the saved body is reused and the
# server isn't contacted at all. Returns the path of the cached file.
# (CI keeps _cache/ between runs with actions/cache, so re-runs are free too.)
cached_get <- function(url, hours = settings$cache_hours, dir = settings$cache_dir) {
  path <- file.path(dir, rlang::hash(url))
  age  <- difftime(Sys.time(), file.mtime(path), units = "hours")
  if (file.exists(path) && age < hours) return(path)

  dir.create(dir, showWarnings = FALSE)
  req_cranwatch(url) |> req_perform(path = paste0(path, ".part"))
  file.rename(paste0(path, ".part"), path)
  path
}

# Add columns that an API/db didn't return, so downstream code can rely on them
add_na_cols <- function(df, cols, na = NA_character_) {
  missing <- setdiff(cols, names(df))
  df |> mutate(!!!set_names(rep(list(na), length(missing)), missing))
}

max_or_na <- function(x) if (all(is.na(x))) x[NA_integer_][1] else max(x, na.rm = TRUE)

# "a, b, c, d, e" -> "a, b, c +2"
label_few <- function(x, n = 3) {
  paste0(paste(head(x, n), collapse = ", "), if (length(x) > n) paste0(" +", length(x) - n) else "")
}

# Coerce an API field to numeric, whatever shape it came back in
as_num <- function(x) {
  if (is.data.frame(x)) x <- x[[1]]
  if (is.list(x)) x <- map_dbl(x, \(v) as.numeric(v %||% NA)[1])
  suppressWarnings(as.numeric(x))
}

# "github.com/owner/repo" anywhere in a URL field -> "owner/repo"
gh_repo_from <- function(x) {
  x |>
    str_extract("github\\.com/[\\w.-]+/[\\w.-]+") |>
    str_remove("^github\\.com/") |>
    str_remove("\\.git$")
}

# Split SystemRequirements on commas/semicolons that aren't inside parentheses:
# "libxml2 (optional), glpk (>= 4.57, optional)" -> c("libxml2 (optional)", "glpk (>= 4.57, optional)")
split_sysreqs <- function(x) {
  x |>
    str_squish() |>
    str_split("[,;](?![^()]*\\))") |>
    map(\(v) v |> str_squish() |> discard(\(s) s == ""))
}

# Dates of "Archived on YYYY-MM-DD" events in CRAN comment/history text ("Unarchived on" excluded)
archive_dates <- function(x) {
  x |>
    str_extract_all("(?i)\\barchived on \\d{4}-\\d{2}-\\d{2}") |>
    map(\(m) as.Date(str_extract(m, "\\d{4}-\\d{2}-\\d{2}")))
}
