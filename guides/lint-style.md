<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** keeping code readable and consistent, which matters most when a team inherits a converted SAS program.

- **styler** *rewrites* code into tidyverse style: indentation, spacing, line breaks. It's available as an RStudio add-in ("Style active file").
- **lintr** *reports* problems without changing anything: unused variables, `T`/`F`, very long lines, inconsistent naming. It's good in CI or as a pre-merge check.
- Worth a look: **Air**, Posit's very fast formatter. It's a command-line tool rather than an R package, also integrated into Positron/VS Code.

**Pick:** both. Format with styler (or Air) and check with lintr. Agree on the style once as a team, so code review is about logic, not spacing.
