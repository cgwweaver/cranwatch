# Packages used by the pipeline (sourced first; also listed in DESCRIPTION) ----

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(readr)
  library(tibble)
  library(yaml)
  library(httr2)
  library(jsonlite, exclude = "flatten")
  library(glue)
})
