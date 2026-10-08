# Knobs -----------------------------------------------------------------------

settings <- list(
  user_agent        = "cranwatch (https://github.com/cgwweaver/cranwatch)",
  site_url          = "https://cgwweaver.github.io/cranwatch/",
  ru_base           = "https://cran.r-universe.dev", # any universe works for /api/scores (it's global)
  cranlogs_base     = "https://cranlogs.r-pkg.org",
  cran_base         = "https://cran.r-project.org",
  github_api        = "https://api.github.com",
  dl_lag_days       = 2,  # cranlogs lags ~1 day; 2 is safe
  dl_chunk          = 50, # packages per cranlogs request
  revdep_min_score  = 10, # "notable" reverse dependency = r-universe score above this
  revdep_min_n      = 3,  # ...and only list the top ones if at least this many
  revdep_top_n      = 3,
  strong_deps       = c("Depends", "Imports", "LinkingTo"),
  sysreq_noise      = "(?i)^(gnu make|c\\+\\+\\s*\\d*)$", # SystemRequirements items not worth showing
  alert_types       = c("deadline", "archived", "orphaned", "not-found", "gh-archived")
)
