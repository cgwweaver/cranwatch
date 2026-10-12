# Small formatters shared by the site pages ------------------------------------

# 1234567 -> "1.2M", NA -> ""
# (each value on its own: scales' cut_short_scale() rounds to the coarsest
# value in the vector, and errors on some mixes)
fmt_short <- function(x) {
  div <- case_when(abs(x) >= 1e9 ~ 1e9, abs(x) >= 1e6 ~ 1e6, abs(x) >= 1e3 ~ 1e3, .default = 1)
  suffix <- c("1" = "", "1000" = "K", "1e+06" = "M", "1e+09" = "B")[as.character(div)]
  if_else(is.na(x), "", paste0(signif(x / div, 2), suffix))
}

# Markdown link to a package's page, or just its name
md_pkg <- function(package, link) if_else(is.na(link), package, glue("[{package}]({link})"))

# c("a", "b", "c", "d") -> "a, b, c and 1 more"
and_more <- function(x, n = 4) {
  if (length(x) <= n) return(paste(x, collapse = ", "))
  paste0(paste(head(x, n), collapse = ", "), " and ", length(x) - n, " more")
}

# guides/<slug>.md -> list(text, draft): text without the status line
read_guide <- function(dir, theme) {
  path <- file.path(dir, paste0(theme_slug(theme), ".md"))
  if (!file.exists(path)) return(list(text = NULL, draft = FALSE))
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  list(text = lines[!str_detect(lines, "status: draft")], draft = any(str_detect(lines, "status: draft")))
}
