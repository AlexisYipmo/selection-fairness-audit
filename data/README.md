# Data sources

| Object | Source | Licence | Unit | Size |
|---|---|---|---|---|
| `datasets::UCBAdmissions` | Graduate admissions, University of California, Berkeley, fall 1973. Published in Bickel, Hammel & O'Connell (1975), *Sex Bias in Graduate Admissions: Data from Berkeley*, Science 187(4175), 398-404. Shipped with base R. | Part of R (GPL-2 / GPL-3) | Applications to the six largest departments | 2 x 2 x 6 table, 4,526 applications |

The data is built into R, so nothing is downloaded. `Rscript data/get_data.R` writes the long-format table to `data/raw/ucb_admissions_1973.csv` (git-ignored) and checks the 4,526 total.

## Data dictionary

| Column | Type | Values |
|---|---|---|
| `admit` | factor | `Admitted`, `Rejected` |
| `gender` | factor | `Male`, `Female` (as recorded in 1973) |
| `dept` | factor | `A` to `F` (department names were anonymised in the original publication) |
| `n` | integer | Number of applications in the cell |

## Check against the original coursework file

The coursework notebook (kept locally in `legacy/`, not versioned) used a CSV with the same 4,526 total and the same number of admitted applicants per department, but **244 rejections recorded under department E instead of D**. 244 is exactly the number of rejected female applicants to department D in the published table. This project uses the published table; the coursework chi-square on Admit x Dept (904.3) therefore differs from the one reported here (778.9).

## Privacy

Aggregated counts only. No individual record, name or identifier.
