library(shiny)
library(tidyverse)
library(papayaWidget)
library(RNifti)

preproc_data_dir <- "/data00/leonardo/GUTS_fmri_preproc/people/francisca/preproc_data_MNI"

# List all files with T1w, mask, tsnr patterns
files <- list.files(
  preproc_data_dir,
  pattern = "sub-.*(desc-(preproc_T1w|brain_mask)|_tsnr)\\.nii\\.gz$",
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
      str_detect(filename, "tsnr") ~ "tsnr",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(type)) %>%
  select(sub_id, type, file) %>%
  tidyr::pivot_wider(names_from = type, values_from = file)


ui <- fluidPage(
  selectInput("subject", "Choose subject:", choices = df$sub_id),
  
  tags$p("To change view: hover onto an image and press the spacebar"),
  
  fluidRow(
    column(6,
           tags$p("T1w and brain mask in MNI"),
           papayaOutput('papayaView1', height = "600px"),
           
    ),
    column(6,
           tags$p("TSNR map in MNI"),
           papayaOutput('papayaView2', height = "600px"),
    )
  )
)

server <- function(input, output, session) {
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
      title = "pippo"
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
        papayaOptions(lut = "Spectrum", alpha = 0.5, min = 0, max = 300)
      ),
      interpolation = FALSE,
      title = "paperino_paolino"
    )
  })
}

shinyApp(ui, server)
