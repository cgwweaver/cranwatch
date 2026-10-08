# Pipeline ---------------------------------------------------------------------

# Swappable so tests can run the whole pipeline offline with fake sources
default_fetchers <- function() {
  list(
    cran_db    = fetch_cran_db,
    cran_in    = fetch_cran_packages_in,
    ru_scores  = fetch_ru_scores,
    ru_sysdeps = fetch_ru_sysdeps,
    downloads  = fetch_downloads,
    github     = fetch_github
  )
}

main <- function(root = ".", today = Sys.Date(), fetch = default_fetchers(), write = TRUE) {
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
  scores  <- src("ru_scores")
  sysdeps <- src("ru_sysdeps")

  snap <- list(
    watch,
    cran_metrics(cran_db, cran_in, watch$package),
    ru_metrics(scores, watch),
    install_metrics(cran_db, sysdeps, watch$package, sys_watch),
    revdep_metrics(cran_db, scores, watch$package)
  ) |>
    reduce(left_join, by = "package") |>
    assign_status()

  dl <- src("downloads", snap |> filter(status %in% cran_statuses) |> pull(package), today)
  gh <- src("github", snap |> filter(is.na(status), !is.na(repo)) |> pull(repo))

  snap <- snap |>
    left_join(dl %||% tibble(package = character()), by = "package") |>
    left_join(gh %||% tibble(repo = character()), by = "repo") |>
    finalize(today, lookups_ok = sources[c("cran_in", "ru_scores", "github")] |> map_lgl("ok") |> all())

  msg("status: {snap |> count(status) |> glue_data('{status} {n}') |> paste(collapse = ', ')}")
  if (write) write_outputs(snap, root, today, sources) else invisible(snap)
}

write_outputs <- function(snap, root, today, sources) {
  data_dir <- file.path(root, "data")
  snap_dir <- file.path(data_dir, "snapshots")
  dir.create(snap_dir, recursive = TRUE, showWarnings = FALSE)

  prev_path <- list.files(snap_dir, "^\\d{4}-\\d{2}-\\d{2}\\.csv$", full.names = TRUE) |>
    keep(\(p) basename(p) < paste0(today, ".csv")) |>
    sort() |>
    tail(1)
  prev_date <- if (length(prev_path)) str_remove(basename(prev_path), "\\.csv$")

  c(file.path(snap_dir, paste0(today, ".csv")), file.path(data_dir, "latest.csv")) |>
    walk(\(p) write_csv(snap, p, na = ""))

  list(
    run_date   = today,
    run_time   = format(Sys.time(), tz = "UTC", usetz = TRUE),
    previous   = prev_date,
    dl_windows = dl_windows(today),
    n_packages = nrow(snap),
    sources    = sources
  ) |>
    write_json(file.path(data_dir, "run.json"), auto_unbox = TRUE, pretty = TRUE)

  write_alerts(snap, if (length(prev_path)) read_snapshot(prev_path), prev_date, file.path(root, "_alerts"))
  invisible(snap)
}
