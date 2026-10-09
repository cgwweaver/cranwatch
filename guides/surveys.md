<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** design-based estimation from complex samples (strata, clusters, weights) and the weighting itself: the bread and butter of official statistics.

- **survey** (Thomas Lumley) is the reference implementation: design objects, totals, means, ratios, quantiles and models with correct variances.
  - It handles **replicate weights**: `svrepdesign()` takes bootstrap weights supplied with a file, as many surveys provide.
  - It does calibration, post-stratification and raking (`calibrate()`, `postStratify()`, `rake()`).
- **srvyr** puts dplyr syntax on top of survey (`as_survey_design()`, then `group_by()` / `summarise(survey_mean(x))`). Same engine, friendlier for tidyverse users.
- **sampling** draws samples (stratified, PPS, balanced/cube) and also calibrates (`calib()`).
- **anesrake** does raking, but its last release was 2018 and it pulls in 100+ packages. `survey::rake()` / `calibrate()` cover the same ground.
- **sae** does small area estimation. It currently has a **CRAN deadline**; **emdi** is an actively maintained alternative to evaluate.
- **Hmisc** has handy weighted helpers (`wtd.mean`, `wtd.quantile`) but is heavy. **questionr** and **surveydata** are convenience layers for questionnaire data.

**Pick:** survey (+ srvyr) for estimation and variance, sampling for selection, survey's calibration for weighting. That pair replaces most PROC SURVEYMEANS / SURVEYFREQ / SURVEYREG work.
