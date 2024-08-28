#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# install.packages("matlab")
# install.packages("openxlsx")
# install.packages("tidyverse")
# install.packages("gganimate")
# install.packages("gifski")
# install.packages("vroom")
# install.packages("png")
# install.packages("shiny")
# 
# remove.packages("matlab")
# remove.packages("openxlsx")
# remove.packages("tidyverse")
# remove.packages("gganimate")
# remove.packages("gifski")
# remove.packages("vroom")
# remove.packages("png")
# remove.packages("shiny")


library(openxlsx)
library(matlab)
library(shiny)
library(ggplot2)
library(dplyr)
library(tidyverse)
library(gganimate)
library(gifski)
library(vroom)
library(png)

source("SampleInputFile.R")
source("ReadInputFile.R")
source("ArduinoToApp.R")
source("ArduinoToModel.R")
source("ModelToApp.R")
source("RunModelV2.R")
source("wellPlatePlot.R")
source("wellPlateAnim.R")
source("heatErrorCheck.R")
source("simToArduinoFile.R")



# Define UI for app that runs simulation ----
ui <- fluidPage(
    titlePanel("Thermoplate Heating GUI"),
    
    sidebarLayout(
        sidebarPanel(position = "left",
            h5("1. Download .xlsx template to specify experimental wells, times, and temps"),
            
            downloadLink('downloadData', 'Download input template (.xlsx)'),
            br(),
            br(),
            numericInput("AmbientTemp",
                         h5("2. Input ambient temperature of experiment"),
                         value = 25,
                         min = 0,
                         max = 45),
              
            fileInput("upload", h5("3. Upload xlsx with wells, times, and temps"), accept = ".xlsx"),

            numericInput("length",
                         h5("4. Input length of experiment (mins)"),
                         value = 30,
                         min = 0,
                         max = 1000),
            br(),
            
            h5("5. When ready to run simulation, press Simulate"),
            actionButton("start",
                         "Simulate")
        ),
        
        mainPanel(
                  h4("Planned heating profile"),
                  plotOutput("plot"),
                  uiOutput("slider"), #placeholder for slider once upload data
                  
                  h4("Heating simulation"),
                  plotOutput("animation"),
                  fluidRow(
                    uiOutput("dl_sim_data_button"), #placeholder for download button once run simulation
                    uiOutput("dl_sim_gif_button"), #placeholder for download button once run simulation
                    uiOutput("dl_arduino_script_button"), #placeholder for download button once run simulation
                  )
                  )
    )
)


