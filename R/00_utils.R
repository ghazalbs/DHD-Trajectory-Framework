# -----------------------------------------------------------------------------
# Shared metric helpers
# -----------------------------------------------------------------------------

# AUC via the Mann-Whitney statistic (equivalent to pROC::auc)
fast_auc <- function(y, p) {
  y <- as.logical(y); n1 <- sum(y); n0 <- sum(!y)
  if (n1 == 0 || n0 == 0) return(NA_real_)
  (sum(rank(p)[y]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

# Precision-recall AUC (average precision)
pr_auc <- function(y, p) {
  y <- as.logical(y); if (!any(y)) return(NA_real_)
  o <- order(p, decreasing = TRUE); y <- y[o]
  tp <- cumsum(y); prec <- tp / seq_along(y)
  sum(prec[y]) / sum(y)
}

# Expected calibration error, equal-width bins
ece <- function(y, p, bins = 10) {
  b <- cut(p, seq(0, 1, length.out = bins + 1), include.lowest = TRUE)
  agg <- aggregate(cbind(y = as.numeric(y), p = p), by = list(b = b), FUN = mean)
  n   <- as.numeric(table(b)[as.character(agg$b)])
  sum(n / length(p) * abs(agg$y - agg$p))
}

# Cross-group AUC: P(score of a positive in group a > score of a negative in group b)
xauc <- function(y, p, in_a, in_b) {
  pos <- p[as.logical(y) & in_a]; neg <- p[!as.logical(y) & in_b]
  if (!length(pos) || !length(neg)) return(NA_real_)
  fast_auc(c(rep(TRUE, length(pos)), rep(FALSE, length(neg))), c(pos, neg))
}

# Percentile bootstrap CI for any statistic of a data frame
boot_ci <- function(d, stat_fun, B = 500, seed = 1) {
  set.seed(seed)
  est  <- stat_fun(d)
  reps <- replicate(B, stat_fun(d[sample.int(nrow(d), replace = TRUE), , drop = FALSE]))
  reps <- matrix(reps, nrow = length(est))
  data.frame(metric = names(est), estimate = est,
             ci_lo = apply(reps, 1, quantile, 0.025, na.rm = TRUE),
             ci_hi = apply(reps, 1, quantile, 0.975, na.rm = TRUE), row.names = NULL)
}
