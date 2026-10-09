<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** turning results into tables people read, from quick checks to publication output.

- **gt** builds publication-quality tables (HTML, Word, PDF) with a grammar of headers, spanners, footnotes and formatting.
  - **gtsummary** builds on it for descriptive "Table 1"s and regression tables in one line.
  - **modelsummary** compares several models side by side, to many output formats.
- **knitr::kable()** gives quick, plain tables in Quarto or R Markdown. **kableExtra** styles them.
- **janitor::tabyl()** gives fast frequency tables and crosstabs with percentages (think PROC FREQ), plus `clean_names()` for messy column names.
- **arsenal** (`tableby()`) does summary tables but currently has a **CRAN deadline**. **sjPlot** does model tables and plots, mostly for social-science models.
- Gotcha: **gtable** is *not* a table package. It's the layout engine ggplot2 uses to arrange plot pieces.
- **rmarkdown** renders documents. For new reports, Quarto is its successor and runs the same R code.

**Pick:** janitor for exploring, gt / gtsummary for anything published.
