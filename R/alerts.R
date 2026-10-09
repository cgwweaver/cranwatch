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

new_alerts <- function(snap, prev) anti_join(alerts_of(snap), alerts_of(prev), by = c("package", "type", "when"))

# Markdown bodies for the workflow's issue step: active.md (issue body), new.md (comment)
write_alerts <- function(snap, prev, prev_date, dir, mention = Sys.getenv("ALERT_MENTION")) {
  unlink(dir, recursive = TRUE)
  dir.create(dir, showWarnings = FALSE)

  active <- alerts_of(snap)
  new    <- new_alerts(snap, prev)
  cc     <- if (nzchar(mention)) paste0("cc @", mention) else ""

  if (nrow(active)) writeLines(c(
    glue("## cranwatch alerts ({snap$run_date[1]})"), "",
    "| package | alert | details |", "|---|---|---|",
    glue("| {active$package} | {active$type} | {active$detail} |"), "",
    glue("_Updated by the weekly [cranwatch]({settings$site_url}) run; closes itself when nothing is flagged._ {cc}")
  ), file.path(dir, "active.md"))

  if (nrow(new)) writeLines(c(
    glue("New since {prev_date %||% 'the first run'}: {cc}"), "",
    glue("- **{new$package}**: {new$detail}")
  ), file.path(dir, "new.md"))

  msg("alerts: {nrow(active)} active, {nrow(new)} new")
  invisible(list(active = active, new = new))
}
