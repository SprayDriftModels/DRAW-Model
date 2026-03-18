# ============================================================================
# DRAW Model Prediction App
# ============================================================================
# Spray drift prediction using Bayesian multilevel regression models (brms)
# and linear mixed effects models (lme4). Compares predictions against
# Rautmann reference curves.
#
# Modernized from periscope/shinydashboard to bslib (Bootstrap 5).
# ============================================================================

library(shiny)
library(bslib)
library(DT)
library(gridExtra)

source("functions.R")

# ============================================================================
# UI
# ============================================================================

ui <- page_navbar(
  title = "DRAW Model Prediction",
  id = "nav",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  fillable = FALSE,

  # -- Tab 1: Dashboard -------------------------------------------------------
  nav_panel(
    title = "Dashboard",
    icon = icon("chart-line"),
    layout_columns(
      col_widths = c(4, 8),

      # ---- Left column: inputs ----
      div(
        card(
          card_header("Application Settings"),
          card_body(
            numericInput(
              "Pressure",
              "Pressure [bar]:",
              min = 0,
              max = 6,
              value = 3,
              step = 0.1
            ),
            numericInput(
              "Boom.height",
              "Boom Height [m]:",
              min = 0,
              max = 2,
              value = 0.5,
              step = 0.1
            ),
            numericInput(
              "Speed",
              "Tractor Forward Speed [m/s]:",
              min = 0,
              max = 20,
              value = 6,
              step = 0.1
            ),
            numericInput(
              "Rate",
              "Application Rate:",
              value = 238,
              min = 0,
              step = 1
            )
          )
        ),
        card(
          card_header("Environmental Conditions"),
          card_body(
            numericInput(
              "Windspeed",
              "Wind Speed [m/s]:",
              min = 0,
              max = 10,
              value = 2.8
            ),
            numericInput(
              "Temp",
              "Temperature [\u00B0C]:",
              value = 18,
              min = -50,
              max = 50,
              step = 0.1
            ),
            radioButtons(
              "wbdType",
              "Input WBD or RH?",
              inline = TRUE,
              choices = c(RH = "RH", WBD = "WBD"),
              selected = "WBD"
            ),
            conditionalPanel(
              condition = "input.wbdType == 'RH'",
              numericInput(
                "RH",
                "Relative Humidity [%]:",
                value = 60,
                min = 0,
                max = 100,
                step = 1
              )
            ),
            conditionalPanel(
              condition = "input.wbdType == 'WBD'",
              numericInput(
                "WBD",
                "Wet Bulb Depression [\u00B0C]:",
                value = 3.0,
                min = 0,
                max = 100,
                step = 0.1
              )
            )
          )
        ),
        card(
          card_header("Crop Information"),
          card_body(
            numericInput(
              "Crop.Height",
              "Crop Height [m]:",
              value = 0.5,
              min = 0,
              max = 1,
              step = 0.1
            ),
            checkboxGroupInput(
              "Cot",
              "Cotyledon Category:",
              choices = c(
                "Monocots" = "monocot",
                "Dicots" = "dicot",
                "Flat Surface" = "Bare Ground"
              ),
              selected = "monocot"
            )
          )
        ),
        card(
          card_header("Output Settings"),
          card_body(
            sliderInput(
              "quantile",
              "Percentile:",
              min = 50,
              max = 99,
              value = 90
            ),
            checkboxInput("PredInt", "Plot Prediction Interval", FALSE),
            checkboxInput("TrialG", "Allow New Trials in Prediction", FALSE),
            radioButtons(
              "mod",
              "Model:",
              choiceNames = list("BRM-lognormal", "Linear Mixed (LME)"),
              choiceValues = list("BRM-lognormal", "LME")
            ),
            actionButton(
              "goButton",
              "Run Prediction",
              class = "btn-success w-100 mt-2"
            ),
            helpText(
              "Click to run the prediction using the selected DRAW model."
            )
          )
        )
      ),

      # ---- Right column: outputs ----
      div(
        card(
          card_header("Prediction Plot"),
          card_body(
            plotOutput("predPlot", height = "500px")
          )
        ),
        card(
          card_header("Prediction Table"),
          card_body(
            DT::dataTableOutput("predTab")
          )
        ),
        card(
          card_header("User Input Check"),
          card_body(
            tableOutput("userScenarioTab")
          )
        ),
        card(
          card_header("Download Report"),
          card_body(
            downloadButton(
              "report",
              "Generate HTML Report",
              class = "btn-primary"
            )
          )
        )
      )
    )
  ),

  # -- Tab 2: About ------------------------------------------------------------
  nav_panel(
    title = "About DRAW",
    icon = icon("info-circle"),
    card(
      card_body(
        tags$iframe(
          srcdoc = paste(
            readLines("program/Documentation.html", warn = FALSE),
            collapse = "\n"
          ),
          style = "width:100%; height:80vh; border:none;"
        )
      )
    )
  ),

  # -- Tab 3: User Manual ------------------------------------------------------
  nav_panel(
    title = "User Manual",
    icon = icon("book"),
    card(
      card_body(
        includeMarkdown("program/Manual.md")
      )
    )
  ),

  # -- Tab 4: Trial Comparisons ------------------------------------------------
  nav_panel(
    title = "Trial Comparisons",
    icon = icon("chart-bar"),
    layout_columns(
      col_widths = c(4, 8),

      # Left: comparison controls
      card(
        card_header("Comparison Settings"),
        card_body(
          checkboxGroupInput(
            "compare",
            "Example Comparisons:",
            choices = c(
              "Boom Height" = "BoomHeight",
              "WBD" = "WBD",
              "Wind Speed" = "Wind Speed",
              "Drop Spectra" = "Drop Spectra",
              "Tractor Speed" = "Tractor Speed"
            )
          ),
          actionButton(
            "compareButton",
            "Plot Comparisons",
            class = "btn-success w-100 mt-2"
          ),
          helpText("Select comparisons and click to visualize.")
        )
      ),

      # Right: comparison outputs
      div(
        card(
          card_header("Comparison Curves"),
          card_body(
            plotOutput("compPlot", height = "600px")
          )
        ),
        card(
          card_header("Example Trials for Comparison"),
          card_body(
            DT::dataTableOutput("compTab")
          )
        )
      )
    )
  ),

  # -- Tab 5: SETAC link -------------------------------------------------------
  nav_item(
    tags$a(
      icon("external-link-alt"),
      "SETAC DRAW",
      href = "https://www.spraydriftmitigation.info/",
      target = "_blank"
    )
  )
)


