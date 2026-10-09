# Alerts: flags worth a GitHub issue + what's new since the previous snapshot --

# One row per (package, alert). `when` makes a moved deadline / re-archival count as new.
# Archivals older than a year are known history: shown on the site, but they
# don't hold the issue open.
alerts_of <- function(snap) {
  if (is.null(snap)) return(tibble(package = character(), type = character(), when = character(), detail = character()))

  snap |>
    separate_longer_delim(flags, "; ") |>
    filter(flags %in% settings$alert_types, !(flags == "archived" & coalesce(archived_last < run_date - 365, FALSE))) |>
    transmute(
      package,
      type   = flags,
      when   = case_when(
        type == "deadline" ~ as.character(deadline),
        type == "archived" ~ as.character(archived_last),
        .default           = ""
      ),
      detail = case_when(
        type == "deadline"    ~ paste("CRAN deadline", deadline),
        type == "archived"    ~ coalesce(cran_comment, paste("Archived on CRAN", archived_last)),
        type == "orphaned"    ~ "orphaned on CRAN (no maintainer)",
        type == "not-found"   ~ "not found on CRAN, r-universe or GitHub; check packages.yml",
        type == "gh-archived" ~ paste("GitHub repo", repo, "is archived")
      ) |> str_replace_all("\\|", "/")
    )
}

new_alerts <- function(snap, base) anti_join(alerts_of(snap), base, by = c("package", "type", "when"))

# Files for the workflow's issue step (.github/scripts/sync-alert-issue.sh):
#   active.md   issue body: everything flagged now
#   new.md      comment: alerts not in `base` (already flagged since the last
#               complete run), which @mentions you. Written in partial runs too:
#               what is flagged is reliable, only unresolved packages are missing
#   degraded    present when a lookup source failed: alerts may be incomplete,
#               so the script won't close the issue
write_alerts <- function(snap, base, base_date, dir, degraded = character(), mention = Sys.getenv("ALERT_MENTION")) {
  unlink(dir, recursive = TRUE)
  dir.create(dir, showWarnings = FALSE)

  active <- alerts_of(snap)
  new    <- new_alerts(snap, base)
  cc     <- if (nzchar(mention)) paste0("cc @", mention) else ""

  if (length(degraded)) writeLines(degraded, file.path(dir, "degraded"))

  if (nrow(active)) writeLines(c(
    glue("## cranwatch alerts ({snap$run_date[1]})"), "",
    "| package | alert | details |", "|---|---|---|",
    glue("| {active$package} | {active$type} | {active$detail} |"), "",
    if (length(degraded)) c(glue("_Partial data: {paste(degraded, collapse = ', ')} failed this run, so some alerts may be missing._"), ""),
    glue("_Updated by the weekly [cranwatch]({settings$site_url}) run; closes itself when nothing is flagged._ {cc}")
  ), file.path(dir, "active.md"))

  if (nrow(new)) writeLines(c(
    if (is.null(base_date)) glue("New alerts: {cc}") else glue("New since {base_date}: {cc}"), "",
    glue("- **{new$package}**: {new$detail}")
  ), file.path(dir, "new.md"))

  msg("alerts: {nrow(active)} active, {nrow(new)} new{if (length(degraded)) ' (partial data)' else ''}")
  invisible(list(active = active, new = new))
}
