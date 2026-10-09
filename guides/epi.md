<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** epidemiology helpers: rates, risk and odds ratios, 2×2 tables, standardisation, confidence intervals.

- **epiR** is broad and actively maintained, but heavy (70+ dependencies).
- **epitools** is small and simple, but its last release was 2020 and it got a **CRAN deadline** in October 2026 (check its Flags below for now).

**Pick:** epiR when you need the breadth. For a few rate CIs, base R (`binom.test`, `poisson.test`) or survey may be enough. If you depend on epitools, watch the deadline flag.
