library(tidyverse)
library(sf)
library(RSQLite)

source('scripts/utils.R')

conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')
hospitals <- dbGetQuery(conn, 'SELECT * FROM hospital')
dbDisconnect(conn)

nys <- read_sf('source_data/Counties_Shoreline.shp')
gps <- read_csv('source_data/hospital_gps_coords.csv')

# Summarize number of hospitals by county
county_hospitals <- hospitals %>%
  distinct(permanent_facility_id, .keep_all = TRUE) %>%
  group_by(hospital_service_area, hospital_county) %>%
  summarize(hospitals = n()) %>%
  filter(!is.na(hospitals))

# County geometries
nys <- nys %>%
  left_join(county_hospitals, by = c('NAME' = 'hospital_county'))

# Hospital GPS
gps <- gps %>%
  st_as_sf(coords = c('longitude', 'latitude'), crs = 4326)

# Plot counts of hospitalizations by county
plt <- ggplot() +
  geom_sf(data = nys, aes(fill = hospitals), color = 'black') +
  scale_fill_gradient(low = 'lightblue', high = 'darkblue', na.value = 'white') +
  theme_void() +
  labs(fill = 'Number of Hospitals') +
  geom_sf(data = gps, color = 'black', fill = 'white', shape = 21, stroke = 0.5)

# Save figure
ensure_directory('figures')
ggsave('figures/hospitals_per_county.png', plt, height = 5, width = 7)
