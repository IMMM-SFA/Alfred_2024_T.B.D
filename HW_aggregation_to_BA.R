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

# Read in Balancing Authority depiction data
BA <- fread("./BA_depiction/ba_service_territory_2019.csv")

# Get the list of BAs (BA_code)
BA_list <- unique(BA$BA_Code)

# Read in county-level heat wave file names (12 files = 12 heat wave definitions)
files <- list.files("./data/Aggregations", pattern = "his")

# Reorder the file names from definition 1 to definition 12
numbers <- gsub(".*usa(\\d+).*", "\\1", files)
numbers <- as.numeric(numbers)
files <- files[order(numbers)]

#Loop through 12 county-level historical heat wave data 
results_list <- foreach(i = 1:length(files), .packages = c("data.table")) %dopar% {
  # Read in the heat wave county-level data
  hw <- fread(paste0("./data/Aggregations/", files[i]))
  
  # Extract names of all columns that contain heat wave variables
  var_columns <- grep("min|max|mean", colnames(hw), value = TRUE)
  
  # Construct a data frame to store the BA-level aggregated data
  results <- as.data.frame(matrix(0, length(BA_list), length(var_columns) + 1))
  colnames(results) <- c("BA_code", var_columns)
  results$BA_code <- BA_list
  
  # Loop through each BA
  for (j in 1:length(BA_list)){
    # Find all the counties within the target BA
    target_counties <- BA[BA$BA_Code == BA_list[j], ]$County_FIPS
    
    # Extract the pop data for the target counties
    target_pop <- pop[pop$county_FIPS %in% target_counties, ]
    
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
  fwrite(results, paste0("heatwave_usa", i, "_BA_his.csv"))
}

# Stop the parallel cluster
stopCluster(cl)
