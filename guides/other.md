<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** everything that didn't fit elsewhere.

- **Config and credentials:**
  - **config** reads a `config.yml` with dev/test/prod sections, picked by an environment variable. Good for switching database servers between environments. **configr** does similar for many formats, but got a **CRAN deadline** in October 2026; config + yaml (or RcppTOML) covers it.
  - Never put passwords in scripts. **keyring** stores secrets in the OS credential store (on Linux servers it may need libsecret, or falls back to an encrypted file). **getPass** asks for a password without echoing it, and works in RStudio Server.
- **Everyday tools:**
  - **glue** builds strings (`glue("{n} rows")`). **magrittr** has the `%>%` pipe; base R's `|>` covers most uses now.
  - **janitor** does `clean_names()` and `tabyl()`. **yaml** and **jsonlite** read and write those formats.
  - **gert** does git from R (libgit2). **bslib** themes Shiny and HTML output; **prettydoc** gives light themes for R Markdown.
- **Speed:** **collapse** has fast grouped statistics and transformations (`fmean()`, `fmedian()` by group), often much faster than dplyr on big data.
- **Niche or ageing:**
  - **zeallot** does multiple assignment (`c(a, b) %<-% f()`). **listenv** provides environments that behave like lists (used by future).
  - **lambda.r** does functional programming with guards. **ArCo** (artificial counterfactuals) is econometrics. Both got **CRAN deadlines** in October 2026.
  - **tidyboot** is bootstrap helpers (rsample covers this). **modelr** is superseded by rsample. **datadiff** (ThinkR) checks data against YAML rules.

**Pick:** config + keyring/getPass for anything touching databases; glue and janitor daily. For packages with a `deadline` flag below, plan a replacement.
