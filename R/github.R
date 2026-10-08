# GitHub: only for packages.yml repos not found on CRAN or r-universe --------
# Uses GITHUB_TOKEN when set (Actions: 1000 req/h; anonymous: 60 req/h).

fetch_github <- function(repos) {
  if (!length(repos)) return(tibble(repo = character()))
  unique(repos) |> map(gh_repo_info) |> list_rbind()
}

gh_repo_info <- function(repo) {
  resp <- gh_get("repos", repo)
  if (resp_status(resp) != 200) return(tibble(repo = repo)) # missing repo -> NAs -> "not-found"
  body <- resp_body_json(resp)

  tibble(
    repo        = repo,
    gh_stars    = as_num(body$stargazers_count),
    gh_pushed   = as.Date(str_sub(body$pushed_at %||% NA_character_, 1, 10)),
    gh_archived = body$archived %||% NA,
    gh_is_pkg   = resp_status(gh_get("repos", repo, "contents", "DESCRIPTION")) == 200
  )
}

gh_get <- function(...) {
  token <- Sys.getenv("GITHUB_TOKEN")
  req <- req_cranwatch(settings$github_api, ...) |>
    req_headers(Accept = "application/vnd.github+json") |>
    req_error(is_error = \(resp) FALSE)
  if (nzchar(token)) req <- req_auth_bearer_token(req, token)
  req_perform(req)
}
