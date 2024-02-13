library(sf)
library(data.table)
library(tigris)
library(stringr)

# Set working directory
setwd("C:/Users/wanh535/OneDrive - PNNL/Desktop/IM3/Heat Waves")

# Read in Balancing Authority depiction data
BA <- fread("./BA_depiction/ba_service_territory_2019.csv")

# Get the list of BAs (BA_code)
BA_list <- unique(BA$BA_Code)

# Read in county shapefile
County <- counties(cb = TRUE, year = 2020)
County <- st_transform(County, crs="EPSG:4326") #reproject
# Remove the leading zeros in the geoid to match with the BA data
County$GEOID <- str_remove_all(County$GEOID, "^0+")
CONUS_county <- County[!(County$STATEFP %in% c('02', '15', '60', '66', '69', '72', '78')), ]

# Construct BA shapefile
first = TRUE
for(i in c(1:length(BA_list))){
  print(i)
  target_counties <- BA[BA$BA_Code == BA_list[i], ]$County_FIPS
  counties <- CONUS_county[CONUS_county$GEOID %in% target_counties, ]
  
  if(first == TRUE){
    merged_counties <- st_union(counties)
    df1 <- data.frame(id = BA_list[i])
    merged_counties <- st_sf(df1, geometry = st_sfc(merged_counties))
    first = FALSE
  } else{
    merged <- st_union(counties)
    df2 <- data.frame(id = BA_list[i])
    merged <- st_sf(df2, geometry = st_sfc(merged))
    
    merged_counties <- rbind(merged_counties, merged)
  }
}

st_write(merged_counties, "BA.shp")
