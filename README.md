# cranwatch

[![cranwatch](https://github.com/cgwweaver/cranwatch/actions/workflows/cranwatch.yml/badge.svg)](https://github.com/cgwweaver/cranwatch/actions/workflows/cranwatch.yml)

Health radar for the R packages I use, or am eyeing, at work: how popular they are, whether CRAN is about to archive them, and how painful they are to install somewhere locked down (air-gapped k8s, source-only mirror, no `apt-get`).

**Site → <https://cgwweaver.github.io/cranwatch/>** · [columns & sources](https://cgwweaver.github.io/cranwatch/about.html) · [latest CSV](data/latest.csv)

## What it tracks

Per package in [`packages.yml`](packages.yml):

- **Popularity**: r-universe score + its parts (stars, recursive dependents, scripts, commits, contributors), CRAN downloads for the last 365 days vs the 365 before
- **CRAN health**: current deadline, orphaned, times archived + last date, CRAN's comment, status (`cran` / `cran-archived` / `r-universe` / `github` / `base` / `not-found`)
- **Install burden**: `NeedsCompilation`, recursive dep count, how many deps compile, SystemRequirements (own + "via deps", optional ones marked), libraries r-universe saw it link, hits on [`sys-deps.yml`](sys-deps.yml)
- **Reverse deps**: direct count, plus the top 3 by r-universe score when at least 3 score > 10

## How it works

```
Monday 06:17 UTC (or push / manual run)
  └─ Rscript run.R
       ├─ CRAN package db + PACKAGES.in   (1 file each)
       ├─ r-universe /api/scores + /stats/sysdeps   (1 request each, all packages)
       ├─ cranlogs totals   (~2 requests per 50 packages)
       ├─ GitHub API   (only repos not found elsewhere)
       └─ data/snapshots/<date>.csv, data/latest.csv, data/run.json, _alerts/*.md
  ├─ commit data/
  ├─ sync the "cranwatch alerts" issue (open / comment on new / close when clear)
  └─ quarto render site → GitHub Pages
```

- A source that's down leaves its columns `NA` and is logged in `data/run.json`. Only the CRAN db is required.
- Pull requests do a dry run: tests, a real fetch and a site render, uploaded as an artifact. No commit, issue or deploy.

## Editing the watchlist

[`packages.yml`](packages.yml): one key per theme. Entries can be `dplyr`, `owner/repo`, or `{pkg: polars, repo: pola-rs/r-polars}`. Push and the workflow re-runs.
Things that aren't packages go in [`links.yml`](links.yml).

## One-time setup

1. **Settings → Pages → Source: GitHub Actions** (otherwise the deploy job fails)
2. Watch the repo, or rely on the @mention in the alert issue, to get emails

## Run locally

```r
pak::local_install_deps(dependencies = TRUE)        # deps listed in DESCRIPTION
testthat::test_dir("tests/testthat")                # offline, fake sources
source("run.R")                                     # real fetch -> data/
quarto::quarto_render("site")                       # or: quarto render site
```

## Layout

| Path | What |
|---|---|
| `packages.yml`, `links.yml`, `sys-deps.yml` | Config: watchlist, non-package links, system libs to flag |
| `run.R` | Entry point |
| `R/` | Pipeline: `cran.R`, `runiverse.R`, `cranlogs.R`, `github.R` (fetch + metrics per source), `build.R` (status/flags), `alerts.R`, `schema.R` (snapshot columns), `main.R` |
| `tests/testthat/` | Offline tests: unit tests + the full pipeline on fake sources |
| `site/` | Quarto site (reactable table, movers, links) |
| `data/` | Snapshots, written by the workflow |
| `IDEAS.txt` | Scratchpad |

## Caveats

- Downloads come only from Posit's CRAN mirror and include CI/bots, so treat them as relative.
- r-universe calls its score formula a work in progress (it's documented on the [about page](https://cgwweaver.github.io/cranwatch/about.html)). Use the component columns for trends.
- CRAN doesn't publish deadline history, so "had a deadline before" only builds up from the first snapshot on.
