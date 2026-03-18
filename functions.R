# ============================================================================
# functions.R - Domain logic for DRAW Model Prediction App
# ============================================================================
# Contains: wet bulb calculations, data preparation, prediction plotting
# ============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(brms)
library(lme4)
library(nleqslv)
library(scales)
library(gridExtra)

# ============================================================================
# Download model files from GitHub Releases if not present locally
# ============================================================================

RELEASE_URL <- "https://github.com/SprayDriftModels/DRAW-Model/releases/download/v1.0.0"

download_model_file <- function(filename) {
  dest <- file.path("program", "data", filename)
  if (!file.exists(dest)) {
    url <- paste0(RELEASE_URL, "/", filename)
    message("Downloading ", filename, " from GitHub Release...")
    message("  URL: ", url)
    tryCatch({
      download.file(url, dest, mode = "wb")
      message("  Done.")
    }, error = function(e) {
      stop(
        "Failed to download ", filename, ": ", conditionMessage(e), "\n",
        "Download manually from: ", url, "\n",
        "Place in: ", normalizePath(dirname(dest), mustWork = FALSE),
        call. = FALSE
      )
    })
  }
}

download_model_file("fit.STD.NoAngle.addTemp.rda")
download_model_file("mod.STD.NoAngle.addTemp.rda")

# -- Load model objects and reference data --
load("program/data/fit.STD.NoAngle.addTemp.rda")
load("program/data/mod.STD.NoAngle.addTemp.rda")
load("program/data/rautmann.rda")

# comparedat.rda may be missing
comparedat <- NULL
comparedat_available <- FALSE
if (file.exists("program/data/comparedat.rda")) {
  tryCatch({
    load("program/data/comparedat.rda")
    comparedat_available <- TRUE
  }, error = function(e) {
    message("Note: comparedat.rda could not be loaded (", conditionMessage(e), ")")
    message("  Trial Comparisons tab will be disabled.")
  })
} else {
  message("Note: comparedat.rda not found. Trial Comparisons tab will be disabled.")
}

compareTrials <- read.csv("program/data/ComparisonCases.csv")

# ============================================================================
# Wet Bulb Depression
# ============================================================================

#' Wet Bulb Depression (rigorous thermodynamic calculation)
#'
#' @param Tair Dry air temperature (Celsius)
#' @param Patm Barometric pressure (mmHg abs)
#' @param RH Relative humidity (%)
#' @return Named numeric vector: DTwb (depression) and Twb (wet bulb T)
wet_bulb <- function(Tair = 17.689, Patm = 760, RH = 35.65) {
  aw <- 18.92676
  bw <- -4169.627
  cw <- -33.568
  air <- 6.917
  bair <- 9.911e-4
  cair <- 7.627e-7
  dair <- -4.696e-10
  Dh0 <- 717.2184
  n <- 0.33246

  MWair <- 2 * (0.79 * 14.007 + 0.21 * 15.994)
  MWw <- 2 * 1.008 + 15.9994

  Psw <- function(T) {
    exp(aw + bw / (T + 273.15 + cw))
  }

  Cpair <- function(T) {
    (air + bair * T + cair * T^2 + dair * T^3) / MWair
  }

  DHv <- function(T) {
    Dh0 * (1 - (T + 273.15) / 647.3)^n
  }

  Tdp <- bw / (log(Psw(Tair) * RH / 100) - aw) - 273.15 - cw

  Eqn <- function(T) {
    Psw(Tdp) - Psw(T) - Patm * MWair / MWw * Cpair(T) * (T - Tair) / DHv(T)
  }

  Twb <- nleqslv::nleqslv(0, Eqn)$x[1]
  DTwb <- Tair - Twb

  c(DTwb = DTwb, Twb = Twb)
}


#' Wet Bulb Depression (Stull approximation)
#'
#' @param Tair Dry air temperature (Celsius)
#' @param RH Relative humidity (%)
#' @return Named numeric vector: DTwb (depression) and Twb (wet bulb T)
wet_bulb_Stull <- function(Tair = 17.689, RH = 50) {
  Twb <- Tair *
    atan(0.151977 * (RH + 8.313659)^(1 / 2)) +
    atan(Tair + RH) -
    atan(RH - 1.676331) +
    0.00391838 * (RH)^(3 / 2) * atan(0.023101 * RH) -
    4.686035
  DTwb <- Tair - Twb
  c(DTwb = DTwb, Twb = Twb)
}


# ============================================================================
# Crop height classification
# ============================================================================

