#####################################################
# Generate map of hospitals by county
# Author: Julia Muller
# Date: 5 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(RSQLite)
})

# Source utility functions
source('scripts/utils.R')

# Pull hospital data from database
hospitals <- query_db('SELECT * FROM hospital')

# Import shape files and GPS data
nys <- read_sf('source_data/Counties_Shoreline.shp')
gps <- read_csv('source_data/hospital_gps_coords.csv', show_col_types = F)

# Summarize number of hospitals by county
county_hospitals <- hospitals %>%
  distinct(permanent_facility_id, .keep_all = TRUE) %>%
  group_by(hospital_service_area, hospital_county) %>%
  summarize(hospitals = n()) %>%
  filter(!is.na(hospitals))

# Join county geometries and county-level hospital data
nys <- left_join(nys, county_hospitals, by = c('NAME' = 'hospital_county'))

# Ensure hospital GPS coordinates can be plotted
gps <- gps %>% st_as_sf(coords = c('longitude', 'latitude'), crs = 4326)

# Plot counts of hospitals by county
plt <- ggplot() +
  geom_sf(data = nys, aes(fill = hospitals), color = 'black') +
  scale_fill_gradient(low = 'lightblue', high = 'darkblue', na.value = 'white') +
  theme_void() +
  labs(fill = 'Number of Hospitals') +
  geom_sf(data = gps, color = 'black', fill = 'white', shape = 21, stroke = 0.5)

# Save figure
ensure_directory('figures')
ggsave('figures/hospitals_per_county.png', plt, height = 5, width = 7)
write_rds(plt, 'figures/hospitals_per_county.rds')
