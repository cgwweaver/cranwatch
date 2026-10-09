# GitHub: only for packages.yml repos not found on CRAN or r-universe --------
# Uses GITHUB_TOKEN when set (Actions: 1000 req/h; anonymous: 60 req/h).
# Not disk-cached: only a handful of calls, and the status code matters.

fetch_github <- function(repos, get = gh_get) {
  if (!length(repos)) return(tibble(repo = character()))
  unique(repos) |> map(\(r) gh_repo_info(r, get)) |> list_rbind()
}

# Only a 404 means "no such repo". Anything else that isn't a 200 (rate limit,
# outage, bad token) stops the source, so main() marks lookups as incomplete and
# unresolved packages become "unknown" rather than raising not-found alerts.
gh_repo_info <- function(repo, get = gh_get) {
  resp <- get("repos", repo)
  if (resp_status(resp) == 404) return(tibble(repo = repo))
  if (resp_status(resp) != 200) stop("GitHub API ", resp_status(resp), " for ", repo, call. = FALSE)
  body <- resp_body_json(resp)
  desc <- resp_status(get("repos", repo, "contents", "DESCRIPTION"))

  tibble(
    repo        = repo,
    gh_stars    = as_num(body$stargazers_count %||% NA),
    gh_pushed   = as.Date(str_sub(body$pushed_at %||% NA_character_, 1, 10)),
    gh_archived = body$archived %||% NA,
    gh_is_pkg   = if (desc == 200) TRUE else if (desc == 404) FALSE else NA
  )
}

gh_get <- function(...) {
  token <- Sys.getenv("GITHUB_TOKEN")
  req <- req_cranwatch(settings$github_api, ...) |>
    req_headers(Accept = "application/vnd.github+json") |>
    req_error(is_error = \(resp) FALSE)
  if (nzchar(token)) req <- req_auth_bearer_token(req, token)
  perform_polite(req)
}
