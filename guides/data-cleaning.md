<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** rule-based data editing for official statistics, from Mark van der Loo and Edwin de Jonge at Statistics Netherlands. Validation rules live *outside* the code as data, and the same rule set drives checking, error localisation and correction. Conceptually it's close to a Banff-style edit-and-imputation process, and it follows the European Statistical System's validation framework.

The flow:
1. **validate** defines rules (`validator(turnover >= 0, staff > 0 | turnover == 0)`), `confront()`s data with them, and summarises violations.
2. **validatetools** checks a rule set for redundancy and contradictions.
3. **errorlocate** finds the *minimal* set of fields to change so a record passes all rules (Fellegi–Holt error localisation).
4. **dcmodify** applies rule-based corrections; **deductive** imputes values that the rules force.
5. **validatesuggest** proposes candidate rules from existing data.

Other repos in the family:
- **validate.viz** and **validatereport** (reporting) and **deriverules** are GitHub-only.
- **validatedb** and **dcmodifydb** (the same ideas run inside a database via dbplyr) were archived from CRAN in 2023.
- **editrules** and **deducorrect** are the predecessors of validate and dcmodify/deductive.
- Background: their book *Statistical Data Cleaning with Applications in R* (Wiley, 2018).

**Pick:** validate + errorlocate + dcmodify for a documented, rule-driven editing step.
