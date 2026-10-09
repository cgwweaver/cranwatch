<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** understanding fitted models: parameters, fit checks, effect sizes, marginal means, plain-language reports. It works across hundreds of model types.

- **performance**: `check_model()` draws all the usual diagnostic plots in one call; `r2()`, `icc()`, model comparison.
- **parameters**: `model_parameters()` gives a tidy coefficient table with CIs, standardisation and robust SEs.
- **insight**: the low-level glue (zero dependencies) the others are built on.
- **effectsize**, **modelbased** (marginal means and contrasts), **correlation**, **bayestestR**: specialised pieces.
- **report**: auto-writes a text description of a model. Good for a first draft, but review the wording.
- **see**: plotting for all of the above.

Design note: each piece is deliberately light (0–6 dependencies). The **easystats** meta-package installs everything, including the ggplot2 stack via see.

**Pick:** install the specific pieces you use (usually performance + parameters) rather than the meta-package on a constrained server.
