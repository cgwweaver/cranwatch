<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** extensions around dbplyr (see *dplyr backends*).

- **pivot** added SQL PIVOT/UNPIVOT to dbplyr, but was archived from CRAN in 2019. dbplyr now translates `tidyr::pivot_longer()` / `pivot_wider()` on database tables itself, so you probably don't need it.
- **dbplyrExtra** couldn't be found anywhere yet. Check the name.

**Pick:** plain dbplyr. Before reaching for an extension, check `show_query()` and dbplyr's own docs: it covers more SQL than people expect.
