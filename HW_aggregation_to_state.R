library(foreach)
library(doParallel) 
library(data.table)

# Set up parallel backend
no_cores <- detectCores() - 1
cl <- makeCluster(no_cores)
registerDoParallel(cl)

# Set working directory
setwd("C:/Users/wanh535/OneDrive - PNNL/Desktop/IM3/Heat Waves")

# Read in population data at county-level
pop <- fread("./pop_data/county_populations_2000_to_2019.csv")

# Get the list of states
state_list <- unique(pop$state_name)
state_list <- state_list[!state_list %in% c("Alaska", "Hawaii")] # Remove Alaska and Hawaii

# Read in county-level heat wave file names (12 files = 12 heat wave definitions)
files <- list.files("./data/Aggregations/County_level", pattern = "his")

# Reorder the file names from definition 1 to definition 12
numbers <- gsub(".*usa(\\d+).*", "\\1", files)
numbers <- as.numeric(numbers)
files <- files[order(numbers)]

#Loop through 12 county-level historical heat wave data 
results_list <- foreach(i = 1:length(files), .packages = c("data.table")) %dopar% {
  # Read in the heat wave county-level data
  hw <- fread(paste0("./data/Aggregations/County_level/", files[i]))
  
  # Extract names of all columns that contain heat wave variables
  var_columns <- grep("min|max|mean", colnames(hw), value = TRUE)
  
  # Construct a data frame to store the state-level aggregated data
  results <- as.data.frame(matrix(0, length(state_list), length(var_columns) + 1))
  colnames(results) <- c("STATE_NAME", var_columns)
  results$STATE_NAME <- state_list
  
  # Loop through each BA
  for (j in 1:length(state_list)){
    # Find all the counties within the target state
    target_counties <- pop[pop$state_name == state_list[j], ]$county_FIPS
    
    # Extract the pop data for the target counties
    target_pop <- pop[pop$state_name == state_list[j], ]
    
    # Extract the hw data for the target counties
    target_hw <- hw[hw$GEOID %in% target_counties, ]
    
    # Loop through each heat wave variable column in hw
    for(col in var_columns){
      selected_cols <- c("GEOID", col)
      target_hw_target_column <- target_hw[, ..selected_cols]
      
      # Extract the corresponding year for the target column
      target_year <- as.numeric(substr(col, nchar(col)-3, nchar(col)))
      if(target_year < 2000) {    # For hw variables before 2000, use pop data 
        target_year <- 2000 }     # from 2000
      
      # Select the population column matching the year
      pop_col_name <- paste0("pop_", target_year)
      cols_to_select <- c("county_FIPS", pop_col_name)
      target_pop_year_matched <- target_pop[, ..cols_to_select]
      
      # Merge the data
      data_merged <- merge(target_hw_target_column, target_pop_year_matched, 
                           by.x = "GEOID", by.y = "county_FIPS")
      
      # Calculate the mean weighted by population
      results[j, col] <- weighted.mean(x = data_merged[, 2], 
                                       w = data_merged[, 3], na.rm = TRUE)
    }
  }
  
  # Write out the pop-weighted BA-level heat wave variables
  fwrite(results, paste0("heatwave_usa", i, "_state_his.csv"))
}

# Stop the parallel cluster
stopCluster(cl)
