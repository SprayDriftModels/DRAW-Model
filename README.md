# DRAW Model Prediction App

A Shiny app for **spray drift prediction** in agricultural risk assessment, using Bayesian multilevel regression models fitted with [brms](https://paul-buerkner.github.io/brms/). A deliverable of the [SETAC DRAW workshop](https://www.spraydriftmitigation.info/).

The app predicts spray drift deposition at various downwind distances under user-specified environmental conditions and application settings, and compares predictions against [Rautmann reference curves](https://doi.org/10.1007/978-3-662-04653-1_18).

## Features

- **Dashboard**: Configure application settings (pressure, boom height, speed, rate), environmental conditions (wind speed, temperature, WBD/RH), and crop information to generate drift predictions with credible/prediction intervals.
- **Trial Comparisons**: Visualise how individual factors (boom height, WBD, wind speed, drop spectra, tractor speed) affect drift using example trial pairs from the DRAW database.
- **Report Download**: Generate an HTML report of the current prediction scenario.
- **Model Selection**: Choose between a Bayesian multilevel model (BRM-lognormal) or a frequentist linear mixed model (LME).

## Getting Started

### Prerequisites

R â‰¥ 4.3 and the following packages:

```r
install.packages(c(
  "shiny", "bslib", "DT", "gridExtra",
  "brms", "lme4", "nleqslv",
  "dplyr", "tidyr", "ggplot2", "scales",
  "rmarkdown", "knitr"
))
```

### Download model data

The fitted model objects (~470 MB total) are hosted as a GitHub Release asset and are **not included in the repository**. They are downloaded automatically on first run, or you can download them manually:

```r
# Automatic: just run the app â€” it will prompt to download
shiny::runApp()

# Manual: download from the latest GitHub Release
# Place files in program/data/
```

### Run the app

```r
shiny::runApp()
```

## Project Structure

```
â”œâ”€â”€ app.R                  # Shiny app (UI + server)
â”œâ”€â”€ functions.R            # Domain logic: models, predictions, plots
â”œâ”€â”€ report.Rmd             # Downloadable HTML report template
â””â”€â”€ program/
    â”œâ”€â”€ Documentation.html # About DRAW (rendered HTML)
    â”œâ”€â”€ Documentation.md   # About DRAW (source)
    â”œâ”€â”€ Manual.md          # User manual
    â””â”€â”€ data/
        â”œâ”€â”€ fit.STD.NoAngle.addTemp.rda  # brms model (~460 MB, via Release)
        â”œâ”€â”€ mod.STD.NoAngle.addTemp.rda  # lme4 model (~8 MB, via Release)
        â”œâ”€â”€ rautmann.rda                 # Rautmann reference curves
        â”œâ”€â”€ comparedat.rda               # Pre-computed comparison trial data
        â””â”€â”€ ComparisonCases.csv          # Comparison trial metadata
```

## Background

Spray drift can be defined as the quantity of plant protection product carried out of the sprayed area by air currents during application. The DRAW (Drift Risk Assessment Workshop) database assembled spray drift trials for boom sprayers from research institutions across the EU and North America.

The models use a Bayesian multilevel framework where each trial has its own intercept and slope for the log-distance relationship, with fixed effects for environmental covariates (wind speed, temperature, wet bulb depression, pressure, boom height, crop height, tractor speed).

For details, see the **About DRAW** tab in the app or the [SETAC DRAW website](https://www.spraydriftmitigation.info/).

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3) — see [LICENSE](LICENSE) for details.

The fitted model objects are derived from the SETAC DRAW database, which is subject to its own data sharing agreement. See the [SETAC DRAW website](https://www.spraydriftmitigation.info/) for details.

## Citation

If you use this app in your work, please cite the SETAC DRAW workshop and the associated publication.
