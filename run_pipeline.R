# -----------------------------------------------------------------------------
# Two-stage trajectory prediction with cross-stage fairness analysis
# End-to-end pipeline (runs on synthetic data by default)
# -----------------------------------------------------------------------------
suppressPackageStartupMessages({ library(readxl); library(Matrix); library(lightgbm) })

source("config/config.R")
for (f in sort(list.files("R", full.names = TRUE))) source(f)
set.seed(cfg$seed)
dir.create(cfg$output_dir, showWarnings = FALSE)

# 1. Data -----------------------------------------------------------------------
if (!file.exists(cfg$data_path)) { source("synthetic/make_synthetic_data.R"); make_synthetic_data() }
d    <- read.csv(cfg$data_path, check.names = FALSE, stringsAsFactors = FALSE)
dict <- read_excel(file.path(cfg$templates_dir, "feature_dictionary.xlsx"), "features")
grid <- as.data.frame(read_excel(file.path(cfg$templates_dir, "hyperparameter_grid.xlsx"), "grid"))
subg <- as.data.frame(read_excel(file.path(cfg$templates_dir, "fairness_subgroups.xlsx"), "subgroups"))

# 2. Labels and stratified train/test split --------------------------------------
lab <- stage_labels(d[[cfg$outcome_col]], cfg)
d$group <- lab$group
test_idx <- unlist(lapply(split(seq_len(nrow(d)), d$group),
                          function(i) sample(i, round(cfg$test_fraction * length(i)))))
is_test <- seq_len(nrow(d)) %in% test_idx

# 3. Design matrices -------------------------------------------------------------
predictors <- intersect(make.names(dict$feature_name), names(d))
X_train <- build_matrix(d[!is_test, ], predictors)
X_test  <- build_matrix(d[is_test, ],  predictors, ref_cols = colnames(X_train))
lab_train <- lapply(lab, function(v) v[!is_test])

# 4-5. Two-stage models and combined risks ---------------------------------------
fit  <- fit_two_stage(X_train, lab_train, grid, cfg)
comp <- predict_components(fit, X_test)
test <- cbind(d[is_test, ], comp, compose_risks(comp))

# 6. Discrimination (bootstrap CI) and calibration --------------------------------
write.csv(boot_ci(test, auc_summary, B = cfg$n_boot, seed = cfg$seed),
          file.path(cfg$output_dir, "auc_summary.csv"), row.names = FALSE)
write.csv(data.frame(trajectory = names(calibration_summary(test)), ece = calibration_summary(test)),
          file.path(cfg$output_dir, "calibration_ece.csv"), row.names = FALSE)

# 7. Cross-stage fairness ---------------------------------------------------------
fair <- cross_stage_fairness(test, subg, cfg$parity_bounds)
write.csv(fair$components, file.path(cfg$output_dir, "fairness_components.csv"), row.names = FALSE)
write.csv(fair$final,      file.path(cfg$output_dir, "fairness_final_with_categories.csv"), row.names = FALSE)

# 8. SHAP aggregated onto Andersen's model ---------------------------------------
shap_out <- do.call(rbind, lapply(c("m1", "m2a", "m2b"), function(m)
  cbind(model = m, andersen_shares(shap_values(fit[[m]]$model, X_test), dict))))
write.csv(shap_out, file.path(cfg$output_dir, "shap_andersen_shares.csv"), row.names = FALSE)

# 9. Sensitivity to follow-up -----------------------------------------------------
write.csv(followup_sensitivity(test, cfg),
          file.path(cfg$output_dir, "followup_sensitivity.csv"), row.names = FALSE)

cat("Done. Outputs written to", cfg$output_dir, "\n")
