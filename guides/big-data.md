<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** data that's slow or doesn't fit in memory with plain data frames, which is easy to hit at 20+ million rows, especially when every column is stored as text.

- **data.table**: very fast, no dependencies, mature. `fread()` and `fwrite()` alone are worth it. The syntax (`dt[i, j, by]`) takes some learning.
- **duckdb**: a full SQL database inside your R session. It queries CSV and Parquet files directly, including ones bigger than memory, and is extremely fast. Use it with SQL, dbplyr or duckplyr.
- **arrow**: Parquet and Arrow datasets, including folders of many files, queried with dplyr verbs.
- **tidytable**: data.table speed with tidyverse-style syntax.
- **polars**: the Rust DataFrame library. It isn't on CRAN (archived in 2023); it's installed from r-universe / R-multiverse, which an internal CRAN mirror may not proxy.
- **Install burden:** duckdb and arrow are large C++ builds. From source they can take a long time and need a lot of memory, so on a source-only mirror ask for binaries or a pre-built image.

**Pick:** store data as **Parquet with proper column types**, then query it with duckdb (or arrow) and pull into data.table or dplyr only what you need. That one change often beats any choice of data-frame package.
