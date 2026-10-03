# Reusable functions for the selection fairness audit.
# Base R + stats only, so they can be unit-tested without the plotting stack.

EXPECTED_TOTAL <- 4526L

#' Repository root: first parent folder containing src/fairness.R.
#' Lets the notebook, the tests and the scripts use relative paths from anywhere.
project_root <- function(start = getwd()) {
  dir <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(dir, "src", "fairness.R"))) return(dir)
    parent <- dirname(dir)
    if (identical(parent, dir)) stop("Project root not found from ", start)
    dir <- parent
  }
}

#' UC Berkeley 1973 admissions as a long data frame (one row per cell).
#' Reference levels: Rejected, Male, department A.
load_admissions <- function() {
  d <- as.data.frame(datasets::UCBAdmissions, stringsAsFactors = FALSE)
  names(d) <- c("admit", "gender", "dept", "n")
  d$admit <- factor(d$admit, levels = c("Rejected", "Admitted"))
  d$gender <- factor(d$gender, levels = c("Male", "Female"))
  d$dept <- factor(d$dept, levels = LETTERS[1:6])
  d$n <- as.integer(d$n)
  if (sum(d$n) != EXPECTED_TOTAL) {
    stop(sprintf("Expected %d applications, found %d", EXPECTED_TOTAL, sum(d$n)))
  }
  d
}

#' Admission rate by one or more grouping columns.
admission_rates <- function(data, by) {
  f <- stats::as.formula(paste("n ~", paste(by, collapse = " + ")))
  total <- stats::aggregate(f, data = data, FUN = sum)
  admitted <- stats::aggregate(f, data = data[data$admit == "Admitted", ], FUN = sum)
  names(total)[names(total) == "n"] <- "applicants"
  names(admitted)[names(admitted) == "n"] <- "admitted"
  out <- merge(total, admitted, by = by)
  out$rate <- out$admitted / out$applicants
  out[do.call(order, out[by]), , drop = FALSE]
}

#' Overall gap in admission rate, men minus women, with a 95 % CI.
#' Uses prop.test (chi-square with Yates correction, 1 df).
gender_gap_test <- function(data, conf_level = 0.95) {
  r <- admission_rates(data, "gender")
  test <- stats::prop.test(r$admitted, r$applicants, conf.level = conf_level)
  list(
    rate_male = r$rate[r$gender == "Male"],
    rate_female = r$rate[r$gender == "Female"],
    gap = unname(test$estimate[1] - test$estimate[2]),
    conf_int = as.numeric(test$conf.int),
    statistic = unname(test$statistic),
    p_value = test$p.value
  )
}

#' Chi-square test of independence Admit x Dept, with the checks the
#' coursework skipped: expected counts (not observed ones) and standardized
#' residuals to locate the cells that drive the dependence.
admit_dept_chisq <- function(data) {
  tab <- stats::xtabs(n ~ admit + dept, data = data)
  test <- suppressWarnings(stats::chisq.test(tab, correct = FALSE))
  k <- min(dim(tab)) - 1
  stdres <- as.data.frame(as.table(test$stdres), stringsAsFactors = FALSE)
  names(stdres) <- c("admit", "dept", "std_residual")
  stdres$observed <- as.vector(tab)
  stdres$expected <- as.vector(test$expected)
  list(
    statistic = unname(test$statistic),
    df = unname(test$parameter),
    p_value = test$p.value,
    min_expected = min(test$expected),
    share_expected_ge5 = mean(test$expected >= 5),
    cramers_v = sqrt(unname(test$statistic) / (sum(tab) * k)),
    residuals = stdres
  )
}

#' Cochran-Mantel-Haenszel test of Admit x Gender stratified by department.
#' Odds ratio is expressed as women vs men (> 1 favours women).
cmh_gender <- function(data) {
  tab <- stats::xtabs(n ~ gender + admit + dept, data = data)
  # Put Female first and Admitted first so the common OR reads "women vs men"
  tab <- tab[c("Female", "Male"), c("Admitted", "Rejected"), ]
  test <- stats::mantelhaen.test(tab)
  list(
    odds_ratio = unname(test$estimate),
    conf_int = as.numeric(test$conf.int),
    statistic = unname(test$statistic),
    p_value = test$p.value
  )
}

#' Logistic regression Admit ~ Gender + Dept on aggregated counts.
#' Returns odds ratios with Wald 95 % CIs and the likelihood-ratio test of
#' the Gender x Dept interaction (is the gender effect the same everywhere?).
logit_gender_dept <- function(data, conf_level = 0.95) {
  fit <- stats::glm(admit ~ gender + dept, family = stats::binomial(),
                    data = data, weights = n)
  fit_int <- stats::glm(admit ~ gender * dept, family = stats::binomial(),
                        data = data, weights = n)
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  est <- stats::coef(summary(fit))
  or <- data.frame(
    term = rownames(est),
    odds_ratio = exp(est[, "Estimate"]),
    conf_low = exp(est[, "Estimate"] - z * est[, "Std. Error"]),
    conf_high = exp(est[, "Estimate"] + z * est[, "Std. Error"]),
    p_value = est[, "Pr(>|z|)"],
    row.names = NULL
  )
  lrt <- stats::anova(fit, fit_int, test = "LRT")
  list(model = fit, odds_ratios = or,
       interaction_p = lrt[["Pr(>Chi)"]][2],
       interaction_deviance = lrt[["Deviance"]][2])
}

#' Where each gender applied: share of its applications going to each
#' department, next to that department's overall admission rate.
application_mix <- function(data) {
  apps <- admission_rates(data, c("dept", "gender"))
  apps$share_of_gender <- stats::ave(apps$applicants, apps$gender,
                                     FUN = function(x) x / sum(x))
  dept_rate <- admission_rates(data, "dept")[, c("dept", "rate")]
  names(dept_rate)[2] <- "dept_rate"
  merge(apps, dept_rate, by = "dept")
}
