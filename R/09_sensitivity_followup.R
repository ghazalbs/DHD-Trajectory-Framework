# -----------------------------------------------------------------------------
# Step 9. Sensitivity to variable follow-up
# Re-evaluates the trained models (no retraining) among test patients with at
# least k years of potential follow-up, and by index period.
# -----------------------------------------------------------------------------

followup_sensitivity <- function(d, cfg,
                                 periods = c(-Inf, 2007, 2012, 2017, 2020, Inf)) {
  fu <- cfg$data_end_year - d[[cfg$index_year_col]]
  subsets <- c(list("All test patients" = rep(TRUE, nrow(d))),
               setNames(lapply(cfg$min_followup, function(k) fu >= k),
                        paste0("Potential follow-up >= ", cfg$min_followup, " years")))
  per <- cut(d[[cfg$index_year_col]], periods)
  for (lv in levels(droplevels(per))) subsets[[paste("Index period", lv)]] <- per == lv

  do.call(rbind, lapply(names(subsets), function(s) {
    dd <- d[which(subsets[[s]]), ]
    cbind(subset = s, n = nrow(dd), boot_ci(dd, auc_summary, B = cfg$n_boot, seed = cfg$seed))
  }))
}
