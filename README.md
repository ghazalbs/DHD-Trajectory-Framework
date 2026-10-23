# Two-stage trajectory prediction with cross-stage fairness analysis

Skeleton code accompanying:

> Ghazalbash S, Zargoush M, Newbold KB. *Predicting Delayed Discharge Trajectories in Patients with Dementia: A Two-Stage Machine Learning Framework with Cross-Stage Fairness Analysis and Explainable Decision Support.* (under review)

The study data are held at ICES (Ontario, Canada) and cannot be shared. This repository provides the
analytic workflow as a runnable skeleton on **synthetic data**, so that the framework can be inspected
and adapted to other data sources.

## Framework

```
Patient features ──► Model 1: DHD-related vs non-DHD            p1
                     Model 2A: high-need vs community | DHD      p2
                     Model 2B: high-need vs community | non-DHD  p3
                          │
                          ▼
     Combined trajectory risks (sum to 1 for each patient)
       DHD high-need          = p1 · p2
       DHD community return   = p1 · (1 − p2)
       non-DHD high-need      = (1 − p1) · p3
       non-DHD community      = (1 − p1) · (1 − p3)
                          │
     ┌────────────────────┼─────────────────────┐
     ▼                    ▼                     ▼
 Discrimination &   Cross-stage fairness   SHAP aggregated onto
 calibration        (components vs final)  Andersen's behavioral model
```

## Repository structure

| Path | Content |
|---|---|
| `config/config.R` | Paths, outcome coding, split, tuning and fairness settings |
| `R/00_utils.R` | AUC, PR-AUC, xAUC, ECE, bootstrap CI |
| `R/01_cohort.R` | Cohort construction (data-source specific; skeleton only) |
| `R/02_trajectories.R` | Trajectory labels and component-model outcomes |
| `R/03_features.R` | Design matrices and train/test column alignment |
| `R/04_two_stage_models.R` | LightGBM component models with cross-validated tuning |
| `R/05_compose.R` | Combining component probabilities into trajectory risks |
| `R/06_evaluate.R` | Discrimination, calibration, threshold-dependent metrics |
| `R/07_cross_stage_fairness.R` | Subgroup parity ratios and cross-stage categories |
| `R/08_shap_andersen.R` | SHAP values and Andersen-construct shares |
| `R/09_sensitivity_followup.R` | Re-evaluation by potential follow-up and index period |
| `templates/*.xlsx` | Feature dictionary, trajectory definitions, fairness subgroups, hyperparameter grid |
| `synthetic/make_synthetic_data.R` | Generates a random cohort with the expected columns |
| `run_pipeline.R` | Runs all steps end to end |

## Templates

- **feature_dictionary.xlsx**: model features with their Andersen major construct, subconstruct and decision implication.
- **trajectory_definitions.xlsx**: assignment rules and priority (terminal > institution-anchored > community return) and how each final group is modelled.
- **fairness_subgroups.xlsx**: equity attributes, comparison and reference groups, and the definitions of cross-stage categories (80% rule).
- **hyperparameter_grid.xlsx**: grid searched by cross-validation.

## Running

```r
# R >= 4.2; packages: lightgbm, Matrix, readxl
install.packages(c("lightgbm", "Matrix", "readxl"))
source("run_pipeline.R")   # creates synthetic data on first run; results in outputs/
```

To use your own data, implement `build_cohort()` in `R/01_cohort.R`, set `data_path` in
`config/config.R`, and edit the templates to match your variables and subgroups.

Results on synthetic data are random and are **not** the study results.

## Citation

Please cite the article above if you use or adapt this code.

## License

MIT (see `LICENSE`).
