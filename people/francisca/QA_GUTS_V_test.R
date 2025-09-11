library(shiny)
library(tidyverse)
library(papayaWidget)
library(RNifti)
library(plotly)


preproc_data_dir <- "/data00/leonardo/GUTS_fmri_preproc/people/francisca/preproc_data_MNI"

# List all files with T1w, mask, tsnr patterns
files <- list.files(
  preproc_data_dir,
  pattern = "sub-.*((desc-(preproc_T1w|brain_mask)|_tsnr|_isc)\\.nii\\.gz|_conf\\.svg)$",
  full.names = TRUE
)


# Extract sub_id and type from filenames
df <- tibble(file = files) %>%
  mutate(
    filename = basename(file),
    sub_id = str_extract(filename, "sub-[a-z0-9]+"),
    type = case_when(
      str_detect(filename, "desc-preproc_T1w") ~ "T1w",
      str_detect(filename, "desc-brain_mask") ~ "mask",
      str_detect(filename, "_tsnr") ~ "tsnr",
      str_detect(filename, "_isc") ~ "isc",
      str_detect(filename, "\\.svg$") ~ "svg",       # <-- added this line
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(type)) %>%
  select(sub_id, type, file) %>%
  pivot_wider(names_from = type, values_from = file)


df_qc <- read.table("reportvals.txt", header = TRUE, stringsAsFactors = FALSE) %>% 
  filter(task == "empmovie") %>% 
  select(sub, fd_mean, fd_perc, mean_gm_tsnr) %>% 
  mutate(
    sub = paste0("sub-", sub),
    fd_mean = as.numeric(fd_mean),
    fd_perc = as.numeric(fd_perc),
    mean_gm_tsnr = as.numeric(mean_gm_tsnr)
  ) %>%
  rename(sub_id = sub) %>% 
  mutate(
    marker_size = log1p(fd_perc),
    marker_size = ifelse(marker_size < 1, 1, marker_size)  # Ensure minimum size
  )



ui <- fluidPage(
  selectInput("subject", "Choose subject:", choices = df$sub_id),
  
  tags$p("To change view: hover onto an image and press the spacebar"),
  
  # First two rows: papaya widgets and plotly
  fluidRow(
    column(6,
           papayaOutput('papayaView1', height = "600px"),
           papayaOutput('papayaView3', height = "600px")
    ),
    column(6,
           papayaOutput('papayaView2', height = "600px"),
           plotlyOutput("scatterPlot")
    )
  ),
  
  # New row for SVG image below
  fluidRow(
    column(12,
           uiOutput("svgImage")
    )
  )
)




server <- function(input, output, session) {
  
  shiny::addResourcePath("preproc_svg", preproc_data_dir)
  
  output$papayaView1 <- renderPapaya({
    sub <- input$subject
    files <- df[df$sub_id == sub, c("T1w", "mask")]
    imgs <- na.omit(as.character(unlist(files)))
    
    papaya(
      imgs,
      sync_view = TRUE,
      hide_controls = TRUE,
      option = list(
        papayaOptions(lut = "Grayscale"),
        papayaOptions(lut = "Red Overlay", alpha = 0.5, min = 0, max = 3)
      ),
      interpolation = FALSE,
      title = "Brain_mask"
    )
  })
  
  output$papayaView2 <- renderPapaya({
    sub <- input$subject
    files <- df[df$sub_id == sub, c("T1w", "tsnr")]
    imgs <- na.omit(as.character(unlist(files)))
    
    papaya(
      imgs,
      sync_view = TRUE,
      hide_controls = TRUE,
      option = list(
        papayaOptions(lut = "Grayscale"),
        papayaOptions(lut = "Spectrum", alpha = 0.7, min = 0, max = 300)
      ),
      interpolation = FALSE,
      title = "TSNR"
    )
  })
  
  output$papayaView3 <- renderPapaya({
    sub <- input$subject
    files <- df[df$sub_id == sub, c("T1w", "isc")]
    imgs <- na.omit(as.character(unlist(files)))
    
    papaya(
      imgs,
      sync_view = TRUE,
      hide_controls = TRUE,
      option = list(
        papayaOptions(lut = "Grayscale"),
        papayaOptions(lut = "Red Overlay", alpha = 0.8, min = 0.4, max = 1)
      ),
      interpolation = FALSE,
      title = "ISC_LOO"
    )
  })
  
  output$scatterPlot <- renderPlotly({
    plot_ly(
      df_qc,
      x = ~fd_mean,
      y = ~mean_gm_tsnr,
      type = 'scatter',
      mode = 'markers',
      marker = list(
        size = ~marker_size * 10,  # scale for visibility
        sizemode = 'diameter',
        color = 'lightblue',
        opacity = 0.7
      ),
      text = ~paste0(
        "Subject: ", sub_id, "<br>",
        "FD Mean: ", round(fd_mean, 3), "<br>",
        "% TR with FD>0.4: ", round(fd_perc, 2), "% <br>",
        "Mean GM TSNR: ", round(mean_gm_tsnr, 1)
      ),
      hoverinfo = 'text'
    ) %>%
      layout(
        title = list(
          text = "FD Mean vs GM TSNR<br>(Marker size = % TR with FD >0.4)"
        ),
        xaxis = list(title = "FD Mean"),
        yaxis = list(title = "Mean GM TSNR"),
        showlegend = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  
  output$svgImage <- renderUI({
    sub <- input$subject
    svg_file <- df %>% filter(sub_id == sub) %>% pull(svg)
    
    if (length(svg_file) == 1 && !is.na(svg_file)) {
      svg_name <- basename(svg_file)
      tags$img(src = file.path("preproc_svg", svg_name), style = "width: 100%; height: auto;")
    } else {
      tags$p("No SVG image available for this subject.")
    }
  })
  
  
}

shinyApp(ui, server)
