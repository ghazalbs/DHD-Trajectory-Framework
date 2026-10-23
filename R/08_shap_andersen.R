# -----------------------------------------------------------------------------
# Step 8. Explainability: SHAP values aggregated onto Andersen's behavioral
# model of health services use (mapping in templates/feature_dictionary.xlsx)
# -----------------------------------------------------------------------------

shap_values <- function(model, X) {
  # LightGBM's built-in TreeSHAP; last column is the baseline (bias term)
  s <- tryCatch(predict(model, X, type = "contrib"),          # lightgbm >= 4
                error = function(e) predict(model, X, predcontrib = TRUE))
  s <- as.matrix(s)[, seq_len(ncol(X)), drop = FALSE]
  colnames(s) <- colnames(X)
  s
}

# Share of total |SHAP| by Andersen construct / subconstruct
andersen_shares <- function(shap, dictionary, level = "andersen_subconstruct") {
  imp <- colMeans(abs(shap))
  map <- dictionary[[level]][match(names(imp), make.names(dictionary$feature_name))]
  map[is.na(map)] <- "Unmapped"
  agg <- tapply(imp, map, sum)
  data.frame(domain = names(agg), share = as.numeric(agg / sum(agg)), row.names = NULL)
}