# Define server logic required to run a simulation ----
server <- function(input, output) {
  timestep = 25 # time resolution (seconds) that will be plotted in output. i.e. each frame corresponds to this many seconds.
  
  #make a lookuptable that matches rows, cols, and WellID
  ColNum = c(rep(1,8),rep(2,8),rep(3,8),rep(4,8),rep(5,8),rep(6,8),rep(7,8),rep(8,8),rep(9,8),rep(10,8),rep(11,8),rep(12,8))
  RowNum = rep(1:8,12)
  wellLUT = data.frame(ColNum, RowNum) %>% 
    mutate(RowName = 
             case_when(RowNum == 1 ~"A",
                       RowNum == 2 ~"B",
                       RowNum == 3 ~"C",
                       RowNum == 4 ~"D",
                       RowNum == 5 ~"E",
                       RowNum == 6 ~"F",
                       RowNum == 7 ~"G",
                       RowNum == 8 ~"H")) %>% 
    mutate(WellID = paste(RowName, ColNum, sep = ""))
  rownames(wellLUT) <- NULL
  rm(ColNum,RowNum)
    
    output$downloadData <- downloadHandler(
          filename = 'SampleInput.xlsx',
          content = function(con){
            SampleInputFile(con)
          }
        )
    
    #store ambient temp, experimental length
    AmbientTemp = reactive({
      input$AmbientTemp
    })    
    
    ExperimentLength = reactive({
      input$length
    })
    
    #import well, time, temp .csv
    UserInput = reactive({
      ReadInputFile(input$upload$datapath)
    })
    
    # Reactive expression to generate a unique key for each upload
    uploadKey <- reactive({
      if (is.null(input$upload)) {
        return(NULL)
      } else {
        # Using file modification time
        file.info(input$upload$datapath)$mtime 
      }
    })
    
    # Convert User Input to that required by App's plots
    WellPlotInput = reactive({
      if(!is.null(UserInput())){
        ArduinoToApp(wellLUT,ExperimentLength(),AmbientTemp(),UserInput())
      }
    })
    
    # Convert User Input to that required by simulation
    ModelInput = reactive({
      if(!is.null(UserInput())){
        ArduinoToModel(AmbientTemp(),ExperimentLength(),timestep,UserInput())
      }
    })
    
    
    #show slider once data is input
    output$slider <- renderUI({
        req(input$upload)
        sliderInput("times", 
                    label = "Run time",
                    min = 0, 
                    max = ExperimentLength(), 
                    value = 0,
                    step = 1,
                    animate = TRUE)
    })
    
    
    # #display input table
    # output$upload_table <- renderTable(
    #     head(AppInput())
    # )
    
    #create interactive plate with heats and numbers
    wellPlot = reactive({
        if(!is.null(input$upload)){
            wellPlatePlot(WellPlotInput(), input$times,ExperimentLength(),AmbientTemp())#generate a plot
        }
      })
    
    #display the plot
    output$plot = renderCachedPlot({
        wellPlot()
       },
        sizePolicy = sizeGrowthRatio(width = 600, 
                                     height = 400, 
                                     growthRate = 1),
        # height = 400,
        # width = 600,
        cacheKeyExpr = list(input$times, uploadKey(),AmbientTemp())
    )
    
    heat_model = reactiveVal(data.frame()) #container for the model
    # Run the simulation
    heatSimulation = eventReactive(input$start,{
        # Create a Progress object
        progressModel <- shiny::Progress$new()
        progressModel$set(message = "Computing", value = 0)
        # Close the progress when this reactive exits (even if there's an error)
        on.exit(progressModel$close())
        
        # Create a callback function to update progress.
        # Each time this is called:
        # - If `value` is NULL, it will move the progress bar 1/5 of the remaining
        #   distance. If non-NULL, it will set the progress to that value.
        # - It also accepts optional detail text.
        updateProgress <- function(value = NULL, detail = NULL) {
            if (is.null(value)) {
                value <- progressModel$getValue()
            }
            progressModel$set(value = value, detail = detail)
        }
        
        heatMod = heating_eval(ModelInput(), timestep, updateProgress) 
        heatMod = ModelToApp(wellLUT,heatMod,timestep,ExperimentLength(),AmbientTemp())

        # Create a Progress object for animation
        progressAnim <- shiny::Progress$new()
        progressAnim$set(message = "Animating...", value = NULL)
        # Close the progress when this reactive exits (even if there's an error)
        on.exit(progressAnim$close(), add = TRUE)
        
        #check if some wells are hotter than programmed by user
        heatMod_wErr = heatErrorCheck(heatMod, WellPlotInput(),ExperimentLength()) 
        heat_model(heatMod_wErr) #update the reactive container for the heatmodel
      
        wellPlateAnim(heatMod_wErr)
    })
        
    
    #output the sim gif
    output$animation = renderImage({
        #specify which image to use (placeholder image if no data yet)
        if(is.null(input$upload) | input$start == 0){
            list(src = "simPlaceHolder.png",  #call the reactive gif file here
                 contentType = 'image/png',
                 width = 600,
                 height = 400,
                 alt = "This is alternate text")
          }else{list(src = heatSimulation(),  #call the reactive gif file here
                                     contentType = 'image/gif',
                                     width = 600,
                                     height = 400,
                                     alt = "This is alternate text")
              }
    },deleteFile = ifelse(is.null(input$upload),FALSE,TRUE)
  
    )
    
    #show button for download of sim data once simulation is run
    output$dl_sim_data_button <- renderUI({
      req(input$start) #only shows up once the button has been pressed to start a sim
      downloadButton("dl_sim_data",
                  "Export Simulation Data")
    })
    
    #export sim data once simulation start button is pressed 
    output$dl_sim_data <- downloadHandler(
      filename =  function(){'heatModelData.csv'},
      content = function(file) {
        write.csv(heat_model(), file)
      }
    )
    
    #show button for download of sim gif once simulation is run
    output$dl_sim_gif_button <- renderUI({
      req(input$start) #only shows up once the button has been pressed to start a sim
      downloadButton("dl_sim_gif",
                     "Export Simulation GIF")
    })
    
    #export sim gif once simulation start button is pressed 
    output$dl_sim_gif <- downloadHandler(
      filename =  function(){'heatModelGIF.gif'},
      content = function(file) {
          file.copy(heatSimulation(), file)
      },
      contentType = "image/gif"
    )
    
    #show button for download of updated arduino script once simulation is run
    output$dl_arduino_script_button <- renderUI({
      req(input$start) #only shows up once the button has been pressed to start a sim
      downloadButton("dl_arduino_script",
                     "Generate Arduino sketch")
    })
    
    #generate and export Arduino sketch with user-defined inputs
    output$dl_arduino_script <- downloadHandler(
      filename =  function(){'thermoPlate_sketch.ino'},
      content = function(file) {
        arduino_text = simToArduinoFile(UserInput())
        writeLines(arduino_text, file)
      }
    )
    
}

# Run the application 
shinyApp(ui = ui, server = server)
