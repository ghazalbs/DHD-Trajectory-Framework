# -----------------------------------------------------------------------------
# Step 5. Combine component probabilities into four trajectory risks
# Each risk is the product of the probabilities along its branch; the four
# risks sum to one for every patient.
# -----------------------------------------------------------------------------
compose_risks <- function(comp) {
  out <- with(comp, data.frame(
    nondhd_cr = (1 - p1) * (1 - p3),
    nondhd_hn = (1 - p1) * p3,
    dhd_cr    = p1 * (1 - p2),
    dhd_hn    = p1 * p2
  ))
  stopifnot(max(abs(rowSums(out) - 1)) < 1e-8)
  out
}