# ============================================================================
# Server
# ============================================================================

server <- function(input, output, session) {
  # -- Compute WBD from RH or direct input --
  getWBD <- reactive({
    if (input$wbdType == "RH") {
      req(input$RH)
      wet_bulb_Stull(Tair = input$Temp, RH = input$RH)[["DTwb"]]
    } else {
      input$WBD
    }
  })

  # -- User scenario summary --
  userScenario <- reactive({
    data.frame(
      Windspeed = input$Windspeed,
      Boom.height = input$Boom.height,
      Pressure = input$Pressure,
      Temp = input$Temp,
      Crop.Height = input$Crop.Height,
      Speed = input$Speed,
      Rate = input$Rate,
      WBD = getWBD(),
      Cot = paste(input$Cot, collapse = ", ")
    )
  })

  # -- Build newdata for model prediction --
  userInput <- reactive({
    getNewData(
      Windspeed = input$Windspeed,
      Boom.height = input$Boom.height,
      Pressure = input$Pressure,
      Temp = input$Temp,
      Crop.Height = input$Crop.Height,
      Speed = input$Speed,
      Rate = input$Rate,
      WBD = getWBD(),
      Cot = input$Cot
    )
  })

  # -- Run prediction on button click --
  preddata <- eventReactive(input$goButton, {
    mod <- switch(
      input$mod,
      "BRM-lognormal" = fit.STD.NoAngle.addTemp,
      "LME" = mod.STD.NoAngle.addTemp
    )
    req(mod)
    allowNewTrial <- input$TrialG

    DrawPlot(
      mod = mod,
      newdata = userInput(),
      pred = input$PredInt,
      probs = c(
        (1 - input$quantile * 0.01) / 2,
        (1 + input$quantile * 0.01) / 2
      ),
      allow_new_levels = allowNewTrial
    )
  })

  # -- Dashboard outputs --
  output$userScenarioTab <- renderTable(userScenario())

  output$predPlot <- renderPlot({
    preddata()$p
  })

  output$predTab <- DT::renderDataTable({
    res <- preddata()
    if (input$mod == "BRM-lognormal") {
      dat <- res$plotdat
    } else {
      dat <- res$plotdat
    }
    # Show key columns
    cols_to_show <- intersect(
      c(
        "Distance",
        "CotHeight",
        "Crop.Height",
        "Estimate",
        "lwrQ",
        "uprQ",
        "Data_Source"
      ),
      names(dat)
    )
    DT::datatable(
      dat[, cols_to_show, drop = FALSE],
      options = list(pageLength = 20, scrollX = TRUE),
      rownames = FALSE
    )
  })

  # -- Report download --
  output$report <- downloadHandler(
    filename = function() {
      paste0("DRAW_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html")
    },
    content = function(file) {
      tempReport <- file.path(tempdir(), "report.Rmd")
      file.copy("report.Rmd", tempReport, overwrite = TRUE)

      params <- list(
        dat = userScenario(),
        res = preddata()
      )

      rmarkdown::render(
        tempReport,
        output_file = file,
        params = params,
        envir = new.env(parent = globalenv())
      )
    }
  )

  # ========================================================================
  # Comparison Tab
  # ========================================================================

  plotComp <- eventReactive(input$compareButton, {
    req(input$compare, comparedat_available)
    comp <- input$compare
    pList <- list()

    for (i in seq_along(comp)) {
      if (comp[i] == "Drop Spectra") {
        tmpdat <- subset(comparedat, Comparison == "Drop Spectra")
        pList[[i]] <- ggplot(
          tmpdat,
          aes(x = Distance, y = Drift, col = factor(Pressure))
        ) +
          geom_point() +
          geom_line(aes(x = Distance, y = Estimate, group = LineG)) +
          scale_y_continuous(
            labels = scales::percent_format(),
            trans = "log10"
          ) +
          scale_x_log10(limits = c(1, 20)) +
          geom_ribbon(
            aes(ymin = FittedQ2.5, ymax = FittedQ97.5, fill = factor(Pressure)),
            alpha = 0.3
          ) +
          geom_line(
            data = rautmann,
            aes(x = Distance, y = Value),
            col = "black"
          ) +
          labs(
            title = "Drop Spectra (Pressure)",
            colour = "Pressure",
            fill = "Pressure"
          ) +
          theme_minimal() +
          theme(legend.position = "bottom")
      } else if (comp[i] == "BoomHeight") {
        tmpdat <- subset(comparedat, Comparison == "BoomHeight")
        pList[[i]] <- ggplot(
          tmpdat,
          aes(x = Distance, y = Drift, col = factor(Boom.height))
        ) +
          geom_point() +
          geom_line(aes(x = Distance, y = Estimate, group = LineG)) +
          scale_y_continuous(
            labels = scales::percent_format(),
            trans = "log10"
          ) +
          scale_x_log10(limits = c(5, 50)) +
          geom_ribbon(
            aes(
              ymin = FittedQ2.5,
              ymax = FittedQ97.5,
              fill = factor(Boom.height)
            ),
            alpha = 0.3
          ) +
          geom_line(
            data = rautmann,
            aes(x = Distance, y = Value),
            col = "black"
          ) +
          labs(
            title = "Boom Height",
            colour = "Boom Height",
            fill = "Boom Height"
          ) +
          theme_minimal() +
          theme(legend.position = "bottom")
      } else if (comp[i] == "WBD") {
        tmpdat <- subset(comparedat, Comparison == "WBD") |>
          mutate(WetBulbDepression = factor(as.character(round(WBD, 1))))
        pList[[i]] <- ggplot(
          tmpdat,
          aes(x = Distance, y = Drift, col = WetBulbDepression)
        ) +
          geom_point() +
          geom_line(aes(x = Distance, y = Estimate, group = LineG)) +
          scale_y_continuous(
            labels = scales::percent_format(),
            trans = "log10"
          ) +
          scale_x_log10(limits = c(1, 20)) +
          geom_ribbon(
            aes(
              ymin = FittedQ2.5,
              ymax = FittedQ97.5,
              fill = WetBulbDepression
            ),
            alpha = 0.3
          ) +
          geom_line(
            data = rautmann,
            aes(x = Distance, y = Value),
            col = "black"
          ) +
          labs(title = "Wet Bulb Depression", colour = "WBD", fill = "WBD") +
          theme_minimal() +
          theme(legend.position = "bottom")
      } else if (comp[i] == "Wind Speed") {
        tmpdat <- subset(
          comparedat,
          Comparison == "Wind Speed" & Country != "DE"
        ) |>
          mutate(Wind.speed = factor(as.character(round(Windspeed, 1))))
        pList[[i]] <- ggplot(
          tmpdat,
          aes(x = Distance, y = Drift, col = Wind.speed)
        ) +
          geom_point() +
          geom_line(aes(x = Distance, y = Estimate, group = LineG)) +
          scale_y_continuous(
            labels = scales::percent_format(),
            trans = "log10"
          ) +
          scale_x_log10(limits = c(1.25, 15.5)) +
          geom_ribbon(
            aes(ymin = FittedQ2.5, ymax = FittedQ97.5, fill = Wind.speed),
            alpha = 0.3
          ) +
          geom_smooth(
            data = rautmann,
            aes(x = Distance, y = Value),
            col = "black",
            method = "lm",
            se = FALSE,
            fullrange = TRUE
          ) +
          labs(
            title = "Wind Speed",
            colour = "Wind Speed",
            fill = "Wind Speed"
          ) +
          theme_minimal() +
          theme(legend.position = "bottom")
      } else if (comp[i] == "Tractor Speed") {
        tmpdat <- subset(comparedat, Comparison == "Tractor Speed")
        pList[[i]] <- ggplot(
          tmpdat,
          aes(x = Distance, y = Drift, col = factor(Speed))
        ) +
          geom_point() +
          geom_line(aes(x = Distance, y = Estimate, group = LineG)) +
          scale_y_continuous(
            labels = scales::percent_format(),
            trans = "log10"
          ) +
          scale_x_log10(limits = c(1, 20)) +
          geom_ribbon(
            aes(ymin = Q2.5, ymax = Q97.5, fill = factor(Speed)),
            alpha = 0.1,
            linetype = 0
          ) +
          geom_ribbon(
            aes(ymin = FittedQ2.5, ymax = FittedQ97.5, fill = factor(Speed)),
            alpha = 0.3
          ) +
          geom_line(
            data = rautmann,
            aes(x = Distance, y = Value),
            col = "black"
          ) +
          labs(title = "Tractor Speed", colour = "Speed", fill = "Speed") +
          theme_minimal() +
          theme(legend.position = "bottom")
      }
    }

    pList
  })

  output$compPlot <- renderPlot({
    if (!comparedat_available) {
      plot.new()
      text(
        0.5,
        0.5,
        "Comparison data (comparedat.rda) is not available.\nResolve git LFS pointers to enable this tab.",
        cex = 1.3,
        col = "grey50"
      )
      return(invisible(NULL))
    }
    pList <- plotComp()
    if (length(pList) > 0) {
      do.call(gridExtra::grid.arrange, c(pList, ncol = 2))
    }
  })

  output$compTab <- DT::renderDataTable({
    DT::datatable(
      compareTrials,
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
}


# ============================================================================
# Run
# ============================================================================

shinyApp(ui, server)
