<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** a record of what a production run did and when, the equivalent of the SAS log people are used to reading.

- **logger** is modern, has zero dependencies, uses glue-style messages (`log_info("Read {nrow(df)} rows")`), and handles levels, files and custom layouts. A good default.
- **logr** writes a log file that deliberately looks like a SAS log. It's handy when the people reviewing a run expect that format.
- **futile.logger** is the older log4j-style option. Its high download count mostly comes from older packages depending on it.
- **progressr** isn't logging: it reports progress, and unlike most progress bars it keeps working when the work runs in parallel (see *parallel*).

**Pick:** logger for pipelines; logr if reviewers want SAS-style logs.
