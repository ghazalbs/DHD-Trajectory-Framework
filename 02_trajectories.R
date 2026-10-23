# -----------------------------------------------------------------------------
# Step 2. Trajectory labels
#
# Each patient's post-index care sequence is assigned to one family
# (DHD-related if a DHD/ALC designation occurs at any point, else non-DHD) and
# then to one pathway, using a fixed priority so categories do not overlap:
#   terminal  >  institution-anchored  >  community return
# Terminal and institution-anchored pathways are combined as "high-need".
# See templates/trajectory_definitions.xlsx.
# -----------------------------------------------------------------------------

assign_trajectory <- function(any_dhd, any_terminal, any_institution) {
  family  <- ifelse(any_dhd, "DHD", "nonDHD")
  pathway <- ifelse(any_terminal | any_institution, "highneed", "community")
  paste(family, pathway, sep = "_")
}

# Binary labels for the three component models
stage_labels <- function(group, cfg) {
  g <- names(cfg$groups)[match(group, cfg$groups)]
  dhd <- g %in% c("dhd_cr", "dhd_hn")
  list(
    y1  = as.integer(dhd),                                 # Model 1: DHD vs non-DHD
    y2a = ifelse(dhd,  as.integer(g == "dhd_hn"), NA),     # Model 2A: within DHD
    y2b = ifelse(!dhd, as.integer(g == "nondhd_hn"), NA),  # Model 2B: within non-DHD
    group = g
  )
}
