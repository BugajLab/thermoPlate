SampleInputFile <- function(con){
  # To set temps use the amount of degrees above ambient temperature.
  OnTemp = array(c(
    c(35, 35, 35, 0, 0, 35, 35, 35), #1
    c(0, 0, 0, 0, 0, 0, 0, 0), #2
    c(0, 0, 0, 0, 0, 28, 0, 0), #3
    c(0, 0, 32, 0, 0, 0, 0, 0), #4
    c(0, 0, 0, 0, 0, 0, 0, 0), #5
    c(0, 0, 0, 0, 0, 0, 0, 0), #6
    c(0, 0, 0, 0, 0, 0, 0, 0), #7
    c(0, 0, 0, 26, 0, 0, 0, 0), #8
    c(26, 26, 26, 0, 0, 0, 0, 31), #9
    c(26, 33, 26, 0, 0, 0, 0, 0), #10
    c(26, 26, 26, 0, 0, 0, 0, 0), #11
    c(0, 0, 0, 0, 0, 0, 29, 0)  #12
    # A  B  C  D  E  F  G  H
  ), dim= c(8,12))
  
  OffTemp = array(c(
    c(27, 27, 27, 0, 0, 27, 27, 27), #1
    c(0, 0, 0, 0, 0, 0, 0, 0), #2
    c(0, 0, 0, 0, 0, 0, 0, 0), #3
    c(0, 0, 28, 0, 0, 0, 0, 0), #4
    c(0, 0, 0, 0, 0, 0, 0, 0), #5
    c(0, 0, 0, 0, 0, 0, 0, 0), #6
    c(0, 0, 0, 0, 0, 0, 0, 0), #7
    c(0, 0, 0, 34, 0, 0, 0, 0), #8
    c(25, 25, 25, 0, 0, 0, 0, 31), #9
    c(25, 29, 25, 0, 0, 0, 0, 0), #10
    c(25, 25, 25, 0, 0, 0, 0, 0), #11
    c(0, 0, 0, 0, 0, 0, 30, 0)  #12
    # A  B  C  D  E  F  G  H
  ), dim= c(8,12))
  
  OnTime = array(c(
    c(10, 10, 10, 0, 0, 10, 10, 10), #1
    c(0, 0, 0, 0, 0, 0, 0, 0), #2
    c(0, 0, 0, 0, 0, 4, 0, 0), #3
    c(0, 0, 5, 0, 0, 0, 0, 0), #4
    c(0, 0, 0, 0, 0, 0, 0, 0), #5
    c(0, 0, 0, 0, 0, 0, 0, 0), #6
    c(0, 0, 0, 0, 0, 0, 0, 0), #7
    c(0, 0, 0, 6, 0, 0, 0, 0), #8
    c(8, 8, 8, 0, 0, 0, 0, 6), #9
    c(8, 8, 8, 0, 0, 0, 0, 0), #10
    c(8, 8, 8, 0, 0, 0, 0, 0), #11
    c(0, 0, 0, 0, 0, 0, 4, 0)  #12
    # A  B  C  D  E  F  G  H
  ), dim= c(8,12))
  
  OffTime = array(c(
    c(10, 10, 10, 0, 0, 10, 10, 10), #1
    c(0, 0, 0, 0, 0, 0, 0, 0), #2
    c(0, 0, 0, 0, 0, 6, 0, 0), #3
    c(0, 0, 7, 0, 0, 0, 0, 0), #4
    c(0, 0, 0, 0, 0, 0, 0, 0), #5
    c(0, 0, 0, 0, 0, 0, 0, 0), #6
    c(0, 0, 0, 0, 0, 0, 0, 0), #7
    c(0, 0, 0, 8, 0, 0, 0, 0), #8
    c(8, 8, 8, 0, 0, 0, 0, 6), #9
    c(8, 8, 8, 0, 0, 0, 0, 0), #10
    c(8, 8, 8, 0, 0, 0, 0, 0), #11
    c(0, 0, 0, 0, 0, 0, 4, 0)  #12
    # A  B  C  D  E  F  G  H
  ), dim= c(8,12))
  
  # Create a new workbook
  wb <- createWorkbook()
  
  # Add sheets to the workbook for each array
  addWorksheet(wb, "OnTemp")
  writeData(wb, sheet = "OnTemp", x = OnTemp, rowNames = FALSE, colNames = FALSE)
  
  addWorksheet(wb, "OffTemp")
  writeData(wb, sheet = "OffTemp", x = OffTemp, rowNames = FALSE, colNames = FALSE)
  
  addWorksheet(wb, "OnTime")
  writeData(wb, sheet = "OnTime", x = OnTime, rowNames = FALSE, colNames = FALSE)
  
  addWorksheet(wb, "OffTime")
  writeData(wb, sheet = "OffTime", x = OffTime, rowNames = FALSE, colNames = FALSE)
  
  # Save the workbook to a file
  saveWorkbook(wb, con, overwrite = TRUE)
}