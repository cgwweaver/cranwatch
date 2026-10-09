# Pipeline ---------------------------------------------------------------------

# Swappable so tests can run the whole pipeline offline with fake sources
default_fetchers <- function() {
  list(
    cran_db    = fetch_cran_db,
    cran_in    = fetch_cran_packages_in,
    ru_index   = fetch_ru_index,
    ru_detail  = fetch_ru_detail,
    ru_sysdeps = fetch_ru_sysdeps,
    downloads  = fetch_downloads,
    github     = fetch_github
  )
}

main <- function(root = ".", today = Sys.Date(), fetch = default_fetchers(), write = TRUE) {
  http_reset()
  # Each source is optional except the CRAN db: a failure is logged, its columns stay NA
  sources <- list()
  src <- function(name, ...) {
    t0  <- Sys.time()
    out <- tryCatch(fetch[[name]](...), error = identity)
    ok  <- !inherits(out, "error")
    sources[[name]] <<- compact(list(
      ok    = ok,
      secs  = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
      error = if (!ok) conditionMessage(out)
    ))
    msg("{name}: {if (ok) 'ok' else paste('FAILED -', conditionMessage(out))}")
    if (ok) out
  }

  watch     <- read_watchlist(file.path(root, "packages.yml")) |> collapse_themes()
  sys_watch <- read_sys_watch(file.path(root, "sys-deps.yml"))
  msg("{nrow(watch)} packages on the watchlist")

  cran_db <- src("cran_db") %||% stop("CRAN package db unavailable; not writing a snapshot", call. = FALSE)
  cran_in <- src("cran_in")
  index   <- src("ru_index")
  if (!is.null(attr(index, "partial"))) sources$ru_index$partial <- attr(index, "partial")
  detail  <- if (!is.null(index)) src("ru_detail", ru_pick(index, watch))
  if (!is.null(detail)) {
    match <- ru_formula_match(detail)
    if (is.finite(match)) sources$ru_detail$formula_match <- match
    if (length(attr(detail, "failed"))) sources$ru_detail$failed <- attr(detail, "failed")
  }
  sysdeps <- src("ru_sysdeps")

  snap <- list(
    watch,
    cran_metrics(cran_db, cran_in, watch$package),
    ru_metrics(index, detail, watch),
    install_metrics(cran_db, sysdeps, watch$package, sys_watch),
    revdep_metrics(cran_db, index, watch$package)
  ) |>
    reduce(left_join, by = "package") |>
    assign_status()

  dl <- src("downloads", snap |> filter(status %in% cran_statuses) |> pull(package), today)
  gh <- src("github", snap |> filter(is.na(status), !is.na(repo)) |> pull(repo))

  # Sources that decide status: if one failed, unresolved packages are "unknown"
  # and alerts are incomplete
  degraded <- c("cran_in", "ru_index", "github") |> keep(\(s) !isTRUE(sources[[s]]$ok))

  snap <- snap |>
    left_join(dl %||% tibble(package = character()), by = "package") |>
    left_join(gh %||% tibble(repo = character()), by = "repo") |>
    finalize(today, complete = !length(degraded))

  msg("status: {snap |> count(status) |> glue_data('{status} {n}') |> paste(collapse = ', ')}")
  if (write) write_outputs(snap, root, today, sources, degraded) else invisible(snap)
}

write_outputs <- function(snap, root, today, sources, degraded = character()) {
  data_dir <- file.path(root, "data")
  snap_dir <- file.path(data_dir, "snapshots")
  dir.create(snap_dir, recursive = TRUE, showWarnings = FALSE)

  snaps    <- list.files(snap_dir, "^\\d{4}-\\d{2}-\\d{2}\\.csv$", full.names = TRUE) |> sort()
  date_of  <- \(p) if (length(p)) str_remove(basename(p), "\\.csv$")
  # run.json "previous": the last run on an earlier day
  prev_path <- snaps |> keep(\(p) date_of(p) < as.character(today)) |> tail(1)
  # Alert baseline, read before today's file is overwritten: every alert already
  # flagged since the last complete run, incl. later partial runs and an earlier
  # run today. So nothing is announced twice, and alerts an outage hid (e.g.
  # not-found turned "unknown") aren't announced again once it's over.
  earlier   <- snaps |> keep(\(p) date_of(p) <= as.character(today)) |> rev() |> map(read_snapshot)
  last_ok   <- detect_index(earlier, \(s) !isFALSE(s$lookups_ok[1]))
  base      <- bind_rows(alerts_of(NULL), map(if (last_ok) earlier[seq_len(last_ok)] else earlier, alerts_of))
  base_date <- if (last_ok) as.character(earlier[[last_ok]]$run_date[1])

  c(file.path(snap_dir, paste0(today, ".csv")), file.path(data_dir, "latest.csv")) |>
    walk(\(p) write_csv(snap, p, na = ""))

  list(
    run_date   = today,
    run_time   = format(Sys.time(), tz = "UTC", usetz = TRUE),
    previous   = date_of(prev_path),
    dl_windows = dl_windows(today),
    n_packages = nrow(snap),
    sources    = sources,
    requests   = list(sent = as.list(http_log$sent), from_cache = as.list(http_log$cached))
  ) |>
    write_json(file.path(data_dir, "run.json"), auto_unbox = TRUE, pretty = TRUE)

  write_alerts(snap, base, base_date, file.path(root, "_alerts"), degraded)
  invisible(snap)
}
