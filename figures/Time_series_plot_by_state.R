library(data.table)


setwd("C:/Users/wanh535/OneDrive - PNNL/Desktop/IM3/Heat Waves/data/Aggregations/State_level")

# Read in all historical heatwave netCDF file names
files <- list.files(pattern = "his")

#Reorder the file names from definition 1 to definition 12
numbers <- gsub(".*usa(\\d+).*", "\\1", files)
numbers <- as.numeric(numbers)
files <- files[order(numbers)]

# Extract all the state names
hw <- fread(files[1])
unique_states <- unique(hw$STATE_NAME)


var <- c("No_mean", "No_min", "No_max", "Day_mean", "Day_min", "Day_max", 
         "Tem_mean", "Tem_min", "Tem_max")

# Loop through each hw variables
for (variable in var){
  # Loop through each state 
  for (state in unique_states){
    # Put the plot into different folder
    if(variable == var[1]){
      output_path = "./Number of heat wave events/Mean/"
    } else if(variable == var[2]){
      output_path = "./Number of heat wave events/Min/"
    }else if(variable == var[3]){
      output_path = "./Number of heat wave events/Max/"
    }else if(variable == var[4]){
      output_path = "./Total heat wave days/Mean/"
    }else if(variable == var[5]){
      output_path = "./Total heat wave days/Min/"
    }else if(variable == var[6]){
      output_path = "./Total heat wave days/Max/"
    }else if(variable == var[7]){
      output_path = "./Highest Temperature/Mean/"
    }else if(variable == var[8]){
      output_path = "./Highest Temperature/Min/"
    }else if(variable == var[9]){
      output_path = "./Highest Temperature/Max/"
    }
    
    png(filename = paste0(output_path, state, "_", variable, ".png"), 
        width = 800, height = 600)
    
   # Set a reasonable y value limit for each plot
    global_min <- Inf # Initialize variables to store the global min and max
    global_max <- -Inf
    for(i in c(1:length(files))){ # Loop through files to update the global min 
      hw <- fread(files[i])       # and max based on each file's data
      cols_index <- grep(variable, colnames(hw))
      row_index <- which(hw$STATE_NAME == state)
      y_values <- hw[row_index, ..cols_index]
      
      current_min <- min(y_values, na.rm = TRUE)
      current_max <- max(y_values, na.rm = TRUE)
      
      # Update global min and max
      if(current_min < global_min) global_min <- current_min
      if(current_max > global_max) global_max <- current_max
    }
    
    # Use the global min and max to pre-set the plot
    plot(1980:2019, type = "n", xlim = c(1980,2019), ylim = c(global_min, global_max), 
         xlab = "Year", ylab = variable, main = state)
    colors <- rainbow(length(files))
    
    # Loop through each definition for time-series line plot
    for(j in c(1:length(files))){
      hw <- fread(files[j])
      cols_index <- grep(variable, colnames(hw))
      row_index <- which(hw$STATE_NAME == state)
      y_values <- hw[row_index, ..cols_index]
      lines(x = c(1980:2019), y = y_values, col = colors[j])
    }
    legend("topleft", legend=paste('Def.', seq_along(files)), col = colors, 
           lty  = 1, ncol = 2, bg=rgb(1, 1, 1, 0.5))
    dev.off()
  }
}









