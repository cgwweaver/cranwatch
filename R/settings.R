# Knobs -----------------------------------------------------------------------

settings <- list(
  # Who we are, on every request (r-universe docs + GitHub API ask for a UA)
  user_agent        = "cranwatch/0.1 (+https://github.com/cgwweaver/cranwatch)",
  site_url          = "https://cgwweaver.github.io/cranwatch/",
  # Politeness: every GET is cached on disk and reused for this long, and
  # requests to one host are spaced out
  cache_dir         = "_cache",
  cache_hours       = 20,
  max_req_per_sec   = 2,
  # Sources
  cran_base         = "https://cloud.r-project.org", # CRAN's CDN mirror, spares the Vienna master
  ru_global         = "https://r-universe.dev",      # global search: every indexed package
  ru_universe       = "https://{universe}.r-universe.dev",
  ru_page_size      = 5000, # bigger pages hit MongoDB's 16 MB document cap server-side
  cranlogs_base     = "https://cranlogs.r-pkg.org",
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
