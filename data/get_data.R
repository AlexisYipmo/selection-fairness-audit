# Export the public UC Berkeley 1973 admissions data to data/raw/ (git-ignored).
#
# The data ships with base R (datasets::UCBAdmissions), so no download is needed;
# this script makes the analysed table explicit and checks it against the
# published total of 4,526 applications.
#
# Usage, from the repository root:
#   Rscript data/get_data.R

source(file.path("src", "fairness.R"))

admissions <- load_admissions()

raw_dir <- file.path("data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
out <- file.path(raw_dir, "ucb_admissions_1973.csv")
utils::write.csv(admissions, out, row.names = FALSE)

message(sprintf("Wrote %s: %d cells, %d applications", out, nrow(admissions), sum(admissions$n)))
