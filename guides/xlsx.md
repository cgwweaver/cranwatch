<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** Excel in and out, because someone will always send a spreadsheet. None of these need Java.

- **readxl**: reads .xls and .xlsx; dependable and fast.
- **writexl**: writes plain .xlsx with zero dependencies. Ideal for "just give me the table".
- **openxlsx2**: reads and writes with full formatting (styles, merged cells, formulas, conditional formatting). It's the actively developed rewrite of **openxlsx**.

**Pick:** readxl to read, writexl for plain output, openxlsx2 when the workbook must look a certain way. Prefer CSV or Parquet for anything machine-to-machine.
