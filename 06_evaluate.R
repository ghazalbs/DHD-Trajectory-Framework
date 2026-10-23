# -----------------------------------------------------------------------------
# Step 6. Discrimination, calibration and threshold-dependent performance
# -----------------------------------------------------------------------------

# Component and trajectory-level AUCs (+ macro-AUC) for one data frame holding
# group, p1, p2, p3 and the four composed risks
auc_summary <- function(d) {
  dhd  <- d$group %in% c("dhd_cr", "dhd_hn")
  traj <- sapply(c("nondhd_cr", "nondhd_hn", "dhd_cr", "dhd_hn"),
                 function(k) fast_auc(d$group == k, d[[k]]))
  c(model1  = fast_auc(dhd, d$p1),
    model2A = fast_auc(d$group[dhd]  == "dhd_hn",    d$p2[dhd]),
    model2B = fast_auc(d$group[!dhd] == "nondhd_hn", d$p3[!dhd]),
    traj, macro_auc = mean(traj))
}

calibration_summary <- function(d) {
  sapply(c("nondhd_cr", "nondhd_hn", "dhd_cr", "dhd_hn"),
         function(k) ece(d$group == k, d[[k]]))
}

# Recall, precision, specificity and F1 across thresholds for a binary model
threshold_table <- function(y, p, thresholds = seq(0.05, 0.95, by = 0.01)) {
  do.call(rbind, lapply(thresholds, function(t) {
    pred <- p >= t
    tp <- sum(pred & y == 1); fp <- sum(pred & y == 0)
    fn <- sum(!pred & y == 1); tn <- sum(!pred & y == 0)
    rec <- tp / (tp + fn); prec <- ifelse(tp + fp > 0, tp / (tp + fp), NA)
    data.frame(threshold = t, recall = rec, precision = prec,
               specificity = tn / (tn + fp), f1 = 2 * prec * rec / (prec + rec))
  }))
}
