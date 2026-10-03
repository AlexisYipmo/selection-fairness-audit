source(file.path(project_root(), "src", "fairness.R"))

d <- load_admissions()

test_that("data matches the published 4,526 applications", {
  expect_equal(sum(d$n), 4526)
  expect_equal(nrow(d), 24)
  expect_equal(levels(d$admit), c("Rejected", "Admitted"))
})

test_that("admission rates are computed per group", {
  r <- admission_rates(d, "gender")
  expect_equal(r$applicants, c(2691, 1835))
  expect_equal(r$admitted, c(1198, 557))
  expect_equal(round(r$rate, 3), c(0.445, 0.304))
})

test_that("overall gap test returns the men minus women difference", {
  g <- gender_gap_test(d)
  expect_equal(round(g$gap, 3), 0.142)
  expect_true(g$conf_int[1] < g$gap && g$gap < g$conf_int[2])
  expect_lt(g$p_value, 1e-10)
})

test_that("chi-square uses expected counts and standardized residuals", {
  cs <- admit_dept_chisq(d)
  expect_equal(round(cs$statistic, 1), 778.9)
  expect_equal(cs$df, 5)
  expect_gt(cs$min_expected, 5)
  # Residuals of a 2-row table are symmetric: Admitted = -Rejected
  res <- cs$residuals
  expect_equal(res$std_residual[res$admit == "Admitted"],
               -res$std_residual[res$admit == "Rejected"])
  expect_equal(sum(res$observed), 4526)
})

test_that("CMH and logistic regression agree on the gender odds ratio", {
  cmh <- cmh_gender(d)
  lg <- logit_gender_dept(d)
  or_logit <- lg$odds_ratios$odds_ratio[lg$odds_ratios$term == "genderFemale"]
  expect_equal(round(cmh$odds_ratio, 2), round(or_logit, 2))
  expect_gt(cmh$p_value, 0.05)
})

test_that("application shares sum to 1 within each gender", {
  mix <- application_mix(d)
  sums <- tapply(mix$share_of_gender, mix$gender, sum)
  expect_equal(as.numeric(sums), c(1, 1))
})