#' Classify crop height into categories
#'
#' @param Crop.Height Numeric crop height in meters
#' @return Character height category
getHeight1 <- function(Crop.Height) {
  sapply(Crop.Height, function(x) {
    if (is.na(x)) {
      NA_character_
    } else if (x < 0.2) {
      "0-0.2"
    } else if (x <= 0.4) {
      "0.2-0.4"
    } else {
      "0.4-1"
    }
  })
}


# ============================================================================
# Data preparation for prediction
# ============================================================================

#' Build prediction newdata from user inputs
#'
#' @param Windspeed Wind speed (m/s)
#' @param Boom.height Boom height above crop (m)
#' @param Pressure Nozzle pressure (bar)
#' @param Temp Temperature (Celsius)
#' @param Crop.Height Crop height (m)
#' @param Speed Tractor forward speed (m/s)
#' @param Rate Application rate
#' @param WBD Wet bulb depression (Celsius)
#' @param RH Relative humidity (%), used if WBD is NULL
#' @param Cot Cotyledon category: "monocot", "dicot", "Bare Ground"
#' @return data.frame suitable for brms/lme4 prediction
getNewData <- function(
  Windspeed = 2.8,
  Boom.height = 0.5,
  Pressure = 3,
  Temp = 18,
  Crop.Height = 0.5,
  Speed = 8,
  Rate = 225,
  WBD = 3.7,
  RH = NULL,
  Cot = "monocot"
) {
  if (missing(WBD) || is.null(WBD)) {
    if (!missing(RH) && !is.null(RH)) {
      WBD <- wet_bulb(Tair = Temp, RH = RH)[["DTwb"]]
    }
  }

  expand.grid(
    Distance = c(1, 2, 5, 15, 20, 25, 30, 50),
    Windspeed = Windspeed,
    Boom.height = Boom.height,
    Pressure = Pressure,
    Temp = Temp,
    Crop.Height = Crop.Height,
    Speed = Speed,
    Rate = Rate,
    WBD = WBD,
    Cot = Cot
  ) |>
    mutate(
      sRate = Rate / 100,
      Height = getHeight1(Crop.Height),
      CotHeight = interaction(Cot, Height),
      logDist = log(Distance)
    )
}


# ============================================================================
# Prediction and plotting
# ============================================================================

# Valid CotHeight levels in the training data
valid_cotheight_levels <- c(
  "Bare Ground.0-0.2",
  "monocot.0-0.2",
  "dicot.0.2-0.4",
  "monocot.0.2-0.4",
  "dicot.0.4-1",
  "monocot.0.4-1"
)


