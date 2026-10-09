# Small shared helpers --------------------------------------------------------

msg <- function(..., .envir = parent.frame()) {
  message(format(Sys.time(), "%H:%M:%S "), glue(..., .envir = .envir))
}

base_pkgs <- function() rownames(installed.packages(priority = "base"))

# Every HTTP request is built here: identifying User-Agent, retries with
# backoff on 429/5xx, timeout...
req_cranwatch <- function(url, ...) {
  request(url) |>
    req_url_path_append(...) |>
    req_user_agent(settings$user_agent) |>
    req_retry(max_tries = 3, is_transient = \(resp) resp_status(resp) %in% c(429, 500, 502, 503, 504)) |>
    req_timeout(300)
}

# ...and sent here: requests to one host are spaced 1/max_req_per_sec apart,
# and counted per host for run.json (network vs served from the disk cache)
http_log <- new.env()
http_reset <- function() list2env(list(last = list(), sent = list(), cached = list()), http_log)
http_reset()

http_count <- function(kind, host) http_log[[kind]][[host]] <- (http_log[[kind]][[host]] %||% 0) + 1

perform_polite <- function(req, ...) {
  host <- url_parse(req$url)$hostname
  wait <- 1 / settings$max_req_per_sec - (as.numeric(Sys.time()) - (http_log$last[[host]] %||% -Inf))
  if (wait > 0) Sys.sleep(wait)
  http_log$last[[host]] <- as.numeric(Sys.time())
  http_count("sent", host)
  req_perform(req, ...)
}

# GET with a disk cache: within cache_hours the saved body is reused and the
# server isn't contacted at all. Returns the path of the cached file.
# (CI keeps _cache/ between runs with actions/cache, so re-runs are free too.)
cached_get <- function(url, hours = settings$cache_hours, dir = settings$cache_dir) {
  path <- file.path(dir, rlang::hash(url))
  age  <- difftime(Sys.time(), file.mtime(path), units = "hours")
  if (file.exists(path) && age < hours) {
    http_count("cached", url_parse(url)$hostname)
    return(path)
  }

  dir.create(dir, showWarnings = FALSE)
  req_cranwatch(url) |> perform_polite(path = paste0(path, ".part")) # errors leave no cache file
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

# Dates of "Archived on YYYY-MM-DD" events in CRAN comment/history text, incl.
# "Archived again on ..." but not "Unarchived on". Impossible dates (CRAN's
# notes have "Archived on 2020-02-30") become NA instead of an error.
archive_dates <- function(x) {
  x |>
    str_extract_all(paste0(
      "(?i)(?<![a-z])archived",
      "(?:\\s+(?:again|yet again|permanently|and removed|for (?:a|the) \\w+ time|\\(again!?\\)))?",
      "\\s+on\\s+\\d{4}-\\d{2}-\\d{2}"
    )) |>
    map(\(m) as.Date(str_extract(m, "\\d{4}-\\d{2}-\\d{2}"), format = "%Y-%m-%d"))
}
