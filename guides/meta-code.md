<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** the "plumbing" packages, mostly from the r-lib team, that other packages are built on. You rarely need all of them, but knowing they exist saves reinventing them.

- **Workflow:** **usethis** sets up projects, tests and git, and **devtools** bundles it all for package development. **testthat** writes tests, and **vdiffr** adds snapshot tests for plots. A converted SAS program that ships with a few testthat tests is worth a lot.
- **Files, paths, processes:**
  - **fs** is a consistent, vectorised replacement for `file.copy()` and friends.
  - **here** builds paths from the project root, so scripts work no matter where they're run from.
  - **withr** temporarily changes options or the working directory and always restores them.
  - **callr** runs code in a fresh R process; **ps** inspects processes.
- **Messages:** **cli** for user-facing messages, progress and errors. **crayon** is superseded by cli.
- **Types and printing:** **vctrs**, **pillar**, **lifecycle**, **hms** and **scales** sit underneath the tidyverse. You get them for free; it's rare to call them directly, apart from **scales** for formatting numbers.
- **Checks:**
  - For argument checks inside your own functions, `stopifnot()` or `cli::cli_abort()` is enough. **assertthat** still works but hasn't changed since 2019.
  - **pointblank** builds data-validation reports, but pulls in 80+ packages; compare with **validate** in *data-cleaning*.
- **stats4** and **tcltk** ship with R. tcltk needs Tcl/Tk on the server and often isn't available on headless containers (`capabilities("tcltk")`).

**Pick:** fs + here + withr + cli in every project; testthat as soon as code is reused.
