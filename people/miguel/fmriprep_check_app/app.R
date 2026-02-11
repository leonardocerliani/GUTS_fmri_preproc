library(shiny)
library(tidyverse)
library(papayaWidget)
library(RNifti)
library(plotly)

# ---- Generate QC_summary.csv if missing ----
generate_QC_summary <- function() {
  subj_list <- read_lines("list_subj.txt")
  
  process_subject <- function(subj) {
    base_path <- file.path("data", subj)
    
    conf_path  <- file.path(base_path,
                            paste0("sub-", subj, "_task-ISC_desc-confounds_timeseries.tsv"))
    
    tsnr_path  <- file.path(base_path,
                            paste0("sub-", subj,
                                   "_task-ISC_space-MNI152NLin6Asym_res-2_desc-preproc_bold_tsnr.nii.gz"))
    
    dseg_path  <- file.path(base_path,
                            paste0("sub-", subj,
                                   "_space-MNI152NLin6Asym_res-2_dseg.nii.gz"))
    
    # mean FD
    confounds <- read_tsv(conf_path, show_col_types = FALSE)
    mean_FD <- mean(
      as.numeric(na_if(confounds$framewise_displacement, "n/a")),
      na.rm = TRUE
    )
    
    # mean TSNR in gray matter
    tsnr_img <- readNifti(tsnr_path)
    dseg_img <- readNifti(dseg_path)
    gm_mask <- dseg_img == 1
    mean_TSNR <- mean(tsnr_img[gm_mask], na.rm = TRUE)
    
    tibble(
      subj = subj,
      mean_FD = mean_FD,
      mean_TSNR = mean_TSNR
    )
  }
  
  results_df <- map_dfr(subj_list, process_subject)
  write_csv(results_df, "QC_summary.csv")
  results_df
}

if (!file.exists("QC_summary.csv")) {
  message("QC_summary.csv not found. Generating now...")
  generate_QC_summary()
}

# ---- data directory ----
preproc_data_dir <- "./data"

# ---- list all relevant files recursively ----
files <- list.files(
  preproc_data_dir,
  pattern = "sub-.*(desc-(preproc_T1w|brain_mask)|tsnr|carpetplot).*\\.(nii\\.gz|svg)$",
  recursive = TRUE,
  full.names = TRUE
)

# ---- build dataframe of files ----
df <- tibble(file = files) %>%
  mutate(
    filename = basename(file),
    sub_id = str_extract(filename, "sub-[A-Za-z0-9]+"),
    type = case_when(
      str_detect(filename, "desc-preproc_T1w") ~ "T1w",
      str_detect(filename, "desc-brain_mask") ~ "mask",
      str_detect(filename, "tsnr") ~ "tsnr",
      str_detect(filename, "carpetplot") ~ "svg",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(type)) %>%
  select(sub_id, type, file) %>%
  pivot_wider(names_from = type, values_from = file)

# ---- read QC summary ----
df_qc <- read_csv("QC_summary.csv", show_col_types = FALSE) %>%
  mutate(sub_id = paste0("sub-", subj),
         marker_size = 5)

# ---- UI ----
ui <- fluidPage(
  
  selectInput("subject", "Choose subject:", choices = df$sub_id),
  
  fluidRow(
    column(6,
           tags$h4("Brain mask in MNI space"),
           papayaOutput('papayaView1', height = "600px"),
           tags$h4("ISC_LOO"),
           tags$p("ISC not available yet.")
    ),
    column(6,
           tags$h4("TSNR"),
           papayaOutput('papayaView2', height = "600px"),
           tags$h4("FD Mean vs GM TSNR"),
           tags$p("click on a marker to load that participant's images"),
           plotlyOutput("scatterPlot", height = "550px")
    )
  ),
  
  fluidRow(
    column(12,
           uiOutput("svgImage")
    )
  )
)

# ---- SERVER ----
server <- function(input, output, session) {
  
  shiny::addResourcePath("preproc_svg", normalizePath(preproc_data_dir))
  
  observe({
    click_data <- event_data("plotly_click")
    if (!is.null(click_data)) {
      updateSelectInput(session, "subject", selected = click_data$customdata)
    }
  })
  
  # ---- Mask viewer ----
  output$papayaView1 <- renderPapaya({
    sub <- input$subject
    files_row <- df %>% filter(sub_id == sub)
    imgs <- na.omit(as.character(unlist(files_row[c("T1w", "mask")])))
    
    papaya(
      imgs,
      sync_view = TRUE,
      hide_controls = TRUE,
      option = list(
        papayaOptions(lut = "Grayscale"),
        papayaOptions(lut = "Red Overlay", alpha = 0.5, min = 0, max = 3)
      ),
      interpolation = FALSE
    )
  })
  
  # ---- TSNR viewer (masked by brain mask) ----
  output$papayaView2 <- renderPapaya({
    sub <- input$subject
    files_row <- df %>% filter(sub_id == sub)
    t1w_file <- files_row$T1w
    tsnr_file <- files_row$tsnr
    mask_file <- files_row$mask
    
    if (!is.na(tsnr_file) && !is.na(mask_file)) {
      tsnr_img <- readNifti(tsnr_file)
      mask_img <- readNifti(mask_file)
      tsnr_masked <- tsnr_img
      tsnr_masked[mask_img == 0] <- 0
      tmp_file <- tempfile(fileext = ".nii.gz")
      writeNifti(tsnr_masked, tmp_file)
      imgs <- c(t1w_file, tmp_file)
    } else {
      imgs <- na.omit(c(t1w_file, tsnr_file))
    }
    
    papaya(
      imgs,
      sync_view = TRUE,
      hide_controls = TRUE,
      option = list(
        papayaOptions(lut = "Grayscale"),
        papayaOptions(lut = "Spectrum", alpha = 0.7, min = 0, max = 150)
      ),
      interpolation = FALSE
    )
  })
  
  # ---- Scatter plot ----
  output$scatterPlot <- renderPlotly({
    plot_ly(
      df_qc,
      x = ~mean_FD,
      y = ~mean_TSNR,
      type = 'scatter',
      mode = 'markers+text',
      marker = list(
        size = 12,
        color = ~ifelse(sub_id == input$subject, 'red', 'lightblue'),
        opacity = 0.7
      ),
      text = ~sub_id,
      textposition = 'bottom center',
      hoverinfo = 'text',
      hovertext = ~paste0(
        "Subject: ", sub_id, "<br>",
        "FD Mean: ", round(mean_FD, 3), "<br>",
        "Mean GM TSNR: ", round(mean_TSNR, 1)
      ),
      customdata = ~sub_id
    ) %>%
      layout(
        xaxis = list(title = "FD Mean"),
        yaxis = list(title = "Mean GM TSNR"),
        showlegend = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ---- SVG carpet plot ----
  output$svgImage <- renderUI({
    sub <- input$subject
    svg_file <- df %>% filter(sub_id == sub) %>% pull(svg)
    
    if (length(svg_file) == 1 && !is.na(svg_file)) {
      # Strip data/ prefix for resource path
      svg_rel <- sub("^.*/data/", "", svg_file)
      tags$img(src = file.path("preproc_svg", svg_rel),
               style = "width: 100%; height: auto;")
    } else {
      tags$p("No carpet plot available.")
    }
  })
}

shinyApp(ui, server)
