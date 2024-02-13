[![DOI](https://zenodo.org/badge/265254045.svg)](https://zenodo.org/doi/10.5281/zenodo.10442485)

## Introduction
Aggregate three historical (1980-2019) heat wave-related variables (number of heat wave events each year, total heat wave days each year, and highest temperature of the hottest event each year) from 1/8 degree (~12.5 km) grids to county level and Balancing Authority(BA)-level. Heat wave-related variables are calculated based on outputs from Weather Research & Forecasting Model (WRF) and are defined by 12 different heat wave definitions. The aggregation to the county-level involves aggregating by taking the mean, minima, and maxima, while the aggregation to the BA-level implements population-based weighting.

## Code 
"HW_aggregation_to_county" is the R code to aggregate the historical heat wave variables from grids (1/8 degree resolution) to county level. "HW_aggregation_to_BA" is the R code to aggregate the heat wave variables from county level to balancing authority level. "BA_shapefile_generation" is the R code to generate the balancing authority boundary shapfile based on its corresponding counties' boundaries.

## Input and output data
|Dataset |Input/output |Repository link|
|------  |-----------  |-------------- |
|County-level population|Input |https://zenodo.org/records/7130351|
|Balancing authority depiction file|Input |https://zenodo.org/records/7130351|
|Gridded heat wave variables |Input|PIC: /rcfs/projects/im3/TGW_Heat_Waves|
|County-level aggregated heat wave variables|Output|https://github.com/crystalandwan/Alfred_2024_T.B.D/tree/main/data/County_level |
|BA-level aggregated heat wave variables|Output|https://github.com/crystalandwan/Alfred_2024_T.B.D/tree/main/data/BA_level|
