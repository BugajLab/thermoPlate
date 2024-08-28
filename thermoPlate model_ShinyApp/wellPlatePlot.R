wellPlatePlot = function(wells_inputs, time_,ExperimentLength,AmbientTemp){
  # Makes the planned heat profile preview's input
  
  #change for plotting purposes. 
  dat = wells_inputs %>%   
    mutate(
      temp = case_when(
               (temp == 0) & (start == 0) & (stop == ExperimentLength) ~ NA_real_,
               TRUE ~ temp
      ),
      error = case_when(
        (temp < AmbientTemp) & (temp != 0) ~ 1,
        TRUE ~ 0
      ),
      temp = case_when(
         (temp == 0) ~ AmbientTemp,
         TRUE ~ temp
      ),
      errStroke = case_when(
        error == 0 ~ .5,
        error == 1 ~ 4
      )
    )
  
  
  #plot wellPlate over time with input data
  p = ggplot(dat) +
    # geom_point(aes(x = ColNum, y = RowNum), size = 17, shape = 21,colour = "black", na.rm = TRUE)+
    geom_point(aes(x = ColNum, y = RowNum, fill = temp, color = error, stroke = errStroke),  size = 17, shape = 21, show.legend = FALSE)+
    scale_color_steps(low = "black", high = "red")+
    geom_point(data = dat %>% filter (start <= time_ & (time_ < stop | (time_ == stop & stop == ExperimentLength))), aes(x = ColNum, y = RowNum, fill = temp), size = 17, shape = 21, show.legend = FALSE, na.rm = TRUE)+
    scale_x_continuous(breaks = 1:12, limits = c(0.75, 12.25)) +
    scale_y_reverse(limits = c(8.25,0.75), breaks = 1:8, labels = LETTERS[1:8])+
    scale_fill_gradient(low = "white", high = "purple", limits = c(AmbientTemp,max(dat$temp)), na.value="white") +
    theme_bw() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.x = element_text(size = 12),
          axis.text.y = element_text(size = 12))+
    geom_text(data = dat %>% filter (start <= time_ & (time_ < stop | (time_ == stop & stop == ExperimentLength))), aes(x = ColNum, y = RowNum, label = temp, size = 0.2), show.legend = FALSE, na.rm = TRUE)+
    #transition_time(time)+
    ggtitle(paste("Time:", time_, "min", sep = " "),
            subtitle =  "Red circles = Wells that have Target temperatures below the desired Ambient temperature.\n--->They will not reach their target.")
  
  return(p)
}