# Status, links, flags ---------------------------------------------------------

cran_statuses <- c("cran", "cran-archived")

# First pass, before GitHub: whatever CRAN / r-universe could tell us
assign_status <- function(snap) {
  snap |>
    mutate(status = case_when(
      package %in% base_pkgs() ~ "base",
      on_cran %in% TRUE        ~ "cran",
      cran_archived %in% TRUE  ~ "cran-archived",
      !is.na(ru_universe)      ~ "r-universe"
    ))
}

# Second pass + derived columns. lookups_ok = FALSE (a lookup API failed) turns
# would-be "not-found" into "unknown", so an outage doesn't raise alerts.
finalize <- function(snap, today, lookups_ok = TRUE) {
  snap |>
    ensure_cols() |>
    mutate(
      run_date = today,
      repo     = coalesce(repo, cran_repo),
      status   = coalesce(status, case_when(
        !is.na(gh_stars) ~ "github",
        lookups_ok       ~ "not-found",
        .default         = "unknown"
      )),
      link = case_when(
        status %in% cran_statuses ~ paste0(settings$cran_base, "/package=", package),
        status == "r-universe"    ~ paste0("https://", ru_universe, ".r-universe.dev/", package),
        status == "github"        ~ paste0("https://github.com/", repo),
        status == "base"          ~ paste0("https://stat.ethz.ch/R-manual/R-patched/library/", package, "/html/00Index.html")
      )
    ) |>
    add_flags(today) |>
    conform() |>
    arrange(package)
}

add_flags <- function(snap, today) {
  yes <- \(x) x %in% TRUE

  hits <- with(snap, tibble(
    deadline           = !is.na(deadline),
    archived           = status %in% "cran-archived",
    orphaned           = yes(orphaned),
    `archived-past-yr` = status %in% "cran" & yes(archived_last >= today - 365),
    `new-past-yr`      = status %in% "cran" & yes(dl_prev365 == 0 & dl_365 > 0),
    `not-found`        = status %in% "not-found",
    `gh-archived`      = yes(gh_archived),
    `watch-sysreq`     = !is.na(sysreqs_watch)
  ))

  snap |>
    mutate(flags = pmap_chr(hits, \(...) {
      hit <- c(...)
      if (any(hit)) paste(names(hit)[hit], collapse = "; ") else NA_character_
    }))
}
