# Small shared helpers --------------------------------------------------------

msg <- function(..., .envir = parent.frame()) {
  message(format(Sys.time(), "%H:%M:%S "), glue(..., .envir = .envir))
}

base_pkgs <- function() rownames(installed.packages(priority = "base"))

# Every HTTP call goes through here: polite UA, retries on 429/5xx, timeout
req_cranwatch <- function(url, ...) {
  request(url) |>
    req_url_path_append(...) |>
    req_user_agent(settings$user_agent) |>
    req_retry(max_tries = 3) |>
    req_timeout(120)
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
