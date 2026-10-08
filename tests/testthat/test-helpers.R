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
