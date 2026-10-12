<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** using more than one CPU core, or running work in the background.

- **future** is the common interface: write code once, then pick *where* it runs with `plan()` (sequential, several local R sessions, a cluster).
  - **furrr** gives purrr-style `future_map()` on top of it.
  - **futurize** is newer: pipe an existing `lapply()`/`map()` call into `futurize()` to parallelise it without rewriting.
- **mirai** is a minimal, very fast alternative with almost no dependencies. It powers **crew** (workers for targets) and purrr's own `in_parallel()` (purrr ≥ 1.1), and is a common choice for Shiny's async tasks.
- **parallelly**: use `parallelly::availableCores()`, not `parallel::detectCores()`. On Kubernetes, `detectCores()` reports the whole node's CPUs rather than your pod's limit, and starting that many workers slows everything down.
- **progressr** shows progress from parallel workers. **promises** is for async code in Shiny. **interprocess** / **jobqueue** give low-level locks and job queues; you'll rarely need them.

**Pick:** futurize or furrr if you already think in `map()`; mirai for new background or async work. Always size workers with `availableCores()`.
