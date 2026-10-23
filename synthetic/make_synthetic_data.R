# -----------------------------------------------------------------------------
# Synthetic data so the pipeline runs end to end without restricted data.
# Values are random and carry no information about the real cohort.
# -----------------------------------------------------------------------------
suppressPackageStartupMessages(library(readxl))

make_synthetic_data <- function(n = 20000, dictionary_path = "templates/feature_dictionary.xlsx",
                                out = "synthetic/synthetic_cohort.csv", seed = 2026) {
  set.seed(seed)
  dict  <- read_excel(dictionary_path, sheet = "features")
  feats <- make.names(dict$feature_name)

  X <- sapply(seq_along(feats), function(j)
    if (j %% 2 == 0) rbinom(n, 1, runif(1, 0.05, 0.5)) else rpois(n, runif(1, 0.5, 5)))
  colnames(X) <- feats

  lin <- function() as.vector(scale(X %*% rnorm(ncol(X), 0, 0.3)))
  p1 <- plogis(-0.7 + lin()); p2 <- plogis(0.3 + 0.5 * lin()); p3 <- plogis(-0.2 + lin())
  dhd <- rbinom(n, 1, p1) == 1
  hn  <- ifelse(dhd, rbinom(n, 1, p2), rbinom(n, 1, p3)) == 1
  group <- ifelse(dhd, ifelse(hn, "DHD_highneed", "DHD_community"),
                       ifelse(hn, "nonDHD_highneed", "nonDHD_community"))

  d <- data.frame(
    ID = sprintf("P%06d", 1:n),
    index_fyear = sample(2003:2022, n, replace = TRUE),
    sex = sample(c("F", "M"), n, TRUE),
    age_group = sample(c("65-79", "80+"), n, TRUE),
    low_income = sample(c("Y", "N"), n, TRUE, prob = c(.2, .8)),
    rural = sample(c("Y", "N"), n, TRUE, prob = c(.15, .85)),
    residential_instability = sample(c("Y", "N"), n, TRUE, prob = c(.3, .7)),
    ethnic_concentration = sample(c("Y", "N"), n, TRUE, prob = c(.2, .8)),
    region = sample(c("Central", "East", "West", "Toronto", "North"), n, TRUE),
    X, trajectory_group4 = group, check.names = FALSE)
  write.csv(d, out, row.names = FALSE)
  invisible(d)
}

if (sys.nframe() == 0) make_synthetic_data()
