test_that("full pipeline on fake sources", {
  root <- fake_root()
  main(root, test_today, fake_fetchers())
  snap <- read_snapshot(file.path(root, "data", "latest.csv"))
  row  <- \(p) snap |> filter(package == p)

  expect_true(file.exists(file.path(root, "data", "snapshots", "2026-10-08.csv")))
  expect_equal(
    snap |> select(package, status) |> deframe(),
    c(alpha = "cran", beta = "cran", delta = "cran", echo = "cran-archived", foxtrot = "r-universe",
      golf = "github", hotel = "not-found", stats4 = "base")
  )

  # themes collapse, r-universe picks the top-scoring universe
  expect_equal(row("alpha")$themes, "core; other")
  expect_equal(row("alpha")$ru_universe, "me")
  expect_equal(row("alpha")$ru_update_weeks, 6) # ingredients come from the detail fetch
  expect_true(is.na(row("beta")$ru_update_weeks)) # ...index-only packages keep the headline numbers
  expect_equal(row("beta")$ru_score, 8)
  expect_equal(row("alpha")$repo, "me/alpha")

  # archive history: Unarchived doesn't count, recent archival flagged
  expect_equal(row("alpha")$archived_n, 1)
  expect_match(row("alpha")$flags, "archived-past-yr")
  expect_equal(row("echo")$archived_last, as.Date("2026-09-01"))

  # install burden: base deps dropped, noise dropped, optional kept, via-deps attributed
  expect_equal(row("alpha")$deps_n, 2)
  expect_equal(row("alpha")$deps_compiled_n, 2)
  expect_equal(row("beta")$sysreqs, "libxml2 (optional); glpk (>= 4.57, optional)")
  expect_match(row("alpha")$sysreqs_via_deps, "libxml2 (optional) [beta]", fixed = TRUE)
  expect_equal(row("alpha")$sysdeps_detected, "glpk; libxml2")
  expect_equal(row("alpha")$sysreqs_watch, "libxml2")
  expect_equal(row("delta")$sysreqs_watch, "cmake")

  # revdeps
  expect_equal(row("alpha")$revdeps_n, 4)
  expect_equal(row("alpha")$revdeps_notable_n, 3)
  expect_equal(row("alpha")$revdeps_top, "rev2 (20), rev1 (15), rev3 (11)")

  # downloads + flags
  expect_match(row("delta")$flags, "deadline")
  expect_match(row("delta")$flags, "new-past-yr")
  expect_true(is.na(row("stats4")$dl_365))

  # alerts: first run -> everything is new
  active <- readLines(file.path(root, "_alerts", "active.md"))
  expect_true(any(str_detect(active, "\\| delta \\| deadline")))
  expect_true(any(str_detect(active, "\\| echo \\| archived")))
  expect_true(any(str_detect(active, "\\| hotel \\| not-found")))
  expect_length(readLines(file.path(root, "_alerts", "new.md")) |> str_subset("^- "), 3)
})

test_that("second run only reports what changed", {
  root <- fake_root()
  main(root, test_today - 7, fake_fetchers())
  db2 <- fake_db |> mutate(
    Deadline   = if_else(Package == "beta", "2026-11-01", Deadline),
    Maintainer = if_else(Package == "beta", "ORPHANED", "someone")
  )
  main(root, test_today, fake_fetchers(cran_db = \() add_na_cols(db2, cran_fields)))

  new <- readLines(file.path(root, "_alerts", "new.md")) |> str_subset("^- ")
  expect_equal(new, c("- **beta**: CRAN deadline 2026-11-01", "- **beta**: orphaned on CRAN (no maintainer)"))
  expect_equal(fromJSON(file.path(root, "data", "run.json"))$previous, "2026-10-01")
})

test_that("a failed lookup source gives 'unknown', not 'not-found' alerts", {
  root <- fake_root()
  main(root, test_today, fake_fetchers(ru_index = \() stop("r-universe down")))
  snap <- read_snapshot(file.path(root, "data", "latest.csv"))

  expect_equal(snap$status[snap$package %in% c("foxtrot", "hotel")], c("unknown", "unknown"))
  expect_true(all(is.na(snap$ru_score)))
  expect_false(any(str_detect(readLines(file.path(root, "_alerts", "active.md")), "not-found")))
  expect_false(fromJSON(file.path(root, "data", "run.json"))$sources$ru_index$ok)
})

test_that("no CRAN db -> no snapshot", {
  root <- fake_root()
  expect_error(main(root, test_today, fake_fetchers(cran_db = \() stop("CRAN down"))), "not writing")
  expect_false(dir.exists(file.path(root, "data")))
})
