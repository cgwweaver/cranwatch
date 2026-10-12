<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** keeping dplyr syntax while a different engine does the work.

- **dbplyr** translates dplyr into SQL and runs it *in the database* (Oracle, SQL Server, Postgres, …), then `collect()` brings back only the result. For data that lives on a database server, this is the big win: filter and summarise there instead of pulling millions of rows over the network. `show_query()` shows the SQL it writes, which is also a nice way to learn SQL.
- **duckplyr** runs dplyr on the DuckDB engine: much faster on large local tables and Parquet files, and it falls back to regular dplyr for anything it can't translate.
- **dtplyr** translates dplyr into data.table code. It's lazy, so finish with `as_tibble()`.
- **multidplyr** splits a data frame across cores. Mostly overtaken by duckplyr and arrow.

**Pick:** dbplyr for data on Oracle/SQL Server, duckplyr for big local files. That covers most of what multidplyr and dtplyr were for.
