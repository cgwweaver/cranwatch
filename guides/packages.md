<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** getting packages onto a machine, and keeping a project's package versions fixed so next month's run uses the same code as this month's.

- **renv** is the one that matters for production. It gives each project its own library and records exact versions in `renv.lock`, so a survey program run in 2027 can be restored to what it used in 2026. It's the successor to **packrat**, which is superseded: don't start new projects on it.
- **pak** installs things fast, resolves dependencies up front, and can tell you which *system* libraries a package needs (`pak::pkg_sysreqs("igraph")`). That's useful to hand to whoever builds your server image.
- **remotes** installs from GitHub and friends. pak covers this now, but remotes is still everywhere in older instructions.
- **pacman** (`p_load()`) installs whatever is missing at the top of a script. Convenient at home; risky in production because it changes the library behind your back. Its last release was in 2019.
- **box** is the odd one out: it's not about installing. `box::use()` gives R Python-style modules and scoped imports, so you can split a big program into files without everything landing in one global environment.

**Pick:** renv for every production project, plus pak for installing. All of them work against an internal CRAN-like mirror through `options(repos)`.
