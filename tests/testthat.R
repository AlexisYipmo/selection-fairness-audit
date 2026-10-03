# Run from the repository root:  Rscript tests/testthat.R
library(testthat)

root <- getwd()
while (!file.exists(file.path(root, "src", "fairness.R"))) {
  parent <- dirname(root)
  if (identical(parent, root)) stop("Run this script from inside the repository")
  root <- parent
}
source(file.path(root, "src", "fairness.R"))

test_dir(file.path(root, "tests", "testthat"), stop_on_failure = TRUE)
