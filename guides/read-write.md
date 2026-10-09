<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** getting data in and out quickly, with column types intact.

- **Parquet** is the interchange format to aim for: columnar, compressed, typed, and readable from R, Python, SAS Viya, Spark and DuckDB. **nanoparquet** reads and writes it with zero dependencies (great for simple cases); **arrow** adds multi-file datasets and querying.
- **qs2** is a fast way to save R objects (lists, models, caches). It replaces **qs**, which was archived from CRAN in January 2026. qs2 needs **RcppParallel**, which needs **CMake** to build from source (the `watch-sysreq` flag).
- **vroom** reads delimited text very fast and is what `readr` uses underneath.
- **fst** was a fast columnar format for data frames, but hasn't had a release since 2022. Prefer Parquet for new work.
- **RcppTOML** reads TOML config files.

**Pick:** Parquet (nanoparquet or arrow) for data, qs2 for R objects, readr/vroom for incoming CSVs.
