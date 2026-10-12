# Real records from r-universe /api/packages?fields=... (tidyverse + cran universes)
fixture <- test_path("fixtures/ru_packages.ndjson") |>
  readLines() |>
  map(\(line) ru_components(fromJSON(line, simplifyVector = FALSE))) |>
  list_rbind()

test_that("our copy of r-universe's score formula reproduces their scores", {
  expect_equal(1 + rowSums(ru_score_parts(fixture)), fixture$score, tolerance = 1e-9)
  expect_equal(ru_formula_match(fixture), 1)
})

test_that("score ingredients are read from the API shapes", {
  dplyr <- fixture |> filter(package == "dplyr")
  expect_equal(dplyr$universe, "tidyverse")
  expect_gt(dplyr$update_weeks, 0)
  expect_gt(dplyr$commits, dplyr$update_weeks)
  expect_true(dplyr$on_cran)
  expect_true(dplyr$readme)
})

test_that("ru_pick prefers the universe of the repo owner, else top score", {
  index <- tibble(package = c("x", "x", "y", "y"), universe = c("big", "own", "a", "b"), score = c(9, 2, 1, 5))
  watch <- tibble(package = c("x", "y"), repo = c("own/x", NA))
  expect_equal(ru_pick(index, watch)$universe, c("own", "b"))
})

test_that("sysdeps NDJSON lines become library-package pairs", {
  line <- '{"library":"libxml2","usedby":[{"owner":"cran","package":"xml2"},{"owner":"cran","package":"igraph"}]}'
  expect_equal(parse_sysdep_line(line), tibble(library = "libxml2", package = c("xml2", "igraph")))
})

test_that("ru_detail falls back to single-package records when a listing has none of ours", {
  dir <- tempfile("cache-"); dir.create(dir)
  old <- settings$cache_dir; settings$cache_dir <<- dir; on.exit(settings$cache_dir <<- old)
  put <- \(url, lines) writeLines(lines, file.path(dir, rlang::hash(url)))
  put(paste0(ru_url("cran", "/api/packages"), "?stream=true&limit=10000&fields=", paste(ru_detail_fields, collapse = ",")),
      '{"Package":"other","_user":"cran","_score":1}')
  put(ru_url("cran", "/api/packages/future"), '{"Package":"future","_user":"cran","_score":11.6,"_stars":9}')

  out <- fetch_ru_detail(tibble(package = "future", universe = "cran"))
  expect_equal(out$package, "future")
  expect_equal(out$score, 11.6)
  expect_length(attr(out, "failed"), 0)
})
