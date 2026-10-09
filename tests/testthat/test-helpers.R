test_that("SystemRequirements split keeps commas inside parentheses", {
  expect_equal(
    split_sysreqs("libxml2 (optional), glpk (>= 4.57, optional);  GNU make")[[1]],
    c("libxml2 (optional)", "glpk (>= 4.57, optional)", "GNU make")
  )
})

test_that("archive dates skip 'Unarchived on'", {
  expect_equal(
    archive_dates("Archived on 2023-01-02 as x.\nUnarchived on 2023-02-03. archived on 2024-05-06")[[1]],
    as.Date(c("2023-01-02", "2024-05-06"))
  )
})

test_that("watchlist entries: name, owner/repo, {pkg, repo}", {
  expect_equal(parse_entry("dplyr"), tibble(package = "dplyr", repo = NA_character_))
  expect_equal(parse_entry("cmmr/jobqueue"), tibble(package = "jobqueue", repo = "cmmr/jobqueue"))
  expect_equal(parse_entry(list(pkg = "polars", repo = "pola-rs/r-polars")), tibble(package = "polars", repo = "pola-rs/r-polars"))
})

test_that("real packages.yml parses and every entry has a name", {
  watch <- read_watchlist(test_path("../../packages.yml")) |> collapse_themes()
  expect_gt(nrow(watch), 100)
  expect_false(anyNA(watch$package))
  expect_false(anyDuplicated(watch$package) > 0)
})

test_that("sys watch hits are whole-word and case-insensitive", {
  expect_equal(watch_hits(c("LibXML2 (>= 2.9)", "libxml2-dev", "libxml22", NA), c("libxml2", "cmake")),
               c("libxml2", "libxml2", NA, NA))
})

test_that("top revdeps need enough notable ones", {
  expect_equal(top_revdeps(c("a", "b", "c", "d"), c(11, 30, 12, 5)), "b (30), c (12), a (11)")
  expect_true(is.na(top_revdeps(c("a", "b"), c(11, 30))))
})

test_that("snapshots round-trip and old ones gain new columns", {
  path <- tempfile(fileext = ".csv")
  tibble(package = "x", ru_score = 1.5, run_date = test_today) |> conform() |> write_csv(path, na = "")
  back <- read_snapshot(path)
  expect_named(back, names(snapshot_cols))
  expect_equal(back$ru_score, 1.5)
  expect_s3_class(back$deadline, "Date")
})

test_that("cached_get reuses a fresh file without touching the network", {
  dir  <- tempfile("cache-")
  url  <- "https://example.invalid/data.json"
  path <- file.path(dir, rlang::hash(url))
  dir.create(dir)
  writeLines("{}", path)

  expect_equal(cached_get(url, dir = dir), path) # fresh: no request (example.invalid would fail)
  Sys.setFileTime(path, Sys.time() - 48 * 3600)
  expect_error(cached_get(url, dir = dir))       # stale: tries the network
})

test_that("YAML comments become per-entry and per-theme notes", {
  path <- tempfile(fileext = ".yml")
  writeLines(c(
    "# file header, ignored",
    "pipelines: # see targetopia",
    "  - targets",
    "  - igraph # dep for targets",
    "  - {pkg: polars, repo: pola-rs/r-polars} # not on CRAN",
    "  - cmmr/jobqueue # gh"
  ), path)
  expect_equal(
    read_watch_notes(path),
    tibble(theme = "pipelines", package = c(NA, "igraph", "polars", "jobqueue"),
           note = c("see targetopia", "dep for targets", "not on CRAN", "gh"))
  )
  expect_equal(theme_slug(c("lint/style", "dplyr backends", "data-cleaning")), c("lint-style", "dplyr-backends", "data-cleaning"))
})

test_that("fmt_short rounds each value on its own", {
  expect_equal(fmt_short(c(4890, 209, 39438, 1234567, 12, NA)), c("4.9K", "210", "39K", "1.2M", "12", ""))
})
