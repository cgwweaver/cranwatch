<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** a consistent framework for predictive modelling and machine learning: resampling, preprocessing, models, tuning, metrics.

- **rsample** splits and resamples (train/test, cross-validation, bootstrap). **recipes** handles preprocessing steps (impute, dummy-code, normalise) that are applied identically to new data.
- **parsnip** gives one interface over many model engines (glm, ranger, xgboost, …). **workflows** bundles a recipe with a model; **tune** and **dials** search hyperparameters; **yardstick** computes metrics.
- **broom** (`tidy()`, `glance()`, `augment()`) turns *any* model into data frames. Useful far beyond tidymodels.
- **infer** does tidy-syntax hypothesis tests and permutation inference. **modelr** is its older sibling for resampling; rsample supersedes it.
- **tidypredict** turns fitted models into SQL or R formulas so you can score *inside a database*. It currently has a **CRAN deadline**. **modeldb** fits some models in-database. **lorax** is a small newer tidymodels package; worth checking what you use it for.
- **Install burden:** the `tidymodels` meta-package pulls in 100+ packages, about half of them compiled. Install the pieces you use.

**Pick:** broom everywhere; the individual tidymodels packages when you build predictive models.
