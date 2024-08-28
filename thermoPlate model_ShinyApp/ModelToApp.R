ModelToApp <- function(template,timecourse,timestep,ExperimentLength,AmbientTemp){
  # Converts the simulation output to one that can be plotted by the app
  ExperimentLength = ExperimentLength*60
  t = seq(0,ExperimentLength+timestep, by=timestep)
  output <- data.frame(matrix(ncol = 4, nrow = 0))
  for (i in 1:length(t)){
    time = rep(t[i],96)
    temp = timecourse[,,i] + AmbientTemp
    temp = reshape(temp,c(96,1))
    Entry = cbind(template,time,temp)
    output = rbind(output,Entry)
  }
  output <- output[, c('WellID','RowName','RowNum','ColNum','time','temp')]
  return(output)
}
