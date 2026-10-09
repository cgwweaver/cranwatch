<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** finding out what's slow or big before guessing. Converting SAS to R is a good moment to measure rather than assume.

- **bench**: `bench::mark(dplyr = ..., data.table = ...)` runs several approaches many times. It reports time *and memory*, and checks they give the same result. The honest way to settle "which is faster".
- **tictoc**: `tic()` / `toc()` around steps of a long job, for a quick wall-clock breakdown.
- **lobstr**: `lobstr::obj_size()` gives the real memory size of an object, counting shared parts once. Useful for seeing how much an all-character 20-million-row table really costs compared with proper types.
- Base R's `system.time()` is fine for one-off checks.

**Pick:** bench to compare approaches, tictoc inside jobs, lobstr when memory is the question.
