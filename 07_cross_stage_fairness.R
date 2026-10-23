# -----------------------------------------------------------------------------
# Step 7. Cross-stage fairness analysis
#
# 1. Compute subgroup metrics (AUC, PR-AUC, xAUC, ECE) for each component
#    model and for each combined trajectory risk.
# 2. Express each as a parity ratio (comparison group / reference group).
# 3. For every trajectory risk, compare its parity ratio with those of the two
#    component models that produce it and classify the change.
# Subgroup definitions: templates/fairness_subgroups.xlsx
# -----------------------------------------------------------------------------

subgroup_metrics <- function(y, p, attr, group, reference) {
  a <- attr == group; r <- attr == reference
  c(AUC    = fast_auc(y[a], p[a])  / fast_auc(y[r], p[r]),
    PR_AUC = pr_auc(y[a], p[a])    / pr_auc(y[r], p[r]),
    xAUC   = xauc(y, p, a, r)      / xauc(y, p, r, a),
    ECE    = ece(y[a], p[a])       / ece(y[r], p[r]))
}

# Parity ratios for one score (a component model or a trajectory risk)
parity_table <- function(y, p, data, subgroups) {
  do.call(rbind, lapply(seq_len(nrow(subgroups)), function(i) {
    s <- subgroups[i, ]
    m <- subgroup_metrics(y, p, data[[s$attribute]], s$comparison_group, s$reference_group)
    data.frame(attribute = s$attribute, comparison = s$comparison_group,
               metric = names(m), ratio = unname(m))
  }))
}

# Classify how fairness changes from components to the combined risk
classify_change <- function(comp_ratios, final_ratio, bounds = c(0.80, 1.25)) {
  out_of <- function(r) !is.na(r) & (r < bounds[1] | r > bounds[2])
  dev    <- function(r) abs(log(r))
  comp_bad  <- any(out_of(comp_ratios))
  final_bad <- out_of(final_ratio)
  if (!comp_bad && !final_bad) return("Stable fairness")
  if (!comp_bad &&  final_bad) return("Emergent final unfairness")
  if ( comp_bad && !final_bad) return("Attenuation/compensation")
  if (dev(final_ratio) > max(dev(comp_ratios), na.rm = TRUE)) return("Amplified unfairness")
  "Reduced but persistent unfairness"
}

# Which components feed each trajectory risk
risk_components <- list(nondhd_cr = c("model1", "model2B"), nondhd_hn = c("model1", "model2B"),
                        dhd_cr    = c("model1", "model2A"), dhd_hn    = c("model1", "model2A"))

cross_stage_fairness <- function(d, subgroups, bounds) {
  dhd <- d$group %in% c("dhd_cr", "dhd_hn")
  comp <- rbind(
    cbind(score = "model1",  parity_table(as.integer(dhd), d$p1, d, subgroups)),
    cbind(score = "model2A", parity_table(as.integer(d$group[dhd] == "dhd_hn"),
                                          d$p2[dhd], d[dhd, ], subgroups)),
    cbind(score = "model2B", parity_table(as.integer(d$group[!dhd] == "nondhd_hn"),
                                          d$p3[!dhd], d[!dhd, ], subgroups)))
  final <- do.call(rbind, lapply(names(risk_components), function(k)
    cbind(score = k, parity_table(as.integer(d$group == k), d[[k]], d, subgroups))))

  key <- function(x) paste(x$attribute, x$comparison, x$metric)
  final$category <- vapply(seq_len(nrow(final)), function(i) {
    f <- final[i, ]
    cr <- comp$ratio[comp$score %in% risk_components[[f$score]] & key(comp) == key(f)]
    classify_change(cr, f$ratio, bounds)
  }, character(1))
  list(components = comp, final = final)
}
