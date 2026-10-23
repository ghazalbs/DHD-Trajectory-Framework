# -----------------------------------------------------------------------------
# Step 1. Cohort construction  (data-source specific; skeleton only)
#
# The study used linked health administrative data held at ICES (Ontario):
#   DAD  - acute-care hospitalizations (diagnoses, disposition, ALC/DHD days)
#   RPDB - demographics and socio-economic
#   WTIS (surgery and entry) - surgical wait times and ALC information
# These data cannot be shared. Replace this step with your own data source.
#
# Expected output: one row per patient with
#   ID, index admission date / fiscal year, predictors (see templates/
#   feature_dictionary.xlsx), equity attributes, and the post-index sequence of
#   care states used in Step 2.
# -----------------------------------------------------------------------------

build_cohort <- function(cfg) {
  # 1. Identify hospitalizations with a dementia diagnosis (any diagnosis field)
  # 2. Keep patients aged >= 65; define the earliest such stay as the index
  # 3. Build predictors from records BEFORE the index admission (+ admission
  #    characteristics available at the time of prediction)
  # 4. Assemble the post-index sequence of care states for trajectory labels
  stop("build_cohort() is data-source specific. Use synthetic/make_synthetic_data.R ",
       "to run the pipeline end to end, or implement this step for your data.")
}
