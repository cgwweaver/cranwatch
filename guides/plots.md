<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** arranging several ggplot2 plots into one figure.

- **gridExtra** (`grid.arrange()`) is long-standing and has few dependencies.
- **ggpubr** (`ggarrange()`) has publication-style themes and adds p-values to plots, but brings 70+ dependencies.
- Worth adding: **patchwork**. `p1 + p2`, `p1 / p2` is the simplest syntax, with shared legends and annotations. It's what most people reach for now.

**Pick:** patchwork for layouts, ggpubr only if you want its statistical annotations.
