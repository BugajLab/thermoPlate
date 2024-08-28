#make new Arduino file based on simulation parameters
simToArduinoFile = function(input){
  #import template Arduino file
  input[[1]] = ceiling(input[[1]]*100) #Decimal Correction
  input[[2]] = ceiling(input[[2]]*100) #Decimal Correction
  all_inputs = input
  
  text <- readLines("DefaultArduinoScript.ino")

  #rearrange arrays to match Arduino input
  rot_inputs = list()
  for (i in 1:length(all_inputs)){
    temp = all_inputs[[i]]
    rotated = t(apply(temp,2,rev))
    colnames(rotated) = NULL
    rownames(rotated) = NULL
    rot_inputs[[i]] = rotated
  }

  #replace Arduino file with simulation paramters
  #create character lines from arrays
  array_chars = list()
  for (i in 1:length(rot_inputs)){
    array_chars[[i]] <- apply(rot_inputs[[i]], 1, function(row) {paste0(paste(row, collapse = ","),",")})
  }

  #replace Arduino lines with array lines
  #replace ON temp (48-59)
  start_line <- 48
  end_line <- start_line + 11  # 12 lines total

  modified_text <- c(
    text[1:(start_line-1)],
    array_chars[[1]],
    text[(end_line+1):length(text)]
  )

  #replace OFF temp (66-77)
  start_line <- 66
  end_line <- start_line + 11  # 12 lines total

  modified_text <- c(
    modified_text[1:(start_line-1)],
    array_chars[[2]],
    modified_text[(end_line+1):length(modified_text)]
  )

  #replace ON time (85-96)
  start_line <- 85
  end_line <- start_line + 11  # 12 lines total

  modified_text <- c(
    modified_text[1:(start_line-1)],
    array_chars[[3]],
    modified_text[(end_line+1):length(modified_text)]
  )

  #replace OFF time (103-114)
  start_line <- 103
  end_line <- start_line + 11  # 12 lines total

  modified_text <- c(
    modified_text[1:(start_line-1)],
    array_chars[[4]],
    modified_text[(end_line+1):length(modified_text)]
  )

  #export Arduino text
  return(modified_text)
}
  