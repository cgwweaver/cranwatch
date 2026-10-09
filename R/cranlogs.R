# cranlogs: download totals from the Posit CRAN mirror ------------------------
# /downloads/total/<from>:<to>/<pkg1,pkg2,...> -> one request per chunk of
# packages, instead of a 365-row daily series per package.

dl_windows <- function(today) {
  end <- today - settings$dl_lag_days
  list(dl_365 = c(end - 364, end), dl_prev365 = c(end - 729, end - 365))
}

fetch_downloads <- function(pkgs, today) {
  dl_windows(today) |>
    imap(\(w, col) cranlogs_totals(pkgs, w[1], w[2]) |> rename(!!col := downloads)) |>
    reduce(full_join, by = "package") |>
    mutate(dl_growth = if_else(dl_prev365 > 0, dl_365 / dl_prev365 - 1, NA_real_))
}

cranlogs_totals <- function(pkgs, from, to) {
  if (!length(pkgs)) return(tibble(package = character(), downloads = double()))

  pkgs |>
    split(ceiling(seq_along(pkgs) / settings$dl_chunk)) |>
    map(\(chunk) {
      glue("{settings$cranlogs_base}/downloads/total/{from}:{to}/{paste(chunk, collapse = ',')}") |>
        cached_get() |>
        fromJSON() |>
        as_tibble()
    }) |>
    list_rbind() |>
    transmute(package, downloads = as_num(downloads))
}
