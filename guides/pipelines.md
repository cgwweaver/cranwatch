<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** turning a long chain of scripts (`01_import.R`, `02_edit.R`, …) into a pipeline that knows what depends on what and reruns only what changed. It's like a Makefile, and a natural fit for monthly or annual survey production.

- **targets** is the engine. You declare steps as targets, and it caches results, skips up-to-date steps, can run independent steps in parallel, and draws the dependency graph.
- **tarchetypes** adds shortcuts on top, such as rendering a Quarto report as a step or mapping over many inputs.
- **crew** supplies parallel workers to targets (built on mirai; see *parallel*).
- **sqltargets** lets `.sql` files be targets, for pipelines that start in a database.
- **igraph** is here because targets depends on it. It's also the heaviest part of the install: compiled C/C++, with libxml2 and glpk as optional system libraries. That's the `libxml2 [igraph]` you'll see under targets' System reqs.

**Pick:** targets (+ tarchetypes) for anything run on a schedule. On a source-only mirror, check that igraph builds before committing to it.
