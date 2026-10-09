# GitHub: only for packages.yml repos not found on CRAN or r-universe --------
# Uses GITHUB_TOKEN when set (Actions: 1000 req/h; anonymous: 60 req/h).
# Not disk-cached: only a handful of calls, and the status code matters.

fetch_github <- function(repos, get = gh_get) {
  if (!length(repos)) return(tibble(repo = character()))
  unique(repos) |> map(\(r) gh_repo_info(r, get)) |> list_rbind()
}

# A GitHub-wide problem (bad token, rate limit, outage) stops the source, so
# main() marks lookups incomplete and unresolved packages become "unknown"
# rather than raising not-found alerts. Anything else that isn't a 200 (404,
# 451, a blocked repo) is this repo's own answer: not found.
gh_repo_info <- function(repo, get = gh_get) {
  resp <- get("repos", repo)
  if (gh_systemic(resp)) stop("GitHub API ", resp_status(resp), " for ", repo, call. = FALSE)
  if (resp_status(resp) != 200) return(tibble(repo = repo))
  body <- resp_body_json(resp)
  desc <- resp_status(get("repos", repo, "contents", "DESCRIPTION"))

  tibble(
    repo        = repo,
    gh_stars    = as_num(body$stargazers_count %||% NA),
    gh_pushed   = as.Date(str_sub(body$pushed_at %||% NA_character_, 1, 10)),
    gh_archived = body$archived %||% NA,
    gh_is_pkg   = if (desc == 200) TRUE else if (desc == 404) FALSE else NA # NA: couldn't tell
  )
}

gh_systemic <- function(resp) {
  status <- resp_status(resp)
  status %in% c(401, 429) || status >= 500 ||
    (status == 403 && (identical(resp_header(resp, "x-ratelimit-remaining"), "0") || !is.null(resp_header(resp, "retry-after"))))
}

gh_get <- function(...) {
  token <- Sys.getenv("GITHUB_TOKEN")
  req <- req_cranwatch(settings$github_api, ...) |>
    req_headers(Accept = "application/vnd.github+json") |>
    req_error(is_error = \(resp) FALSE)
  if (nzchar(token)) req <- req_auth_bearer_token(req, token)
  perform_polite(req)
}
