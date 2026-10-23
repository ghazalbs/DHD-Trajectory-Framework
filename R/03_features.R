# -----------------------------------------------------------------------------
# Step 3. Design matrices
# Predictors and their Andersen-model mapping are listed in
# templates/feature_dictionary.xlsx.
# -----------------------------------------------------------------------------
suppressPackageStartupMessages(library(Matrix))

build_matrix <- function(data, predictors, ref_cols = NULL) {
  f <- stats::as.formula(paste("~", paste(predictors, collapse = " + ")))
  X <- Matrix::sparse.model.matrix(f, data = data)[, -1, drop = FALSE]
  stopifnot(nrow(X) == nrow(data))            # no rows silently dropped
  if (!is.null(ref_cols)) X <- align_columns(X, ref_cols)
  X
}

# Make a matrix match the training columns (adds absent levels as zeros)
align_columns <- function(X, cols) {
  miss <- setdiff(cols, colnames(X))
  if (length(miss))
    X <- cbind(X, Matrix::Matrix(0, nrow(X), length(miss), sparse = TRUE,
                                 dimnames = list(NULL, miss)))
  X[, cols, drop = FALSE]
}
