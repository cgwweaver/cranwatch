<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** working with data that lives in databases, or with many related tables at once.

- Not listed but foundational: **DBI** + **odbc** connect to Oracle and SQL Server; dbplyr then lets you query with dplyr (see *dplyr backends*).
- **dm** manages a *set* of related tables with primary and foreign keys: check key integrity, join along relationships, draw the data model, and copy whole models between databases. Good for survey frames with many linked tables.
- **dplyneage** draws column-level lineage diagrams for dplyr/dbplyr pipelines: which output column came from which inputs. Handy for documenting a converted program.
- **ducklake** works with DuckLake, a "lakehouse" table format on Parquet files with a catalog (versioned tables, time travel).
- **bigrquery** is for Google BigQuery. **polarssql** (r-universe) is an experimental SQL interface to polars. **oRm** couldn't be found yet.

**Pick:** DBI + odbc + dbplyr for the corporate databases; dm when you juggle many keyed tables; dplyneage to document pipelines.