#' Generate drift prediction plot and tables
#'
#' @param mod A brmsfit or lmerMod model object
#' @param newdata Prediction data from getNewData()
#' @param raneff Logical: include trial-level random effects?
#' @param pred Logical: include prediction intervals?
#' @param probs Quantile bounds for credible/prediction intervals
#' @param allow_new_levels Logical: allow new random effect levels?
#' @param sample_new_levels How to sample new levels (brms argument)
#' @return List with: p (ggplot), preddat, fitdat, plotdat
DrawPlot <- function(
  mod,
  newdata,
  raneff = FALSE,
  pred = FALSE,
  probs = c(0.025, 0.975),
  allow_new_levels = FALSE,
  sample_new_levels = "uncertainty"
) {
  # Filter to valid CotHeight levels
  newdata <- droplevels(
    subset(newdata, CotHeight %in% valid_cotheight_levels)
  )

  # Build Rautmann reference data
  rautmann1 <- merge(
    data.frame(Distance = rautmann$Distance, Estimate = rautmann$Value),
    unique(newdata[, -c(1, ncol(newdata))]),
    by = NULL
  )
  rautmann1$Data_Source <- "Rautmann"

  nx <- ncol(newdata)
  preddat <- NULL

  if (inherits(mod, "brmsfit")) {
    # --- Fitted values ---
    if (allow_new_levels) {
      newdata1 <- newdata
      newdata1$TrialG <- "Tnew"
      yfit <- fitted(
        mod,
        newdata = newdata1,
        re_formula = ~ (1 | TrialG),
        probs = probs,
        allow_new_levels = TRUE
      )[, c(1, 3, 4)]
    } else {
      yfit <- fitted(
        mod,
        newdata = newdata,
        re_formula = NA,
        probs = probs
      )[, c(1, 3, 4)]
    }

    fitdat <- cbind(newdata, exp(yfit))
    fitdat$Data_Source <- "Model Fit"
    plotdat <- dplyr::full_join(
      fitdat,
      rautmann1,
      by = intersect(names(fitdat), names(rautmann1))
    )

    ny <- ncol(plotdat)
    names(plotdat)[(nx + 2):(nx + 3)] <- c("lwrQ", "uprQ")

    p <- ggplot(plotdat, aes(x = Distance, y = Estimate, col = Data_Source)) +
      geom_point() +
      geom_line(aes(x = Distance, y = Estimate)) +
      facet_wrap(CotHeight + Crop.Height ~ ., scale = "free") +
      scale_x_log10() +
      geom_ribbon(
        aes(ymin = lwrQ, ymax = uprQ, fill = Data_Source),
        alpha = 0.3
      ) +
      scale_y_continuous(labels = scales::percent_format()) +
      ylab("Estimated Drift") +
      theme_minimal()

    # --- Prediction intervals ---
    if (pred) {
      if (allow_new_levels) {
        newdata1 <- newdata
        newdata1$TrialG <- "Tnew"
        ypred <- predict(
          mod,
          newdata = newdata1,
          re_formula = NA,
          probs = probs,
          allow_new_levels = TRUE
        )[, c(1, 3, 4)]
      } else {
        ypred <- predict(
          mod,
          newdata = newdata,
          re_formula = NA,
          probs = probs
        )[, c(1, 3, 4)]
      }
      preddat <- cbind(newdata, exp(ypred))
      preddat$Data_Source <- "Model Prediction"
      names(preddat)[(nx + 2):(nx + 3)] <- c("lwrQ", "uprQ")
      plotdat <- dplyr::full_join(
        plotdat,
        preddat,
        by = intersect(names(plotdat), names(preddat))
      )

      p <- ggplot(plotdat, aes(x = Distance, y = Estimate, col = Data_Source)) +
        geom_point() +
        facet_wrap(CotHeight + Crop.Height ~ ., scale = "free") +
        scale_x_log10() +
        geom_ribbon(
          aes(ymin = lwrQ, ymax = uprQ, fill = Data_Source),
          alpha = 0.2,
          colour = NA
        ) +
        geom_line(aes(x = Distance, y = Estimate)) +
        scale_y_continuous(labels = scales::percent_format()) +
        ylab("Estimated Drift") +
        theme_minimal()

      preddat <- preddat[, c(1:10, (nx + 1):(nx + 3))]
    }

    fitdat <- fitdat[, c(1:10, (nx + 1):(nx + 3))]
    plotdat <- subset(plotdat, Data_Source != "Rautmann")
  } else if (inherits(mod, "lmerMod")) {
    yfit <- predict(mod, newdata = newdata, re.form = NA)
    fitdat <- cbind(newdata, Estimate = exp(yfit))
    fitdat$Data_Source <- "Model Fit"
    plotdat <- dplyr::full_join(
      fitdat,
      rautmann1,
      by = intersect(names(fitdat), names(rautmann1))
    )

    p <- ggplot(plotdat, aes(x = Distance, y = Estimate, col = Data_Source)) +
      geom_point() +
      geom_line(aes(x = Distance, y = Estimate)) +
      facet_wrap(CotHeight + Crop.Height ~ ., scale = "free") +
      scale_x_log10() +
      scale_y_continuous(labels = scales::percent_format()) +
      ylab("Estimated Drift") +
      theme_minimal()

    fitdat <- fitdat[, c(1:10, (nx + 1))]
    plotdat <- subset(plotdat, Data_Source != "Rautmann")
  }

  list(p = p, preddat = preddat, fitdat = fitdat, plotdat = plotdat)
}


# ============================================================================
# Reference scenario (for documentation/defaults)
# ============================================================================

RefScenario <- expand.grid(
  Distance = c(1, 3, 5, 10, 15, 20),
  Boom.height = 0.5,
  Windspeed = 2.8,
  Speed = 6,
  Temp = 18,
  Pressure = 3,
  WBD = 3.92,
  Rate = 225,
  sRate = 2.25,
  Cot1 = factor(c("monocot", "Bare Ground", "dicot")),
  Crop.Height = c(0.1, 0.2, 0.4, 0.6)
) |>
  mutate(
    logDist = log(Distance),
    Height1 = getHeight1(Crop.Height),
    CotHeight = interaction(Cot1, Height1)
  ) |>
  filter(CotHeight %in% valid_cotheight_levels) |>
  droplevels()

