# -----------------------------------------------------------------------------
# Step 4. Two-stage LightGBM framework
#   Model 1  : DHD-related vs non-DHD (all patients)
#   Model 2A : high-need vs community return, trained on DHD patients
#   Model 2B : high-need vs community return, trained on non-DHD patients
# Hyperparameters: grid in templates/hyperparameter_grid.xlsx, tuned by k-fold
# cross-validation on the training set (AUC), class-weighted learning.
# -----------------------------------------------------------------------------
suppressPackageStartupMessages(library(lightgbm))

fit_binary_lgb <- function(X, y, grid, cfg) {
  w  <- ifelse(y == 1, sum(y == 0) / sum(y == 1), 1)        # class weighting
  dt <- lgb.Dataset(X, label = y, weight = w, free_raw_data = FALSE)
  base <- list(objective = "binary", metric = "auc", verbosity = -1, seed = cfg$seed)

  cv <- lapply(seq_len(nrow(grid)), function(i) {
    r <- lgb.cv(params = c(base, as.list(grid[i, ])), data = dt,
                nrounds = cfg$max_rounds, nfold = cfg$cv_folds, stratified = TRUE,
                early_stopping_rounds = cfg$early_stopping, verbose = -1)
    data.frame(grid[i, ], best_iter = r$best_iter, cv_auc = r$best_score)
  })
  cv   <- do.call(rbind, cv)
  best <- cv[which.max(cv$cv_auc), ]
  model <- lgb.train(params = c(base, as.list(best[, names(grid)])), data = dt,
                     nrounds = best$best_iter, verbose = -1)
  list(model = model, cv = cv, best = best, columns = colnames(X))
}

fit_two_stage <- function(X, labels, grid, cfg) {
  dhd <- labels$y1 == 1
  list(
    m1  = fit_binary_lgb(X,         labels$y1,       grid, cfg),
    m2a = fit_binary_lgb(X[dhd, ],  labels$y2a[dhd], grid, cfg),
    m2b = fit_binary_lgb(X[!dhd, ], labels$y2b[!dhd], grid, cfg)
  )
}

predict_components <- function(fit, X) {
  data.frame(
    p1 = predict(fit$m1$model,  X),   # P(DHD-related)
    p2 = predict(fit$m2a$model, X),   # P(high-need | DHD)
    p3 = predict(fit$m2b$model, X)    # P(high-need | non-DHD)
  )
}
