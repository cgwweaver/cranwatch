# Watchlist config ------------------------------------------------------------

# packages.yml -> one row per (theme, entry). Entries are "pkg", "owner/repo",
# or {pkg: name, repo: owner/repo}.
read_watchlist <- function(path) {
  read_yaml(path) |>
    imap(\(entries, theme) entries |> map(parse_entry) |> list_rbind() |> mutate(theme = theme)) |>
    list_rbind() |>
    relocate(theme)
}

parse_entry <- function(x) {
  if (is.list(x)) return(tibble(package = x$pkg, repo = x$repo %||% NA_character_))
  tibble(package = basename(x), repo = if (str_detect(x, "/")) x else NA_character_)
}

# One row per package, themes collapsed in config order
collapse_themes <- function(watchlist) {
  out <- watchlist |>
    summarise(
      themes  = paste(unique(theme), collapse = "; "),
      n_repos = n_distinct(repo, na.rm = TRUE),
      repo    = first(na.omit(repo), default = NA_character_),
      .by     = package
    )

  out |>
    filter(n_repos > 1) |>
    pull(package) |>
    walk(\(p) warning(glue("{p} is listed with different repos; using the first"), call. = FALSE))

  out |> select(-n_repos)
}

# sys-deps.yml -> flat character vector of library names
read_sys_watch <- function(path) {
  if (!file.exists(path)) return(character())
  read_yaml(path) |> unlist(use.names = FALSE) |> unique()
}

# The "# ..." comments in packages.yml (read_yaml() drops them) -> one row per
# commented entry or theme: theme, package (NA for a theme-level note), note
read_watch_notes <- function(path) {
  tibble(line = readLines(path, warn = FALSE)) |>
    mutate(
      theme = str_match(line, "^([^\\s#-][^:#]*):")[, 2],
      entry = str_match(line, "^\\s+-\\s+(.+?)\\s+#")[, 2],
      note  = str_match(line, "\\s#\\s*(.+?)\\s*$")[, 2]
    ) |>
    fill(theme) |>
    filter(!is.na(note), !is.na(entry) | !is.na(str_match(line, "^[^\\s#]")[, 1])) |>
    mutate(package = map_chr(entry, \(e) if (is.na(e)) NA_character_ else parse_entry(yaml.load(e))$package)) |>
    select(theme, package, note)
}

# "lint/style" -> "lint-style": file name for guides/<slug>.md
theme_slug <- function(theme) theme |> str_to_lower() |> str_replace_all("[^a-z0-9]+", "-") |> str_remove_all("^-|-$")
