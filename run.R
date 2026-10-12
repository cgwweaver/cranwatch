#!/usr/bin/env Rscript
# cranwatch: fetch -> data/snapshots/<date>.csv + data/latest.csv -> _alerts/*.md
# Run from the repo root: Rscript run.R

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
main()
