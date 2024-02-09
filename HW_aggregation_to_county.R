library(foreach)
library(doParallel) 

# Register parallel backend
num_cores <- detectCores() -1
registerDoParallel(num_cores) 

# Read in all historical heatwave netCDF file names
files <- list.files(pattern = "his")

#Reorder the file names from definition 1 to definition 12
numbers <- gsub(".*usa(\\d+).*", "\\1", files)
numbers <- as.numeric(numbers)
files <- files[order(numbers)]

# Loop through each netCDF file (12 definitions) for aggregation in parallel
foreach(i = 1:length(files), .packages = c("ncdf4", "raster", "tigris", "sf", "exactextractr", "data.table")) %dopar% {
  # Read in county boundary (CONUS) shapefile from tigris
  County <- counties(cb = TRUE, year = 2020)
  County <- st_transform(County, crs="EPSG:4326") #reproject
  CONUS_county <- County[!(County$STATEFP %in% c('02', '15', '60', '66', '69', '72', '78')), ]
  
  # Read in NetCDF data
  nc_data <- nc_open(files[i])
  
  # Extract the longitude/latitude data
  lon <- ncvar_get(nc_data, "lon")
  lon <- (lon+180) %% 360 -180 #Convert the longitude range to (-180, 180)
  lat <- ncvar_get(nc_data, "lat")
  
  # Create three empty list to store aggregation results for 3 HW variables
  aggregations_list1 <- list()
  aggregations_list2 <- list()
  aggregations_list3 <- list()
  
  # Looping through each year for the aggregation process
  for(year_index in c(1:nc_data$dim$byr$len)){
    # Get the heat wave data for the target year
    stat_hw_data <- ncvar_get(nc_data, "stat_hw", start = c(1, 1, 1, year_index), 
                              count = c(-1, -1, 3, 1))
    
    # Convert the heat wave data to raster stack
    r <- raster(nrow=length(lat), ncol=length(lon))   # Set the raster dimensions
    extent(r) <- extent(min(lon)-1/16, max(lon)+1/16, # Set the raster extent
                        min(lat)-1/16, max(lat)+1/16)
    crs(r) <- CRS("+init=epsg:4326")  # Assign CRS to the raster
    r1 <- r
    r1[] <- apply(t(stat_hw_data[,,1]), 2, rev) # Fill in raster 1 by HW var 1
    r2 <- r
    r2[] <- apply(t(stat_hw_data[,,2]), 2, rev) # Fill in raster 2 by HW var 2
    r3 <- r
    r3[] <- apply(t(stat_hw_data[,,3]), 2, rev) # Fill in raster 3 by HW var 3
    
    # Extract the Heat Wave data to county level
    aggregations1 <- exact_extract(r1, CONUS_county, c('mean', 'max', 'min'))
    aggregations2 <- exact_extract(r2, CONUS_county, c('mean', 'max', 'min'))
    aggregations3 <- exact_extract(r3, CONUS_county, c('mean', 'max', 'min'))
    
    # Add year to column names for easy identification
    colnames(aggregations1) <- paste0("No_", colnames(aggregations1), "_", 
                                      1979+year_index)
    colnames(aggregations2) <- paste0("Day_", colnames(aggregations2), "_", 
                                      1979+year_index)
    colnames(aggregations3) <- paste0("Tem_", colnames(aggregations3), "_", 
                                      1979+year_index)
    
    # Store the aggregation results for the current year in the list
    aggregations_list1[[year_index]] <- aggregations1
    aggregations_list2[[year_index]] <- aggregations2
    aggregations_list3[[year_index]] <- aggregations3
  }
  
  # Combine aggregation results for all years into a single data frame
  combined_aggregations1 <- do.call(cbind, aggregations_list1)
  combined_aggregations2 <- do.call(cbind, aggregations_list2)
  combined_aggregations3 <- do.call(cbind, aggregations_list3)
  
  # Combine county boundaries with aggregation results
  CONUS_county <- cbind(CONUS_county, combined_aggregations1, 
                        combined_aggregations2, combined_aggregations3)
  
  # Remove unnecessary columns in CONUS_county
  columns_to_remove <- c("COUNTYNS", "NAME", "AFFGEOID", "LSAD", "ALAND", "AWATER")
  CONUS_county <- CONUS_county[, setdiff(names(CONUS_county), columns_to_remove)]
  
  # Write out the aggregated data
  CONUS_county <- st_drop_geometry(CONUS_county)
  
  fwrite(CONUS_county, paste0("heatwave_usa", i, "_county_his.csv"))
}

# Stop the parallel backend
stopImplicitCluster()
